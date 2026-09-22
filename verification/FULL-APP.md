# FRI — expanded app verification

Verified 22 September 2026. Free first version; no account, paywall, backend, advertising or analytics. Native SwiftUI app and WidgetKit extension. This is a tested local build, not a published App Store release.

## Automated checks

- `swift test`: **32 core tests passed, zero failures**. Covers savings arithmetic, historical prices, setbacks and undo, day/time-zone boundaries, migrations, validation, milestones, check-ins, pause persistence, backup rotation, corrupt-file preservation and deletion.
- Xcode UI suite: **10 tests passed, zero failures** on iPhone 17 / iOS 27 simulator. Covers onboarding and draft recovery, check-in editing and relaunch, largest accessibility text size, reminder enable/disable, pause resumption, plan edits, Danish decimal settings, local backup restoration and dismissal of stale editors, and the pouch/undo/support journey.
- Release build and launch succeeded. Both app and extension report **1.0.0 (2)**. Privacy manifest is bundled. Debug-only test/demo/reset/timer switches are absent from the Release executable.
- After the final welcome-backup entry point and check-in date refresh changes, reran onboarding validation/persistence, check-in editing/relaunch, and largest-text check-in: **3 passed, zero failures**. These repeat existing tests; the unique total remains 42 automated tests.

Final targeted result bundle:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/result-bundles/test_sim_2026-09-21T23-12-43-141Z_pid59653_c0b732dd.xcresult`

Full UI result bundle:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/result-bundles/test_sim_2026-09-21T23-03-00-310Z_pid59653_8681a2c8.xcresult`

Release build log:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/logs/build_run_sim_2026-09-21T23-06-12-878Z_pid59653_2889905d.log`

## Manual runtime checks

Inspected the actual running app's Plan, Check-in, Progress and Milestone screens, retaining the selected yellow paper/navy ink design. These are runtime screenshots, not design mockups:

- [Plan](full-app/plan.jpg)
- [Daily check-in](full-app/check-in.jpg)
- [Progress](full-app/progress.jpg)
- [Milestones](full-app/milestones.jpg)
- [Imported backup preview](full-app/backup-preview.jpg)
- [Welcome and restore entry point](full-app/welcome.jpg)

Confirmed that a fresh welcome screen opens backup import before onboarding, with no existing journey required.

**Native Files roundtrip passed in the Release build:** exported illustrative QA data through the system save sheet to On My iPhone; the app confirmed “Din kopi er gemt.” Selected that JSON through the system import picker, reviewed the date/counts/savings preview, confirmed restoration, and saw “Din sikkerhedskopi er gendannet.” The restored home displayed the same 15-day illustrative plan, and old sheets/editors closed. No real user data was involved.

Earlier MVP widget verification is recorded separately in [VERIFIED.md](VERIFIED.md): actual Lock Screen rendering, shared-data savings update, deep link and undo. The current extension builds successfully; physical-device refresh and locked-device behavior still require the checklist below.

## Scope and remaining gates

Simulator verification does not establish physical-device signing, actual reminder delivery while locked, widget refresh after reboot, complete VoiceOver usability, or App Store acceptance. Reminder UI tests verify authorization/scheduling state and disable behavior, not timed delivery.

Before distribution:

1. Configure an owned Apple Developer team, app/widget identifiers and shared App Group; produce a signed device archive.
2. Fill in actual developer identity/contact and publish the prepared Danish privacy/support pages at owned HTTPS URLs.
3. Run [DEVICE-CHECK.md](../release/DEVICE-CHECK.md) on a real iPhone, including Files transfer, notifications, Lock Screen widgets, VoiceOver and deletion.
4. Upload to TestFlight, collect beta feedback and finish App Store Connect metadata/review. Nothing has been uploaded or submitted by this work.

See [APP-STORE.md](../release/APP-STORE.md) for the listing, reviewer instructions and distribution steps. The development simulator contains clearly illustrative QA data; a fresh installation opens onboarding.
