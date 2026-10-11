---
type: ADR
title: D3 — Downstream patches to the vendored core
description: Two fork-only patches applied to the vendored MapLibre Native at configure time — style-spec properties and a Debug assert relaxation.
tags: [ adr, patches ]
status: accepted
---
## Status

Accepted (2026-10-10 / 2026-10-11; commits `6db61e9`, `6e06e49`).

## Context

The [Open Waters](../flows/open-waters-rendering.md) style uses newer style-spec properties that MapLibre Native (even `main`) does not implement, and Native throws away a whole layer on any unknown property. Separately, enabling data-driven `line-dasharray` made Native's cross-fade evaluator call `evaluate(zoom)` on a data expression, tripping a **Debug-only** assert.

## Decision

Carry two **fork-only** patches to the vendored core, applied idempotently at configure time by `src/core/CMakeLists.txt` (`patches/maplibre-native-*.patch`, forced to LF by `.gitattributes`):

1. `maplibre-native-0001-style-spec-properties.patch` — [`icon-overlap`/`text-overlap` → allow-overlap; data-driven `line-dasharray`; accept colour-relief `resampling`](../concepts/style-spec-properties.md).
2. `maplibre-native-0002-relax-evaluate-asserts.patch` — drop the two asserts in `PropertyExpression<T>::evaluate(float zoom)`.

These are **not** upstreamed: upstream has no data-driven `line-dasharray`, so the assert cannot fire there.

## Consequences

- Open Waters renders its buoys / marks / lights; 0 style-parse warnings.
- The `line-dasharray` part is non-conformant (spec: cross-faded / zoom-only) and is what forced patch 0002 — a candidate to drop.
- After configure the submodule shows as modified (` m vendor/maplibre-native`); the committed gitlink stays clean and the patch re-applies on a fresh checkout.

## Related

- [Style-spec properties](../concepts/style-spec-properties.md) · [Downstream patches](../references/fork-patches.md) · [Upstream issues](../references/upstream-issues.md)
