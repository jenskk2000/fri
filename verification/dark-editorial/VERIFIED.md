# Dark editorial redesign — verification

22 September 2026. Native app redesign based on the user's selected dark Elias Bonde concept. Version 1.0.0, build 3. No account, paywall, storage schema or bundle/App Group identifier changes.

## Visual checks

Inspected actual iPhone 17 / iOS 27 simulator renders of Home, onboarding, Plan, Progress and Check-in. Native controls and type are drawn over a bundled image; the screens are not flattened mockups.

- [Home](home.jpg): photographic background, live DKK amount with øre, streak chip, white craving action and three-tab navigation.
- [Plan](plan.jpg): solid charcoal surface, Montserrat headings, mint section labels and dark cards.
- [Check-in](check-in.jpg): readable fields, mint selected states and white save control.
- [Onboarding](onboarding.jpg): photographic welcome with native text and restore entry point.
- [Progress](progress.jpg): savings, check-in and weekly self-report overview.

Solid-color contrast calculations: mint on charcoal 11.30:1; muted gray on raised surface 8.61:1; primary button foreground/background 18.91:1. These checks do not certify every photographic pixel or a comprehensive accessibility audit.

## Regression tests

Full existing UI suite: **10 passed, zero failed or skipped**, 293.4 seconds. Covers onboarding completion and draft recovery, daily check-in persistence, largest accessibility text size, pouch logging/undo, pause resumption, plan edits, Danish decimal settings, local backup recovery and stale editor dismissal, and reminder enable/disable.

Result bundle:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/result-bundles/test_sim_2026-09-22T12-33-50-054Z_pid37672_b3a3319b.xcresult`

## Build and assets

- Final Release build/install/launch succeeded with no warnings or errors. App and widget both report 1.0.0 (3). Final Home screenshot is from this Release build, and both fonts were verified in its bundle.

Release build log:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/logs/build_run_sim_2026-09-22T12-40-14-695Z_pid37672_02a80918.log`

- Initial Debug build/install/launch succeeded with no warnings or errors.
- Bundled font PostScript names checked with CoreText: `Montserrat-ExtraBold` and `Inter-Regular` are present, with both fonts included in UIAppFonts and the resources build phase.
- Font license notices are bundled.
- New app icon verified 1024 × 1024, without alpha.
- Home Screen widget updated to charcoal/white/mint; Lock Screen families retain platform-controlled monochrome rendering. Physical-device refresh remains a release checklist item.

Initial build log:
`/Users/jenskristian/Library/Developer/XcodeBuildMCP/workspaces/snus-3ee8d5708a58/logs/build_run_sim_2026-09-22T12-31-25-602Z_pid37672_8f79a843.log`

## Limits

This is local simulator verification, not a signed device/TestFlight build. Existing [release checklist](../../release/DEVICE-CHECK.md) still applies. Earlier domain/storage verification remains documented in [FULL-APP.md](../FULL-APP.md); no domain/storage code changed for the redesign.
