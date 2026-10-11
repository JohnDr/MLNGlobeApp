---
type: Reference
title: Upstream pull requests
description: The five draft PRs prepared for maplibre-native-qt and maplibre-native.
tags: [ reference, upstream, prs ]
status: draft
---
## Summary

Five PRs were prepared for the MapLibre projects. All are **Draft** as of 2026-10-11 ([D6](../decisions/d6-draft-upstream-prs.md)). The branches are pushed to the fork `JohnDr/...`.

## maplibre-native-qt

| # | Title | Branch | What |
|---|-------|--------|------|
| #323 | Update vendored MapLibre Native to android-v13.6.1 | `pr/upgrade-maplibre-native-13.6.1` | Submodule bump + `mbgl`→`mln` rename + `include/mln`; folds in the OpenGL `Renderable::size` fix ([D2](../decisions/d2-upgrade-13-6-1.md)). |
| #324 | Use vendored Vulkan headers when building the Qt core bindings | `pr/vulkan-vendored-headers` | Adds the vendored Vulkan include paths to `MLNQtCore` (handover §2). |
| #325 | MapQuickItem: also accept the right mouse button | `pr/mapquickitem-right-button` | `setAcceptedMouseButtons(LeftButton \| RightButton)` ([D4](../decisions/d4-right-drag-zoom.md)). |
| #326 | MapQuickItem: apply setStyle at runtime | `pr/mapquickitem-runtime-style` | Reloads the style on the live map ([style flow](../flows/style-load-and-switch.md)). |

## maplibre-native

| # | Title | Branch | What |
|---|-------|--------|------|
| #4752 | feat: support icon-overlap and text-overlap symbol layout properties | `mln-icon-text-overlap` | Implements `icon-overlap`/`text-overlap`, refs issue #251; CHANGELOG updated. |

## Notes

- Only `src/` and the submodule pointer change in the Native Qt PRs; examples are untouched (they now live in MapLibreEarth, [D1](../decisions/d1-standalone-app.md)).
- The fork-only [patches](./fork-patches.md) are **not** part of any PR.
- CI: platform builds on Qt 6.11.2 + `pre-commit.ci` (clang-format v23). PR #4752 discloses AI usage per MapLibre policy.

## Related

- [D6](../decisions/d6-draft-upstream-prs.md) · [Upstream issues](./upstream-issues.md) · [Fork patches](./fork-patches.md)
