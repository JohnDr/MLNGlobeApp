---
type: Runbook
title: Build (macOS)
description: Build and install QMapLibre (Metal) on the Mac mini, then build and run MapLibreEarth against it.
tags:
  - runbook
  - macos
  - build
status: draft
---
## Summary

Two stages, same split as on Windows and Linux: the [`QMapLibre`](../concepts/maplibre-native-qt.md)
library is built and installed from the command line, and the
[MapLibreEarth app](../modules/mapplibrerearth-app.md) is built and run through **Qt Creator only**
(repo policy, see `AGENTS.md`).

macOS is **Metal-only**: OpenGL and Vulkan are not available on Apple platforms, so this is the one
build that exercises the fork's patches against the Metal backend.

**Status 2026-10-22 — first run, not yet validated.** Pristine QMapLibre is green in upstream CI
(`.github/workflows/macOS.yml`, Qt 6.11.2, `cmake --workflow --preset macOS-sccache`), but this
fork's 56 patches have never been through a macOS build. Four of them (0003, 0004, 0006, 0007) also
touch Metal headers/shaders (`include/mln/mtl/`, `include/mln/shaders/mtl/`) and
`src/mln/mtl/context.cpp` (`Context::getGenericShader` gains a `ProjectionVariant` parameter); the
rest are shared code, Vulkan or OpenGL. Treat the first build as bring-up work.

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
  Qt Quick / Qt Quick Controls 2, **Qt Positioning**, **Qt Location**, and Qt Creator.
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

A failed `--check` means the submodule is not at the pin, or is already patched. Patches 0001–0056
must apply in `ls` order (the four-digit prefixes make that the patch order).

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
  Drop it again for anything you hand to someone else — universal is what upstream ships.
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

## 3. Build the app (Qt Creator)

Per the build policy the app is **built and run through Qt Creator**, not from a shell.

- **Kit**: Qt 6.12.0 macOS (Desktop), Ninja, Release.
- **Build directory**: `~/dev/tmp/build-MapLibreEarth-Desktop_Qt_6_12_0_macOS-Release`.
- **CMake configuration** (Projects → Build → CMake):

  ```
  -DQMapLibre_DIR=$HOME/dev/tmp/install-maplibre-native-qt-macos/lib/cmake/QMapLibre
  ```

  (`CMAKE_PREFIX_PATH=<Qt root>` comes from the kit; `QMapLibre_DIR` must point at the
  `lib/cmake/QMapLibre` directory, not the prefix root.)
- Build, then Run. The app calls `qmaplibre_quick_setup_plugins(MapLibreEarth)`, which publishes the
  install's `qml/` directory as `QML_IMPORT_PATH` for Qt Creator, so `import MapLibre 4.0`
  resolves without extra setup. `qt_generate_deploy_qml_app_script(... MACOS_BUNDLE_POST_BUILD)`
  deploys Qt into the `.app` after each build, so the bundle in the build dir is directly runnable.

Launching **outside** Qt Creator (`open <build>/MapLibreEarth.app`): if the MapLibre QML module is not
found, export

```bash
export QML_IMPORT_PATH="$HOME/dev/tmp/install-maplibre-native-qt-macos/qml"
```

Add `DYLD_FRAMEWORK_PATH="$HOME/dev/tmp/install-maplibre-native-qt-macos/lib"` only if the prefix has
been moved after the app was built (CMake records the absolute framework path).

**Debug vs Release**: unlike Windows/MSVC, one `RelWithDebInfo` install serves both app
configurations — the frameworks and QML plugin are not split by config, so there is no
Debug-install counterpart of the Windows setup. If you need to step into the library, build a second
tree with `-DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=...-debug` and point the Debug kit at it.

## 4. First-run checks (unvalidated)

1. App starts and draws the base map — watch for `Failed to create graphics backend` or
   `Cannot assign to non-existent property "terrainExaggeration"` (the latter means an old/foreign
   QMapLibre was picked up, i.e. `QMapLibre_DIR` is stale).
2. Fork features on Metal: globe projection (the app's `gljs-terrain-style.json`), terrain +
   `terrainExaggeration`, and the custom style layers.
3. `ctest` green in the library tree (pristine upstream is green on macOS, so failures here are
   fork-specific and worth recording).
4. Record the outcome in [upstream contribution progress](./upstream-contribution-progress.md) — the
   same Metal build is the baseline for the macOS WebGPU work on the upstream PR branches.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Could not find toolchain file .../Qt6/qt.toolchain.cmake` | `QT_ROOT_DIR` unset or pointing at a non-Qt dir. |
| `QMapLibre ... not found` | `QMapLibre_DIR` must be `<prefix>/lib/cmake/QMapLibre`. |
| `error: patch failed` / `does not apply` | Submodule not at `c7506d6`, or patches already applied (`git -C vendor/maplibre-native checkout .` then re-apply). |
| Build fails in `src/mln/mtl/*` or `include/mln/shaders/mtl/*` | Fork-specific Metal breakage from patches 0003/0004/0006/0007 — capture the file/line, this is new information. |
| `module "MapLibre" is not installed` at run | Set `QML_IMPORT_PATH=<prefix>/qml` (Qt Creator normally does this for you). |
| Builds are slow | Universal arch; add `-DCMAKE_OSX_ARCHITECTURES=arm64`. |
| Qt Location not found (Qt ≥ 6.9 also wants private headers) | Install the Qt Positioning/Location modules, or disable Location/Widgets as above. |

## Related

- [Build (Windows)](./build-windows.md) · [Qt Creator Debug/Release](./qt-creator-debug-release.md) · [Upstream contribution progress](./upstream-contribution-progress.md)
- [QMapLibre](../concepts/maplibre-native-qt.md) · [MapLibreEarth app](../modules/mapplibrerearth-app.md) · [Verification](../verification/index.md)
