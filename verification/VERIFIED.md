# FRI MVP verification — 22 September 2026

## Delivered

Native SwiftUI iPhone app and WidgetKit extension, following the selected yellow-paper / blue-ink attachment. Six-step Danish onboarding, consumption-derived savings, persistent local journey, craving support, lapse logging and undo, personal plan, progress and savings goal, editable settings, export/reset, optional reminders, and lock-screen widgets.

## Evidence

- Final Debug app + extension build succeeded without warnings or errors on iPhone 17 / iOS 27.0. Build log: `/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/logs/build_run_sim_2026-09-21T22-32-24-944Z_pid59653_9d145c5b.log`.
- `swift test`: 17 core tests passed, zero failures. Verified continuous and fractional accrual, 15-day example, future start, midnight/DST, lapse deductions, undo, historical consumption changes, captured prices, validation, overspending carry-forward, local archive roundtrip and corrupt-file preservation.
- Three XCUITests passed, zero failures: onboarding validation and persistence; lapse/undo/craving journey; settings persistence with Danish decimal input and preservation of historical savings.
- UI result bundle: `/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/result-bundles/test_sim_2026-09-21T22-27-29-053Z_pid59653_a9c3de72.xcresult`.
- Manual visual inspection of home, onboarding, consumption, plan, progress, and lock-screen widget. Final diary date formatting was explicitly localized to Danish after the UI suite; the final build includes this presentation-only fix.
- Actual rectangular WidgetKit widget installed using the simulator wallpaper editor. Displayed 375 kr. / 15 days, matched the app-group journey, and opened Progress when tapped.
- Logging one 2.50 kr. pouch changed the app to approximately 372.68 kr. and the widget to rounded 373 kr. / 0 days. Undo restored approximately 375.20 kr. and the original streak. Screenshots show the real running widget, not a mockup.
- Final onboarding welcome and consumption screens inspected after layout refinements. Default 50 kr. / 20 pouches × 10 per day correctly projects 750 kr. over 30 days.

## Screenshots

- `home.jpg`: running app with illustrative 15-day data.
- `onboarding.jpg`: fresh welcome screen.
- `consumption.jpg`: consumption inputs and calculated 30-day projection.
- `plan.jpg`: personal plan.
- `progress.jpg`: saved progress opened through the widget deep link.
- `lock-screen.jpg`: installed live rectangular widget.
- `lock-screen-after-pouch.jpg`: updated widget after the logged test pouch.

## Scope and limits

The installed simulator main archive contains illustrative QA data; its temporary pouch record was undone. UI tests use a separate archive. A fresh installation starts onboarding. Settings provides an explicit reset.

Savings are a consumption-based estimate, not a bank balance. Whole-tin purchases and nicotine replacement costs are excluded and explained in-app. WidgetKit controls refresh; widget amounts update periodically rather than every second.

Physical-device signing and App Store distribution require the owner's Apple team and App Group configuration. This MVP was verified on Simulator, not on a physical iPhone. Optional local notification scheduling is implemented; notification delivery was not included in the runtime acceptance tests. Circular, inline and small Home Screen widget layouts compile; the rectangular Lock Screen widget is the layout installed and exercised end-to-end.
