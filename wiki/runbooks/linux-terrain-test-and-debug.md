---
type: Runbook
title: Linux (Vulkan) terrain — build, test, stress-test and debug
description: Everything needed to pick up the 3D-terrain work on the Linux box after a reboot - paths, commands, the scripted screenshot sweeps, the memory guard, and the pitfalls found on 2026-10-16/17.
tags: [ linux, vulkan, terrain, testing, runbook, handover ]
status: current
---
## Machine and trees (Linux, 2026-10-17)

- Ubuntu 26.04, AMD Radeon 780M (RADV, Vulkan), Qt 6.11.2 (`~/Qt`), Ninja at `~/Qt/Tools/Ninja`, Qt Creator `~/Qt/Tools/QtCreator/bin/qtcreator`.
- Repos (all under `~/dev/projects/`): **`maplibreearth`** (app + this wiki, `johndr/maplibreearth`), **`maplibre-native-qt`** (QMapLibre wrapper + `patches/0001..0056`, `johndr/maplibre-native-qt`; its submodule `vendor/maplibre-native` is pinned at upstream `c7506d6` and its **working tree is intentionally dirty = the patches applied**; never commit it), **`maplibre-native`** (clean fork clone `johndr/maplibre-native`, no local work — our core changes live only as patch files).
- Canonical build trees (`~/dev/tmp/`): `build-maplibre-native-qt-{Release,Debug}` (library), installs `install/maplibre-native-qt` (Release) and `install-maplibre-native-qt-debug`; `build-maplibre-native-core-tests` (vendored core tests, Release); the app builds in `maplibreearth/build/Desktop_Qt_6_11_2_{Release,Debug}` from the command line (the Qt Creator MCP rule is **Windows-only**).
- Qt Creator is optional on Linux. If you do use it and its MCP: after a restart the MCP can be unreachable (ECONNREFUSED) — `~/Qt/Tools/QtCreator/bin/qtcreator -client ~/dev/projects/maplibreearth/CMakeLists.txt`, then reconnect.
- **`/tmp` is wiped on reboot** (kernel crash included). Keep anything you need under `~/dev/tmp`.

## Build the library (both configs, then install) — always both

```bash
cd ~/dev/tmp; export PATH=$HOME/Qt/Tools/Ninja:$PATH
for c in Release Debug; do cmake --build build-maplibre-native-qt-$c 2>&1 | grep -E "error:|FAILED" ; done
cmake --install build-maplibre-native-qt-Release; cmake --install build-maplibre-native-qt-Debug
```

**Filter compile output with `error:`**, not ` error ` — the latter hides real failures (a stale library then looks like a behaviour bug). Then build the app in each config (command line on Linux — the Qt Creator MCP rule is Windows-only) so POST_BUILD copies the matching runtime.

## Tests

- Qt: `QT_QPA_PLATFORM=xcb QSG_RENDER_LOOP=basic ctest` in each library tree (`test_mln_quick`; passes in both).
- Vendored core tests (configure once): `cmake -G Ninja -S vendor/maplibre-native -B ~/dev/tmp/build-maplibre-native-core-tests -DCMAKE_BUILD_TYPE=Release -DMLN_WITH_VULKAN=ON -DMLN_WITH_OPENGL=OFF -DMLN_WITH_GLFW=OFF -DMLN_WITH_WERROR=OFF -DMLN_TEXT_SHAPING_HARFBUZZ=OFF`, then `ninja mbgl-test-runner mbgl-render-test-runner mbgl-benchmark-runner`; run **from `vendor/maplibre-native`**. Status 2026-10-18 (after patch 0055): 1110 pass, 0 fail on Vulkan (the 3 failures of 2026-10-17, `StyleConversion.Projection` and `CustomDrawableLayer.Line/Fill`, turned out to be fork regressions fixed by 0055; pristine upstream passes them). Render tests must be run **per group** (one process over all groups aborts with "Failed to initialize thread-specific storage key"): for each dir in `metrics/integration/render-tests`, `mbgl-render-test-runner -p metrics/linux-vulkan.json -f render-tests/<group>/` -> only `fill-extrusion-pattern/tile-buffer` (fails) and `text-font/{burmese,khmer,devanagari}` (error) are not passing, identical to pristine upstream. Benchmarks: `mbgl-benchmark-runner --benchmark_filter=TileCover`.

## Test trees (2026-10-18)

| Tree | Purpose |
|---|---|
| `~/dev/tmp/build-maplibre-native-core-tests` | fork, Vulkan (canonical, `mbgl-test-runner`, `mbgl-render-test-runner`, `mbgl-expression-test`) |
| `~/dev/tmp/build-maplibre-native-core-tests-opengl` | fork, OpenGL (`-DMLN_WITH_OPENGL=ON -DMLN_WITH_VULKAN=OFF`; needs `sudo apt install libgles-dev`) |
| `~/dev/tmp/maplibre-native-pristine` + `build-pristine-opengl` / `build-pristine-vulkan` | upstream `c7506d6` baseline: a copy of `vendor/maplibre-native` (without `.git`) with every patch reverse-applied (`git apply -R`, newest first) |
| `~/dev/tmp/build-maplibre-native-qt-Release` | Qt library; `cmake --build` then `QT_QPA_PLATFORM=xcb QSG_RENDER_LOOP=basic ctest` |

