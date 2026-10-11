---
type: Concept
title: Globe projection
description: Rendering MapLibre on a sphere and morphing back to flat at high zoom — the phased plan to port globe into the vendored MapLibre Native core.
tags:
  - concept
  - globe
  - projection
  - maplibre-native
  - roadmap
status: draft
---
# Globe projection

Rendering MapLibre on a sphere, and the automatic morph back to the flat Mercator map at close zoom. This doc is the **roadmap** for porting that feature into the MapLibre Native core this project vendors. It is a multi-phase effort; only the API seam is implemented so far.

## Summary

**MapLibre Native — the C++ engine the bindings wrap — has no globe.** It is the single most-requested Native feature and, unlike MapLibre GL JS (which shipped globe in v5), it did not exist until a community implementation landed on a fork in 2026. This project does not need to invent the algorithm: an authoritative implementation and a phase-by-phase plan already exist upstream, and this doc maps them onto [MapLibre Native Qt](./maplibre-native-qt.md) and this repo.

## What "globe" actually is

From the [GL JS globe guide](./../external-sources/maplibre-gl-js-globe-guide.md), the projection is three steps:

1. compute angular spherical coordinates from the source Web Mercator tile data;
2. convert those to a 3D vector — a point on the surface of a **unit sphere**;
3. project that vector with the ordinary perspective projection matrix.

So the globe is a unit sphere from the projection's point of view. Geometry is projected onto the sphere **in the vertex shader**, which keeps the same vector polygons and lines as Mercator.

The **morph back to flat** is not a mode switch — it is a shader-interpolated blend. Globe and Mercator converge at high zoom, so around **zoom 12** the shader fades a `globeness` scalar from 1 to 0, and the map becomes ordinary Mercator with no visible jump. This is the behavior we want in MapLibreEarth.

## Why this is not a port from GL JS

The two share the *math* and the style-spec concept, not the code:

- GL JS does globe in JavaScript vertex shaders over WebGL; Native does it in C++ across **four** GPU backends (Metal, Vulkan, OpenGL, WebGPU).
- Native's `Transform`/`TransformState` is a monolith that assumes a flat Mercator plane; globe needs a projection seam behind it, new shader preludes, geometry subdivision at the tile generators, a new tile cover, and sphere-aware gestures.
- Upstream estimates the effort at "at least 6 figures in USD" and a working implementation is ~**30,000 lines**.

The realistic path is therefore to **port the upstream Native globe work**, using GL JS's globe render tests as the correctness oracle.

## Upstream references

| Reference | What it gives us |
|-----------|------------------|
| [GL JS globe guide](./../external-sources/maplibre-gl-js-globe-guide.md) | The algorithm: unit-sphere projection, `projectTile`, subdivision, the `globeness` mercator hand-off, horizon clipping, raster seams, pole caps, symbol AABBs. |
| maplibre-native **PR #4525** (Globe Projection Design Proposal) | The C++ **13-phase plan** (below), each phase its own PR, GL JS render tests as the oracle. |
| maplibre-native **PR #4533** (`feat(core): render the map as a globe when the style sets projection`) | The actual implementation branch — the code we port/write against. |
| maplibre-native **issue #3161** | The feature request and history. |

## Phase plan (from PR #4525)

Each phase ships with existing render tests **pixel-identical** (no behavior change) until it is supposed to change pixels.

| # | Phase | Deliverable | Oracle / visible result |
|---|-------|-------------|-------------------------|
| 1 | Projection seam | `ProjectionBase` + `ProjectionData` behind `TransformState`, carried through the layer tweakers into per-drawable UBOs, all four backends. **Mercator only.** | Every existing render test pixel-identical |
| 2 | Shader prelude | `projectTile()` added to the preludes; the fill family switched to it. Still Mercator. | Render tests pixel-identical |
| 3 | `projection` style property | Parser, code-gen, expression type, `Style` API, a transition scalar plumbed to the (still Mercator) transform. | Parser/expression unit tests |
| 4 | First globe pixels | Globe prelude + vertical-perspective projection on **Metal**; fill and background only, no subdivision. | First ported GL JS globe tests (`fill-planet-solid`, `background`) |
| 5 | Subdivision | Subdivide fill/line geometry at the generators; background tile meshes with **pole caps**. | `fill-planet-tiles`, `fill-seams`, `fill-planet-pole` |
| 6 | Gestures & unproject | Ray–sphere unproject, anchored zoom, horizon clamp, `easeTo`/`flyTo`, constrain on the globe. | `TransformState` unit tests; GLFW app by hand |
| 7 | Tile cover | Cover the globe with only the tiles the camera can see (convex volumes, horizon plane, no world copies). | `antimeridian-lod`, tile-count assertions |
| 8 | Symbols & collision | Globe symbol placement, collision, curved-symbol AABBs. | `collision-*`, `text-*`, `icon-text-*` globe tests |
| 9a–9d | Remaining layers on Metal | lines; circle + heatmap; raster + hillshade + color-relief; fill-extrusion (with depth prepass). | The per-family globe render tests |
| **9e** | **The morph** | Hand the globe over to Mercator between zoom 11 and 12, keeping tiles across the hand-off. | `zoom-transition`; `Map.GlobeHandOffKeepsTiles` |
| 9f–9i | Clip masks, location indicator, debug borders, custom layers | Stencil clip masks culled on the far side; the rest of the layer families. | Overlapping-tile globe tests; `custom` tests |
| 10a–10c | Other backends | Globe prelude + clip masks for **OpenGL**, **Vulkan**, **WebGPU**. | Globe tests on the Linux-OpenGL, Vulkan and WebGPU manifests |
| 11a–11b | Platform SDKs | GLFW toggle (F9); iOS example app. | GLFW app by hand; iOS render tests |


