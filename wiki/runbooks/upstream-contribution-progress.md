---
type: Runbook
title: Upstream contribution progress
description: "Live tracker for offering the fork's terrain/globe/sky work upstream: branch status, per-platform test results, and pickup steps across Windows, Android and Linux."
tags:
  - runbook
  - upstream
  - status
  - testing
status: current
---
# Upstream contribution progress

> Live tracker, updated 2026-10-21. Strategy: join the existing upstream feature branches, report test results, and contribute focused gaps (Qt/QMapLibre wrapper first). **Do not** submit the 56-patch fork stack or a competing globe/terrain/sky implementation.

## Strategy (agreed 2026-10-20)

1. **Join the existing branches** — test them on Windows/Android/Linux and report; they explicitly need testers.
2. **Focused PRs** against `feature/terrain-3d` / the globe branch for gaps. The unique, working stack is the **Qt/QMapLibre wrapper + app API** (63 commits in `maplibre-native-qt`), which the core PRs need.
3. **Only if the implementation is materially different/better**: write a comparison/design proposal for the TSC first; no competing PRs.

## Upstream landscape

| Effort | Owner | Branch / base | State | Notes |
|---|---|---|---|---|
| Globe #4533 | johncarmack1984 | `phased/12h` → `main` | open, not draft, `BLOCKED`, CI green (2026-10-20) | Issue #3161; design proposal #4525 closed; 673 files. |
| Sky #4534 | ClayWarren | `codex/sky-style-spec-4414`, stacked on globe | open, not draft, `DIRTY` | Issue #4414; CI fails Android OpenGL instrumentation/render, iOS, macOS WebGPU; Metal/Vulkan render pass. |
| Terrain #4190 | NathanMOlson | `feature/terrain-3d` → `main` | **draft**, `DIRTY` | Maintainer `louwers` coordinating; follow-ups #4558, #4790, #4791, #4801, #4809, #4810 target `feature/terrain-3d`; issue #252. |
| Overlap #4752 | JohnDr | `mln-icon-text-overlap` → `main` | **draft**, `BLOCKED`, pre-commit green | Our icon/text-overlap implementation; build workflows await approval; refs #251. |
| Qt #323–#326 | JohnDr | fork branches → `maplibre-native-qt` `main` | #323 draft; #324/#325/#326 ready | #323 Metal fix at `91297dd`, CI approval pending; #326 has empty-style fallback + `styleChanged` NOTIFY at `5d1077a`. |

## Gap analysis (summary)

