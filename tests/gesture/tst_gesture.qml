// Tests for the pointer-gesture logic in main.qml (object `gest`): GL JS-aligned drag pan, scroll zoom, inertia.
//
// main.qml is NOT edited or duplicated: this test reads it, cuts out the `QtObject { id: gest ... }` block and
// instantiates that exact text next to mock `map` / timers, so a change in main.qml is what gets tested.
// Run with tests/gesture/run.sh (needs QML_XHR_ALLOW_FILE_READ=1 to read main.qml).
import QtQuick
import QtTest

TestCase {
    id: tc
    name: "Gestures"
    width: 800
    height: 600

    // ---- mocks of what `gest` reaches in main.qml ----
    property var log: []
    QtObject {
        id: map
        property real zoomLevel: 10
        property real width: 800
        property real height: 600
        property bool globe: false
        property var terrain: undefined         // {elevation} or undefined
        property real centreElevation: 0
        property real cameraAlt: 10000
        property bool setResult: true
        property bool locationUndefined: false
        function globeRendering() { return globe; }
        function terrainPointAt(pos) { return terrain === undefined ? {} : terrain; }
        function elevation() { return centreElevation; }
        function cameraAltitude() { return cameraAlt; }
        function coordinateAtElevation(pos, el) {
            tc.log.push(["coordinateAtElevation", pos.x, pos.y, el]);
            return locationUndefined ? {} : { latitude: 46 + pos.y / 1000, longitude: 8 + pos.x / 1000 };
        }
        function setLocationAtPoint(lat, lon, pos, el) {
            tc.log.push(["setLocationAtPoint", lat, lon, pos.x, pos.y, el]);
            return setResult;
        }
        function pan(p) { tc.log.push(["pan", p.x, p.y]); }
        function scale(f, pos) { tc.log.push(["scale", f, pos.x, pos.y]); }
        function easeTo(cam, opt) { tc.log.push(["easeTo", cam.zoom]); zoomLevel = cam.zoom; }
        function setElevationHold(h) { tc.log.push(["hold", h]); }
    }
    QtObject {
        id: frameTimer
        property int starts: 0
        property int stops: 0
        function start() { starts++; }
        function stop() { stops++; }
    }
    QtObject {
        id: clearTimer
        property int restarts: 0
        function restart() { restarts++; }
    }
    QtObject {
        id: inertiaAnim
        property real previous: 0
        property real duration: 0
        property int restarts: 0
        property bool running: false
        function restart() { restarts++; }
        function stop() { }
    }

    property var gest: null
    property real fakeNow: 1000000

    function loadGest() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", Qt.resolvedUrl("../../main.qml"), false);
        xhr.send();
        const text = xhr.responseText;
        verify(text.length > 1000, "main.qml could not be read (set QML_XHR_ALLOW_FILE_READ=1)");
        const m = /QtObject\s*\{\s*id:\s*gest\b/.exec(text);
        verify(m !== null, "`QtObject { id: gest` not found in main.qml");
        let depth = 0, end = -1;
        for (let i = m.index + m[0].indexOf("{"); i < text.length; i++) {
            if (text[i] === "{") { depth++; }
            else if (text[i] === "}" && --depth === 0) { end = i; break; }
        }
        verify(end > 0, "unbalanced gest block");
        // `window` is only used inside functions we do not call; give it a harmless stand-in.
        // The created object does not see a replaced Date.now, so route its clock through the test (the only rewrite).
        const block = text.substring(m.index, end + 1).replace(/Date\.now\(\)/g, "tc.fakeNow");
        return Qt.createQmlObject("import QtQuick\n" + block, tc, "gest-from-main.qml");
    }

    function init() {
        log = [];
        map.zoomLevel = 10; map.globe = false; map.terrain = undefined; map.centreElevation = 0;
        map.cameraAlt = 10000; map.setResult = true; map.locationUndefined = false;
        frameTimer.starts = 0; frameTimer.stops = 0; clearTimer.restarts = 0;
        inertiaAnim.restarts = 0; inertiaAnim.duration = 0;
        fakeNow = 1000000;
        gest = loadGest();
    }
    function cleanup() {
        if (gest) { gest.destroy(); gest = null; }
    }

    function entries(kind) { return log.filter(e => e[0] === kind); }

    // ---- constants agreed with GL JS ----
    function test_constants() {
        compare(gest.clickTolerance, 3);
        compare(gest.rotateSpeed, 0.8);
        compare(gest.pitchSpeed, -0.5);
        compare(gest.bearingSnap, 7);
        compare(gest.maxScalePerFrame, 2);
        fuzzyCompare(gest.defaultZoomRate, 1 / 100, 1e-12);
        fuzzyCompare(gest.wheelZoomRate, 1 / 450, 1e-12);
        fuzzyCompare(gest.wheelZoomDelta, 4.000244140625, 1e-12);
    }

    // ---- bezier (WebKit unit bezier, as GL JS) ----
    function test_bezier_endpoints_and_linear() {
        const lin = gest.bezier(1 / 3, 1 / 3, 2 / 3, 2 / 3);
        fuzzyCompare(lin(0), 0, 1e-5);
        fuzzyCompare(lin(1), 1, 1e-5);
        fuzzyCompare(lin(0.37), 0.37, 1e-4);
    }
    function test_bezier_css_ease() {
        // CSS `ease` = cubic-bezier(0.25, 0.1, 0.25, 1): y(0.5) = 0.8024 (published value).
        fuzzyCompare(gest.defaultEasing(0.5), 0.8024, 1e-3);
        fuzzyCompare(gest.defaultEasing(0), 0, 1e-5);
        fuzzyCompare(gest.defaultEasing(1), 1, 1e-5);
    }
    function test_bezier_inertia_curve_monotonic_and_front_loaded() {
        let prev = -1;
        for (let i = 0; i <= 20; i++) {
            const y = gest.inertiaEasing(i / 20);
            verify(y >= prev - 1e-9, "monotonic at " + i);
            prev = y;
        }
        verify(gest.inertiaEasing(0.5) > 0.5); // decelerating: most of the distance early
    }

    // ---- elevationAt (anchor pick, 0.9 guard) ----
    function test_elevationAt_globe_is_NaN() {
        map.globe = true; map.terrain = { elevation: 500 };
        verify(isNaN(gest.elevationAt(Qt.point(1, 1))));
    }
    function test_elevationAt_no_terrain_is_NaN() {
        verify(isNaN(gest.elevationAt(Qt.point(1, 1))));
    }
    function test_elevationAt_returns_terrain_height() {
        map.terrain = { elevation: 1200 }; map.centreElevation = 1000; map.cameraAlt = 11000;
        compare(gest.elevationAt(Qt.point(1, 1)), 1200);
    }
    function test_elevationAt_plane_too_close_to_camera_is_NaN() {
        // 0.9 of the camera height above the centre: 0.9 * (11000 - 1000) = 9000 -> terrain at >= 10000 is rejected.
        map.centreElevation = 1000; map.cameraAlt = 11000;
        map.terrain = { elevation: 9999 };
        compare(gest.elevationAt(Qt.point(1, 1)), 9999);
        map.terrain = { elevation: 10000 };
        verify(isNaN(gest.elevationAt(Qt.point(1, 1))));
    }

    // ---- dragPan ----
    function test_dragPan_globe_pans_by_pixel_delta() {
        map.globe = true;
        gest.dragPan(Qt.point(100, 100), Qt.point(130, 90), NaN);
        compare(log.length, 1);
        compare(log[0], ["pan", 30, -10]);
    }
    function test_dragPan_centrePan_pans_by_pixel_delta() {
        gest.centerPan = true;
        gest.dragPan(Qt.point(100, 100), Qt.point(70, 140), 500);
        compare(log, [["pan", -30, 40]]);
    }
    function test_dragPan_sets_location_at_anchor_elevation() {
        gest.dragPan(Qt.point(100, 200), Qt.point(150, 260), 750);
        compare(entries("pan").length, 0);
        // the location under `from` (at the anchor elevation) is put under `to`
        compare(entries("coordinateAtElevation")[0], ["coordinateAtElevation", 100, 200, 750]);
        compare(entries("setLocationAtPoint")[0], ["setLocationAtPoint", 46.2, 8.1, 150, 260, 750]);
    }
    function test_dragPan_pointer_above_horizon_falls_back_to_pan() {
        map.locationUndefined = true;
        gest.dragPan(Qt.point(10, 10), Qt.point(20, 30), NaN);
        compare(entries("setLocationAtPoint").length, 0);
        compare(entries("pan")[0], ["pan", 10, 20]);
    }
    function test_dragPan_failed_set_falls_back_to_pan() {
        map.setResult = false;
        gest.dragPan(Qt.point(10, 10), Qt.point(25, 15), NaN);
        compare(entries("pan")[0], ["pan", 15, 5]);
    }

    // ---- zoomAround ----
    function test_zoomAround_zero_is_noop() {
        gest.zoomAround(Qt.point(5, 5), 0);
        compare(log.length, 0);
    }
    function test_zoomAround_globe_scales() {
        map.globe = true;
        gest.zoomAround(Qt.point(5, 7), 1);
        compare(log, [["scale", 2, 5, 7]]);
    }
    function test_zoomAround_keeps_location_under_pointer() {
        map.terrain = { elevation: 300 };
        gest.zoomAround(Qt.point(400, 300), 0.5);
        const names = log.map(e => e[0]);
        // location is read BEFORE the zoom, then re-applied after it, at the same elevation
        compare(names, ["coordinateAtElevation", "easeTo", "setLocationAtPoint"]);
        compare(log[0][3], 300);
        fuzzyCompare(log[1][1], 10.5, 1e-12);
        compare(log[2], ["setLocationAtPoint", 46.3, 8.4, 400, 300, 300]);
    }

    // ---- wheel / trackpad input (scroll_zoom.ts) ----
    function test_wheelEvent_notch_is_calibrated_delta() {
        gest.wheelEvent(120, 0, false, Qt.point(50, 60));
        compare(gest.wheelType, "wheel");
        fuzzyCompare(gest.wheelDelta, 242.6, 1e-9);   // up (positive angle) = zoom in
        compare(gest.zoomActive, true);
        compare(gest.aroundPoint, Qt.point(50, 60));
        compare(frameTimer.starts, 1);
    }
    function test_wheelEvent_trackpad_uses_pixel_delta() {
        gest.wheelEvent(0, -10, false, Qt.point(1, 1));
        compare(gest.wheelType, "trackpad");
        compare(gest.wheelDelta, -10);
    }
    function test_wheelEvent_shift_divides_by_four() {
        gest.wheelEvent(120, 0, true, Qt.point(1, 1));
        fuzzyCompare(gest.wheelDelta, 242.6 / 4, 1e-9);
    }
    function test_wheelEvent_second_event_accumulates_without_restarting_frames() {
        gest.wheelEvent(120, 0, false, Qt.point(1, 1));
        gest.wheelEvent(120, 0, false, Qt.point(9, 9));
        fuzzyCompare(gest.wheelDelta, 485.2, 1e-9);
        compare(frameTimer.starts, 1);
        compare(gest.aroundPoint, Qt.point(1, 1)); // the zoom stays about the first pointer position
    }
    function test_zoomFrame_one_wheel_notch_is_0_337_levels() {
        // The documented calibration: one notch = 0.337 zoom levels (john's GL JS).
        gest.wheelEvent(120, 0, false, Qt.point(400, 300));
        gest.zoomFrame();
        fuzzyCompare(gest.targetZoom - 10, 0.337, 2e-3);
        fuzzyCompare(gest.targetZoom - 10, Math.log(2 / (1 + Math.exp(-242.6 / 450))) / Math.LN2, 1e-9);
    }
    function test_zoomFrame_wheel_smooths_over_200ms() {
        gest.wheelEvent(120, 0, false, Qt.point(400, 300));
        gest.zoomFrame();
        const first = map.zoomLevel;
        verify(first > 10 && first < gest.targetZoom, "first frame is partway");
        compare(frameTimer.stops, 0);
        fakeNow += 250;
        gest.zoomFrame();
        fuzzyCompare(map.zoomLevel, gest.targetZoom, 1e-9);
        compare(frameTimer.stops, 1);
        compare(clearTimer.restarts, 1);
        compare(gest.zoomActive, false);
    }
    function test_zoomFrame_trackpad_applies_immediately_and_zooms_out_symmetrically() {
        gest.wheelEvent(0, -10, false, Qt.point(400, 300));  // Qt pixelDelta.y < 0 = scroll down = zoom out
        gest.zoomFrame();
        const expected = -Math.log(2 / (1 + Math.exp(-10 * (1 / 100)))) / Math.LN2;
        fuzzyCompare(map.zoomLevel - 10, expected, 1e-9);
        verify(map.zoomLevel < 10);
        compare(frameTimer.stops, 1);
    }
    function test_zoomFrame_clamps_to_zoom_range() {
        map.zoomLevel = 21.9;
        for (let i = 0; i < 5; i++) { gest.wheelEvent(120, 0, false, Qt.point(1, 1)); }
        gest.zoomFrame();
        compare(gest.targetZoom, 22);
    }
    function test_zoomFrame_limits_scale_per_frame_to_two() {
        gest.wheelEvent(0, -100000, false, Qt.point(1, 1)); // enormous trackpad gesture
        gest.zoomFrame();
        verify(map.zoomLevel - 10 <= 1.0000001, "at most one level per frame");
    }

    // ---- pan inertia (handler_inertia.ts) ----
    function test_inertia_needs_two_samples() {
        gest.record(5, 5);
        gest.startInertia();
        compare(inertiaAnim.restarts, 0);
    }
    function test_inertia_speed_and_distance() {
        gest.record(0, 0);
        fakeNow += 100;
        gest.record(100, 0);                 // 100 px over 100 ms
        gest.startInertia();
        // speed = 100 * 0.3 / 0.1 s = 300 px/s; time = 300 / (2500 * 0.3) = 0.4 s; distance = 300 * 0.4 / 2 = 60 px
        compare(inertiaAnim.restarts, 1);
        fuzzyCompare(inertiaAnim.duration, 400, 1e-6);
        fuzzyCompare(gest.inertiaPan.x, 60, 1e-6);
        fuzzyCompare(gest.inertiaPan.y, 0, 1e-6);
    }
    function test_inertia_direction_follows_the_motion() {
        gest.record(0, 0);
        fakeNow += 100;
        gest.record(-30, 40);
        gest.startInertia();
        const mag = Math.hypot(gest.inertiaPan.x, gest.inertiaPan.y);
        fuzzyCompare(gest.inertiaPan.x / mag, -0.6, 1e-9);
        fuzzyCompare(gest.inertiaPan.y / mag, 0.8, 1e-9);
    }
    function test_inertia_speed_is_capped_at_1400() {
        gest.record(0, 0);
        fakeNow += 10;
        gest.record(1000, 0);                // 100 000 px/s raw
        gest.startInertia();
        // seconds = 1400 / 750 = 1.8667 s; distance = 1400 * 1.8667 / 2
        fuzzyCompare(inertiaAnim.duration, 1400 / 750 * 1000, 1e-6);
        fuzzyCompare(gest.inertiaPan.x, 1400 * (1400 / 750) / 2, 1e-6);
    }
    function test_inertia_ignores_samples_older_than_160ms() {
        gest.record(0, 0);
        fakeNow += 100;
        gest.record(50, 0);
        fakeNow += 100;                      // the first sample is now 200 ms old, the second 100 ms
        gest.startInertia();
        compare(inertiaAnim.restarts, 0);    // only one sample left
    }
    function test_record_prunes_old_samples() {
        gest.record(1, 1);
        fakeNow += 500;
        gest.record(2, 2);
        compare(gest.samples.length, 1);
    }

    // ---- smooth-out easing (scroll_zoom.ts) ----
    function test_smoothOutEasing_first_call_is_the_default_ease() {
        const e = gest.smoothOutEasing(200);
        fuzzyCompare(e(0.5), gest.defaultEasing(0.5), 1e-9);
        compare(gest.prevEase.duration, 200);
    }
    function test_smoothOutEasing_second_call_continues_the_velocity() {
        gest.smoothOutEasing(200);
        fakeNow += 100;
        const e = gest.smoothOutEasing(200);
        verify(Math.abs(e(0.5) - gest.defaultEasing(0.5)) > 1e-4, "a new curve is built from the previous speed");
        fuzzyCompare(e(0), 0, 1e-5);
        fuzzyCompare(e(1), 1, 1e-5);
    }
}
