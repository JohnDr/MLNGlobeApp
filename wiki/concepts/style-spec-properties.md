---
type: Concept
title: Style-spec properties
description: The newer style-spec properties MapLibre Native does not implement, and how this project's patch handles them.
tags: [ concept, style-spec ]
status: draft
---
## Summary

The MapLibre style spec has moved ahead of MapLibre Native's implementation. The [Open Waters](../flows/open-waters-rendering.md) style uses several of these newer properties, and because [Native drops an entire layer on any unknown property](./maplibre-native.md), they matter: without a workaround roughly 16 symbol layers vanish and no icons render.

## The three properties the Open Waters style uses

| Property | Spec status | Native | [Patch](../references/fork-patches.md) behaviour |
|----------|-------------|--------|------------------|
| `icon-overlap` / `text-overlap` | Real spec property (enum `never` / `always` / `cooperative`); spec `sdk-support` links to [issue #251](../references/upstream-issues.md) | Not implemented | Mapped onto `icon-allow-overlap` / `text-allow-overlap` |
| data-driven `line-dasharray` | `line-dasharray` is `cross-faded` with **zoom-only** expressions | Data expressions rejected | Data expressions allowed |
| `resampling` (colour-relief) | **Not** a colour-relief property — the spec only defines `raster-resampling` | Rejected | Accepted (no-op) |

## `icon-overlap` / `text-overlap`

These are the successors of the boolean `icon-allow-overlap` / `text-allow-overlap` (the spec says *"If `icon-overlap` is not set, `icon-allow-overlap` is used instead"*). Native only knows the boolean forms. The patch maps: `never` → allow-overlap `false`; `always` and `cooperative` → `true` (a `cooperative` collision mode does not exist in Native).

## Data-driven `line-dasharray`

The Open Waters `hazard-areas` / `shoreline-constructions` layers vary the dash pattern by feature, e.g.:

```json
"line-dasharray": ["case", ["<=", ["coalesce", ["get","depth"], ["get","seabed_depth"], -9999], 2],
                   ["literal",[1,1.5]], ["literal",[4,2]]]
```

This is **non-conformant** (the spec marks `line-dasharray` cross-faded / zoom-only) and Native's cross-fade evaluator cannot hold a data expression, so Release renders a best-effort constant dash and Debug used to abort on an assert ([assert-relaxation patch](../decisions/d3-downstream-patches.md)).

## `resampling`

Open Waters puts `resampling: "nearest"` on a **colour-relief** layer (`depth-shading`). The style spec defines no such property for colour-relief — only `raster-resampling` — so the style is using an invalid property. The patch simply accepts it (a no-op) so the layer is not dropped.

## Related

- [MapLibre Native](./maplibre-native.md) · [The QML map item](./qml-map-item.md) · [Downstream patches](../references/fork-patches.md) · [Upstream issues](../references/upstream-issues.md)
