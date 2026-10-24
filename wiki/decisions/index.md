---
type: ADR
title: Decisions
description: Index of the architecture decision records for MLNGlobeApp and the MapLibre work.
tags: [ wiki, adr ]
status: draft
---
# Decisions

Architecture decision records: the context, decision and consequences behind the project's choices.

## Project

- [D1 — Standalone MLNGlobeApp app](./d1-standalone-app.md) — splitting the example into its own CMake project.
- [D6 — Hold upstream PRs as drafts](./d6-draft-upstream-prs.md) — no upstreaming until the project stabilises.

## MapLibre stack

- [D2 — Upgrade to MapLibre Native 13.6.1](./d2-upgrade-13-6-1.md) — the submodule bump and the `mbgl` → `mln` rename.
- [D3 — Downstream patches to the vendored core](./d3-downstream-patches.md) — the style-spec and assert-relaxation patches.
- [D4 — Right-drag zoom](./d4-right-drag-zoom.md) — `acceptedMouseButtons` plus a one-point `PinchHandler`.
- [D5 — Debug vs Release libraries](./d5-debug-release-libraries.md) — a Debug app needs a Debug `QMapLibre`.

## Related

- [Concepts](../concepts/index.md) · [Reference](../references/index.md)
