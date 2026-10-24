---
type: Architecture
title: Technology
description: The languages, libraries, toolchains and build systems MLNGlobeApp and MapLibre Native Qt are built from.
tags: [ architecture, technology ]
status: draft
---
## Summary

The project is C++ (the Qt bindings and [MapLibre Native](./)), QML (the [app UI](./)), and CMake. Everything targets **Qt 6.12.0**.

## Qt

| Purpose | Path |
|---------|------|
| Desktop host | `C:\Qt\6.12.0\msvc2022_64` |
| Android arm64 | `C:\Qt\6.12.0\android_arm64_v8a` |
| Android x86_64 | `C:\Qt\6.12.0\android_x86_64` |

Qt modules used by the app: **Core, Gui, Network, Quick, QuickControls2**. The MapLibre QML module is `declarative_maplibre` (`import MapLibre 4.0`).

## Compilers & tooling

- **MSVC** — Visual Studio 2022 Preview (toolset 14.43).
- **CMake** — `C:\Qt\Tools\CMake_64`; **Ninja** — `C:\Qt\Tools\Ninja`; **JOM** — bundled with Qt Creator (used by the kit-mode build).
- **Android** — NDK `27.2.12479018`, SDK build-tools `36.0.0`, JDK 21 (Eclipse Adoptium).
- **Vulkan SDK** — `C:\VulkanSDK\1.4.304.0` (Windows).

## Renderers

MapLibre Native is built with **Vulkan** (`MLN_WITH_VULKAN=ON`) on Windows and Android. An **OpenGL** build (`MLN_WITH_OPENGL=ON`) is also used for CI-parity checks ([Windows runbook](../runbooks/build-windows.md)). The Qt Quick item renders into a texture node — `texture_node_vulkan.cpp` or `texture_node_opengl.cpp`.

## Build systems

- **MapLibre Native Qt** — CMake, with bundled `CMakePresets.json`. Built in Qt Creator **kit mode** (generator `NMake Makefiles JOM`) or on the command line.
- **MLNGlobeApp** — its own standalone CMake project; locates the library with `find_package(QMapLibre COMPONENTS Core Quick)`, built with Ninja locally.

## Upstream CI

MapLibre Native Qt CI builds **Windows / Linux / macOS / Android / iOS / WASM** on **Qt 6.11.2**, and `pre-commit.ci` runs clang-format (v23) plus whitespace/EOL fixers. See [Upstream pull requests](../references/upstream-prs.md).

## Related

- [Overview](./overview.md) · [Environment](./environment.md)
