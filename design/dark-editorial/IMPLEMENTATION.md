# Dark editorial redesign

Selected direction: `../elias-bonde/01-dark-home.png`, explicitly chosen by the user. Implemented in native SwiftUI; all text, controls and counters remain live. The app name remains FRI pending a naming decision.

## Visual system

- Charcoal `#0B0D12`, raised surface `#191D24`, white foreground, muted gray body copy and mint `#4ADE9B`.
- Bundled Montserrat ExtraBold for headings and savings, Inter for supporting copy. Both retain their SIL Open Font License notices under `ios/App/Fonts`.
- Full-bleed generated waterfront photography on Home and the onboarding welcome, with a native dark fade for contrast. Supporting screens use solid surfaces.
- White pill primary actions, outlined streak chip, mint selected states, subtle separators, rounded dark cards and a mint wordmark.
- Dynamic Type, scrolling, selected-state accessibility traits, existing labels and reduced-motion behavior retained.
- Matching app icon and dark/mint Home Screen widget. Lock Screen widgets retain system-controlled monochrome rendering.

## Scope

Applied to onboarding, Home, Plan, Progress, check-ins, craving support, settings, journal, milestones, reminders, plan editing, backup/recovery, privacy/help and widget guidance. Storage format, calculations, business model and identifiers are unchanged. Home now displays two decimal places so the live savings estimate visibly advances. Version 1.0.0, build 3.

Photography depicts a fictional adult. No Elias Bonde portrait, endorsement, logo or website content is bundled. The earlier paper-design assets and previous icon are preserved for reference; the UI no longer displays them.

## Asset provenance

- Hero: built-in ImageGen, visually based on the selected mockup. Bundled at `ios/App/Assets.xcassets/Waterfront.imageset/image.png`.
- Icon: built-in ImageGen, packaged at 1024 × 1024 in `ios/App/Assets.xcassets/AppIcon.appiconset/icon.png`. Previous icon saved as `previous-app-icon.png`.
- Montserrat: https://github.com/JulietaUla/Montserrat/tree/master/fonts/ttf
- Inter and license: https://github.com/google/fonts/tree/main/ofl/inter
- Design reference: https://eliasbonde.dk/ (observations recorded in `../elias-bonde/DESIGN-NOTES.md`).

Generation prompts are in `ASSET-PROMPTS.md`. See `../../verification/dark-editorial/VERIFIED.md` for runtime evidence.
