# Light appearance — verified 2026-09-22

FRI 1.0.0 (5), native SwiftUI, iPhone 17 simulator, iOS 27.

## Implemented

- Warm paper background, white cards, dark green text, deeper green accents and a softened waterfront image. Semantic colors adapt all app screens and sheets.
- Indstillinger → Udseende offers Lys, Mørk and System. Light is the default. Changes save immediately in device-local UserDefaults, separately from the journey and exported backups.
- The scene window applies the preference so sheets, status bars and native controls inherit it. System removes the override and responds to live iOS changes without relaunching.
- Launch background has light and dark asset variants, following system appearance. The app applies its saved preference when its window attaches.
- UI tests use a separate appearance suite; test resets never change the real preference or journey.

## Verification

- Debug and Release builds succeeded.
- Three targeted UI tests passed, zero failures: appearance persistence through multiple relaunches; resumed onboarding draft; historical consumption/settings with Danish decimal input.
- Visually inspected light Home, welcome/onboarding, personal plan, progress, craving sheet and settings; dark Home and settings; System with simulator appearance changed live from dark to light.
- Light and dark toggles update an already-open settings sheet. Return to System was tested with live OS changes.
- Text contrast on the solid light background: primary 13.98:1, green accent 5.89:1, muted text 5.72:1. These calculations exclude the photograph and native controls; the photographed screens were visually checked.
- Release installed and left on Home in light mode with the existing normal archive preserved. No account, payment or journey schema changes.

Screenshots in this directory are actual simulator captures. home-release.jpg and settings-light.jpg show the normal Release installation; the other screenshots use isolated QA data. UI test and Release build logs are included.

The widget extension is unchanged; app appearance is not a widget setting. No physical-device or App Store distribution validation was performed for this theme change. The existing domain suite was not rerun because the quit-tracking model and calculations were unchanged.
