---
type: Runbook
title: Build (macOS)
description: Build and install QMapLibre (Metal) on the Mac mini, then build and run MapLibreEarth against it.
tags:
  - runbook
  - macos
  - build
status: current
---
## Summary

Two stages: the [`QMapLibre`](../concepts/maplibre-native-qt.md) library is built and installed from
the command line, then the [MapLibreEarth app](../modules/mapplibrerearth-app.md) is built and run
from the command line too. The **Qt Creator MCP requirement is Windows-only**, so on macOS no IDE
round-trip is needed (`AGENTS.md`; policy in
[Qt Creator Debug/Release](./qt-creator-debug-release.md#agent-policy)).

macOS is **Metal-only**: OpenGL and Vulkan are not available on Apple platforms, so this is the one
build that exercises the fork's patches against the Metal backend.

**Status 2026-10-22 — validated (first macOS/Metal build).** Built on macOS 27.0.1 with Xcode 27.1,
Qt 6.12.0 and `-DCMAKE_OSX_ARCHITECTURES=arm64`: the library compiles and installs, `ctest` is
**3/3 green** (`test_mln_quick`, `test_mln_location`, `test_mln_widgets`), and the app starts on
**Metal** (`Graphics API: 6`) with `Root objects loaded successfully`. The install and the app have
since been rebuilt with the preset's default **universal** `x86_64;arm64` (§4, item 5); the arm64
slice is what runs here, because this Mac has no Rosetta.

The series needs one **core** fix on Metal — patch 0057, which makes **symbols** (icons/text) render
through the globe `ProjectionUBO` (see §4) — plus two **wrapper** fixes, because `MetalRendererBackend`
was written against a different `gfx` API than the pinned core `c7506d6`: it overrode
`updateAssumedState()` (declared only by `gl::RendererBackend`) and assigned the private
`Renderable::size` directly (now the protected `setRenderableSize()`). The wrapper fixes are
committed in `maplibre-native-qt` (`e15fa52`). Patch 0058 moves one terrain-camera test pixel off a
sea-level crossing (test-only).

Still open: the human visual Metal feature checks in §4. The macOS WebGPU / PR-branch work is done
(2026-10-22) and recorded in [upstream contribution progress](./upstream-contribution-progress.md#macos-webgpu--reproduced-and-fixed-2026-10-22)
and [macOS verification](../verification/macos.md#webgpu-pr-branches-2026-10-22). iOS is a **separate
platform**: its toolchain was fixed on this Mac 2026-10-23 (Xcode's additional components plus the
iOS 27.0/27.1 simulator runtimes), so the `ios-*` CMake presets now configure — but the CMake iOS
build additionally needs `bazel` (see
[macOS verification → iOS on this Mac](../verification/macos.md#ios-on-this-mac-toolchain-fixed-2026-10-23)).

## Prerequisites

- **macOS 13+** — the preset pins `CMAKE_OSX_DEPLOYMENT_TARGET=13.0`.
- **Xcode** (upstream CI uses latest stable; full Xcode is the safe choice, Command Line Tools the
  minimum). Check with `xcodebuild -version` and `xcode-select -p`.
- **Homebrew tools**:

  ```bash
  brew install cmake ninja ccache
  ```

  CMake ≥ 3.25 is required by the presets (CI uses 4.4.x); Ninja is the preset generator; ccache is
  optional (only the `macOS-ccache` preset uses it).
- **Qt 6.12.0 (macOS)** from the Qt online installer, at `~/Qt/6.12.0/macos`, with:
  Qt Quick / Qt Quick Controls 2, **Qt Positioning**, **Qt Location**. Qt Creator is optional on
  macOS (the app is built from the command line), but useful for editing and debugging.
  Qt ≥ 6.5 is required; CI validates 6.11.2. QMapLibre's defaults build its Location and Widgets
  components, which is why Positioning/Location are needed. If you would rather not install them,
  configure with `-DMLN_QT_WITH_LOCATION=OFF -DMLN_QT_WITH_WIDGETS=OFF` — the app only needs Core +
  Quick, and the corresponding tests/examples are then skipped.
- Export the Qt root (the presets take their toolchain from `$QT_ROOT_DIR`):

  ```bash
  export QT_ROOT_DIR="$HOME/Qt/6.12.0/macos"
  ```

## 1. Sources and fork patches

The core lives in the `vendor/maplibre-native` submodule, pinned at upstream `c7506d6`
(`android-v13.6.1`). Its **working tree must stay dirty = all patches applied; never commit it.**

```bash
git clone git@github.com:johndr/maplibre-native-qt.git
cd maplibre-native-qt
git submodule update --init --recursive

# Apply the fork patches in numeric order.
for p in "$PWD"/patches/maplibre-native-*.patch; do
  git -C vendor/maplibre-native apply --check "$p" \
    && git -C vendor/maplibre-native apply "$p" \
    || { echo "FAILED: $p"; break; }
done

git -C vendor/maplibre-native status --short | wc -l   # expect a few dozen modified files
```

A failed `--check` means the submodule is not at the pin, or is already patched. Patches 0001–0058
must apply in `ls` order (the four-digit prefixes make that the patch order). Patch 0057 ports the
projection UBO to the Metal symbol shaders (`include/mln/shaders/mtl/symbol.hpp`); without it icons
and text render nothing on Metal because the shaders still read the pre-globe `drawable.matrix`.
Patch 0058 is test-only (one `TerrainCamera` pixel off a sea-level crossing).

## 2. Build + install the library (Metal)

```bash
cd ~/dev/projects/maplibre-native-qt
cmake --preset macOS \
  -B "$HOME/dev/tmp/build-maplibre-native-qt-macos" \
  -DCMAKE_INSTALL_PREFIX="$HOME/dev/tmp/install-maplibre-native-qt-macos"
cmake --build "$HOME/dev/tmp/build-maplibre-native-qt-macos"
cmake --install "$HOME/dev/tmp/build-maplibre-native-qt-macos"
```

- The `macOS` preset = Ninja, `RelWithDebInfo`, `MLN_WITH_METAL=ON`, deployment target 13.0,
  universal `x86_64;arm64`.
- On an Apple Silicon mini add `-DCMAKE_OSX_ARCHITECTURES=arm64` for roughly half the build time.
  Drop it again for anything you hand to someone else — universal is what upstream ships. The
  canonical install at `~/dev/tmp/install-maplibre-native-qt-macos` is **universal** as of
  2026-10-22 (built with the preset defaults); use the override only for a faster local arm64-only
  loop, and reconfigure without it before handing anything over.
- First build only: the vendored core plus tests take **20–40 min**; later builds are incremental.
- Tests (quick/location/widgets; gated by the component options above):

  ```bash
  ctest --test-dir "$HOME/dev/tmp/build-maplibre-native-qt-macos" --output-on-failure
  ```

Install layout — this is what the app consumes:

```
lib/QMapLibre.framework              core + Metal backend
lib/QMapLibreQuickPrivate.framework  Quick bindings
lib/cmake/QMapLibre/                 package config (QMapLibre_DIR points here)
qml/MapLibre/                        MapLibre QML module (plugin dylib + qmldir + qmltypes)
include/                             headers
```

### iOS (simulator) library tree — 2026-10-23

There was no iOS library tree before; the canonical one is now
`~/dev/tmp/build-maplibre-native-qt-ios-sim`, built from the repo's own `iOS` preset against the
**simulator** kit:

```bash
export QT_ROOT_DIR="$HOME/Qt/6.12.0/ios_simulator_arm64"
cmake --preset iOS-ccache -B "$HOME/dev/tmp/build-maplibre-native-qt-ios-sim" \
  -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build "$HOME/dev/tmp/build-maplibre-native-qt-ios-sim" --config Release
```

- **The `-DCMAKE_OSX_ARCHITECTURES=arm64` override is required on this Mac.** The preset asks for
  `arm64;x86_64`, but the Qt-installer iOS kits are single-arch (verified with `lipo`: `ios_device`
  arm64, `ios_simulator_arm64` arm64, `ios_simulator_x86_64` x86_64) while only the macOS host kit is
  fat. Configure accepts `arm64;x86_64` and then the **link** fails
  (`ld: warning: ignoring file …/QtCore …: found architecture 'arm64', required architecture 'x86_64'`
  → `Undefined symbols … _qt_main_wrapper`). Use the arch that matches the kit. Upstream's own
  `iOS CI` is green with the preset defaults because it installs Qt via `aqtinstall`
  (`target: ios`), so check the aqt-vs-Qt-installer packaging before calling this an upstream bug.
- Cross-compiling normally wants the host tools (`QT_HOST_PATH`; upstream CI sets
  `readlink -f "$QT_ROOT_DIR/../macos"`). Not needed here — Qt's iOS toolchain found
  `~/Qt/6.12.0/macos` by itself — but set it if a moc/uic error appears.
- Result 2026-10-23 (Release only): configure 6.1 s; build **551 steps, 0 warnings, 0 errors**.
  Artifacts are **static** libraries (Qt for iOS is static here), not the frameworks the macOS tree
  installs — `src/core/Release/libQMapLibre.a`, `src/quick/Release/libQMapLibreQuickPrivate.a`,
  `src/location/Release/libQMapLibreLocation.a`, `src/widgets/Release/libQMapLibreWidgets.a`, plus the
  QML module `src/quick/plugins/MapLibre/{libdeclarative_maplibre.a,qmldir,declarative_maplibre.qmltypes}`
  and the location plugin. Objects are `platform IOSSIMULATOR, minos 17.0, sdk 27.1`, arm64.
- `MLN_WITH_GLFW` stays **ON** in this configuration. Harmless for the libraries (nothing references
  GLFW and no test target is built), but a GLFW-linked test/benchmark target could not link for iOS —
  add `-DMLN_WITH_GLFW=OFF` if that ever matters.
- Not done yet: no `cmake --install`, no Debug configuration, no device build (that would use
  `QT_ROOT_DIR="$HOME/Qt/6.12.0/ios_device"`, also arm64-only).

## 3. Build the app (command line)

The **Qt Creator MCP policy is Windows-only**, so on macOS the app is built and run from a shell.
The app's `default` preset takes the Qt and QMapLibre locations from the environment:

```bash
export QT_ROOT_DIR="$HOME/Qt/6.12.0/macos"
export QMapLibre_DIR="$HOME/dev/tmp/install-maplibre-native-qt-macos"   # prefix, not lib/cmake

cmake --preset default \
  -B "$HOME/dev/tmp/build-MapLibreEarth-macos" \
  -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"   # current canonical build; use arm64 for a quick loop
cmake --build "$HOME/dev/tmp/build-MapLibreEarth-macos"
open "$HOME/dev/tmp/build-MapLibreEarth-macos/MapLibreEarth.app"
```

- `QMapLibre_DIR` is the **prefix** here — the preset appends `/lib/cmake/QMapLibre` itself. A
  hand-written configure (`-DQMapLibre_DIR=...`) must point at the `lib/cmake/QMapLibre`
  directory instead.
- `CMAKE_PREFIX_PATH` comes from the Qt toolchain file that the preset loads via `QT_ROOT_DIR`.
- The app calls `qmaplibre_quick_setup_plugins(MapLibreEarth)`, which publishes the install's `qml/`
  directory as `QML_IMPORT_PATH`, so `import MapLibre 4.0` resolves without extra setup.
  `qt_generate_deploy_qml_app_script(... MACOS_BUNDLE_POST_BUILD)` deploys Qt into the `.app` after
  each build, so the bundle in the build dir is directly runnable.

If the MapLibre QML module is not found at run time, export

```bash
export QML_IMPORT_PATH="$HOME/dev/tmp/install-maplibre-native-qt-macos/qml"
```

Add `DYLD_FRAMEWORK_PATH="$HOME/dev/tmp/install-maplibre-native-qt-macos/lib"` only if the prefix has
been moved after the app was built (CMake records the absolute framework path).

**Debug vs Release**: unlike Windows/MSVC, one `RelWithDebInfo` install serves both app
configurations — the frameworks and QML plugin are not split by config, so there is no
Debug-install counterpart of the Windows setup. If you need to step into the library, build and
install a second tree with `-DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=...-debug`, then
configure a Debug app build dir against it.

### iOS simulator app build — 2026-10-23

The same `default` preset targets iOS by pointing `QT_ROOT_DIR` at an iOS kit; the app tree is
`~/dev/tmp/build-MapLibreEarth-ios-sim`:

```bash
export QT_ROOT_DIR="$HOME/Qt/6.12.0/ios_simulator_arm64"
export QMapLibre_DIR="$HOME/dev/tmp/install-maplibre-native-qt-ios-sim"

cmake --preset default -B "$HOME/dev/tmp/build-MapLibreEarth-ios-sim" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \      # Qt-installer iOS kits are single-arch
  -DCMAKE_OSX_DEPLOYMENT_TARGET=18.0     # Qt 6.12's iOS libs are built for 18.0; 17.0 only warns
cmake --build "$HOME/dev/tmp/build-MapLibreEarth-ios-sim"

# run it (no Simulator.app on this Mac, so there is no visible window — see the verification page)
xcrun simctl boot 841FAFD2-A2A2-4AB3-886C-BD21CE7D95C3        # "iPhone Duo", iOS 27.1
xcrun simctl install booted "$HOME/dev/tmp/build-MapLibreEarth-ios-sim/MapLibreEarth.app"
xcrun simctl launch --stdout=/tmp/o.log --stderr=/tmp/e.log booted com.yourcompany.MapLibreEarth
```

- Configure 1.6 s; the build produces a **flat iOS bundle** (Ninja handles this correctly):
  `MapLibreEarth.app/{Info.plist, LaunchScreen.storyboard, MapLibreEarth}`, a ~54 MB single binary
  (static Qt + static QMapLibre + the fork's core). `Info.plist` comes from Qt's default iOS support
  (bundle id `com.yourcompany.MapLibreEarth`).
- The QMapLibre QML plugin is linked statically (`qmaplibre_quick_setup_plugins` links
  `QMapLibre::PluginQml` when Core is a static library), so `import MapLibre 4.0` resolves with no
  `QML_IMPORT_PATH` — the app writes a `.qmlc` cache under `Library/Caches/MapLibre/MapLibreEarth/qmlcache`
  in its container, which is the quickest proof the QML side really loaded.
- **App-side portability fix required** (2026-10-23, uncommitted): `main.cpp`'s `applyAndRestart()`
  called `QProcess::startDetached`, which Qt omits on iOS → build error. It is now guarded with
  `#if defined(Q_OS_IOS)` (persist the scale, skip the relaunch). Desktop behaviour is unchanged.
- Set `QT_HOST_PATH` only if a moc/uic error appears; the toolchain found `~/Qt/6.12.0/macos` alone.

## 4. First-run checks

Library build, `ctest`, app startup and the core Metal test suites are verified (2026-10-22). Only the
human visual checks (item 2) are still open.

1. **Startup — verified.** Metal backend starts, QML loads; watch for
   `Failed to create graphics backend` or `Cannot assign to non-existent property
   "terrainExaggeration"` (the latter means an old/foreign QMapLibre was picked up, i.e.
   `QMapLibre_DIR` is stale).
2. **Fork features on Metal — needs a human look:** globe projection (the app's
   `gljs-terrain-style.json`), terrain + `terrainExaggeration`, and the custom style layers. The
   app window cannot be captured from this shell (`screencapture` → "could not create image from
   display", no Screen Recording permission), so the projection paths behind these features are
   covered by the render tests below instead — including a temporary globe-projection symbol test. 
3. **`ctest` — 3/3 pass** (quick, location, widgets). Pristine upstream is green on macOS, so
   failures here are fork-specific and worth recording.
4. **Metal symbol shaders — fixed by patch 0057** (`maplibre-native-0057-globe-symbols-metal.patch`).
   Patches 0003/0004/0014 moved the fill/line/raster/background shaders to the per-tile
   `ProjectionUBO` but never touched `include/mln/shaders/mtl/symbol.hpp`, so on Metal the symbol
   vertex shaders still projected through the pre-globe `drawable.matrix` while the CPU uploaded the
   globe contract — every `icon-*`, `text-*` and `symbol-*` render test drew a blank frame (104/175
   groups passed before, 175/175 after). Patch 0057 mirrors the Vulkan symbol shaders: the
   `SymbolDrawableUBO` grows to `18 * 16`, all three vertex shaders bind `idProjectionUBO`, and the
   anchor/label-plane/z logic uses `projectTileWithElevation()`.
5. **Universal (`x86_64;arm64`) build — verified 2026-10-22.** The library was reconfigured with the
   `macOS` preset's defaults (no arch override), rebuilt and installed; `lipo -archs` reports
   `x86_64 arm64` for `QMapLibre`, `QMapLibreQuickPrivate` and both MapLibre QML plugins
   (`libdeclarative_maplibre`, `libdeclarative_maplibre_locationplugin`). The app was rebuilt the same
   way (`lipo -archs` on the executable → `x86_64 arm64`), `ctest` stays 3/3, and it starts on Metal
   (`Graphics API: 6`, `Root objects loaded successfully`). Only the arm64 slice can be executed
   here — this Mac has no Rosetta (`arch -x86_64 /usr/bin/true` → *Bad CPU type in executable*), so
   the x86_64 slice is link-checked only.

### Core test results, 2026-10-22 (Metal, `metrics/macos-xcode11-release-style.json`)

- **Render tests: all 175 groups pass**, run one process per group
  (`~/dev/tmp/render-suite-macos.sh` → `~/dev/tmp/render-macos/summary.txt`). Before 0057 only 104
  groups passed.
- **Expression tests: 332 pass, 18 ignored, 0 fail.**
- **Unit tests (everything except `Map.*`): 991 pass, 0 fail** — `991` tests / `130` suites, filter
  `-Map.*:HTTPFileSource.*:OnlineFileSource.*:MainResourceLoader.*:MapSnapshotter.*:LocalGlyphRasterizer.PingFang*`.
  The last failure, `TerrainCamera.RaycastSlopeHitLiesOnTerrainAndOnTheRay`, was a test-data boundary
  fixed by patch 0058 (below).
- **`Map.*` hangs** — root cause found and filed upstream as
  [#4822](https://github.com/maplibre/maplibre-native/issues/4822): `mtl::OffscreenTextureResource::bind()`
  allocates a new `MTLCommandBuffer` per pass, but a frame binds the headless default renderable three
  times (two `UploadPass`es + main pass) and commits once, so two buffers per frame are abandoned and
  hold the queue's in-flight slots; after ~32 frames `-[MTLCommandQueue commandBuffer]` blocks in
  `dispatch_semaphore_wait`. Reproduces on pristine `c7506d6`. Adding the `if (!commandBuffer)` guard
  used by the iOS/macOS `MTKView` renderables makes `Map.ContinuousRendering` pass (1.35 s) and the
  `Map.*` CI filter 55/55 (7.5 s); the guard is not shipped as a fork patch yet.
- **Server-dependent tests: 60 pass, 0 fail** — `HTTPFileSource` (11), `MainResourceLoader` (20),
  `MapSnapshotter` (6), `OnlineFileSource` (23), each suite in its own process. They need the
  in-process `HttpServer`, which `test/src/mln/test/test.cpp` starts only for
  `(TEST_HAS_SERVER && __QT__) || USE_CPP_TEST_SERVER`, while `test/CMakeLists.txt` defines
  `USE_CPP_TEST_SERVER` only for Windows/Linux/WebGPU. A local `if (APPLE)` per-file
  `COMPILE_DEFINITIONS` on `test.cpp` (recompiles one file) was enough; it is **not** a fork patch and
  was reverted after the run. Running all four suites in one process instead trips a timing flake in
  `OnlineFileSource.TemporaryError` (keep-alive connections saturate the server's 4-thread pool, so
  the first response takes 1–4 s instead of < 0.2 s). Details:
  [macOS tests](../verification/macos.md).

### `TerrainCamera` boundary — fixed by patch 0058 (test-only)

`test/map/terrain_camera.test.cpp:204` asserts `EXPECT_GT(hit->elevation, 0.0)`; its pixel `{400, 300}`
sits exactly on the slope's sea-level crossing, so the hit elevation was `-3.31e-07` on this Mac (the
rest of the test — hit on the slope surface, hit on the pixel ray — passed). Raycasting `{400, y}` gives
`y=300 → 0.000000` m, `y=350 → +122.9 m`, `y=400 → +261.7 m`, so only `y=300` can fall either side of
zero. Patch 0058 moves the pixel to `{400, 350}`; all 22 `TerrainCamera` tests pass and the macOS unit
suite is now 991/991.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Could not find toolchain file .../Qt6/qt.toolchain.cmake` | `QT_ROOT_DIR` unset or pointing at a non-Qt dir. |
| `QMapLibre ... not found` | `QMapLibre_DIR` must be the prefix for the preset, or `<prefix>/lib/cmake/QMapLibre` for a hand-written configure. |
| `error: patch failed` / `does not apply` | Submodule not at `c7506d6`, or patches already applied (`git -C vendor/maplibre-native checkout .` then re-apply). |
| Build fails in `src/mln/mtl/*` or `include/mln/shaders/mtl/*` | Known first-build breakage is fixed (`maplibre-native-qt` `e15fa52`: `updateAssumedState` override, `Renderable::size`); capture file/line for anything new — fork-specific Metal breakage from patches 0003/0004/0006/0007. |
| `module "MapLibre" is not installed` at run | Set `QML_IMPORT_PATH=<prefix>/qml`. |
| Builds are slow | Universal arch; add `-DCMAKE_OSX_ARCHITECTURES=arm64`. |
| Qt Location not found (Qt ≥ 6.9 also wants private headers) | Install the Qt Positioning/Location modules, or disable Location/Widgets as above. |

## Related

- [Build (Windows)](./build-windows.md) · [Qt Creator Debug/Release](./qt-creator-debug-release.md) · [Upstream contribution progress](./upstream-contribution-progress.md)
- [QMapLibre](../concepts/maplibre-native-qt.md) · [MapLibreEarth app](../modules/mapplibrerearth-app.md) · [macOS tests](../verification/macos.md) · [Verification](../verification/index.md)
