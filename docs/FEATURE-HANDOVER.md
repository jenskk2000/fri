# FRI — proposed feature handover

Date: 22 September 2026
Historical research proposal. The later review analysis and current user request supersede its scope; see FOCUSED-CORE-PLAN.md for the implemented direction. This research does not establish clinical effectiveness.

## Purpose and constraints

Help users learn from difficult moments, recognize successful coping strategies, and see progress beyond their current streak. Build on FRI's existing Danish, free, offline iPhone experience. Preserve its paper-and-blue-ink design, local storage, accessibility, and absence of accounts, advertising, analytics, paywalls, and a backend.

Recommended next-release scope: features 1–3 below. Features 4–5 are subsequent candidates, not committed scope. This note does not authorize implementation or change the existing roadmap.

## Existing foundation

FRI already has a persistent two-minute craving pause, recorded wins, timestamped pouch logging with trigger selection, daily energy/craving check-ins and optional notes, savings and a savings goal, retained longest-streak milestones, a journal, editable triggers and a coping action, reminders, and discreet widgets.

Relevant starting points:

- `ios/App/SupportViews.swift`: craving pause and setback recording.
- `ios/App/CheckInView.swift`: daily check-in and note editing.
- `ios/App/MainView.swift`: Today, Plan, and Progress navigation.
- `ios/App/PlanEditorView.swift`: personal plan editing.
- `ios/App/JournalView.swift`: journal presentation.
- `ios/Shared/Journey.swift`, `Reflection.swift`, and `JourneyArchive.swift`: domain data and persistence.
- `ios/App/AppStore.swift`: application mutations and saving.
- `README.md`: current behavior and calculation contract.

## 1. Learn from successful cravings — highest priority

Problem: setbacks capture a trigger, while completing a craving pause records a win without equivalent context about what helped.

Proposed experience:

1. Keep immediate craving support available without answering questions first.
2. After “Jeg er kommet videre”, offer optional selections for “Hvad udløste trangen?” and “Hvad hjalp?”.
3. Offer familiar triggers and concrete actions, plus an optional custom answer. Allow skipping and completing the flow quickly.
4. Save this context with the successful craving event. Later show simple descriptive summaries, for example “Du valgte en gåtur ved 4 svære øjeblikke.”

Acceptance criteria:

- Skipping questions still saves exactly one win; retries and repeated taps cannot duplicate it.
- Existing wins without additional context remain valid and visible.
- Saved context can be inspected and corrected in the journal.
- Summaries describe recorded choices, not proven effectiveness or causal conclusions.
- Timer restoration and existing error handling continue to work.

## 2. Optional guided reflection

Problem: a blank note field provides little help to users who do not know what to write.

Proposed experience: add one optional prompt to the existing daily check-in. Examples:

- “Hvornår var det sværest i dag?”
- “Hvad hjalp dig gennem et svært øjeblik?”
- “Hvad vil du prøve næste gang?”

Keep energy/craving ratings and free writing. Use a small, curated Danish prompt collection rather than generated content or a long questionnaire.

Acceptance criteria:

- Users can ignore the prompt and save normally.
- Store which prompt an answer responds to so old entries retain their meaning.
- Editing a daily entry preserves the existing one-entry-per-local-day behavior.
- Older unprompted notes render unchanged.
- Copy is supportive and does not interpret self-reports as medical measurements.

## 3. Cumulative progress calendar

Problem: a restarted streak can visually overshadow effort accumulated before a setback.

Proposed experience: add a calendar to Progress with three clearly distinguishable states: explicitly confirmed pouch-free day, recorded pouch use, and unknown/unconfirmed day. Add an explicit daily confirmation; energy/craving ratings alone are not confirmation of abstinence. Keep previous milestones and savings accessible beside the current streak.

Acceptance criteria:

- No recorded use does not automatically mean a pouch-free day; historic gaps remain unknown.
- Define a pouch-free day as a completed local calendar day explicitly confirmed by the user. Do not count an unfinished day as completed abstinence.
- Recorded pouch use takes precedence over a conflicting confirmation. Corrections and undo recalculate the display consistently.
- A calendar summary may say “12 bekræftede dage uden snus denne måned”; it must not imply unknown days were successful or unsuccessful.
- A setback preserves legitimate earlier progress and the existing savings calculation contract.
- Labels and symbols distinguish states without depending on color alone.

## 4. Situation-specific coping plans — later

Extend the existing single coping action into optional trigger/action pairs. Example: “Når jeg drikker kaffe, tager jeg tyggegummi frem.” Let the user select a relevant plan during a craving, without delaying access to the pause.

Acceptance criteria: existing plans remain usable after migration; users can add, edit, and remove pairs; suggestions remain user-controlled; the default action works when no matching plan exists.

## 5. One small daily action — later

Offer an optional, short action during the early journey: prepare an alternative, change a familiar routine, or write down a personal reason for quitting. Use a small curated Danish collection with a clear end, rather than a large content library.

Acceptance criteria: actions can be skipped without penalty; completion is optional; no additional notification is scheduled without user choice; content avoids unsupported health promises. Define duration and editorial ownership before implementation.

## Delivery and verification

- Introduce backward-compatible optional data and validate imports, exports, restoration, and reset for new records.
- Reuse established local-date handling; explicitly test corrections, midnight boundaries, and time-zone changes where relevant.
- Test new behavior meaningfully: old archive loading, duplicate-save prevention, journal editing, and calendar conflicts/unknown states.
- Verify complete journeys in the simulator, including large text and accessible state labels. Recheck interrupted craving pauses after changes.
- Keep unknown data distinct from zero, absence of cravings, and confirmed abstinence.
- Preserve current counters, historical consumption pricing, widget behavior, and retained milestones.

## Research basis and limits

Research used Appllama app descriptions and flow metadata, public US App Store descriptions/reviews, and the current FRI source. Publicly displayed reviews are a small selected sample, several years old in some cases. These observations generate product hypotheses; they do not establish prevalence, clinical effectiveness, or that a feature causes commercial success.

| Reference | Observed signal | Proposed application |
| --- | --- | --- |
| [I Am Sober](https://apps.apple.com/us/app/i-am-sober/id672904239) | Reviewers value workbook questions, evening reflection, and encouragement. One reports harmful community interactions. | Private guided reflection; supportive responses; defer public community. |
| [Smoke Free](https://apps.apple.com/us/app/smoke-free-quit-smoking-now/id577767592) | Description includes craving patterns and daily missions; a reviewer values visible progress alongside other support. | Successful-craving context and small practical actions. |
| [Reframe](https://apps.apple.com/us/app/reframe-drink-less-thrive/id1485756576) | Reviewers value understanding motivations and developing alternative coping strategies. | Trigger/action plans. |
| [Sunnyside](https://apps.apple.com/us/app/sunnyside-drink-less-alcohol/id1593489083) | Reviewers value planning, accountability, and a nonjudgmental approach. | Preparation and review of difficult situations. |
| [QuitNow](https://apps.apple.com/us/app/quitnow/id483994930) | Reviewers return to progress for reassurance; another criticizes paywalls. | Visible accumulated effort and continued free access. |

## Deferred scope

Public chat, AI coaching, and support for multiple substances would materially change FRI's product and operating model. They are not part of this proposal. Smoking- or alcohol-specific health timelines should not be transplanted into a snus/nicotine-pouch app; any future educational health content needs an appropriate source review.
