# GL JS reference harness

Renders the MapLibre GL JS "3D Terrain" example (maplibre-gl 6.14.0, Mapterhorn DEM, OSM raster, hillshade)
with the camera set from the URL, so MapLibreEarth can be compared with the reference at the same view.

    cd tools/gljs-harness && python3 serve.py
    http://localhost:8765/?lat=56.645543&lon=-5.014887&zoom=13.3176&pitch=81.12&bearing=189.375

Parameters: lat, lon, zoom, pitch, bearing, exag (terrain exaggeration, default 1), hillshade=0/1, osm=0/1, globe=0/1 (globe projection).
A globe button (top right, under the navigation control) toggles globe / Mercator at runtime.
A Sky checkbox (top left) turns the style `sky` on/off at runtime; `sky=0` starts with it off.
`window.__ready` becomes true when the map is idle (all tiles loaded) - use it before screenshots.
The HUD (bottom left) prints the camera in the same order as MapLibreEarth's Copy block.
Compare at the same window size / pixel ratio; MapLibreEarth's panel reports its window size and scale.

Extra parameters: `w`, `h` (render size in CSS px), `dpr` (pixel ratio), `save=NAME` (POSTs the canvas as
`/tmp/shots/NAME.png` via `serve.py` once idle; `window.__savedOk` becomes true). Use `serve.py` rather than
`http.server` for `save`.

## Matching the app's window (important)

MapLibreEarth renders at device pixel ratio = system scale x app scale (2.0 x 1.2 = 2.4 here); the map zoom is
relative to *logical* pixels. To match a 3542x2230-pixel app shot, render GL JS at the logical size with the same
ratio: `w=1476&h=929&dpr=2.4` (not w=3542&dpr=1, which shows ~2.4x more ground). The app's Copy block reports
window size and scale; logical size = device pixels / 2.4.
