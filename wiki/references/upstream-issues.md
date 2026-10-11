---
type: Reference
title: Upstream issues
description: The MapLibre Native style-spec gaps this project works around, and where they belong upstream.
tags: [ reference, upstream, issues ]
status: draft
---
## Summary

The gaps the [downstream patches](./fork-patches.md) work around, and the right place to report each.

## `icon-overlap` / `text-overlap` — issue #251

These are real style-spec properties (successors of `icon-allow-overlap` / `text-allow-overlap`) that MapLibre Native does not implement. The spec's `sdk-support` block for both points at **maplibre/maplibre-native issue #251**. Addressed by PR [#4752](./upstream-prs.md).

## Data-driven `line-dasharray`

The spec marks `line-dasharray` `cross-faded` with **zoom-only** expressions, so a data-driven dash is non-conformant — and Native's cross-fade evaluator cannot hold a data expression. The Open Waters style uses it anyway (`hazard-areas`, `shoreline-constructions`). Not a good upstream change; a candidate to drop from the [patch](./fork-patches.md).

## `resampling` on colour-relief

Open Waters sets `resampling: "nearest"` on a **colour-relief** layer, but the spec defines no such property for colour-relief (only `raster-resampling`). The style is using an invalid property; nothing to fix in Native.

## The general behaviour

Regardless of the specific properties, MapLibre Native **drops an entire layer** on any unknown property, whereas MapLibre GL JS ignores it. A more tolerant parser would be a defensible upstream improvement.

## Related

- [Style-spec properties](../concepts/style-spec-properties.md) · [D3](../decisions/d3-downstream-patches.md) · [Upstream PRs](./upstream-prs.md)
