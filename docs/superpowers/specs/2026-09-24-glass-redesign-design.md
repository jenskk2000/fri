# FRI redesign: time first, phases, Liquid Glass

Approved in brainstorming on 24 September 2026 (mockup "A · Big clock" plus the phase backbone).

## Intent
Make FRI feel modern, with far less text. Home is about one thing: the time since the last pouch. The research report's evidence gives the app its structure:
- the first 14 days are the critical window;
- craving help follows Stop → Move → Surf;
- a lapse gets a kind, same-moment recommit;
- counselling (Stoplinien) is the strongest behavioural lever, so it is prominent early.

## Decisions
- **Minimum iOS 26.** Liquid Glass throughout, with no fallback path.
- **Phases** (new `QuitPhase` in Shared, unit-tested) are computed from the current streak:
  - critical: day 0–14, target 14 days;
  - consolidation: target 30, then 90 days;
  - maintenance: target 180, then 365 days, then each further year.
- **Home:**
  - identity line "Jeg bruger ikke snus.";
  - a giant day count with a ticking h:m:s;
  - a glass phase bar showing the target and days left;
  - a glass savings chip (`savingsCounter`, opens the calculation);
  - a glass counsellor chip during the critical phase;
  - a mint-tinted glass craving button (`cravingHelp`) and a quiet "Jeg tog en pose" link (`logLapse`).
  - If the stop date is in the future, the clock counts down to the start instead.
- **Craving:** the sheet shows the photo under glass controls.
  - Stop: name the urge, show the personal if-then action and the situation picker.
  - Start (`startPause`) runs a 5-minute timer. The first half is Move (walk, stairs, isometrics); the second half is Surf (watch the urge peak and fall).
  - `finishPause` is always available while the timer runs. Persistence and idempotency are unchanged.
- **Lapse:** a compact form (count, trigger chips, date), then a recommit screen:
  - "Et glip er data, ikke et nederlag.";
  - a suggested "Når … så …" plan for that trigger, which can be saved as a personal action;
  - "Start igen fra nu" (`recommit`).
- **Navigation:** a native `TabView` gives the floating glass tab bar, minimised on scroll. The settings button is a glass circle.
- **Other screens** keep their features but drop explanatory paragraphs; details stay one tap away.
- **Glass placement:** glass goes only on controls and floating layers, never behind long text. Light, Dark and System modes all remain.
- **Wording:** no health or quit-rate claims in the app (App Store guideline 1.4). Only "hjælper mange" or neutral phrasing.

## Out of scope
Deposit contracts, social or backend features, mindfulness or diet content, and changes to the archive schema.

## Testing
- Unit tests for `QuitPhase`.
- UI tests updated for the native tab bar and the recommit step.
- Full suite on the simulator, then regenerate the App Store screenshots and run preflight.
