# AGENTS.md — MapLibreEarth

## Build & run policy (agreed with John)

- **This app is built and run through Qt Creator, always** — never ad-hoc
  command-line app builds. Use the Qt Creator MCP tools:
  `qt-creator_switch_build_config` (Debug | Release), `qt-creator_build`,
  `qt-creator_run_project` / `qt-creator_debug`.
- **Dependencies (QMapLibre and others) are built from the command line**, not
  through the Qt Creator MCP — see `../maplibre-native-qt/AGENTS.md`.

## If you cannot follow an instruction — ask John

If for any reason you cannot follow an instruction in this file (or in the
QMapLibre `AGENTS.md`), **stop and come back to John for a decision**. Do not
silently deviate, and do not substitute a workaround on your own initiative. State
plainly what you could not do and why, and wait.

This applies in particular to the build & run policy above — e.g. a Qt Creator MCP
tool that blocks or fails (such as `qt-creator_run_project` never returning for a
long-running GUI app), a build-tree / install-prefix mismatch, or any urge to
build or run the app outside Qt Creator (ad-hoc command-line app builds, launching
the exe directly, hand-copying runtime DLLs). In all such cases: ask first.

## Handoff guarantee (what John relies on)

John may **Run** this app in Debug **or** Release and expects to be on the latest
code. Both must hold, because each config loads its own QMapLibre runtime + QML
plugin:

| Config  | `QMapLibre_DIR` prefix | App build dir |
|---------|------------------------|---------------|
| Release | `C:\hda\dev\tmp\install\maplibre-native-qt` | `C:\hda\dev\tmp\build-MapLibreEarth-Desktop_Qt_6_12_0_MSVC2022_64bit-Release` |
| Debug   | `C:\hda\dev\tmp\install-maplibre-native-qt-debug` | `C:\hda\dev\tmp\build-MapLibreEarth-Desktop_Qt_6_12_0_MSVC2022_64bit-Debug` |

Before handing back, after any library change:
1. Refresh **both** QMapLibre installs (Release **and** Debug) —
   `%LOCALAPPDATA%\Temp\opencode\build-libs-both.bat`.
2. Build the app via Qt Creator in the config(s) you're handling, so its
   POST_BUILD copies the matching runtime next to the exe.

A stale install shows up as `Cannot assign to non-existent property
"terrainExaggeration"` at startup (old `MapLibre` QML plugin).

## Rules

- Do not create alternate build dirs (ninja/`build/`, MinGW, `build-pr1-opengl`,
  examples). The two app dirs above and the two library dirs are canonical.
- The app loads the `MapLibre` QML module and QMapLibre runtime from the
  per-config install above (its `qt.conf` `QmlImports` + POST_BUILD copy); do not
  substitute another install.
- `.qtcreator/CMakeLists.txt.user` is rewritten by Qt Creator on save — edit it
  only via the runbook procedure (unload → edit → reopen).
- Wiki is authoritative: `wiki/runbooks/{build-windows,qt-creator-debug-release}.md`,
  `wiki/architecture/environment.md`, `wiki/decisions/d5-debug-release-libraries.md`.
