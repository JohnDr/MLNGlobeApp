---
type: Runbook
title: Open Waters
description: Selecting the Open Waters nautical style and what to expect.
tags: [ runbook, style, open-waters ]
status: draft
---
## Summary

[Open Waters](../flows/open-waters-rendering.md) is the nautical seamap style the app targets. It needs the [style-spec patch](../references/fork-patches.md) and Qt's WebP plugin.

## Select it

In the **Maps** dialog, click **Open Waters**. The choice is persisted (Windows: `HKCU\Software\MapLibre\MLNGlobeApp\map\styleUrl` → `https://tiles.openwaters.io/seamap/style.json`).

## Requirements

- The `QMapLibre` install must be built from the fork with [patches 0001 / 0002](../references/fork-patches.md) applied.
- Qt's `qwebp` imageformats plugin must be present (the elevation/terrain source is WebP). Windows finds it in the Qt prefix; the [Android build](./build-android.md) bundles it via `QT_ANDROID_EXTRA_LIBS`.

## Expected result

- Buoys, marks, lights, topmarks and landmarks render; dashed hazard areas render.
- **0** `ParseStyle` warnings (was 16 *doesn't support property* + 2 *data expressions not supported*).
- The only remaining line is `[General]: Invalid geometry in line layer` — a data issue, harmless.

## Related

- [Open Waters rendering](../flows/open-waters-rendering.md) · [Style-spec properties](../concepts/style-spec-properties.md) · [Verification](../verification/open-waters.md)