**Key read:** the "earth sphere → flat on zoom-in" behavior the request asks for is **phase 9e**. It can only be built after phases 1–9d, i.e. after the globe renders at all.

## Where the work lands in this project

- **Vendored core** — `vendor/maplibre-native` (submodule, pinned `android-v13.6.1`). This is where the globe renderer goes. See [MapLibre Native](./maplibre-native.md) and the [Downstream patches](../references/fork-patches.md) mechanism: because this repo pins a submodule rather than a fork, large changes are carried as **patches under `patches/`**, applied idempotently at configure time. The globe is far too large for that route, so the practical options are (a) advance the submodule to an upstream release once globe lands, or (b) build against the PR #4533 branch.
- **Qt bindings** — `src/core` and `src/quick` of `maplibre-native-qt`. Need to expose the projection so an app can switch it: a `mln::Map` / `MapOptions` setter, then `QMapLibre::Map` and the QML `MapLibre` item ([QMapLibre core](../modules/qmaplibre-core.md), [QMapLibre Quick](../modules/qmaplibre-quick.md)).
- **App** — MapLibreEarth. Add a control (toggle/button) that flips the projection and observe the zoom morph.

### QRhi vs the Native backend

Qt's `QRhi` is the **compositing** abstraction, not the map renderer. The Widgets path (`MapWidget : QRhiWidget`) uses it, but MapLibreEarth is QML: `MapQuickItem` renders through per-backend `QSGSimpleTextureNode`s (`TextureNode{OpenGL,Vulkan,Metal}`), selected at compile time by `MLN_RENDER_BACKEND_*`. In **all** paths the map is rasterized by MapLibre Native's own GPU backend (the `*_renderer_backend` wrappers); QRhi only decides where the finished texture lands. So globe — which is about *geometry projection* — must live in Native regardless of QRhi, and QRhi removes none of the backend work.

Native's shaders are authored **once** in GLSL (`shaders/*.glsl` + a shared `_prelude.vertex.glsl`) and transpiled per backend, so the globe *algorithm* is written once; the per-backend work is the UBO/prelude/clip-mask plumbing (phases 4, 10a–c). This project runs **Vulkan** on Windows/Android, so **phase 10b (Vulkan) is the path that matters** here.

## What has been implemented

Fourteen increments have landed:

