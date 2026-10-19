// SPDX-License-Identifier: MIT

import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Controls.Material 6.5
import QtQuick.Layouts 6.5

import MapLibre 4.0

Window {
    id: window
    visible: true
    // Normal window (not maximized) filled entirely by the map.
    width: Qt.platform.os === "android" ? Screen.width : 1024
    height: Qt.platform.os === "android" ? Screen.height : 768
    visibility: Qt.platform.os === "android" ? Window.FullScreen : Window.Windowed

    // Controls style (dialogs, buttons, text fields)
    property bool darkMode: false
    Material.theme: darkMode ? Material.Dark : Material.Light
    Material.accent: "#2d7ef7"

    // ---- Application (UI) scale -------------------------------------------------
    // Scales the whole application, including the map and its labels, via
    // QT_SCALE_FACTOR. Applied on startup, so a restart is required to change it.
    property double appliedScale: appState.appliedScale()
    property double selectedScale: appliedScale
    readonly property var scalePresets: [0.75, 1.0, 1.25, 1.5, 2.0]
    readonly property bool scalePending: Math.abs(selectedScale - appliedScale) > 0.001

    // 3D = globe projection (sphere when zoomed out); 2D = flat Mercator.
    property bool globe3D: true
    // 3D terrain: drape the DEM source "dem" over the map (requires a style with a raster-dem source named "dem").
    property bool terrainEnabled: false
    // Sky: the horizon gradient (and the globe's atmosphere); the style's own `sky` is kept when it has one.
    property bool skyEnabled: true
    // Camera tilt (pitch) and bearing (rotation) in degrees. Tracked here so the
    // middle-drag tilt gesture and the compass rose have a value to read and modify.
    property real mapTilt: 0
    property real mapBearing: 0

    // 3D buildings opacity: Liberty's "building-3d" layer is 0.8 by default.
    property bool buildingsOpaque: false
    // The 3D-buildings opacity override only applies to styles that actually
    // contain a "building-3d" fill-extrusion layer (the OpenFreeMap styles).
    // It is added/removed dynamically so styles without it (e.g. Open Waters)
    // don't log "Unable to add layer building-3d" / "Layer not found".
    property var buildingLayerParam: null

    // True while any modal dialog is open. The map's gesture handlers are
    // disabled then, so touch is handled by the dialog (otherwise dragging a
    // list inside a dialog scrolled the map behind it).
    readonly property bool dialogOpen:
        presetsDialog.visible || settingsDialog.visible || mapDialog.visible
        || presetDialog.visible || addMapDialog.visible

    // ---- Camera presets ---------------------------------------------------------
    // Each entry: { name: string, center: [lat, lon], zoom: real, globe3D: bool }
    property var presets: []
    property int presetIndex: -1
    // Set while a preset's style is loading; the camera is applied once it loads.
    property var pendingPreset: null

    // ---- Map styles (style URLs) ------------------------------------------------
    // Each entry: { name: string, url: string }
    property string styleUrl: "https://tiles.openfreemap.org/styles/liberty"
    property var mapStyles: []
    property int mapIndex: -1
    readonly property var defaultMapStyles: [
        { "name": "Liberty (OSM)", "url": "https://tiles.openfreemap.org/styles/liberty" },
        { "name": "Bright (OSM)", "url": "https://tiles.openfreemap.org/styles/bright" },
        { "name": "Positron (OSM)", "url": "https://tiles.openfreemap.org/styles/positron" },
        { "name": "Open Waters", "url": "https://tiles.openwaters.io/seamap/style.json" },
        { "name": "3D Terrain (satellite draped)", "url": window.terrainStyleUrl },
        { "name": "3D Terrain (GL JS example)", "url": window.gljsTerrainStyleUrl }
    ]

    // Local style with a raster-dem source + `terrain`, so the satellite imagery is draped over the relief.
    // maplibre's local file source needs "file://" followed directly by the drive path (not a third slash).
    // Adjust this path to wherever the repo's terrain-style.json lives on your machine.
    readonly property string terrainStyleUrl: Qt.platform.os === "windows"
        ? "file://C:/hda/dev/Projects/MapLibreEarth/terrain-style.json"
        : "file:///home/takserver1/dev/projects/maplibreearth/terrain-style.json"

    // The MapLibre GL JS "3D Terrain" example style (Mapterhorn DEM + OSM raster + hillshade) for comparison.
    readonly property string gljsTerrainStyleUrl: Qt.platform.os === "windows"
        ? "file://C:/hda/dev/Projects/MapLibreEarth/gljs-terrain-style.json"
        : "file:///home/takserver1/dev/projects/maplibreearth/gljs-terrain-style.json"

    // QSettings returns stored booleans as strings ("true"/"false").
    function asBool(v) {
        return v === true || v === "true" || v === 1;
    }

    function nearestScalePresetIndex(value) {
        let best = 0;
        let bestDist = Math.abs(scalePresets[0] - value);
        for (let i = 1; i < scalePresets.length; ++i) {
            const d = Math.abs(scalePresets[i] - value);
            if (d < bestDist) {
                bestDist = d;
                best = i;
            }
        }
        return best;
    }

    function stepScale(direction) {
        let index = nearestScalePresetIndex(selectedScale) + direction;
        index = Math.max(0, Math.min(scalePresets.length - 1, index));
        selectedScale = scalePresets[index];
    }

    function restartNow() {
        saveState();
        appState.applyAndRestart(selectedScale);
    }

    // ---- Camera (tilt / bearing) ------------------------------------------------
    // Apply the tracked tilt + bearing to the map. `animated` eases the change.
    function applyCamera(animated) {
        // Keep center + zoom: a style load resets the camera, and an easeTo without zoom leaves the map's
        // transform at a stale, low zoom (the draped raster source then builds its tile cover at z2).
        map.easeTo({ center: map.coordinate, zoom: map.zoomLevel, pitch: window.mapTilt, bearing: window.mapBearing },
                    { duration: animated ? 300 : 0 });
    }

    // Apply only the tracked tilt + bearing, leaving centre and zoom as the map has them. Used by the gestures and the
    // compass: `map.coordinate` / `map.zoomLevel` are stale while a preset's flyTo runs and after it (they are only
    // refreshed by gestures), so re-passing them would jump the map back to an old position.
    function applyOrientation(animated) {
        map.easeTo({ pitch: window.mapTilt, bearing: window.mapBearing }, { duration: animated ? 300 : 0 });
    }

    // 2D / 3D projection toggle: 3D = globe (sphere when zoomed out), 2D = flat Mercator.
    // The zoom is left unchanged, so the same zoom applies in both projections.
    function toggle3D() {
        window.globe3D = !window.globe3D;
    }

    // Middle-drag tilt: vertical -> pitch, horizontal -> bearing (rotate).
    function tiltBy(dx, dy) {
        window.mapTilt = Math.max(0, Math.min(85, window.mapTilt - dy * 0.4));
        window.mapBearing = window.mapBearing + dx * 0.4;
        applyOrientation(false);
    }

    // Compass rose actions.
    function northUp() {
        window.mapBearing = 0;
        applyOrientation(true);
    }

    function tiltZero() {
        window.mapTilt = 0;
        applyOrientation(true);
    }

    // Zoom in/out buttons (anchored at the map centre).
    function zoomBy(steps) {
        map.scale(Math.pow(2, steps), Qt.point(map.width / 2, map.height / 2));
    }

    // Adds the 3D-buildings opacity override for styles that have the layer,
    // removes it otherwise.
    function syncBuildingOverride() {
        const supported = window.styleUrl.indexOf("openfreemap.org") !== -1;
        if (supported && window.buildingLayerParam === null) {
            window.buildingLayerParam = buildingLayerComponent.createObject(map);
            map.addStyleParameter(window.buildingLayerParam);
        } else if (!supported && window.buildingLayerParam !== null) {
            map.removeStyleParameter(window.buildingLayerParam);
            window.buildingLayerParam.destroy();
            window.buildingLayerParam = null;
        }
    }

    Component {
        id: buildingLayerComponent
        LayerParameter {
            styleId: "building-3d"
            type: "fill-extrusion"
            paint: ({ "fill-extrusion-opacity": window.buildingsOpaque ? 1.0 : 0.8 })
        }
    }

    // ---- Camera presets ---------------------------------------------------------
    function savePresets() {
        appState.setValue("presets/list", JSON.stringify(presets));
    }

    function loadPresets() {
        const raw = appState.value("presets/list");
        if (raw === undefined || raw === null || raw === "") {
            presets = [];
            return;
        }
        try {
            const parsed = JSON.parse(raw);
            presets = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            presets = [];
        }
    }

    function addPreset(name, saveMap) {
        const c = map.liveCoordinate();
        const entry = {
            "name": name,
            "center": [c[0], c[1]],
            "zoom": map.liveZoom(),
            "globe3D": window.globe3D,
            "tilt": window.mapTilt,
            "bearing": window.mapBearing
        };
        if (saveMap) {
            entry["styleUrl"] = window.styleUrl;
        }
        window.presets = window.presets.concat([entry]);
        window.savePresets();
        window.presetIndex = window.presets.length - 1;
    }

    function removePresetAt(i) {
        if (i < 0 || i >= window.presets.length) {
            return;
        }
        const arr = window.presets.slice();
        arr.splice(i, 1);
        window.presets = arr;
        window.savePresets();
        window.presetIndex = arr.length > 0 ? Math.min(i, arr.length - 1) : -1;
    }

    function editPresetAt(i, name, saveMap) {
        if (i < 0 || i >= window.presets.length) {
            return;
        }
        // Editing updates all the preset values from the current camera (and the current
        // map when "Save map" is ticked).
        const c = map.liveCoordinate();
        const arr = window.presets.slice();
        const p = Object.assign({}, arr[i]);
        p.name = name;
        p.center = [c[0], c[1]];
        p.zoom = map.liveZoom();
        p.tilt = window.mapTilt;
        p.bearing = window.mapBearing;
        p.globe3D = window.globe3D;
        if (saveMap) {
            p.styleUrl = window.styleUrl;
        } else {
            delete p.styleUrl;
        }
        arr[i] = p;
        window.presets = arr;
        window.savePresets();
    }

    function flyToPreset(i) {
        if (i < 0 || i >= window.presets.length) {
            return;
        }
        window.presetIndex = i;
        const p = window.presets[i];
        window.globe3D = p.globe3D === true;
        // Switch to the preset's map (style) when it was saved with one. Changing the
        // style reloads it, which resets the camera, so defer the flyTo until the new
        // style has loaded (see the styleLoaded Connections below).
        if (p.styleUrl && p.styleUrl !== window.styleUrl) {
            window.pendingPreset = p;
            window.styleUrl = p.styleUrl;
            return;
        }
        window.applyPresetCamera(p);
    }

    function applyPresetCamera(p) {
        window.mapTilt = p.tilt !== undefined ? p.tilt : 0;
        window.mapBearing = p.bearing !== undefined ? p.bearing : 0;
        map.flyTo({ center: p.center, zoom: p.zoom, pitch: window.mapTilt, bearing: window.mapBearing },
                  { duration: 1500 });
    }

    // ---- Map styles -------------------------------------------------------------
    function saveMapStyles() {
        appState.setValue("maps/list", JSON.stringify(mapStyles));
    }

    function loadMapStyles() {
        const raw = appState.value("maps/list");
        let parsed = null;
        if (raw !== undefined && raw !== null && raw !== "") {
            try {
                const arr = JSON.parse(raw);
                if (Array.isArray(arr)) {
                    parsed = arr;
                }
            } catch (e) {
                parsed = null;
            }
        }
        if (parsed !== null && parsed.length > 0) {
            // Migrate the old "MapLibre Demo" (demotiles) entry to Open Waters.
            let styles = parsed.map(function(m) {
                if (m && m.url === "https://demotiles.maplibre.org/style.json") {
                    return { "name": "Open Waters", "url": "https://tiles.openwaters.io/seamap/style.json" };
                }
                // Re-point a saved terrain-style.json entry at this machine's path.
                if (m && m.url && m.url.endsWith("/terrain-style.json") && m.url !== window.terrainStyleUrl) {
                    return { "name": m.name, "url": window.terrainStyleUrl };
                }
                return m;
            });
            // Ensure the built-in maps are present (e.g. after adding a new one in a later version).
            const known = {};
            styles.forEach(function(m) {
                if (m && m.url) {
                    known[m.url] = true;
                }
            });
            defaultMapStyles.forEach(function(d) {
                if (!known[d.url]) {
                    styles = styles.concat([d]);
                }
            });
            mapStyles = styles;
            saveMapStyles();
        } else {
            mapStyles = defaultMapStyles.slice();
            saveMapStyles();
        }
    }

    function addMapStyle(name, url) {
        const entry = { "name": name, "url": url };
        window.mapStyles = window.mapStyles.concat([entry]);
        window.saveMapStyles();
        window.mapIndex = window.mapStyles.length - 1;
    }

    function removeMapAt(i) {
        if (i < 0 || i >= window.mapStyles.length) {
            return;
        }
        const arr = window.mapStyles.slice();
        arr.splice(i, 1);
        window.mapStyles = arr;
        window.saveMapStyles();
        window.mapIndex = arr.length > 0 ? Math.min(i, arr.length - 1) : -1;
    }

    function selectMap(i) {
        if (i < 0 || i >= window.mapStyles.length) {
            return;
        }
        window.mapIndex = i;
        window.styleUrl = window.mapStyles[i].url;
        appState.setValue("map/styleUrl", window.styleUrl);
    }

    // ---- Persisted state --------------------------------------------------------
    function saveState() {
        // On Android the window is full-screen; don't persist window geometry.
        if (Qt.platform.os !== "android") {
            appState.setValue("window/width", window.width);
            appState.setValue("window/height", window.height);
            appState.setValue("window/x", window.x);
            appState.setValue("window/y", window.y);
        }
        appState.setValue("map/coordinate", map.liveCoordinate());
        appState.setValue("map/zoomLevel", map.liveZoom());
        appState.setValue("map/tilt", window.mapTilt);
        appState.setValue("map/bearing", window.mapBearing);
        appState.setValue("map/globe3D", window.globe3D);
        appState.setValue("map/styleUrl", window.styleUrl);
        appState.setValue("ui/darkMode", window.darkMode);
        savePresets();
        saveMapStyles();
    }

    function restoreState() {
        // On Android the window is full-screen; don't restore window geometry
        // (a stale persisted size would leave the map not filling the screen).
        if (Qt.platform.os !== "android") {
            const w = appState.value("window/width");
            const h = appState.value("window/height");
            if (w !== undefined && h !== undefined && w > 0 && h > 0) {
                window.width = w;
                window.height = h;
            }

            const x = appState.value("window/x");
            const y = appState.value("window/y");
            if (x !== undefined && y !== undefined && isOnScreen(x, y, window.width, window.height)) {
                window.x = x;
                window.y = y;
            }
        }

        const coordinate = appState.value("map/coordinate");
        if (coordinate !== undefined && coordinate.length === 2) {
            map.coordinate = coordinate;
        }

        const zoom = appState.value("map/zoomLevel");
        if (zoom !== undefined && zoom > 0) {
            map.zoomLevel = zoom;
        }

        if (asBool(appState.value("map/globe3D"))) {
            window.globe3D = true;
        }

        if (appState.value("map/skyEnabled") !== undefined) {
            window.skyEnabled = asBool(appState.value("map/skyEnabled"));
        }
        if (asBool(appState.value("map/terrainEnabled"))) {
            window.terrainEnabled = true;
        }

        const storedStyle = appState.value("map/styleUrl");
        if (storedStyle !== undefined && storedStyle !== null && storedStyle !== "") {
            window.styleUrl = storedStyle;
        }
        if (window.styleUrl === "https://demotiles.maplibre.org/style.json") {
            // follow the MapLibre Demo -> Open Waters change
            window.styleUrl = "https://tiles.openwaters.io/seamap/style.json";
            appState.setValue("map/styleUrl", window.styleUrl);
        }

        // Restore the camera tilt and heading. The style's
        // load re-applies them (see onStyleLoadedChanged -> applyCamera).
        const savedTilt = Number(appState.value("map/tilt"));
        const savedBearing = Number(appState.value("map/bearing"));
        if (appState.value("map/tilt") !== undefined && isFinite(savedTilt)) {
            window.mapTilt = Math.max(0, Math.min(85, savedTilt));
        }
        if (appState.value("map/bearing") !== undefined && isFinite(savedBearing)) {
            window.mapBearing = savedBearing;
        }
        if (appState.value("map/tilt") !== undefined || appState.value("map/bearing") !== undefined) {
            window.applyCamera(false);
        }

        window.darkMode = asBool(appState.value("ui/darkMode"));

        loadPresets();
        window.presetIndex = -1;
        loadMapStyles();
        window.mapIndex = -1;
    }

    function isOnScreen(x, y, w, h) {
        const screens = Qt.application.screens;
        for (let i = 0; i < screens.length; ++i) {
            const s = screens[i];
            if (x < s.virtualX + s.width && x + w > s.virtualX
                    && y < s.virtualY + s.height && y + h > s.virtualY) {
                return true;
            }
        }
        return false;
    }

    Component.onCompleted: {
        restoreState();
        syncBuildingOverride();
    }
    onClosing: saveState()
    onStyleUrlChanged: {
        syncBuildingOverride();
        // The draped-terrain style needs its "dem" terrain enabled (setting terrainSource="dem" turns terrain on;
        // an empty terrainSource would clear the style's own terrain).
        if (window.styleUrl.indexOf("terrain-style.json") !== -1) {
            window.terrainEnabled = true;
            appState.setValue("map/terrainEnabled", true);
        } else if (window.terrainEnabled) {
            // The terrain toggle only applies to the draped-terrain style (it has a "dem" source); leave it off
            // for other styles so we don't ask for a source they don't have.
            window.terrainEnabled = false;
            appState.setValue("map/terrainEnabled", false);
        }
    }

    // Persist the scale as soon as the user changes it, so it survives an abrupt
    // exit too (the value is applied on the next start). The untouched default
    // of 1.0 is left unset so it does not override native/OS scaling.
    onSelectedScaleChanged: {
        if (appState.hasExplicitScale() || Math.abs(selectedScale - 1.0) > 0.001) {
            appState.setValue("ui/scaleFactor", selectedScale);
        }
        if (scaleSlider) {
            scaleSlider.value = selectedScale;
        }
    }

    // Re-apply the tilt when the style (re)loads, as a style load resets the camera.
    Connections {
        target: map
        function onStyleLoadedChanged() {
            if (!map.styleLoaded) {
                return;
            }
            if (window.pendingPreset) {
                // A preset's style was just loaded; now fly the camera to the preset.
                const p = window.pendingPreset;
                window.pendingPreset = null;
                window.applyPresetCamera(p);
            } else {
                window.applyCamera(false);
            }
        }
    }

    Shortcut { sequence: "Ctrl+="; onActivated: { window.stepScale(1); settingsDialog.open(); } }
    Shortcut { sequence: "Ctrl+Shift+="; onActivated: { window.stepScale(1); settingsDialog.open(); } }
    Shortcut { sequence: "Ctrl+-"; onActivated: { window.stepScale(-1); settingsDialog.open(); } }
    Shortcut { sequence: "Ctrl+0"; onActivated: { window.selectedScale = 1.0; settingsDialog.open(); } }

    MapLibre {
        id: map
        anchors.fill: parent
        focus: true

        style: window.styleUrl
        zoomLevel: 4
        coordinate: [51.5074, -0.1278]

        // 2D / 3D projection. 3D = globe (sphere when zoomed out); 2D = flat Mercator.
        projectionType: window.globe3D ? MapLibre.Globe : MapLibre.Mercator

        // Space backdrop shown around the globe.
        backgroundColor: "#333366"

        // 3D terrain: the DEM source ("dem") is draped as an elevated surface.
        terrainSource: window.terrainEnabled ? "dem" : ""

        // Sky (GL JS `map.setSky`): default sky unless the style defines its own.
        skyEnabled: window.skyEnabled
        terrainExaggeration: 1.0

        // The 3D-buildings opacity override is added dynamically in C++/QML via
        // syncBuildingOverride() (see the Component at the top level).

        // Two-finger pinch: zoom about the centroid (the point between the
        // fingers stays put). Scale-only, like the upstream example.
        PinchHandler {
            id: pinch
            target: null
            acceptedDevices: PointerDevice.TouchScreen
            enabled: !window.dialogOpen
            onScaleChanged: (delta) => {
                if (delta > 0.25 && delta < 4.0) {
                    map.scale(delta, pinch.centroid.position)
                }
            }
        }

        // Single-finger touch pan, as a one-point PinchHandler (touch only, so the
        // mouse gestures below own the mouse buttons).
        PinchHandler {
            id: panHandler
            target: null
            acceptedDevices: PointerDevice.TouchScreen
            minimumPointCount: 1
            maximumPointCount: 1
            enabled: !window.dialogOpen
            onTranslationChanged: (delta) => {
                if (Math.abs(delta.x) < 200 && Math.abs(delta.y) < 200) {
                    map.pan(Qt.point(delta.x, delta.y))
                }
            }
        }

        // Mouse gestures, aligned with MapLibre GL JS (handler_manager.ts, handler/mouse.ts, handler/scroll_zoom.ts,
        // handler_inertia.ts, handler/click_zoom.ts). See wiki/references/gljs-alignment.md for the agreed deviations.
        //   left drag = pan (grabbed point stays under the cursor, at the terrain height there) with inertia
        //   right drag / ctrl+left drag = rotate (0.8 deg/px, circular about the centre) + pitch (-0.5 deg/px)
        //   wheel / trackpad = scroll zoom about the cursor; double click = zoom in (shift: out)
        //   middle drag = continuous zoom (DEVIATION agreed with John: kept from the earlier app, not in GL JS)
        QtObject {
            id: gest
            readonly property real clickTolerance: 3
            readonly property real rotateSpeed: 0.8
            readonly property real pitchSpeed: -0.5
            readonly property real bearingSnap: 7
            // pan
            property var samples: []
            property real anchorElevation: NaN
            // Terrain drag whose start point is not on the terrain (sky / beyond the DEM): GL JS pans by the pixel delta about the centre.
            property bool centerPan: false
            property real inertiaDone: 0
            property point inertiaPan: Qt.point(0, 0)
            // scroll zoom (ScrollZoomHandler)
            readonly property real wheelZoomDelta: 4.000244140625
            readonly property real defaultZoomRate: 1 / 100
            readonly property real wheelZoomRate: 1 / 450
            readonly property real maxScalePerFrame: 2
            // deltaY the reference browser reports for one mouse wheel notch. Calibrated on John's setup: GL JS zooms
            // 0.337 levels per click there (2/(1+exp(-d/450)) = 2^0.337 -> d = 242.6); ours gave 0.151 with 100.
            property real wheelNotchDelta: 242.6
            property real wheelDelta: 0
            property string wheelType: ""
            property real lastWheelTime: 0
            property point aroundPoint: Qt.point(0, 0)
            property bool zoomActive: false
            property real targetZoom: NaN
            property real startZoom: NaN
            property var zoomEasing: null
            property var prevEase: null

            // WebKit/GL JS unit bezier.
            function bezier(x1, y1, x2, y2) {
                const cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx;
                const cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by;
                const sx = t => ((ax * t + bx) * t + cx) * t;
                const sy = t => ((ay * t + by) * t + cy) * t;
                const dx = t => (3 * ax * t + 2 * bx) * t + cx;
                return function (x) {
                    let t = x;
                    for (let i = 0; i < 8; i++) {
                        const e = sx(t) - x;
                        if (Math.abs(e) < 1e-6) { return sy(t); }
                        const d = dx(t);
                        if (Math.abs(d) < 1e-6) { break; }
                        t -= e / d;
                    }
                    let lo = 0, hi = 1;
                    t = x;
                    while (lo < hi) {
                        const v = sx(t);
                        if (Math.abs(v - x) < 1e-6) { break; }
                        if (x > v) { lo = t; } else { hi = t; }
                        t = (hi - lo) * 0.5 + lo;
                    }
                    return sy(t);
                };
            }
            readonly property var defaultEasing: bezier(0.25, 0.1, 0.25, 1)
            readonly property var inertiaEasing: bezier(0, 0, 0.3, 1)

            // Anchor elevation for a pointer position (GL JS screenTerrainPointToMercatorCoordinate); NaN = centre plane.
            function elevationAt(pos) {
                if (map.globeRendering()) { return NaN; }
                const tp = map.terrainPointAt(pos);
                if (tp.elevation === undefined) { return NaN; }
                // handler_manager.ts: an anchor plane too close to the camera is not stable; solve on the centre plane.
                if (tp.elevation - map.elevation() >= 0.9 * (map.cameraAltitude() - map.elevation())) { return NaN; }
                return tp.elevation;
            }

            // GL JS pan (setLocationAtPoint): the location under `from` goes under `to`.
            function dragPan(from, to, elevation) {
                if (map.globeRendering() || centerPan) {
                    map.pan(Qt.point(to.x - from.x, to.y - from.y));
                    return;
                }
                const loc = map.coordinateAtElevation(from, elevation);
                if (loc.latitude !== undefined && map.setLocationAtPoint(loc.latitude, loc.longitude, to, elevation)) {
                    return;
                }
                // Pointer above the horizon: pan by the pixel delta about the centre (handler_manager.ts).
                map.pan(Qt.point(to.x - from.x, to.y - from.y));
            }

            // Zoom by dz levels, keeping the location under `pos` (at the terrain height there) in place.
            function zoomAround(pos, dz) {
                if (!dz) { return; }
                if (map.globeRendering()) {
                    map.scale(Math.pow(2.0, dz), pos);
                    return;
                }
                const elevation = elevationAt(pos);
                const loc = map.coordinateAtElevation(pos, elevation);
                map.easeTo({ zoom: map.liveZoom() + dz }, { duration: 0 });
                if (loc.latitude !== undefined) {
                    map.setLocationAtPoint(loc.latitude, loc.longitude, pos, elevation);
                }
            }

            // ---- pan inertia (handler_inertia.ts) ----
            function record(dx, dy) {
                const now = Date.now();
                samples = samples.filter(s => now - s.t <= 160).concat([{ t: now, dx: dx, dy: dy }]);
            }
            function startInertia() {
                const now = Date.now();
                const e = samples.filter(s => now - s.t <= 160);
                samples = [];
                if (e.length < 2) { return; }
                let first = Math.max(0, e.length - 2);
                while (first > 0 && e[first - 1].t >= now - 60) { first--; }
                const used = e.slice(first);
                if (used.length < 2) { return; }
                let px = 0, py = 0;
                for (let i = 1; i < used.length; i++) { px += used[i].dx; py += used[i].dy; }
                const mag = Math.hypot(px, py);
                if (!mag) { return; }
                const duration = now - used[0].t;
                const linearity = 0.3, maxSpeed = 1400, deceleration = 2500;
                const speed = Math.max(-maxSpeed, Math.min(maxSpeed, mag * linearity / (duration / 1000)));
                const seconds = Math.abs(speed) / (deceleration * linearity);
                const amount = speed * (seconds / 2);
                let panX = px * amount / mag, panY = py * amount / mag;
                // handlePanInertia (mercator_camera_helper.ts): never past the horizon, 0.75 of the pixels to it
                // (getMercatorHorizon: cameraToCenterDistance * min(tan(90 - pitch) * 0.85, tan(89.25 - pitch))).
                const deg = Math.PI / 180;
                const horizon = Math.abs(1.5 * map.height * Math.min(Math.tan((90 - window.mapTilt) * deg) * 0.85,
                                                                      Math.tan((89.25 - window.mapTilt) * deg)));
                const len = Math.hypot(panX, panY);
                if (len > 0) {
                    const k = Math.min(horizon * 0.75 / len, 1.0);
                    panX *= k;
                    panY *= k;
                }
                inertiaPan = Qt.point(panX, panY);
                inertiaDone = 0;
                inertiaAnim.previous = 0;
                inertiaAnim.duration = seconds * 1000;
                inertiaAnim.restart();
            }
            function stopInertia() { inertiaAnim.stop(); }

            // ---- scroll zoom (scroll_zoom.ts) ----
            function wheelEvent(angleY, pixelY, shift, pos) {
                // Qt tells wheel (angleDelta only) from trackpad (pixelDelta) directly: GL JS's timing heuristic is not needed.
                let value;
                if (pixelY !== 0) {
                    wheelType = "trackpad";
                    value = -pixelY;
                } else {
                    wheelType = "wheel";
                    value = -angleY / 120 * wheelNotchDelta;
                }
                if (shift && value) { value = value / 4; }
                lastWheelTime = Date.now();
                wheelDelta -= value;
                if (!zoomActive) {
                    zoomActive = true;
                    aroundPoint = pos;
                    frameTimer.start();
                }
            }
            function zoomFrame() {
                const cur = map.liveZoom();
                if (wheelDelta !== 0) {
                    const rate = (wheelType === "wheel" && Math.abs(wheelDelta) > wheelZoomDelta) ? wheelZoomRate : defaultZoomRate;
                    let scale = maxScalePerFrame / (1 + Math.exp(-Math.abs(wheelDelta * rate)));
                    if (wheelDelta < 0 && scale !== 0) { scale = 1 / scale; }
                    const from = isNaN(targetZoom) ? cur : targetZoom;
                    targetZoom = Math.max(0, Math.min(22, from + Math.log(scale) / Math.LN2));
                    if (wheelType === "wheel") {
                        startZoom = cur;
                        zoomEasing = smoothOutEasing(200);
                    }
                    wheelDelta = 0;
                }
                const target = isNaN(targetZoom) ? cur : targetZoom;
                let zoom, finished = false;
                if (wheelType === "wheel" && !isNaN(startZoom) && zoomEasing) {
                    const t = Math.min((Date.now() - lastWheelTime + 5) / 200, 1);
                    zoom = startZoom + (target - startZoom) * zoomEasing(t);
                    finished = t >= 1;
                } else {
                    zoom = target;
                    finished = true;
                }
                zoomAround(aroundPoint, zoom - cur);
                if (finished) {
                    frameTimer.stop();
                    zoomActive = false;
                    clearTimer.restart();
                }
            }
            function smoothOutEasing(duration) {
                let easing = defaultEasing;
                if (prevEase) {
                    const t = (Date.now() - prevEase.start) / prevEase.duration;
                    const speed = prevEase.easing(t + 0.01) - prevEase.easing(t);
                    const x = 0.27 / Math.sqrt(speed * speed + 0.0001) * 0.01;
                    const y = Math.sqrt(0.27 * 0.27 - x * x);
                    easing = bezier(x, y, 0.25, 1);
                }
                prevEase = { start: Date.now(), duration: duration, easing: easing };
                return easing;
            }
        }

        NumberAnimation {
            id: inertiaAnim
            target: gest
            property: "inertiaDone"
            from: 0
            to: 1
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0, 0, 0.3, 1, 1, 1]
            property real previous: 0
            onStarted: previous = 0
            onRunningChanged: if (!running) { gest.inertiaDone = 0; map.setElevationHold(false); }
        }
        Connections {
            target: gest
            function onInertiaDoneChanged() {
                if (!inertiaAnim.running) { return; }
                const k = gest.inertiaDone, d = k - inertiaAnim.previous;
                inertiaAnim.previous = k;
                const c = Qt.point(map.width / 2, map.height / 2);
                gest.dragPan(c, Qt.point(c.x + gest.inertiaPan.x * d, c.y + gest.inertiaPan.y * d), NaN);
            }
        }
        Timer {
            id: frameTimer
            interval: 16
            repeat: true
            onTriggered: gest.zoomFrame()
        }
        Timer {
            id: clearTimer
            interval: 200
            onTriggered: { gest.targetZoom = NaN; gest.startZoom = NaN; }
        }

        MouseArea {
            id: mouseGestures
            anchors.fill: parent
            enabled: !window.dialogOpen
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            property point startPos
            property point lastPos
            property int activeButton: Qt.NoButton
            property bool rotateMode: false
            property bool moved: false
            property point panApplied
            property bool panPending: false

            function flushPan() {
                if (!panPending) { return; }
                panPending = false;
                const to = Qt.point(lastPos.x, lastPos.y);
                gest.dragPan(panApplied, to, gest.anchorElevation);
                gest.record(to.x - panApplied.x, to.y - panApplied.y);
                panApplied = to;
            }
            FrameAnimation {
                running: mouseGestures.panPending
                onTriggered: mouseGestures.flushPan()
            }

            onPressed: (mouse) => {
                gest.stopInertia();
                gest.wheelDelta = 0;
                startPos = Qt.point(mouse.x, mouse.y);
                lastPos = startPos;
                activeButton = mouse.button;
                moved = false;
                rotateMode = mouse.button === Qt.RightButton
                             || (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier));
                gest.samples = [];
                panPending = false;
            }
            onReleased: (mouse) => handleRelease()
            function handleRelease() {
                if (moved && activeButton === Qt.LeftButton && !rotateMode) {
                    flushPan();
                    gest.startInertia();
                    if (!inertiaAnim.running) { map.setElevationHold(false); }
                }
                if (moved && rotateMode) {
                    // bearingSnap: snap to north within 7 degrees at the end of the gesture.
                    let b = window.mapBearing % 360;
                    if (b > 180) { b -= 360; } else if (b < -180) { b += 360; }
                    if (b !== 0 && Math.abs(b) < gest.bearingSnap) {
                        window.mapBearing = 0;
                        window.applyOrientation(true);
                    }
                }
                activeButton = Qt.NoButton;
            }
            onDoubleClicked: (mouse) => {
                if (mouse.button !== Qt.LeftButton) { return; }
                // ClickZoomHandler: zoom +1 (shift: -1) over 300 ms about the pointer, default easing.
                dblZoom.pos = Qt.point(mouse.x, mouse.y);
                dblZoom.sign = (mouse.modifiers & Qt.ShiftModifier) ? -1 : 1;
                dblZoom.last = 0;
                dblZoom.restart();
            }
            onPositionChanged: (mouse) => handleMove(Qt.point(mouse.x, mouse.y))
            function handleMove(cur) {
                if (activeButton === Qt.NoButton) { return; }
                if (!moved && Math.hypot(cur.x - lastPos.x, cur.y - lastPos.y) < gest.clickTolerance) { return; }
                const first = !moved;
                moved = true;
                const prev = Qt.point(lastPos.x, lastPos.y); // copy: point values are references in QML JS
                lastPos = cur;
                if (activeButton === Qt.MiddleButton) {
                    map.scale(Math.pow(2.0, -(cur.y - prev.y) / 250.0), cur); // drag up = zoom in
                } else if (rotateMode) {
                    const c = Qt.point(map.width / 2, map.height / 2);
                    let bearing;
                    if (Math.abs(c.y - prev.y) > 100) {
                        // getAngleDelta(): the y axis is "saved" for pitch.
                        const a = Qt.point(cur.x - c.x, cur.y - c.y), b = Qt.point(prev.x - c.x, prev.y - c.y);
                        bearing = Math.atan2(a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y) * 180 / Math.PI;
                    } else {
                        bearing = (cur.x - prev.x) * gest.rotateSpeed;
                        if (cur.y < c.y) { bearing = -bearing; }
                    }
                    window.mapBearing += bearing;
                    window.mapTilt = Math.max(0, Math.min(85, window.mapTilt + (cur.y - prev.y) * gest.pitchSpeed));
                    window.applyOrientation(false);
                } else {
                    if (first) {
                        gest.anchorElevation = gest.elevationAt(startPos);
                        gest.centerPan = window.terrainEnabled && !map.globeRendering() && map.terrainPointAt(startPos).elevation === undefined;
                        if (!map.globeRendering()) { map.setElevationHold(true); } // GL JS holdElevation('gesture')
                    }
                    // Like GL JS, pointer moves are combined and applied once per frame (see panFrame).
                    if (first) { panApplied = prev; }
                    panPending = true;
                }
            }
        }

        NumberAnimation {
            id: dblZoom
            property point pos
            property real sign: 1
            property real last: 0
            property real progress: 0
            target: dblZoom
            property: "progress"
            from: 0
            to: 1
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1, 1, 1]
        }
        // progress drives the zoom steps
        Connections {
            target: dblZoom
            function onProgressChanged() {
                const d = dblZoom.progress - dblZoom.last;
                dblZoom.last = dblZoom.progress;
                gest.zoomAround(dblZoom.pos, dblZoom.sign * d);
            }
        }

        WheelHandler {
            id: wheel
            enabled: !window.dialogOpen
            acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                            || Qt.platform.pluginName === "xcb"
                            ? PointerDevice.Mouse | PointerDevice.TouchPad
                            : PointerDevice.Mouse
            onWheel: (event) => {
                gest.stopInertia();
                gest.wheelEvent(event.angleDelta.y, event.pixelDelta.y, (event.modifiers & Qt.ShiftModifier) !== 0,
                                wheel.point.position);
            }
        }
    }

    // ---- Top-left control cluster: Presets, Maps, Settings, light/dark switch ----
    Rectangle {
        id: controlCluster
        z: 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 8
        color: "#cc000000"
        radius: 8
        width: clusterRow.implicitWidth + 20
        height: Math.max(44, clusterRow.implicitHeight) + 12

        Row {
            id: clusterRow
            anchors.centerIn: parent
            spacing: 8

            // Presets (Material bookmark icon)
            Item {
                width: 44
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                Canvas {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const x0 = width * 0.25;
                        const x1 = width * 0.75;
                        const y0 = height * 0.15;
                        const y1 = height * 0.85;
                        ctx.strokeStyle = "white";
                        ctx.lineWidth = 2;
                        ctx.lineJoin = "miter";
                        ctx.beginPath();
                        ctx.moveTo(x0, y0);
                        ctx.lineTo(x1, y0);
                        ctx.lineTo(x1, y1);
                        ctx.lineTo((x0 + x1) / 2, y1 - height * 0.22);
                        ctx.lineTo(x0, y1);
                        ctx.closePath();
                        ctx.stroke();
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: presetsDialog.open()
                }
            }

            // Maps (Material folded-map icon)
            Item {
                width: 44
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                Canvas {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const x0 = width * 0.15;
                        const x1 = width * 0.5;
                        const x2 = width * 0.85;
                        const y0 = height * 0.2;
                        const y1 = height * 0.8;
                        ctx.strokeStyle = "white";
                        ctx.lineWidth = 2;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(x0, y0 + 2);
                        ctx.lineTo(x1, y0 - 2);
                        ctx.lineTo(x2, y0 + 2);
                        ctx.lineTo(x2, y1);
                        ctx.lineTo(x1, y1 - 2);
                        ctx.lineTo(x0, y1);
                        ctx.closePath();
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(x1, y0 - 2);
                        ctx.lineTo(x1, y1 - 2);
                        ctx.stroke();
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: mapDialog.open()
                }
            }

            // Settings (Material tune icon)
            Item {
                width: 44
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                Canvas {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const x0 = width * 0.15;
                        const x1 = width * 0.85;
                        const ys = [0.25, 0.5, 0.75];
                        const xs = [0.35, 0.7, 0.45];
                        ctx.strokeStyle = "white";
                        ctx.lineWidth = 2;
                        ctx.lineCap = "round";
                        for (let i = 0; i < 3; ++i) {
                            const y = height * ys[i];
                            ctx.beginPath();
                            ctx.moveTo(x0, y);
                            ctx.lineTo(x1, y);
                            ctx.stroke();
                        }
                        for (let i = 0; i < 3; ++i) {
                            const kx = width * xs[i];
                            const y = height * ys[i];
                            ctx.beginPath();
                            ctx.moveTo(kx, y - 4);
                            ctx.lineTo(kx, y + 4);
                            ctx.stroke();
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: settingsDialog.open()
                }
            }

            // Light / dark switch
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Dark"
                    color: "white"
                    font.pixelSize: 14
                }

                Switch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: window.darkMode
                    onToggled: window.darkMode = checked
                }
            }

            // Sky switch
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Sky"
                    color: "white"
                    font.pixelSize: 14
                }

                Switch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: window.skyEnabled
                    onToggled: {
                        window.skyEnabled = checked;
                        appState.setValue("map/skyEnabled", checked);
                    }
                }
            }
        }
    }

    // ---- Performance metrics (as the MapLibre GL JS "Display performance metrics" example) ---------
    // Load: time until the map finished loading; Idle: time until it was fully rendered (nothing left to load or
    // draw); FPS: map frames rendered per second; Frame: average CPU time (encoding + rendering) per frame. Timing restarts whenever a style (re)loads.
    Rectangle {
        id: metricsPanel
        z: 10
        anchors.top: controlCluster.bottom
        anchors.left: parent.left
        anchors.topMargin: 8
        anchors.leftMargin: 8
        // Same look as the camera panel at the bottom left.
        color: "#d91e1e1e"
        radius: 4
        width: metricsColumn.implicitWidth + 16
        height: metricsColumn.implicitHeight + 12

        property double createdAt: Date.now()
        property string loadText: "\u2014"
        property string idleText: "\u2014"
        property string fpsText: "\u2014"
        property string frameText: "\u2014"
        property int lastFrames: 0
        property double lastFpsTime: Date.now()

        function restart() {
            createdAt = Date.now();
            loadText = "\u2014";
            idleText = "\u2014";
        }

        Column {
            id: metricsColumn
            anchors.centerIn: parent

            Repeater {
                model: [
                    { label: "Load:  ", value: metricsPanel.loadText },
                    { label: "Idle:  ", value: metricsPanel.idleText },
                    { label: "FPS:   ", value: metricsPanel.fpsText },
                    { label: "Frame: ", value: metricsPanel.frameText }
                ]
                Text {
                    required property var modelData
                    text: modelData.label + modelData.value
                    color: "white"
                    font.pixelSize: 12
                    font.family: "monospace"
                }
            }
        }

        Connections {
            target: map
            function onMapLoaded() {
                if (metricsPanel.loadText === "\u2014") {
                    metricsPanel.loadText = (Date.now() - metricsPanel.createdAt).toFixed(0) + " ms";
                }
            }
            function onMapIdle() {
                if (metricsPanel.idleText === "\u2014") {
                    metricsPanel.idleText = (Date.now() - metricsPanel.createdAt).toFixed(0) + " ms";
                }
            }
            function onStyleLoadedChanged() {
                if (!map.styleLoaded) {
                    metricsPanel.restart();
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                const now = Date.now();
                const frames = map.renderedFrames();
                const elapsed = now - metricsPanel.lastFpsTime;
                metricsPanel.fpsText = Math.round((frames - metricsPanel.lastFrames) * 1000 / elapsed).toString();
                const frameMs = map.averageFrameTimeMs();
                metricsPanel.frameText = isNaN(frameMs) ? "\u2014" : frameMs.toFixed(1) + " ms";
                metricsPanel.lastFrames = frames;
                metricsPanel.lastFpsTime = now;
            }
        }
    }

    // ---- Settings dialog (App scale) --------------------------------------------
    Dialog {
        id: settingsDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: Math.min(420, Overlay.overlay.width - 40)
        title: "Settings"

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "App scale"
                    color: Material.foreground
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: window.selectedScale.toFixed(2) + "x"
                    color: Material.foreground
                }
            }

            Slider {
                id: scaleSlider
                Layout.fillWidth: true
                from: 0.5
                to: 3.0
                stepSize: 0.05
                Component.onCompleted: value = window.selectedScale
                onMoved: window.selectedScale = value
            }

            Text {
                Layout.fillWidth: true
                visible: window.scalePending
                text: "Restart required to apply the new scale."
                wrapMode: Text.WordWrap
                color: Material.foreground
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "Restart to apply"
                    enabled: window.scalePending
                    onClicked: {
                        settingsDialog.close();
                        window.restartNow();
                    }
                }
            }
        }
    }

    // ---- Presets dialog (list / add / remove) -----------------------------------
    Dialog {
        id: presetsDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: Math.min(380, Overlay.overlay.width - 40)
        height: Math.min(440, Overlay.overlay.height - 40)
        title: "Presets"

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                visible: window.presets.length === 0
                Layout.fillWidth: true
                text: "No presets yet. Move the map, then press Add."
                wrapMode: Text.WordWrap
                color: Material.foreground
            }

            ListView {
                id: presetList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: window.presets

                delegate: ItemDelegate {
                    width: presetList.width
                    text: modelData && modelData.name ? modelData.name : ""
                    highlighted: index === window.presetIndex
                    onClicked: {
                        window.flyToPreset(index);
                        presetsDialog.close();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "Add"
                    onClicked: {
                        presetsDialog.close();
                        presetDialog.editingPreset = false;
                        presetDialog.open();
                    }
                }

                Button {
                    text: "Edit"
                    enabled: window.presetIndex >= 0
                    onClicked: {
                        presetsDialog.close();
                        presetDialog.editingPreset = true;
                        presetDialog.open();
                    }
                }

                Button {
                    text: "Remove"
                    enabled: window.presetIndex >= 0
                    onClicked: window.removePresetAt(window.presetIndex)
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    // Prompt for preset "Add" / "Edit".
    Dialog {
        id: presetDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: Math.min(320, Overlay.overlay.width - 40)
        property bool editingPreset: false
        title: editingPreset ? "Edit preset" : "Add preset"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: {
            if (editingPreset && window.presetIndex >= 0) {
                const p = window.presets[window.presetIndex];
                nameField.text = p && p.name ? p.name : "";
                saveMapCheck.checked = p !== undefined && p.styleUrl !== undefined;
            } else {
                nameField.text = "Preset " + (window.presets.length + 1);
                saveMapCheck.checked = false;
            }
            nameField.selectAll();
            nameField.forceActiveFocus();
        }
        onAccepted: {
            const n = nameField.text.trim();
            const fallback = "Preset " + (window.presets.length + 1);
            const name = n.length > 0 ? n : fallback;
            if (editingPreset) {
                window.editPresetAt(window.presetIndex, name, saveMapCheck.checked);
            } else {
                window.addPreset(name, saveMapCheck.checked);
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: 8

            TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: "Preset name"
                onAccepted: presetDialog.accept()
            }

            CheckBox {
                id: saveMapCheck
                text: "Save map (style + projection)"
            }
        }
    }

    // ---- Maps dialog (list / add / remove) --------------------------------------
    Dialog {
        id: mapDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: Math.min(440, Overlay.overlay.width - 40)
        height: Math.min(480, Overlay.overlay.height - 40)
        title: "Maps"

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            ListView {
                id: mapList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: window.mapStyles

                delegate: ItemDelegate {
                    width: mapList.width
                    text: modelData && modelData.name ? modelData.name : ""
                    highlighted: modelData && modelData.url === window.styleUrl
                    onClicked: {
                        window.selectMap(index);
                        mapDialog.close();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "Add"
                    onClicked: {
                        mapDialog.close();
                        addMapDialog.open();
                    }
                }

                Button {
                    text: "Remove"
                    enabled: window.mapIndex >= 0
                    onClicked: window.removeMapAt(window.mapIndex)
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    // Add-map prompt (name + style URL)
    Dialog {
        id: addMapDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: Math.min(420, Overlay.overlay.width - 40)
        title: "Add map"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: {
            mapNameField.text = "Map " + (window.mapStyles.length + 1);
            mapUrlField.text = "";
            mapNameField.forceActiveFocus();
        }
        onAccepted: {
            const n = mapNameField.text.trim();
            const u = mapUrlField.text.trim();
            if (u.length > 0) {
                window.addMapStyle(n.length > 0 ? n : u, u);
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            TextField {
                id: mapNameField
                Layout.fillWidth: true
                placeholderText: "Name"
                onAccepted: addMapDialog.accept()
            }

            TextField {
                id: mapUrlField
                Layout.fillWidth: true
                placeholderText: "Style URL, e.g. https://tiles.openfreemap.org/styles/liberty"
                onAccepted: addMapDialog.accept()
            }
        }
    }

    // ---- 2D / 3D toggle button (Material globe icon) ----------------------------
    Rectangle {
        id: toggle3DButton
        z: 10
        width: 44
        height: 44
        radius: width / 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        color: window.globe3D ? "#2d7ef7" : "#cc000000"

        Canvas {
            id: globeIcon
            anchors.centerIn: parent
            width: 26
            height: 26
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2;
                const cy = height / 2;
                const r = width / 2 - 2;
                const rx = r * 0.55;   // meridian horizontal radius
                const ry = r * 0.55;   // parallel vertical radius
                const k = 4 / 3;       // cubic-bezier ellipse constant
                ctx.strokeStyle = "white";
                ctx.lineWidth = 2;
                ctx.lineCap = "round";

                // Outer circle
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.stroke();

                // Vertical meridian (a tall ellipse)
                ctx.beginPath();
                ctx.moveTo(cx, cy - r);
                ctx.bezierCurveTo(cx + k * rx, cy - r, cx + k * rx, cy + r, cx, cy + r);
                ctx.bezierCurveTo(cx - k * rx, cy - r, cx - k * rx, cy + r, cx, cy - r);
                ctx.stroke();

                // Horizontal parallel (a wide ellipse)
                ctx.beginPath();
                ctx.moveTo(cx - r, cy);
                ctx.bezierCurveTo(cx - r, cy + k * ry, cx + r, cy + k * ry, cx + r, cy);
                ctx.bezierCurveTo(cx + r, cy - k * ry, cx - r, cy - k * ry, cx - r, cy);
                ctx.stroke();
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: window.toggle3D()
        }
    }

    // ---- Camera position readout (bottom left) -----------------------------------
    // Camera height is the altitude above the ground under the map centre (not
    // terrain-aware): distance-to-centre = 1.5 x viewport height (36.87 deg field of
    // view) in pixels, times metres per pixel at this latitude and zoom (512 px tiles).
    Rectangle {
        id: cameraReadout
        z: 10
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 8
        width: cameraReadoutText.implicitWidth + 16
        height: cameraReadoutText.implicitHeight + 12
        radius: 4
        color: "#d91e1e1e"

        // `tick` (the 400 ms timer) makes the live camera values re-evaluate; the comma operator keeps the dependency.
        readonly property real lat: (tick, map.liveCoordinate())[0]
        readonly property real lon: (tick, map.liveCoordinate())[1]
        readonly property real zoomNow: (tick, map.liveZoom())
        // Terrain data comes from the map (the elevation tiles load asynchronously), so poll it.
        readonly property bool terrainStyle: window.styleUrl.indexOf("terrain-style.json") !== -1
        property int tick: 0
        // Camera altitude above sea level, and the drawn terrain surface under the map centre
        // (exaggeration included); NaN until the elevation tile has loaded.
        property real cameraMeters: 0
        property real groundMeters: NaN
        // Refreshed imperatively by the timer below. Bindings of the form `tick >= 0 ? map.cameraAltitude() : 0` were
        // evaluated once at start-up, before the map had terrain, and never again, so the panel stayed at 0 / NaN.
        function refresh() {
            cameraMeters = map.cameraAltitude();
            groundMeters = terrainStyle ? map.terrainElevation(lat, lon) : NaN;
        }
        readonly property real surfaceMeters: groundMeters * map.terrainExaggeration

        // GL JS reports the bearing in (-180, 180].
        function signedHeading(b) {
            const r = ((b % 360) + 360) % 360;
            return r > 180 ? r - 360 : r;
        }

        function formatHeight(m) {
            return Math.abs(m) >= 10000 ? (m / 1000).toFixed(1) + " km" : Math.round(m) + " m";
        }

        Timer {
            interval: 400
            repeat: true
            running: true
            onTriggered: {
                cameraReadout.tick++;
                cameraReadout.refresh();
            }
        }

        // Selectable (drag to select, Ctrl+C copies the selection as shown).
        TextEdit {
            id: cameraReadoutText
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            textFormat: TextEdit.PlainText
            color: "white"
            selectionColor: "#2d7ef7"
            selectedTextColor: "white"
            font.pixelSize: 12
            font.family: "monospace"
            // Same lines and format as the MapLibre GL JS reference harness (tools/gljs-harness/index.html).
            text: "MapLibre Native Qt"
                  + "\nLat " + cameraReadout.lat.toFixed(6) + "  Lon " + cameraReadout.lon.toFixed(6)
                  + "\nZoom " + cameraReadout.zoomNow.toFixed(4) + "  Pitch " + window.mapTilt.toFixed(2)
                  + "  Heading " + cameraReadout.signedHeading(window.mapBearing).toFixed(2)
                  + "\nExaggeration " + map.terrainExaggeration + "  Ground "
                  + (isNaN(cameraReadout.groundMeters) ? "NaN" : cameraReadout.groundMeters.toFixed(1))
                  + " m (unexaggerated)"
                  + "\nWindow " + Math.round(window.width) + "x" + Math.round(window.height)
                  + "  DPR " + window.devicePixelRatio
        }

        // Full-precision description of the exact camera for bug reports / reproduction.
        function details() {
            const lat = cameraReadout.lat, lon = cameraReadout.lon;
            return "camera: lat=" + lat.toFixed(6) + " lon=" + lon.toFixed(6)
                + " zoom=" + cameraReadout.zoomNow.toFixed(4) + " pitch=" + window.mapTilt.toFixed(2)
                + " bearing=" + window.mapBearing.toFixed(2)
                + "\ncameraAltitude=" + cameraReadout.cameraMeters.toFixed(1) + "m"
                + " ground=" + (isNaN(cameraReadout.groundMeters) ? "n/a" : cameraReadout.groundMeters.toFixed(1) + "m")
                + " exaggeration=" + map.terrainExaggeration.toFixed(2)
                + "\nprojection=" + (window.globe3D ? "globe" : "mercator")
                + " terrain=" + window.terrainEnabled
                + " style=" + window.styleUrl
                + "\nwindow=" + window.width + "x" + window.height + " scale=" + window.selectedScale.toFixed(2)
                + "\nJSON: " + JSON.stringify({ center: [lat, lon], zoom: cameraReadout.zoomNow, pitch: window.mapTilt,
                                                  bearing: window.mapBearing, globe: window.globe3D });
        }

        function copyDetails() {
            clipboardHelper.text = details();
            clipboardHelper.selectAll();
            clipboardHelper.copy();
            copiedLabel.opacity = 1;
            copiedFade.restart();
        }

        TextEdit { id: clipboardHelper; visible: false }

        Rectangle {
            id: copyButton
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            width: 46
            height: 20
            radius: 4
            color: copyArea.pressed ? "#2d7ef7" : "#55ffffff"
            Text {
                id: copiedLabel
                anchors.centerIn: parent
                text: opacity > 0.5 && copiedFade.running ? "Copied" : "Copy"
                color: "white"
                font.pixelSize: 11
                font.bold: true
            }
            MouseArea {
                id: copyArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: cameraReadout.copyDetails()
            }
        }
        Timer { id: copiedFade; interval: 1200 }
    }

    // ---- Zoom in / out buttons --------------------------------------------------
    Column {
        id: zoomButtons
        z: 10
        anchors.top: toggle3DButton.bottom
        anchors.topMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        spacing: 8

        Rectangle {
            width: 44
            height: 44
            radius: width / 2
            color: "#cc000000"
            Text {
                anchors.centerIn: parent
                text: "+"
                color: "white"
                font.pixelSize: 26
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: window.zoomBy(1)
            }
        }

        Rectangle {
            width: 44
            height: 26
            radius: 6
            color: "#cc000000"
            Text {
                anchors.centerIn: parent
                text: (cameraReadout.tick, map.liveZoom()).toFixed(1)
                color: "white"
                font.pixelSize: 13
                font.bold: true
            }
        }

        Rectangle {
            width: 44
            height: 44
            radius: width / 2
            color: "#cc000000"
            Text {
                anchors.centerIn: parent
                text: "\u2212"
                color: "white"
                font.pixelSize: 26
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: window.zoomBy(-1)
            }
        }
    }

    // ---- 3D buildings opacity toggle (Material buildings icon) ------------------
    Rectangle {
        id: buildingsButton
        z: 10
        width: 44
        height: 44
        radius: width / 2
        anchors.top: zoomButtons.bottom
        anchors.topMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        color: window.buildingsOpaque ? "#2d7ef7" : "#cc000000"

        Canvas {
            anchors.centerIn: parent
            width: 24
            height: 24
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const bx = width * 0.28;
                const by = height * 0.12;
                const bw = width * 0.44;
                const bh = height * 0.76;
                ctx.strokeStyle = "white";
                ctx.lineWidth = 2;
                ctx.lineJoin = "round";
                ctx.strokeRect(bx, by, bw, bh);
                ctx.fillStyle = "white";
                for (let r = 0; r < 3; ++r) {
                    for (let c = 0; c < 2; ++c) {
                        ctx.fillRect(bx + bw * (0.22 + c * 0.36),
                                     by + bh * (0.12 + r * 0.28),
                                     bw * 0.2, bh * 0.12);
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: window.buildingsOpaque = !window.buildingsOpaque
        }
    }

    // ---- Compass rose (bottom-right) --------------------------------------------
    // Rotates with the map bearing so "N" points to geographic north, and squashes
    // with the tilt. Single click puts north up; double click resets the tilt to zero.
    Item {
        id: compass
        z: 10
        width: 56
        height: 56
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12

        Canvas {
            id: compassCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2, cy = height / 2, r = width / 2 - 2;
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.fillStyle = "#cc000000";
                ctx.fill();
                ctx.lineWidth = 2;
                ctx.strokeStyle = "white";
                ctx.stroke();

                ctx.save();
                ctx.translate(cx, cy);
                ctx.rotate(-window.mapBearing * Math.PI / 180);
                ctx.scale(1, Math.max(0.25, Math.cos(window.mapTilt * Math.PI / 180)));
                const tip = r - 7;
                ctx.beginPath();
                ctx.moveTo(0, -tip);
                ctx.lineTo(-tip * 0.4, 0);
                ctx.lineTo(tip * 0.4, 0);
                ctx.closePath();
                ctx.fillStyle = "#ff5555";
                ctx.fill();
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(-tip * 0.4, 0);
                ctx.lineTo(tip * 0.4, 0);
                ctx.lineTo(0, tip);
                ctx.closePath();
                ctx.fillStyle = "white";
                ctx.fill();
                ctx.restore();
            }
        }

        // Repaint the rose whenever the bearing or tilt changes.
        Connections {
            target: window
            function onMapBearingChanged() { compassCanvas.requestPaint() }
            function onMapTiltChanged() { compassCanvas.requestPaint() }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: compassSingleClick.restart()
            onDoubleClicked: {
                compassSingleClick.stop();
                window.tiltZero();
            }
        }

        // Distinguish a single click from the first half of a double click.
        Timer {
            id: compassSingleClick
            interval: 250
            onTriggered: window.northUp()
        }
    }
}