- Fork work: 56 core patches on 13.6.1, 258 files, all authored by JohnD (audit on 2026-10-20).
- Upstream branches touch 233 of those 258 files; only 25 are untouched by all three (#4533/#4534/#4190).
- Architectures differ: upstream `RenderTerrain` / `style::Terrain` / `TerrainLayerTweaker` / `TerrainLoadMode` / `TerrainSkirtLength`; ours `TerrainTileManager` / `TerrainPass` / `terrain_stitch` / per-tile RTT pool. File overlap is infrastructure, not mergeable code.
- **Likely unique candidates**: Qt/QMapLibre wrapper (terrain/sky/globe API, `liveCoordinate`/`liveZoom`, metrics, gestures), terrain-camera ray-scan centre (verify against #4190's `TerrainCamera` tests and #4711), RTT drape pool/fingerprint, globe-terrain pole caps, flat draped wrapped tiles.
- **Likely already covered**: globe (#4533), sky/atmosphere (#4534), LOD skirts/occlusion, overzoom/backfill (#4809/#4810). Do not re-submit.

## Test results

### Windows 11 (MSVC, Vulkan)

Build setup now works (see [pickup](#pickup-after-restart--os-switch)):

- **#4190 terrain**: unit tests **30/30 pass** (`*Terrain*`). Terrain render tests are **ignored** upstream (native 3D terrain not graded against GL JS yet).
- **#4534 sky**: render tests **3/3 pass** on Windows/Vulkan — `sky/basic`, `sky/atmosphere-globe`, `sky/zoom-expression`.
- **#4533 globe** (tested through #4534's globe snapshot `2a85b5d`, 2026-10-17): 53 groups, **2 unique failures**, both tile-edge seams:
  - `projection/globe/fill-seams/checkerboard`
  - `projection/globe/raster-warped`
  Ignored: `debug-tile-borders`, `fill-planet-pole`, `fill-planet-pole-top`, `fill-planet-tiles`, 2 in `antimeridian-overdraw`. All other groups pass. Re-run the two failures on the newer #4533 head `ff96700` before reporting.
- **Full unit suite**: stops on platform tests, not PR-related — `OnlineFileSource.ConnectionError` (backoff timing) and `LocalFileSource.InvalidUTF8Path`.

### Android (S23, serial `RFCW910087W`)

Built from the PR CI `android-ui-test-vulkan` artifacts (package `org.maplibre.android.testapp`):

- **#4533**: `GlobeActivity` renders correctly. **PASS**.
- **#4190**: `TerrainActivity` renders pitched 3D terrain with draped imagery. **PASS**.
- **#4534**: no Sky activity; `GlobeActivity` shows no atmosphere. Not visually verifiable; CI failures above stand.

### Linux (Ubuntu 26.04, Vulkan/RADV, AMD Radeon 780M) — 2026-10-21

All three branches built as worktrees of the local clone (`~/dev/tmp/mln-pr4533|pr4534|pr4190`), submodules populated from the shared object store (no re-download), Release + `MLN_WITH_VULKAN=ON`/X11 (no GLFW/OpenGL), Ninja, build trees `~/dev/tmp/build-pr45xx-vk`. Core build ≈2.5 min; the existing [Linux tests](../verification/linux-tests.md) path works unchanged for PR branches.

**Unit tests** (`mbgl-test-runner`, Vulkan, RADV; one runner at a time — fixed HTTP test port 3000):

| Branch | Head | Result |
|---|---|---|
| #4533 globe | `ff96700` | **1243 tests / 145 suites — all pass**, 4 disabled |
| #4534 sky | `2a85b5d` | **1245 tests — all pass**, 4 disabled |
| #4190 terrain | `c6b31b7` | **1145 tests — all pass**, 30 tests named `*Terrain*` included |

The Windows-only stops (`OnlineFileSource.ConnectionError`, `LocalFileSource.InvalidUTF8Path`) did **not** reproduce on Linux.

**Render tests** (`mbgl-render-test-runner -p metrics/linux-vulkan.json`, one group per process):

- `projection/globe` (72 tests): 66 passed, 3 ignored, 2 passed-but-ignored, **1 failed** — `projection/globe/fill-seams/checkerboard`. Byte-identical outcome on #4533 `ff96700` and #4534 `2a85b5d` (`actual.png` md5 `127999d3…`), so it is not a stale globe snapshot.
- `raster-warped` **passes** on Linux/RADV: its Windows/Vulkan failure is platform-specific, not a globe defect.
- The checkerboard failure is a **threshold technicality, not a visible seam**. mapbox `pixelmatch` (threshold 0.1285, as in GL JS) counts **10 mismatched pixels of 65536** against `allowed = 0.00015` (9.83 px). All 10 sit on the image border (x=0 column, x=247, y=252 row) where the globe wraps; the other 4180 differing pixels are anti-aliasing-only. The same frame on **lavapipe** (`VK_ICD_FILENAMES=…/lvp_icd.json` — the software ICD GitHub's Ubuntu runners fall back to, which is why Linux CI is green) scores **9 mismatched pixels and passes**. Graded instead against the repo's own Linux expectation for this test (`metrics/expectations/platform-linux-opengl/…/checkerboard/expected.png`) the RADV frame differs by ≤59/255 with one pixel over 25: RADV Vulkan looks like RADV OpenGL, so the test fails on the Metal-rendered expectation, not on the globe's seams.
- `sky/` (3 tests: `basic`, `atmosphere-globe`, `zoom-expression`): **3/3 pass** on Linux/Vulkan — the Metal sky expectations hold here.
- `terrain/` (6 tests): **6/6 ignored** (all-platform ignore, graded against GL JS) — same as Windows.
- Full suite, #4533 (all 184 groups, ≈38 min): only two failing groups — `projection` (the checkerboard test above) and `fill-extrusion-pattern/tile-buffer`, the pre-existing upstream Linux/Vulkan baseline failure also present on pristine `c7506d6`. `text-font` 7/7 pass here (pristine had `burmese`/`khmer`/`devanagari` errors).
- Full suite, #4534 (184 groups): the **same two failures** as #4533 — `projection/globe/fill-seams/checkerboard` and `fill-extrusion-pattern/tile-buffer`.
- Full suite, #4190 (184 groups): **only** `fill-extrusion-pattern/tile-buffer` (the pre-existing baseline failure). This branch is based on `main` and carries no globe (`projection/globe`) or `sky/` fixtures, so those groups do not exist here — its `projection` group is the pre-globe four tests, all passing.

## Pickup after restart / OS switch

### Windows

- PR clone: `C:\hda\dev\tmp\maplibre-native-pr`; branches `pr4533`, `pr4534`, `pr4190`; currently on **pr4534** (`2a85b5d`); build tree `build-windows-vulkan`.
- **vcpkg is a copy** at `platform/windows/vendor/vcpkg` (not a junction). 34 MSYS package pins were updated to current mirror versions + SHA512; `msys2-runtime` is 3.6.9-2. Do not replace it with the Qt vendor's vcpkg.
- **ICU**: configure overrides `ICU_I18N_LIBRARY_RELEASE` / `ICU_UC_LIBRARY_RELEASE` to the vcpkg ICU 74 libs; otherwise the Windows SDK ICU is mixed with vcpkg headers and the link fails.
- Scripts (temp): `%LOCALAPPDATA%\Temp\opencode\configure-mln-pr3.bat`, `build-mln-test.bat`, `build-mln-render.bat`. Recreate from this doc if the temp dir is cleaned.
- Submodule dirs are **junctions** to `maplibre-native-qt/vendor/maplibre-native`. Before any `git switch`/`status`, remove all reparse points under `vendor`, `platform`, `docs` (their `.git` files point into the Qt repo); switch, then recreate. Keep the vcpkg copy.
- Targets: `mbgl-test-runner`, `mbgl-render-test-runner`.
- Render tests: `mbgl-render-test-runner -p metrics/windows-vulkan.json -f render-tests/<group>/` from the repo root; **one group per process**. Delete generated `actual.png`/`diff.png` afterwards.

### Android

- Download artifacts: `gh run download <run-id> --repo maplibre/maplibre-native -n android-ui-test-vulkan -D <dir>`.
- Runs: globe `39488232473`, sky `38968592220`, terrain `39293102159`.
- Install `InstrumentationTestAppVulkan.apk` (or `...MultiBackend.apk`); uninstall the package first when switching artifacts (different debug signatures).
- Activities: `org.maplibre.android.testapp/org.maplibre.android.testapp.activity.style.GlobeActivity` and `...style.TerrainActivity`.

### Linux (works — 2026-10-21)

- Source trees: `git worktree add ~/dev/tmp/mln-pr<NNNN> pr<NNNN>` inside the existing clone `~/dev/projects/maplibre-native` (PR refs fetched with `git fetch https://github.com/maplibre/maplibre-native refs/pull/<n>/head:refs/heads/pr<n>`; submodule pointers are unchanged by all three, so no re-download). Populate submodules by hard-linking the clone's checkouts and pointing each `.git` file at the shared `…/.git/modules/<name>` (helper `/tmp/opencode/link-submodules.sh`).
- Configure: `cmake -B ~/dev/tmp/build-pr<NNNN>-vk -S . -G Ninja -DCMAKE_BUILD_TYPE=Release -DMLN_WITH_VULKAN=ON -DMLN_WITH_X11=ON -DMLN_WITH_GLFW=OFF -DMLN_WITH_OPENGL=OFF -DMLN_WITH_PMTILES=ON` — GLFW defaults ON and then demands `glfw3`.
- Build (`PATH=$HOME/Qt/Tools/Ninja:$PATH`): `ninja -C ~/dev/tmp/build-pr<NNNN>-vk mbgl-test-runner mbgl-render-test-runner mbgl-expression-test` (≈2.5 min, 16 cores).
- Run: unit tests from the source dir, one runner at a time (port 3000); render tests `-p metrics/linux-vulkan.json -f render-tests/<group>/`; all 184 groups via `/tmp/opencode/render-suite.sh <src> <bin> metrics/linux-vulkan.json <outdir>`.
- Force software Vulkan (what CI uses) for AA comparisons: `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`.
- Qt tests: N/A — none of the three branches touches the Qt wrapper.

## Next actions (ordered)

1. ~~**Linux**: build/test #4533/#4534/#4190; run `fill-seams` and `raster-warped`~~ **Done 2026-10-21**: all three build, unit tests all pass; `raster-warped` is Windows-only; `fill-seams/checkerboard` fails on both Windows and Linux/RADV but by one pixel (10 mismatched vs 9.83 allowed) against the Metal expectation, and passes on lavapipe. Diffs saved. Full render suites also finished: #4534 matches #4533's two failures; #4190 has only the pre-existing `fill-extrusion-pattern/tile-buffer`.
2. **Post one consolidated test report** after Linux: #4533 (seams + platform), #4534 (Windows Vulkan render pass, CI failures), #4190 (Windows terrain tests pass; CI Windows job failures are platform tests).
3. **Qt wrapper**: adapt the 63-commit QMapLibre API to the upstream core, split into focused `maplibre-native-qt` PRs, coordinate with maintainers.
4. **Unique core pieces**: verify the terrain-camera ray scan against #4190's `TerrainCamera`/#4711; then RTT pool/pole caps if still gaps. Target `feature/terrain-3d`.
5. **Existing PRs**: #4752 review/CI, #323 CI approval, #326.
6. **Design proposal only** if `TerrainPass`/`terrain_stitch` is materially better than `RenderTerrain`; write a comparison for the TSC first.

## Guardrails

- No competing full implementation; no 56-patch dump.
- Keep MapLibreEarth on 13.6.1 until upstream features land.
- GL JS is the reference; disclose AI use; each PR needs tests and a platform statement.

## Open questions

- ~~Are the two Windows/Vulkan seam failures platform-specific or a stale globe snapshot?~~ **Answered 2026-10-21**: `raster-warped` is Windows-only (passes on Linux/RADV); `fill-seams/checkerboard` reproduces on Windows **and** Linux/RADV but is a one-pixel threshold miss (10 mismatched vs 9.83 allowed) against the Metal-rendered expectation, and passes under lavapipe — an expectation-coverage gap, not a stale snapshot.
- Does #4190 already cover the terrain-camera ray scan (it has `TerrainCamera` tests and #4711)?
- Which Qt API shape should the upstream core expose?
- ~~Which Linux build/deps path is fastest for the PR branches?~~ **Answered 2026-10-21**: worktrees of the existing clone + hard-linked submodules (no download, no junctions), Release Vulkan Ninja build ≈2.5 min per branch — see Linux pickup above.

## Related

- [Contribution plan](upstream-contribution-plan.md) · [Upstream PRs](../references/upstream-prs.md) · [Upstream issues](../references/upstream-issues.md) · [D6](../decisions/d6-draft-upstream-prs.md)
- [Linux tests](../verification/linux-tests.md) · [Windows](../verification/windows.md) · [Android](../verification/android.md)
