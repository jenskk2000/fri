# Reliability pass — 22 September 2026

Build 6. Bounded implementation of the audit findings; plan: [RELIABILITY-PASS.md](../../docs/RELIABILITY-PASS.md).

## Changes

- General plan actions have one 500-character limit across onboarding, drafts, imports and editing. Situation-specific actions and pause feedback retain their 250-character limit.
- Archive loading supplies defaults for legacy empty required plan fields without changing JSON v1 or truncating valid text. Unsupported versions and unrelated malformed data still reject.
- Named operations centralize plan, pause, feedback, pouch and history edits. Unchanged quit dates retain baseline IDs. Saving still completes before success state or dismissal.
- Home's scroll container is outside its per-second timeline; live values are computed once per update. History projections reuse computed values. Widgets store display values and reload only for relevant model changes.
- Date validation avoids per-record formatter construction. Formatting preserves tested Danish output. Backup availability is checked off the main thread once per presentation and revalidated when selected.
- Current progress excludes future pouch records while history retains them for correction. Copenhagen day boundaries and original check-in date semantics remain separate.

## Core verification

`swift test`: **51 passed, 0 failed**. [Full output](core-tests.txt).

Covers savings and historical prices, DST and midnight boundaries, unsupported/malformed imports, legacy normalization and 500-character text, corrupt-archive preservation, recovery, targeted deletion, unchanged baseline IDs, future records and pause idempotency.

## Performance measurement

Optimized Swift executable on the development Mac; median of five runs. Synthetic histories include one confirmation, one legacy reflection and one pause per day, weekly pouch entries and monthly baseline changes. Save includes validation, JSON encoding, previous-file decoding and atomic backup/current writes. These are host measurements, **not physical iPhone latency measurements**.

| History | Validation before → after | Save with backup before → after |
|---|---:|---:|
| 1 year / ~115 KB | 136.3 → 4.5 ms | 236.8 → 59.3 ms |
| 5 years / ~573 KB | 494.5 → 16.6 ms | 1,027.4 → 224.2 ms |

The isolated savings/duration workload was roughly unchanged at 0.04–0.06 ms. No frame-rate improvement is claimed from this benchmark. [Harness](benchmark.swift), [before](benchmark-before.txt), [after](benchmark-after.txt).

Synchronous saving remains a deliberate limitation: the five-year stress case can still block the main actor for a perceptible interval. Profile representative histories on a physical device before release; consider a serialized background writer if needed, preserving ordering and save-before-success semantics. Backup validation and immediate onboarding-draft durability were retained.

## Native verification

Debug build and launch succeeded on iPhone 17 / iOS 27 Simulator with no compiler warnings reported.

**12 distinct UI tests passed** across bounded batches: long general action editing after relaunch, plan edits, settings/history/Danish decimals, local backup restoration with stale-editor dismissal, pause recovery, personal situation and feedback persistence, pouch correction without duplication, day confirmation/undo, lapse undo, accessibility XXXL flows, onboarding validation and draft recovery.

The first draft-recovery attempt failed because its two immediate taps on the moving welcome footer only advanced one screen. The captured accessibility hierarchy showed step 1 with no consumption field. The test now waits for the next screen before the second tap. Both accessibility XXXL and draft recovery passed when rerun in the same sequence; no production change was needed. [Structured results, including the initial failure](ui-results.json).

Appearance and notification-specific UI tests were not repeated in this pass; those flows were unchanged.

Release build 6 compiled, installed and launched successfully (39.4 seconds; no compiler warnings reported). Final browser-mirror interaction at `http://localhost:3200/` successfully navigated Home → My Plan → Home. The saved normal plan and its dark appearance were retained; no demo/reset arguments were used for the Release launch. [Final Home screenshot](release-home.jpg).

Release build log: `/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/logs/build_run_sim_2026-09-22T19-26-22-563Z_pid13593_09ab4489.log`.

An independent Sol integration review found no actionable regression in persistence ordering, legacy backup compatibility, pause lifecycle or widget reload inputs. `git diff --check` passed.

Automated UI tests use the isolated test archive, draft and appearance settings. The normal simulator archive is preserved. Device signing, real-device profiling and App Store distribution are outside this pass.
