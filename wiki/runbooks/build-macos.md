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
**Metal** (`Graphics API: 6`) with `Root objects loaded successfully`.

The 56 patches needed **no core changes** on Metal. Two **wrapper** fixes were needed because
`MetalRendererBackend` was written against a different `gfx` API than the pinned core `c7506d6`:
it overrode `updateAssumedState()` (declared only by `gl::RendererBackend`) and assigned the private
`Renderable::size` directly (now the protected `setRenderableSize()`). Both are committed in
`maplibre-native-qt` (`e15fa52`).

Still open: universal (`x86_64;arm64`) build, the visual Metal feature checks in §4, and the
macOS WebGPU / PR-branch work in
[upstream contribution progress](./upstream-contribution-progress.md).

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

## 3. Build the app (command line)

The **Qt Creator MCP policy is Windows-only**, so on macOS the app is built and run from a shell.
The app's `default` preset takes the Qt and QMapLibre locations from the environment:

```bash
export QT_ROOT_DIR="$HOME/Qt/6.12.0/macos"
export QMapLibre_DIR="$HOME/dev/tmp/install-maplibre-native-qt-macos"   # prefix, not lib/cmake

cmake --preset default \
  -B "$HOME/dev/tmp/build-MapLibreEarth-macos" \
  -DCMAKE_OSX_ARCHITECTURES=arm64          # Apple Silicon; drop it for universal
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

## 4. First-run checks

Library build, `ctest` and app startup are verified (2026-10-22). The visual checks are still open.

1. **Startup — verified.** Metal backend starts, QML loads; watch for
   `Failed to create graphics backend` or `Cannot assign to non-existent property
   "terrainExaggeration"` (the latter means an old/foreign QMapLibre was picked up, i.e.
   `QMapLibre_DIR` is stale).
2. **Fork features on Metal — not yet checked visually:** globe projection (the app's
   `gljs-terrain-style.json`), terrain + `terrainExaggeration`, and the custom style layers.
3. **`ctest` — verified 3/3** (quick, location, widgets). Pristine upstream is green on macOS, so
   failures here are fork-specific and worth recording.
4. Record the outcome in [upstream contribution progress](./upstream-contribution-progress.md) — the
   same Metal build is the baseline for the macOS WebGPU work on the upstream PR branches.

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
- [QMapLibre](../concepts/maplibre-native-qt.md) · [MapLibreEarth app](../modules/mapplibrerearth-app.md) · [Verification](../verification/index.md)
