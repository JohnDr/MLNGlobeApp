---
type: Status
title: Next steps
description: What to do next on MapLibreEarth and the MapLibre Native / Native Qt work, in order.
tags: [ status, project, handover ]
status: draft
---
## Summary

Ordered to-do list. Update it at the end of each session and record results in [Project history](./history.md) and the [wiki log](./log.md).

## Where things stand (2026-10-11)

- MapLibreEarth builds and runs on Windows (Release **and** Debug) and Android arm64-v8a; deployed to a Galaxy S23 (serial `RFCW910087W`).
- [`QMapLibre`](./concepts/maplibre-native-qt.md) is built from a fork of MapLibre Native Qt, with the MapLibre Native submodule at `android-v13.6.1` plus two [downstream patches](./references/fork-patches.md).
- Five upstream PRs are open as **Drafts** ([references/upstream-prs.md](./references/upstream-prs.md)); **hold** further upstream work until the project stabilises ([D6](./decisions/d6-draft-upstream-prs.md)).

## Open items

## Globe port — resume here

The globe **renders on Vulkan**: curved, covers the visible hemisphere, morphs back to flat past zoom ~11, and draws **fills, background, lines and rasters/hillshade/color-relief** (see [Globe projection](./concepts/globe-projection.md)). It is driven by **fourteen** downstream patches in `maplibre-native-qt/patches/` (`maplibre-native-0001`…`0014`), which reproduce the vendored tree. **Every layer family in the design proposal's phase plan is now globe-aware on Vulkan** — fills, background, lines (9a), rasters/hillshade/color-relief (9c), circles/heatmaps (9b), fill-extrusions (9d) and symbols (8).

**Remaining work is verification and polish, not porting:**

- [ ] Eyeball the globe with a style that exercises each family at low zoom — the ports are compile-verified, but the app's styles may not exercise every one end to end.
- [ ] Optional: upstream's feature-query paths (the TileProjector capture and the symbol label-plane capture) were skipped; they affect querying, not rendering.

See [Fork patches](./references/fork-patches.md) and the [globe log](./log.md).
- [ ] Decide whether to keep the `line-dasharray` data-expression part of the [style-spec patch](./references/fork-patches.md). It is non-conformant (the spec marks `line-dasharray` cross-faded / zoom-only) and is what forced the [assert-relaxation patch](./decisions/d3-downstream-patches.md).
- [ ] Take the draft PRs out of Draft and merge when stable; rebase #324–#326 after #323.
- [ ] Optional: raise the style-spec gaps upstream — [`icon-overlap`/`text-overlap`](./references/upstream-issues.md) (issue #251), data-driven `line-dasharray`, and the Open Waters `resampling` misuse.
- [ ] Optional: add a Qt Creator **Android** kit / CMake preset with `QMapLibre_DIR` so MapLibreEarth builds for Android from the IDE (currently command-line only — see [Android build](./runbooks/build-android.md)).
- [ ] Optional: provide a fork branch/tag that produces the exact `QMapLibre` install MapLibreEarth consumes (the fork `personal` branch does this today).

## Related

- [History](./history.md) · [Wiki log](./log.md) · [Decisions](./decisions/index.md)
