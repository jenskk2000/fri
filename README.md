# FRI

A free, Danish, offline SwiftUI app for quitting snus and nicotine pouches. iOS 17+, iPhone. Light and dark editorial themes with waterfront photography, green accents and bold typography. No account, backend, analytics, advertising, paywall or third-party dependencies.

## Run

Open `ios/FRI.xcodeproj`, select **FRI**, choose an iPhone simulator and Run.

The checked-in project is generated from `ios/project.yml`. After adding source files or changing target settings:

```sh
xcodegen generate --spec ios/project.yml
swift test
```

Run the **FRI** scheme's UI tests in Xcode. Tests use separate journey, onboarding-draft and appearance storage. Reminder testing temporarily schedules then removes a local notification in the simulator.

For physical devices, use your Apple team and owned app/extension/App Group identifiers. Follow [release/APP-STORE.md](release/APP-STORE.md). The app has not been uploaded or submitted to the App Store.

## Three core features

1. **Trustworthy progress.** Live DKK estimates, calendar-based years/months/days since the last recorded pouch, exact start date, a 14-day history of explicitly confirmed completed days, recorded use and unknown days. Correct pouch count/time/situation or undo mistakes. Lock Screen widgets are another surface of this overview.
2. **Your personal plan.** Brief, resumable onboarding with an editable first action. Motivation changes the Home heading. Each selected situation can have a specific action, with the original general action as a fallback. Optional reminders remain off until requested.
3. **Help right now.** One tap from Home, an optional situation picker and a two-minute pause that survives closure. A persisted session ID prevents duplicate wins. Optional feedback records what helped and can be edited in History.

Daily reflection cards and the weekly energy chart are removed from the main screens. Existing check-ins remain readable/editable in History; retained milestones are a secondary link. No new reflection prompts, missions or content library.

Settings retain historical consumption editing, savings goals, discreet widgets, local backup/import/recovery, deletion and privacy/help. Data remains offline with no account or paywall. Appearance lives under **Indstillinger → Udseende**: Lys, Mørk, or System. Light is the default; the choice saves immediately on this device, independently of the quit plan. System follows live iOS appearance changes. The light theme uses warm paper, dark green typography, white cards and softened waterfront photography; Dark retains the original mint design.

See [the research-based plan](docs/FOCUSED-CORE-PLAN.md) and [verification](verification/focused-core/VERIFIED.md).

### What a day means

The confirmation calendar uses **Europe/Copenhagen** consistently, including when travelling. A full day after the stop date can be explicitly confirmed only after its local midnight end. An unfinished day and the partial first day cannot be counted as complete. Missing entries stay unknown; recorded pouches override any conflicting confirmation. Undoing a mistaken pouch restores the prior confirmation. Editing the stop date can make an earlier confirmation ineligible without deleting it.

Time since the last recorded pouch is a separate counter, based on entries; it is not verified abstinence. Day confirmations do not change the financial estimate. Savings integrate real elapsed seconds, while the long-duration label uses calendar years/months/days.

## Calculation contract

`daily cost = tin price / pouches per tin × pouches per day`

Historical consumption segments integrate over actual elapsed seconds; 86,400 seconds equals a day. Recorded pouches are subtracted at their captured historical unit prices. Fractional prices are retained until display. Negative raw balances carry forward while the visible total is floored at zero.

Example: 50 kr. / 20 pouches × 10 pouches/day = 25 kr./day; 15 days = 375 kr. One pouch deducts 2.50 kr. and restarts the current streak. Past milestones use the longest completed streak and remain after a subsequent setback. Backdated records can correct that history.

Editing consumption applies from now, preserving earlier segments. Correcting the original stop date is deliberately different: the app previews and confirms a recalculation from the corrected date while preserving later price segments and valid events.

The value is a **consumption estimate**, not a bank balance. Whole-tin purchases, offers and nicotine replacement expenses are excluded and explained in the app. The app does not measure nicotine from other products.

Widgets prepare 24 hours of 15-minute entries; iOS controls update timing. In-app counters are more current between widget updates.

## Data and migration

`JourneyArchive` stores JSON in `group.dk.fri.shared`, using atomic writes and iOS protection after first unlock. Optional new fields preserve the original v1 MVP format. Imports reject unsupported versions, invalid values/dates, duplicate IDs, inconsistent baselines and oversized files before replacing data.

General coping actions support 500 characters throughout onboarding, import and editing; situation-specific actions support 250. Older v1 plans with empty required plan fields receive usable defaults on load, preserving their history. Nonempty valid actions are not truncated.

Every save retains the previous valid version as `.previous`. Explicit restore preserves unreadable primary bytes as `.unreadable`. Neither is transmitted. User-exported files and system backups remain under the user's control. Import replaces rather than merges and resets open editors to prevent stale settings from overwriting restored data.

Daily check-ins store a local date key, stable if the phone changes time zone. Reminders follow the phone's local time. Self-reports are not interpreted as medical results.

## Structure

- `ios/Shared`: Foundation domain, reflections, milestones and archive; shared with widget and SwiftPM tests.
- `ios/App`: native SwiftUI views, observable store, onboarding draft and file backup workflow.
- `ios/Widgets`: WidgetKit provider and four families.
- `Tests/FRICoreTests`: savings, time, history, migration, invalid import and recovery tests.
- `ios/UITests`: simulator journeys, interruption, settings, notifications, large type and restoration.
- `verification`: actual runtime screenshots and dated verification reports.
- `release`: Danish listing, privacy/support drafts, reviewer notes and owner-dependent distribution steps.

Debug-only arguments: `-ui-testing` selects an isolated archive; `-reset-state` clears only the test archive, draft and appearance; `-demo` seeds an empty selected archive with 15 illustrative days; `-fast-timer` uses two seconds for timer tests. Release builds compile these out. Never use `-demo` on a real user's archive.

The normal development simulator archive may contain user edits and must be preserved. Automated tests use isolated data. A fresh installation starts onboarding.

## Design and references

Selected direction: the dark home concept in `design/elias-bonde/01-dark-home.png`. ImageGen produced the bundled waterfront photograph and mint app icon. Montserrat and Inter are bundled with their SIL Open Font Licenses. All text and controls remain native SwiftUI. The original paper assets remain archived for reference.

See [design/dark-editorial/IMPLEMENTATION.md](design/dark-editorial/IMPLEMENTATION.md) for the visual system and asset provenance, and [verification/dark-editorial/VERIFIED.md](verification/dark-editorial/VERIFIED.md) for redesign verification.
Support: [Stoplinien](https://www.stoplinien.dk/om-os/tilbud).
Technical references: [Apple file import](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)), [Observation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app), [WidgetKit timelines](https://developer.apple.com/documentation/widgetkit/timelineprovider).

See [verification/reliability-pass/VERIFIED.md](verification/reliability-pass/VERIFIED.md) for the latest reliability checks and measurements, and [verification/focused-core/VERIFIED.md](verification/focused-core/VERIFIED.md) for the preceding product verification. [verification/FULL-APP.md](verification/FULL-APP.md) records the earlier broader version and distribution gates. The older `VERIFIED.md` documents the initial MVP only.
