---
type: Runbook
title: Preparing to contribute upstream
description: Contribution rules and CI gates of maplibre-native and maplibre-native-qt, what we meet today, and the plan to offer the fork's work back.
tags: [ runbook, upstream, contributing, ci, tests ]
status: draft
---
## Summary

Read 2026-10-18: `maplibre-native` `CONTRIBUTING.md`, `FORK.md`, `.pre-commit-config.yaml`, `.github/workflows/*` and `validate-pr-title.ts`; `maplibre-native-qt` `.github/workflows/*`, pre-commit, `codecov.yml`, `CHANGELOG.md`. The Qt repo has no `CONTRIBUTING.md` or PR template; it follows the same pre-commit + CI conventions. Targets: Windows 11, Linux (Ubuntu 26.04), Android; development is on Linux.

## Rules

- **PR title** contains the platform keyword of its label (`core`, `qt`, `android`, `ios`, `node`); CI-checked.
- **CHANGELOG**: add to the `main` section of the relevant `CHANGELOG.md` (root = core, `platform/qt`, `platform/android`, ...).
- **AI policy** (MapLibre `AI_POLICY.md`): disclose AI use in the PR, verify everything personally.
- **Design Proposal** for substantial changes: `design-proposals/YYYY-MM-DD-keyword.md`, PR, 72 h vote. Terrain, sky and globe qualify.
- **pre-commit**: clang-format v23.1.1 plus hygiene hooks (end-of-file, trailing whitespace, JSON/YAML, large files).
- **Licensing**: no code from non-free Mapbox projects; GL JS is the BSD-3 reference, port with attribution.

## CI gates

| Repo | Gate |
|------|------|
| maplibre-native | linux-ci: Vulkan + OpenGL builds, `mbgl-test-runner` (Vulkan: non-blocking), render tests (`metrics/linux-<renderer>.json`, blocking), expression tests, benchmark + bloaty size report, CodeQL, Bazel coverage |
| maplibre-native | windows-ci: OpenGL, EGL, Vulkan on MSVC and MSYS2 clang, same test trio (Vulkan unit tests non-blocking) |
| maplibre-native | android-ci: unit tests, UI tests, C++ tests, render tests, WebGPU builds; plus ios/macos/node CI |
| maplibre-native-qt | Linux: OpenGL + Vulkan (Qt 6.11.2), coverage (OpenGL), clang-tidy (OpenGL, Vulkan) |
| maplibre-native-qt | Windows: OpenGL with tests; Vulkan build-only; arm64 build-only |
| maplibre-native-qt | Android: OpenGL and Vulkan x 4 ABIs, build-only; plus iOS/macOS/WASM builds and docs-test |

## Where we stand

Met on Linux/Vulkan only: core unit, render and expression tests and the Qt quick test run ([results](../verification/linux-tests.md)). **Not met:** (Linux OpenGL and Vulkan are now green); nothing run on Windows or Android from the dev PC; patches 0003/0004/0006/0007 touch Metal, GL and WebGPU shaders we cannot build here; no render-test fixtures for terrain/sky/globe; no pristine-upstream baseline for the known failures; Qt location and widgets tests not configured locally; formatting (pre-commit) unchecked; stray edits in the vendored tree (`metrics/ignores/platform-all.json` whitespace, untracked `metrics/linux-vulkan.html`, `test/fixtures/style_parser/projection-not-object.*`).

## Plan

0. **OpenGL regression - fixed by patch 0055** (was 15 unit / 497 render failures vs pristine, [details](../verification/linux-tests.md)). Rule: every shared-shader/UBO change must build and pass on GL as well as Vulkan (and Metal/WebGPU via CI) before upstreaming. Metal/WebGPU consumers of the changed shared shaders are still unchecked.
1. **Baseline**: pristine `c7506d6` done on Linux OpenGL (1060 unit pass, 5 render failures) and Vulkan (1025 unit pass); still to do: Vulkan render tests and current `main`.
2. **Decide what to offer**: the 53 core patches (~25k lines) are not one PR. Split into independent PRs rebased on current upstream `main`. Bug fixes with a test each go first (0052 background-layer tweaker rebuild, 0049 DEM half-pixel sampling, `icon-overlap`/`text-overlap` PR #4752). Features (terrain, sky, globe phases) need a Design Proposal; check upstream PR #4533 and drop our globe ports where upstream already has them. The core patches cannot go to the Qt repo (it only carries them under `patches/`); its PRs are #323-#326 (vendored upgrade, Vulkan headers, right button, runtime style).
3. **Test matrix to close**: Linux OpenGL (core + Qt); Windows 11 MSVC OpenGL + Vulkan (`mbgl-test-runner`, render tests, Qt `ctest` incl. quick/location/widgets); Android (Qt build both renderers x ABIs; core Android tests need device/emulator). Enable `MLN_QT_WITH_LOCATION` and `MLN_QT_WITH_WIDGETS` locally. Open draft PRs early so GitHub CI covers macOS, iOS and WebGPU.
4. **Fixtures**: add render-tests (style + expected PNG) for each visual feature; per-platform metrics come from CI iteration; ignore-list entries need a linked reason. Add QML tests in `test/quick` for the new `MapQuickItem` API (terrain, sky, `setLocationAtPoint`, render metrics) and docs.
5. **Hygiene**: install pre-commit (clang-format 23.1.1) and run on every touched file; no unrelated reformatting; remove the stray edits above; strip fork-only parts (GL JS alignment deviations, HUD/app code, Windows paths).
6. **Per PR**: keyword title and label, CHANGELOG entry, AI-use disclosure, statement of what was verified on which platform.

## Related

- [Progress tracker](upstream-contribution-progress.md) · [Linux tests](../verification/linux-tests.md) · [Upstream PRs](../references/upstream-prs.md) · [Fork patches](../references/fork-patches.md) · [GL JS alignment](../references/gljs-alignment.md)
