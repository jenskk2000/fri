# Focused core verification

Date: 22 September 2026. FRI 1.0.0 (4), iPhone 17 / iOS 27 simulator. **42 core tests and all 12 UI tests passed. Final Release build succeeded with no warnings or errors.**

## Scope

Implemented the research-based three-feature plan in `docs/FOCUSED-CORE-PLAN.md`: trustworthy progress, a personal plan, and immediate craving support. The chosen dark waterfront/mint design and account-free, offline model remain.

The later Danish review analysis was used to prioritize reliable counters, corrections and personalization over additional reflection prompts/content. Existing reflection records remain editable in History; the daily cards and weekly energy graph are removed. This is product research, not clinical validation.

## Completed domain checks

`swift test`: **42 passed, 0 failures** (32 retained tests + 10 new focused-core tests). Full output: `core-tests.log`.

New coverage includes:

- Missing days remain unknown; current/future/partial first days cannot be confirmed.
- Repeated confirmation is idempotent; use overrides confirmation; undo restores earlier state and savings.
- Danish 23-hour/25-hour DST days and exact-midnight event classification.
- Calendar years/months/days, including multi-year history.
- Old archive migration and round-trip of personal plans, confirmations and active pause context.
- Idempotent pause completion and preservation of old wins without context.
- Pouch corrections preserve IDs and captured prices; moved dates use the correct historical baseline.
- Invalid dates, duplicate plans and overlong context are rejected.

Existing tests cover continuous savings, negative balances, baseline history, date corrections, archive recovery, import validation, deletion and legacy reflections.

## Simulator checks

Final focused-flow batch: **4 passed, 0 failures**, 158.9 seconds:

- Largest accessibility text: reach and complete craving support, then confirm a completed day.
- Onboarding validation, customized first action, draft restoration after termination, completed journey restoration.
- Per-situation custom action appears in support, survives an interrupted pause, and feedback can be saved/corrected without duplicate wins.
- Pouch correction changes the existing record rather than appending another one.

Result bundle:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/result-bundles/test_sim_2026-09-22T13-16-23-373Z_pid37672_627b54bb.xcresult`

Earlier runs exposed oversized navigation/logo at accessibility sizes and brittle test scrolling/text insertion. The logo now retains its wordmark size; navigation text grows up to XXXL while content continues to support accessibility sizes. Tab content starts at the top. The test helper scrolls within the visible area above the keyboard, and the draft test compares the actual edited string after relaunch. These corrections are included in the passing batch.

Final regression batch: **8 passed, 0 failures**, 191.3 seconds. Covered confirmation persistence/undo and current-day exclusion, pouch undo, pause restoration, onboarding drafts, plan persistence, backup restoration/stale-editor dismissal, reminders, and Danish prices/history.

Result bundle:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/result-bundles/test_sim_2026-09-22T13-19-12-736Z_pid37672_41127e10.xcresult`

A final visual pass removed duplicate general-action cards from Plan. General situations now share one card; only explicitly customized actions get separate cards. Both plan-related UI tests were rerun after this change: **2 passed**, 90.5 seconds (repeat coverage, not additional unique tests).

Result bundle:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/result-bundles/test_sim_2026-09-22T13-24-14-671Z_pid37672_876a5f59.xcresult`

## Final build and visual verification

Release build/install/launch succeeded, 18.4 seconds, no warnings/errors. App and widget extension are included. Existing normal-app data was retained; automated mutations used the isolated UI-test archive.

Build log:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/logs/build_run_sim_2026-09-22T13-25-51-432Z_pid37672_7e121cdb.log`

Actual Release runtime screenshots, visually inspected:

- [Home](home.jpg): live estimate and clearly qualified elapsed time.
- [Plan](plan.jpg): one general action, relevant situations, editing and immediate support.
- [Craving support](craving.jpg): personal action, optional situation picker, single pause action.
- [Progress](progress.jpg): unknown days and recorded use remain distinct.
- [An older day](day.jpg): native date picker successfully opened 8 September, outside the visible 14-day window, with correct date and confirmation control. This read-only manual check did not confirm or alter the user's normal history.

Widget extension builds and shares the tested calculation model. Its estimate/recorded-time wording was updated; native Lock Screen rendering and physical-device refresh were not reverified in this pass.

## Important contracts and limits

- Savings are a consumption estimate, not measured cash. Time since the last recorded pouch is not confirmation of abstinence.
- Calendar confirmations use Europe/Copenhagen, disclosed in the UI. The partial stop day is not a full confirmed day; old confirmations survive date corrections but can become ineligible.
- Confirmed days do not alter savings. Recorded use takes precedence.
- Pause completion is saved before optional feedback. Dismissing feedback keeps the saved success; context can be edited later.
- New fields are optional, so existing archives remain readable. No existing user history is deleted to simplify navigation.
- Widget source uses the same domain calculations and identifies amounts as estimated. WidgetKit controls refresh timing; no per-second Lock Screen update is promised.
- No physical-device, signing, TestFlight, clinical-effectiveness or full VoiceOver certification is implied by simulator tests. Owner-dependent distribution work remains in `release/APP-STORE.md`.
