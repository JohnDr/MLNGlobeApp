---
type: Runbook
title: Qt Creator Debug/Release
description: How MapLibreEarth's Debug and Release build configurations are set up in Qt Creator and why each needs its own QMapLibre install.
tags: [ runbook, qtcreator ]
status: draft
---
## Summary

MapLibreEarth has two Qt Creator build configurations (Debug, Release) for the **Desktop Qt 6.12.0 MSVC2022 64bit** kit, stored in `MapLibreEarth\.qtcreator\CMakeLists.txt.user`. Each configuration passes a different `-DQMapLibre_DIR`.

## The configurations

| Config | `QMapLibre_DIR` | Build dir |
|--------|------------------|-----------|
| Debug | `C:\hda\dev\tmp\install-maplibre-native-qt-debug\lib\cmake\QMapLibre` | `...\build-MapLibreEarth-...-Debug` |
| Release | `C:\hda\dev\tmp\install\maplibre-native-qt\lib\cmake\QMapLibre` | `...\build-MapLibreEarth-...-Release` |

## Why two installs

A **Debug** app cannot load a **Release** Qt QML plugin — Qt refuses with *"uses incompatible Qt library (Cannot mix debug and release libraries)"*. So the Debug config needs a **Debug** `QMapLibre` ([D5](../decisions/d5-debug-release-libraries.md)). Build it with `build-mnqt-debug.bat` and install to `install-maplibre-native-qt-debug`.

## Editing the configs without the GUI

Qt Creator rewrites the `.user` file when the project is saved/closed, so edits made while the project is open are lost. The working procedure is:

1. Close the project: run the `ProjectExplorer.UnloadCM` action.
2. Edit `MapLibreEarth\.qtcreator\CMakeLists.txt.user` (per-build-config `CMake.Initial.Parameters`).
3. Reopen: switch to Welcome mode (`QtCreator.Mode.Welcome`) then `Welcome.OpenRecentProject1`.

## Running

The app's POST_BUILD step copies the correct QMapLibre runtime next to the executable, so no `PATH` setup is needed. Both **Run** and **Debug** work for both configurations.

## Agent policy

- **Windows only:** the **app** must be built and run **through Qt Creator** (MCP tools: `switch_build_config` / `build` / `run_project` / `debug`) — never ad-hoc command-line app builds.
- **macOS and Linux:** the Qt Creator MCP is **not** required; the app is built and run from the command line (see [Build (macOS)](./build-macos.md) and [Linux terrain test and debug](./linux-terrain-test-and-debug.md)).
- The **QMapLibre library** (and other dependencies) are built **from the command line** into the canonical trees, not through the MCP, on every platform.
- **Handoff guarantee:** before returning, refresh **both** QMapLibre installs when the library changed — `%LOCALAPPDATA%\Temp\opencode\build-libs-both.bat` — then rebuild the app in the config(s) being handed back so the POST_BUILD copy is current. A stale install is why the app aborts with `Cannot assign to non-existent property "terrainExaggeration"`.

The Windows-only scope is mirrored in `MapLibreEarth/AGENTS.md` and `maplibre-native-qt/AGENTS.md`, which are loaded every agent session.

## Related

- [Build (Windows)](./build-windows.md) · [D5](../decisions/d5-debug-release-libraries.md) · [Environment](../architecture/environment.md)
