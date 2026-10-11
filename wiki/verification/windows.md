---
type: Verification
title: Windows
description: Verified Windows builds and runs — library, app, Debug/Release and right-drag zoom.
tags: [ verification, windows ]
status: draft
---
## What was verified

| Check | Result |
|-------|--------|
| Library builds (Vulkan, Release) | `QMapLibre.dll`, `QMapLibreQuickPrivate.dll`, `declarative_maplibre.dll` link. |
| Library builds (Vulkan, Debug) | `QMapLibred.dll`, `QMapLibreQuickPrivated.dll`, debug plugin link. |
| Library builds (OpenGL, PR #323 branch) | Links after the `Renderable::size` → `getSize()`/`setRenderableSize()` fix. |
| App builds + runs (Release) | Launches, renders the map. |
| App builds + runs (Debug) | Launches after the [Debug QMapLibre + runtime copy](../decisions/d5-debug-release-libraries.md). |
| Right-drag smooth zoom | Fires 35 translation events and zooms in (screenshot before/after); left-drag pans (15 events). |
| Open Waters in Debug | Runs after the [assert relaxation](../references/fork-patches.md) (was a CRT *Assertion failed* dialog). |

## Method

Right-drag was exercised with synthetic mouse input (`mouse_event` + `SetCursorPos`) while logging the handler's `onTranslationChanged`; the app's window was captured with `PrintWindow`. The Debug assert was traced with a conditional breakpoint at `property_expression.hpp:96` and a call stack.

## Related

- [Build (Windows)](../runbooks/build-windows.md) · [Qt Creator Debug/Release](../runbooks/qt-creator-debug-release.md) · [D4](../decisions/d4-right-drag-zoom.md)
