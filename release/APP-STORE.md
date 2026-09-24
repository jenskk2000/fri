# FRI — free first release

Status: the binary is App Store ready. `release/preflight.sh` checks configuration, assets and an unsigned Release archive. What remains needs the owner's Apple account and identity (see *Owner-dependent steps*). Nothing has been uploaded or submitted.

## Readiness tooling

- `release/preflight.sh` fails on upload/review blockers: empty team, device family, privacy manifests (including the UserDefaults `CA92.1` reason), icon size/alpha, 6.9" screenshots, unfilled public pages, archive warnings, and debug launch arguments leaking into Release.
- `release/screenshots.sh` regenerates the 6.9" (1320 × 2868) screenshot set in `release/screenshots/6.9/` from isolated demo data (`AppStoreScreenshots` UI test, skipped in normal test runs). No real user data appears.
- `site/` holds the public Danish pages (`index.html`, `privacy.html`, `support.html`). Replace `{{DEVELOPER_NAME}}` and `{{SUPPORT_EMAIL}}`, host them at HTTPS (e.g. GitHub Pages), and use `…/privacy.html` as the Privacy Policy URL and `…/support.html` as the Support URL.

## Fixed during readiness pass (24 September 2026)

- The build declared iPad support (`UIDeviceFamily` 1,2) because XcodeGen's target default overrode the project setting. That would have required iPad screenshots, iPad review and all-orientation support. Both targets are now pinned to iPhone only, which also removes the orientation warning.
- The privacy manifest omitted the required reason for `UserDefaults` (appearance preference). Uploads without it are rejected (ITMS-91053). The widget extension now carries its own manifest.
- In-app version labels read `CFBundleShortVersionString` instead of a hardcoded "1.0".

## Danish listing draft

Name: **FRI – Stop med snus**
Subtitle: **Mere frihed. Flere kroner.**
Keywords: `nikotin,nikotinposer,nikotinstop,snusstop,tobak,vaner,opsparing,trang,abstinenser,afvænning,dagbog` (98/100; "snus" and "stop" are already indexed from the name, and competitor trademarks are deliberately excluded per guideline 2.3.7)
Category: Health & Fitness
Business model: free, no purchases, ads or account.

### Description

Fylder snus lidt for meget? FRI hjælper dig med at få mere plads til dig selv – ét øjeblik ad gangen.

Lav en personlig plan ud fra din hverdag, dit forbrug og din grund til at stoppe. Følg de kroner, du anslået har sparet, og få støtte, når trangen dukker op.

• Personlig onboarding og en plan, du kan rette undervejs.
• Sparebeløb i kroner beregnet ud fra dine egne forbrugstal.
• En diskret widget til låseskærmen.
• Se tiden siden din sidste pose – og hvor langt du er i de vigtige første 14 dage.
• Hjælp ved trang på 5 minutter: stop op, bevæg dig, og lad trangen falde.
• Et venligt restart efter en pose, med en ny plan til netop den situation.
• Bekræft hele dage uden poser, og bevar overblikket over ukendte dage.
• Egne handlinger til svære situationer og valgfri noter om det, der hjalp.
• Milepæle, der husker din indsats – også efter en svær dag.
• Valgfri påmindelse på dit tidspunkt.
• Sikkerhedskopi, gendannelse og sletning af dine data.

Ingen konto, reklamer eller abonnement. Din plan bliver på din iPhone. Du bestemmer selv, om du vil eksportere en kopi.

FRI bruger ordet snus om snus og nikotinposer. Sparebeløbet er et forbrugsestimat, ikke en bankkonto. Udgifter til nikotinerstatning og køb af hele dåser indgår ikke. Appen giver støtte til vaner og overblik, ikke individuel medicinsk rådgivning. Stoplinien kan hjælpe med professionel rådgivning om nikotinstop.

### Promotional text

Mere plads til dig. Lav din plan, følg dine sparede kroner og tag næste skridt med FRI – helt uden konto eller abonnement.