Rules learned: run the unit suites **one at a time** (fixed test HTTP server port 3000; parallel runs hang); never `pkill -f mbgl-test-runner` from the same shell (kills the shell, kill by PID); `node shaders/generate_shader_code.mjs` writes into the tree and clobbers `shader_source.*`/`shader_manifest.hpp` (see [Linux tests](../verification/linux-tests.md)); app gesture tests: `tests/gesture/run.sh`. Scripts used (in `~/dev/tmp`): `run-render-tests.sh`, `run-gl-tests.sh`, `run-verify.sh` (Qt build + ctest + three render suites).

## Scripted screenshot sweeps (no hands on the window)

Temporarily append a QML `Item` with `Timer`s to `main.qml` (restore the file afterwards; never commit it): after 3 s `window.selectMap(<terrain style index>)` (`window.mapStyles.findIndex(m => m.url.indexOf("terrain-style.json") !== -1)`), then every ~10 s `map.easeTo({center:[56.6598,-5.0343], zoom:Z, pitch:P, bearing:-127}, {duration:0})` (set `window.mapTilt = P` too), and at the start of the next tick `window.contentItem.grabToImage(function(r){ r.saveToFile("/tmp/shots/NAME.png"); })`; finish with `Qt.quit()`. `mkdir -p /tmp/shots` first. `run_project` then returns when the script quits; read the PNGs. Drag tests: call `map.pan(Qt.point(dx,dy))` from a 33 ms timer. A few seconds of beige hillshade tint after a big zoom jump is the drape loading (slower in Debug), not a bug. Ben Nevis (56.66, -5.03) is a good relief test; the app's saved `QSettings` position persists between runs.

**Globe sweeps / sequences (2026-10-18):** `~/dev/tmp/sweep/sweep2.py STYLEURL OUTDIR PREFIX GLOBE(1|0) name:lat:lon:zoom:pitch ...` appends a temporary Timer block to `main.qml` (generated from the backup `~/dev/tmp/main.qml.orig-0050`; set `window.globe3D` AFTER the style loaded, because switching style resets it) and `seq.py` runs timed operations (zoom jumps, flyTo, projection toggles) with grabs; always restore `main.qml` and check `git diff main.qml` afterwards. GL JS reference on the globe: harness URL parameter `globe=1`. In the built-in browser pane nudge the page (a screenshot) while waiting for `save=`.

## Memory guard (use for any pitch/zoom stress test)

`tools/memguard.sh` in the app repo (copy of `~/dev/tmp/memguard.sh`; start in a terminal first, leave it running): logs every 2 s to `~/dev/tmp/memguard.log` and, if `MapLibreEarth` RSS > 8 GB, system MemAvailable < 5 GB or amdgpu GTT (`/sys/class/drm/card1/device/mem_info_gtt_used`) > 9 GB, dumps all stacks to `~/dev/tmp/memguard_stacks.txt` and kills it. Why: on 2026-10-17 an unbounded terrain cover (16,679 tiles at pitch 71) drove amdgpu GEM allocations until the kernel wedged (list_debug corruption, reboot). Forensics: `journalctl -k -b -1 | grep -E "amdgpu|MapLibreEarth"` after a crash.

## Pitfalls / facts learned (details in [log](../log.md))

- **World z is in METRES** in this fork (`Camera::getWorldToCamera` multiplies the z column by pixels-per-metre, like GL JS). Terrain mesh z, symbol elevation, the pan/zoom unprojection plane (`getCenterAltitude()`), tile bounding boxes and the frustum z are all metres. `TransformState::z` is the centre altitude in *pixels*.
- A tile cover on the sea-level plane drops terrain that rises into view; GL JS gives every cover node a bounding box spanning its DEM min/max (`Terrain#getMinMaxElevation`, nearest loaded ancestor fallback) and `Frustum::intersects` tests all 8 corners. Terrain also forces variable zoom (`calculateTileZoom`) — see patch 0040.
- Debug-only `BackendScope::exists()` assertions came from resizing/destroying the Vulkan offscreen texture outside a scope; `MapRenderer::updateRenderer` and `~VulkanRendererBackend` now take an Implicit scope (Qt wrapper, not in patches).
- gdb attach works for hang forensics (`gdb -p PID -batch -ex "thread apply all bt 30"`); `pkill -f name` inside a Bash tool call kills the tool's own shell if the command line contains the name.

## Where the code lives on GitHub (2026-10-17)

- `johndr/maplibreearth` (app + wiki) `main`; `johndr/maplibre-native-qt` (wrapper + `patches/0001..0056`) `main`; `johndr/maplibre-native` branch **`maplibreearth-patches`** = upstream `android-v13.6.1` (`c7506d6`) + one commit per patch 0001..0056 (tree identical to the patched `vendor/maplibre-native` working tree). `main` of that fork is untouched upstream.
- When a new patch `NNNN` is added to `maplibre-native-qt/patches/`: in a **worktree** of `~/dev/projects/maplibre-native` on `maplibreearth-patches` run `git apply --index patches/NNNN-....patch` and commit (identity: this Linux account has no git identity; use `GIT_AUTHOR_NAME/EMAIL` + `GIT_COMMITTER_*` env vars, JohnD <johndrummond0@gmail.com>), then `git push origin maplibreearth-patches`. If an existing patch is regenerated (as 0040 was repeatedly), amend/replace its commit accordingly.
