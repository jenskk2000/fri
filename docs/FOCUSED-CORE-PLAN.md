# FRI: three useful things, done well

22 September 2026. Implementation plan based on the complete task “Explore Appllama capabilities” (01a0c8fd-e091-74a1-a5e9-1eca3405a245), including its later Danish review analysis and personalization decision.

## Decision

Three user jobs: **see my progress, follow my own plan, get through a craving**. These are the product scope, not three additional features on top of the old app. Keep the chosen dark/mint design and free, local, account-free model.

The later review evidence outweighs the handover's earlier suggestion to add more reflection prompts. Counters, corrections, privacy and meaningful Danish copy take priority. Reviews were selected, sometimes old and overlapping, and mixed Kvit/Kwit; app revenue figures do not establish effectiveness or profitability. This is a product hypothesis to test with users, not clinical validation.

## 1. Progress I can trust

- Elapsed-time DKK estimate, clearly marked as an estimate, alongside an exact stop date and calendar-based years/months/days.
- Label streaks as time since the last **recorded** pouch; do not infer confirmed abstinence from silence.
- A compact 14-day history: explicitly confirmed completed pouch-free days, recorded use, unknown days, current unfinished day, and dates before the stop. Recorded use overrides confirmation.
- Confirm or undo a completed day with one clear action. Fix the calendar to Danish time (Europe/Copenhagen), disclose this, and test DST boundaries. Today cannot be confirmed early.
- Keep savings, milestones and history after setbacks. Allow correction of pouch count/time/situation, and undo. Preserve historical prices.
- Keep Lock Screen widgets and their discreet mode as another surface of the same progress feature.

## 2. A plan that feels like mine

- Retain brief onboarding with resumable drafts. Make the first coping action editable before starting.
- Motivation changes the home heading. Money motivation foregrounds the user's goal; no promised health improvements.
- Let each selected trigger have its own editable action. The old general coping action remains the fallback and migrates unchanged.
- Show actual chosen actions in both Plan and craving support. Every onboarding question has a visible use.
- Optional reminders stay user-controlled. Stop date/consumption remain editable with existing confirmation/history protections.

## 3. Help right now

- Immediate access to a simple action and persistent two-minute pause, without a questionnaire first.
- Optional situation picker uses the matching personal plan. Selection survives closing the app during a pause.
- Completing a pause saves one success, idempotently. Optional feedback can record what helped; skipping or dismissing retains the success.
- Existing successes migrate; context can be corrected in history. Descriptive feedback only, no claim an action is clinically effective.

## Simplification

Remove daily mood/craving check-in cards, weekly energy charts and achievement lists from primary screens. Existing notes remain available/editable through History; do not delete data. No new reflection prompts, content library, missions, community, AI coach, account, monetization or tapering program. Keep settings/backup/help as supporting utilities.

## Delivery order

1. Backward-compatible domain fields and deterministic rules; test migration, duplicates, corrections, unknown dates and DST.
2. Simplify main screens; personalize onboarding/plan and craving flow.
3. Verify focused end-to-end simulator journeys, relaunch/backup, large text, widgets/build, and Danish copy. Save runtime screenshots and a verification report.

## Acceptance

- Old archives load without losing data; invalid new data is rejected before replacement.
- No missing day appears confirmed. Today is never counted as a completed day. Lapse edits/undo recalculate consistently.
- Savings never jump at midnight; original price history is preserved.
- Craving help is one tap from Home; pause and selected situation survive termination; finishing twice cannot create two wins.
- Personal actions and first-run draft persist, and are actually used in support.
- Existing account-free use, backups, accessibility and dark visual direction remain functional.

Source handover: docs/FEATURE-HANDOVER.md (historical proposal; this plan supersedes its scope and old paper-design requirement).
Technical reference: https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