- **API seam** — a projection setter/getter threaded through `mln::MapOptions`, `TransformState`, `mln::Map`, and the Qt `QMapLibre::Map` / QML `MapLibre` item, so a projection is **selectable** end to end (`projectionType: MapLibre.Globe`).
- **Phase 1 — the projection seam** — ported from `955e04af` (PR #4533): `ProjectionBase` + `ProjectionData`, a `MercatorProjection`, routed through `TransformState` and carried through every layer tweaker into a per-drawable `ProjectionUBO` on all four backends.
- **Phase 2 — `projectTile()`** — ported from `642c2973`: the shared prelude now defines `ProjectionUBO`/`projectTile()`, and the whole **fill family** (fill, outline, pattern, outline-pattern, outline-triangulated — GL/Metal/Vulkan/WebGPU) projects through it instead of `drawable.matrix`. Still pixel-identical.
- **Phase 3 — the `projection` style property** — ported from `69376bbd`: the style-root `projection` property is parsed (`{"type":"globe"}`, or a `[from, to, transition]` array), given an expression type (`ProjectionDefinition`), a `Style`/`Style::Impl` API, and its transition scalar is plumbed to the (still Mercator) transform. Rendering unchanged. This phase needed manual reconciliation — our release predates several style-subsystem changes upstream built on.

- **Phase 4 — globe pixels, fast-pathed to Vulkan** — the globe now **renders**. We ported phase 4's projection math (`VerticalPerspectiveProjection`, a `ProjectionVariant`, the per-drawable `depth_offset`) but wired it to **Vulkan** instead of Metal: a globe `projectTile` prelude in `vulkan/common.hpp`, the Vulkan fill and background shaders projecting through it, and the renderer requesting the globe variant when the projection is globe. Metal/GL/WebGPU globe is out of scope.
- **Phase 5 — subdivision** — ported from `aef0619` (with its Vulkan shader half hand-written): fill and line geometry is subdivided at the generators, the background tiles become meshes with **pole caps**, and `SubdivisionGranularitySetting` is plumbed through the tile worker into the buckets. The sphere is now **curved** rather than faceted. The Vulkan shaders gained the pole-aware `projectTile(pos, rawPos)` variant.

- **Phase 7 — tile cover** — ported from `4e83526f`: a globe tile cover that tests tiles against the camera frustum in unit-sphere space (convex bounding volumes) and the horizon plane, so only the visible hemisphere loads. This removes the empty gaps along the globe's limb that appeared and moved as the globe rotated.

- **Phase 6 — globe transform & gestures** — ported from `2f7bcd9e`: globe unproject, anchored zoom, constrain and camera-state caching, plus the projection-type rename, so panning and zooming behave on the sphere.
- **The globe→Mercator hand-off (the core of 9e)** — ported into `style::Projection::Impl::evaluate`: `globe` is the world on a sphere above zoom 11 and ordinary Mercator below 12, blended in between, exactly as GL JS does. This also **fixed a bug** — without it the globe radius grows without bound while the camera distance is fixed, so the camera ends up on the sphere's surface and zooming in showed a single flat colour. You now get the globe→flat **morph**.

- **Lines on the globe (the first slice of 9a)** — the Vulkan line vertex shaders (`line`, `line-gradient`, `line-pattern`, `line-sdf`) had not been switched to the globe, so they projected with the Mercator matrix. On the globe the road-casing lines smeared across the whole window in their colour (`#E9AC77`), which looked like the map filling with one colour at many zoom levels. They now project through `projectTile` like the fill family. (This was found by hand and verified with a screenshot of the fixed globe.)

- **Phase 9c — raster, hillshade and color-relief** — ported to Vulkan: their vertex shaders project through `projectTile` and their render layers build the subdivided pole-capped `GlobeTileMesh` instead of the flat quad. The `natural_earth` shaded relief now wraps onto the sphere instead of showing as a flat block.

- **Phase 9b — circles & heatmaps** — ported to Vulkan: their extruded corners are projected on the sphere (`projectToSphere` + `globeRotateVector` + `interpolateProjection`) using a new `globe_extrude_scale` drawable field.
- **Phase 9d — fill-extrusions (3D buildings)** — ported to Vulkan: vertices project through `projectTileFor3D`, and a new **`GlobeDepthPass`** writes the planet into the depth buffer ahead of the translucent pass so 3D geometry behind the horizon is hidden. Adds `projectionVariant` to `RenderLayer`, the globe depth shader, and 3D prelude helpers.

- **Phase 8 — symbols & labels** — ported to Vulkan: the symbol projection, collision index and placement work on the sphere; the symbol vertex shaders project through `projectTileWithElevation` and the symbol render layer switches the projection variant. Adds `src/mln/map/tile_projector.hpp`.

**Every layer family in the design proposal's phase plan is now globe-aware on Vulkan** — fills, background, **lines (9a)**, **rasters/hillshade/color-relief (9c)**, **circles/heatmaps (9b)**, **fill-extrusions (9d)** and **symbols (8)** — carried as twelve downstream patches, `…-0003` through `…-0014-globe-symbols-vulkan.patch` (see [Fork patches](../references/fork-patches.md)).

## Verification

- **Upstream oracle:** the ported GL JS globe render tests (per phase). Locally these run through MapLibre Native's render-test harness; MapLibreEarth's own verification is manual (see the [Verification](../verification/index.md) section).
- **Windows/Vulkan and Android** are this project's targets; phase 10b (Vulkan) is therefore on the critical path, not an optional extra.
- **In-app check** for the morph: zoom through level 11–12 in globe mode and confirm no visible jump; see the [Gestures](../flows/gestures.md) flow for the zoom inputs.

## Risks

- **Scale.** This is weeks-to-months of specialist renderer work, not a sprint. Phases 1–4 are the minimum to see anything.
- **Backend coverage.** Metal is the reference backend in the plan; this project runs **Vulkan** on Windows/Android, so phase 10b must be done before the globe is usable here.
- **Submodule vs fork.** A patch-based approach cannot carry 30k lines; decide early whether to track a globe release or a branch.
- **Style-spec coupling.** The `projection` style property (phase 3) interacts with the [Style-spec properties](./style-spec-properties.md) work already patched into this tree.

## Related

- [MapLibre Native](./maplibre-native.md) · [MapLibre Native Qt](./maplibre-native-qt.md) · [Downstream patches](../references/fork-patches.md) · [MapLibre Native core](../modules/maplibre-native-core.md) · [QMapLibre core](../modules/qmaplibre-core.md) · [QMapLibre Quick](../modules/qmaplibre-quick.md) · [Next steps](../next-steps.md)