## Reviewer notes (English)

FRI is a Danish offline habit-support app for adults wishing to stop snus/nicotine pouches. No login, purchases, external server or special reviewer account is required.

1. Complete onboarding. Default consumption is editable with steppers/slider: 10 pouches/day, 20/tin, preset typical price DKK 70/tin = DKK 35/day.
2. Choose “Jeg er allerede stoppet” and a past date to see accrued estimates, or start now.
3. “Jeg har lyst lige nu” opens a 5-minute Stop → Move → Surf flow. Closing/reopening preserves an active timer. The completion action records the user's confirmation, not a medical outcome.
4. “Jeg tog en pose” records usage with a chosen date and trigger, adjusts the estimate and restarts the current streak, then offers an optional if-then plan for that trigger. A record can be undone under Fremskridt.
5. Min plan has motivation, editable situation-specific actions, the stop date, and an optional local reminder. Permission is requested only after opting in.
6. Fremskridt separates time since the last recorded pouch from explicitly confirmed completed days. The calendar uses Danish time. History supports pouch/feedback corrections and retains older check-ins; milestones are secondary.
7. Settings provides backup export/import and confirmed data deletion.
8. After completing onboarding, add FRI from the Lock Screen widget gallery. Tap the widget to open Progress. WidgetKit controls refresh frequency.

All artwork is bundled. No health diagnosis, treatment recommendation, measured health effect, or guaranteed cessation outcome is claimed.

## Submission answers to confirm against the actual release binary

- Data collection: no developer collection. Data stays in the app's local App Group unless the user exports it. No third-party SDKs or analytics.
- Tracking: none.
- Accounts/login: none.
- In-app purchases/subscription: none.
- Encryption: uses only standard platform facilities; `ITSAppUsesNonExemptEncryption = false`.
- Permissions: notifications, requested only by a deliberate opt-in. File picker grants access to a user-selected backup.
- Age rating: complete Apple's current questionnaire honestly. The app references tobacco/nicotine use (in a cessation context) and contains health/wellness content. Answer those questions accordingly rather than "None"; target audience 18–35 does not itself determine the platform rating.
- Screenshots: upload `release/screenshots/6.9/*.png` for the 6.9" iPhone size; App Store Connect scales them for smaller iPhones. No iPad set is needed (iPhone-only build).
- Privacy Nutrition Label: "Data Not Collected".
- Accessibility: large-text layouts and labels are implemented; do not claim full VoiceOver certification before a real-device assistive-technology pass.

## Owner-dependent steps before TestFlight / App Store

1. Choose an Apple Developer team and confirm the final app name is available.
2. Register owned app and widget bundle IDs and a shared App Group. Replace `dk.fri.app`, `dk.fri.app.widgets`, `group.dk.fri.shared` consistently in `ios/project.yml` and `JourneyArchive.group`; regenerate the project.
3. Set DEVELOPMENT_TEAM for app and extension. Make a device Archive in Xcode and validate signing. Simulator builds do not prove signing.
4. Fill in the actual developer identity and support contact in the privacy/support drafts. Host them at public HTTPS URLs under an owned domain; add those URLs to App Store Connect.
5. On a real iPhone, verify first launch, widget update/deep link after locking/rebooting, local notification delivery, backup transfer via Files, VoiceOver, and deletion. No user data should be copied into promotional screenshots.
6. Create the App Store Connect record, complete the privacy and age-rating questionnaires, upload the archive, and run a small TestFlight beta with consenting adults.
7. Review feedback and any crashes, prepare final device screenshots, then submit for App Review. This work does not authorize signing agreements or a public release.

## Sources checked 22 September 2026

- Apple: https://developer.apple.com/app-store/app-privacy-details/ — data processed only on device is not developer collection.
- Apple: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy — privacy disclosures and policy URL.
- Apple: https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:) — security-scoped file access.
- Stoplinien: https://www.stoplinien.dk/om-os/tilbud — free counseling includes snus; telephone 80 31 31 31.
