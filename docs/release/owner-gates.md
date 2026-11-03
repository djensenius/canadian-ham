# Owner gates: device checks and decisions

Status as of 2026-11-03 (UTC). This guide lists every open Backlog task labelled `owner-gate` and says what the owner must do or decide for each one. It groups the hardware checks so that one sitting per device covers them. It also covers owner-only steps outside those tasks: the Xcode Cloud and App Store Connect setup that TASK-86 prepared, and the TASK-85 sign-off needed before App Store submission. Backlog is the source of truth: this guide restates and links each task's acceptance criteria (AC) without changing them. Where a step-by-step checklist already exists, follow that checklist; this guide says when to use it and which criteria it closes.

For criteria that need manual device observations or owner decisions, simulator runs, structural UI tests and accessibility audits are no substitute: only the owner's recorded observations or decisions close them. Criteria that name an automated or coordinator check close on that check's evidence instead. These are TASK-54 AC #1 (the four named UI tests on a real iPhone Duo or a newer iOS 27.1+ simulator), now done on the iOS 27.2 simulator, and the coordinator steps named in each section, such as the TASK-1.8 verification, TASK-29 AC #3 and TASK-54 AC #3. Agents do not change repository visibility, rewrite history, distribute builds beyond internal TestFlight, submit or release to the App Store, change Xcode Cloud workflows or App Store Connect settings, or check an owner-gate criterion without the evidence described in [Reporting results](#reporting-results).

## Open gates at a glance

| Task | Open criteria | What the owner does or decides | Sitting |
| --- | --- | --- | --- |
| TASK-1.1 Record ISED permission | AC #2, #3 | When ISED replies, give the coordinator the reference number, date and exact scope, and confirm the scope explicitly covers bundling verbatim EN/FR question text in the web and Apple apps. | [Decisions](#sitting-1-owner-decisions-no-device) |
| TASK-1.7 Make the repository public | AC #1–#4 | The repository is already public while TASK-1.1 is pending. Decide whether to record the permission and a decision to publish early, or return the repository to private until the gates pass. Later, approve public visibility (AC #3). | [Decisions](#sitting-1-owner-decisions-no-device) |
| TASK-1.8 Purge out-of-scope reference PDFs | AC #1–#3 | Choose the method (fresh public repository or `git filter-repo`) and approve the history change. | [Decisions](#sitting-1-owner-decisions-no-device) |
| TASK-65 iOS heading-wait and figure-audit flakes | None (3/3 checked) | Answer the owner decision in its evidence file; the task stays In Progress until then. | [Decisions](#sitting-1-owner-decisions-no-device) |
| TASK-85 required-reason APIs (not an `owner-gate` task) | None for the owner; a sign-off, not a criterion | Before App Store submission, sign off the decision to declare the `AppleLanguages` read under User defaults reason `CA92.1`, or choose a fallback. | [Decisions](#task-85-sign-off-on-ca921-before-app-store-submission) |
| TASK-14.6 watchOS internal TestFlight lane | AC #4 | Install the processed internal build on a physical watch and check practice, Morse, reference and EN/FR without the phone app or network. | [Apple Watch](#sitting-2-apple-watch) |
| TASK-14.3 watchOS Morse haptics | AC #2 | Compare the three haptic styles on a physical watch and record whether short, long and mixed characters can be told apart. | [Apple Watch](#sitting-2-apple-watch) |
| TASK-14.5 watchOS EN/FR and accessibility | AC #4 | VoiceOver and Reduce Motion checks and physical output observations, recorded with device and watchOS version. | [Apple Watch](#sitting-2-apple-watch) |
| TASK-29 tvOS About cards and VoiceOver | AC #1, #2 (AC #3 follows from them) | VoiceOver listening check in English and French on a physical Apple TV. | [Apple TV](#sitting-3-apple-tv) |
| TASK-54 iPhone Duo keyboard, back button, layout and hinge | AC #2–#7 (AC #1 done on the iOS 27.2 simulator) | Back control's VoiceOver label and position, unfolded layouts, fold/unfold state, hinge-peek angle, dwell and fast-unfold checks on a real iPhone Duo; connect it for the four UI tests, the real-hardware evidence AC #3 needs. | [iPhone Duo](#sitting-4-iphone-duo) |
| TASK-34 Signed-device iCloud account changes | AC #1–#8 | Sign-out, account switch, iCloud off, airplane mode, no-account and Reset checks on a signed device with a `DebugCloudKit` build; decisions for AC #6 and #7; privacy-answer re-check for AC #8. | [iCloud device](#sitting-5-signed-device-icloud-debugcloudkit-only) and [Decisions](#sitting-1-owner-decisions-no-device) |
| Xcode Cloud and App Store Connect setup (TASK-86, Done) | None; owner-only setup | Create the internal Xcode Cloud workflow. Before the first build, try a Next Build Number above the highest recorded upload; if App Store Connect refuses it, choose the option (b) and (c) fallbacks. | [Xcode Cloud](#sitting-6-xcode-cloud-and-app-store-connect-setup-no-device) |

The sittings are independent and can be done in any order. Each one lists what the coordinator must prepare first.

## Internal builds for the sittings

Sittings 2–4 need a processed internal TestFlight build from main, for the internal team group only: no external groups or public links. Xcode Cloud is the release path, and Fastlane is only a temporary fallback ([distribution](distribution.md)):

- Once the owner's internal Xcode Cloud workflow ([Sitting 6](#sitting-6-xcode-cloud-and-app-store-connect-setup-no-device)) has shipped a platform, that platform's builds come from Xcode Cloud.
- Until then, they come from the internal Fastlane fallback ([TestFlight runbook](testflight.md#internal-beta-lanes)), which stops for each platform once Xcode Cloud ships it. Under build-number [option (b)](distribution.md#owner-decision-before-the-first-xcode-cloud-build), Fastlane stops for iOS, tvOS and visionOS at the version-bump merge, so their builds then come only from Xcode Cloud.
- Either way, the coordinator gives you the TestFlight version and build number and the commit. Distribution uploads, external testing, App Store submission and release stay owner-gated.

## Reporting results

Send results to the coordinator as a reply. Any result that contains personal data (names, Apple Account emails, serial numbers, UDIDs, screenshots showing them, private correspondence) goes only as a reply. You can append a result without personal data to the task with `backlog task edit <task-id> --append-notes "..."`, but Backlog auto-commits that edit at once, and the repository is public. The coordinator copies results into the existing result tables ([TASK-14.3](../testing/task-14.3-watch-morse.md#hardware-observations-owner-to-fill-after-testing), [TASK-14.5](../testing/task-14.5-watch-a11y.md#owner-manual-checks--pending-do-not-mark-ac4-complete), [TASK-14.6](../testing/task-14.6-watch-release.md#owner-upload-and-physical-watch-results-pending), [tvOS listening check](../accessibility.md#owner-listening-check-tvos-voiceover), [permission record](../content-licensing.md#permission-record)), checks the criteria that passed, and files follow-up work for anything that failed.

Give one block per acceptance criterion. If one step covers several criteria, list each AC with its own result.

```text
Task and AC:    TASK-54 AC #4
Date and time:  2026-11-05 19:30, with time zone
Tester:         role or initials, e.g. owner
Device:         model, e.g. iPhone Duo; for a watch, also the case size
OS version:     from Settings > General > About, with the build if shown
Install method: TestFlight, or Xcode/development install
App build:      TestFlight install: TestFlight version and build number (required).
                Xcode/development install only: commit SHA and build configuration.
Settings used:  whatever the checklist asks for: language, VoiceOver voice and rate,
                text size, Reduce Motion, Silent Mode, haptic strength, network state
Result:         PASS, FAIL, or NOT RUN (say why)
Observations:   what you did and what you saw, heard or felt; for a failure,
                the exact steps that reproduce it
Attachments:    screenshot or screen-recording file names
```

- Refer to beta builds by TestFlight build number. Every result from a TestFlight install needs its TestFlight version and build number: TASK-14.6 AC #4, TASK-14.3 AC #2 and TASK-14.5 AC #4 when run from TestFlight, TASK-29 AC #1–#2, and TASK-54 AC #2 and #4–#7. A commit SHA alone is accepted only for Xcode/development installs: the `DebugCloudKit` build for TASK-34, the TASK-54 device test run for AC #3, and Debug seeded Morse rounds.
- A PASS needs observations, not just "OK". Where a checklist asks for counts, angles, speeds, letters or confusions, include them.
- Screen recordings help with timing (hinge dwell; VoiceOver speech before the first Morse tone) and with VoiceOver checks; record them with audio.
- FAIL and partial results are still useful evidence. The criterion stays unchecked, and the coordinator escalates or files follow-up work as the task says.
- For a decision, state the option chosen, the date and any conditions, e.g. "Owner decision 2026-11-05: ...". The coordinator records it in the task notes and the linked document.
- The repository is public. Before copying anything into the repository or Backlog, the coordinator removes personal data from screenshots and notes: Apple Account emails, names, device serial numbers or UDIDs, and private correspondence such as ISED emails. Keep the originals in private owner records.

## Sitting 1: owner decisions (no device)

### TASK-1.7: the repository is already public

- **Facts.** The TASK-1.7 notes (2026-11-03) record that GitHub reports `djensenius/canadian-ham` as public; `gh repo view` still showed `PUBLIC` when this guide was written. TASK-1.1 permission is still pending, and TASK-1.8 is not done, so the English Basic reference PDFs under `content/sources/ised/basic-2025-07-15/reference/` (not part of the ISED request) are in the public history. The [interim private-development policy](../content-licensing.md#interim-private-development-policy) and [public-release gate](../content-licensing.md#public-release-gate) assume a private repository.
- **Decide** (from the TASK-1.7 note): either record the permission and the decision to publish early, or return the repository to private until the gates pass. Agents must not change visibility.
- **Later criteria.** AC #1 follows from TASK-1.1, and TASK-1.7 also depends on TASK-1.8. AC #2 needs the TASK-1.6 release-candidate pass to be Done (not an owner-gate task). AC #3 is the owner's approval of public visibility after reviewing the TASK-1.6 evidence ([release checklist: Public repo](release-checklist.md#public-repo)). AC #4 is the visibility itself.

### TASK-1.1: record ISED permission

- AC #1 is done: the request was sent on 2026-10-02.
- **AC #2:** when ISED's written permission arrives, give the coordinator the reference number, the permission date and the exact scope wording. The coordinator fills in the [permission record](../content-licensing.md#permission-record). Say where the original correspondence is kept; it isn't committed unless you approve.
- **AC #3:** confirm that the written scope explicitly covers bundling the verbatim EN/FR question text as data in the web and Apple apps. If permission is refused or narrower than requested, the [public-release gate](../content-licensing.md#public-release-gate) describes the contingency.
- Related, but not a TASK-1.1 criterion: the permission record lists the [reference-sheet follow-up request](ised-reference-sheet-request.md) as "sent/granted: pending", and the public-release gate also needs written coverage of the official reference sheet before TASK-1.7.

### TASK-1.8: purge out-of-scope reference PDFs

- **Decide the method.** For the case where permission is refused or narrower than requested, [content licensing](../content-licensing.md#public-release-gate) recommends publishing from a fresh public repository whose history holds only in-scope files, and keeping the current repository private or archiving it privately. TASK-1.8 needs one of the gate's two methods whatever ISED replies: the 2026-10-02 request deliberately left out the Basic reference PDFs, so they stay outside the recorded scope even if the original request is granted in full (TASK-1.8 description). The pending [reference-sheet follow-up](ised-reference-sheet-request.md) asks ISED to add only the Exam reference sheet, so any written answer to it decides the Exam PDF's scope; the Training PDF is in neither request and stays out of scope. The alternative method is `git filter-repo` plus force-pushing rewritten branches and tags; that doesn't remove copies in existing clones, forks or caches, and GitHub may keep cached commits and pull-request refs until GitHub Support purges them. Because the repository is already public, those caveats apply now.
- **Approve the change.** Agents don't rewrite history, force-push or create repositories without explicit approval. Name the method and who runs it.
- **What the coordinator then verifies:** AC #1, a history scan showing the files are absent from every commit; AC #2, the source manifest, `SHA256SUMS` and docs no longer reference them, and `pnpm import:check`, `pnpm check:links` and the content checks pass; AC #3, the method and its verification are recorded in content licensing and the release checklist.
- TASK-1.8 depends on TASK-1.1: the recorded permission scope decides what counts as out of scope.

### TASK-65: flake follow-up

All three criteria are checked; the task stays In Progress until the owner answers the [owner decision](../testing/task-65-flakes.md#checks-and-owner-decision):

1. Approve or decline at most one rerun of the full default audit, only for the XCTest audit timeout (`Code=-56`), in the shared audit helper. Any real finding must still fail.
2. Decide whether to scope a separate follow-up to evaluate lazy rendering of long lessons.

The file also asks an open question: is the sending fixture's 120-second auto-grade too short for UI tests under heavy host load? A change to a shared audit helper trips the CI test guard, so date the decision; the pull request then cites it as `Test-guard-approved: owner decision YYYY-MM-DD`.

### TASK-85: sign off on `CA92.1` before App Store submission

This isn't a TASK-85 criterion, but App Store submission waits for it. TASK-85 itself must be Done before any distribution upload ([distribution gates](distribution.md#gates)).

- **Facts.** TASK-85 (PR #1064, not yet merged when this guide was updated) declares the User defaults required-reason category with reason `CA92.1` for `CanadianHam`, `CanadianHamTV` and `CanadianHamVision`. That covers the app reading and writing its own settings in its own defaults domain. The open point is `AppleLanguages`: on iOS and macOS the app reads it back from its own domain, where it can hold the per-app language chosen in system Settings. Apple's `CA92.1` text excludes information written by the system and doesn't say whether that entry counts.
- **Coordinator decision 2026-11-02:** keep `CA92.1`. If App Review objects, the fallbacks are to drop the adoption of the system per-app language and the legacy French migration check, so the app reads back only what it wrote, or to request a new reason from Apple.
- **Decide** before App Store submission: sign off keeping `CA92.1`, or choose a fallback. The rationale is in [privacy-label evidence](privacy-label-evidence.md) (TASK-85's "Why these reasons" once PR #1064 merges). Reply with a dated decision; the coordinator records it on TASK-1.7.

### TASK-34 decisions

These can be made before or after [Sitting 5](#sitting-5-signed-device-icloud-debugcloudkit-only):

- **AC #6 (second part):** decide what a Reset should do after sync was turned off without deleting cloud data, then confirm the observed behaviour matches.
- **AC #7:** after an iCloud account switch, keep or remove the previous account's local progress? If kept, it would upload to the new account when sync is turned on again.
- **AC #8:** re-check the App Store Connect privacy answers for the gated iCloud build: no data collected; the device id is a random per-install id stored locally and in the user's private CloudKit database only. Use [privacy-label evidence](privacy-label-evidence.md) and [privacy](../privacy.md). The gated build is not distributed; v1 builds have no iCloud.

## Sitting 2: Apple Watch

Covers TASK-14.6 AC #4, TASK-14.3 AC #2 and TASK-14.5 AC #4.

**Before the sitting**

- A processed internal iOS TestFlight build from main ([Internal builds](#internal-builds-for-the-sittings)); it embeds the watch app. The coordinator gives you the version, build number and commit. The build must include the TASK-14.6 merge (`f3394899`, PR #1037, 2026-10-25).
- You need the paired iPhone with TestFlight signed in to your App Store Connect team-member account, and the watch. TASK-14.5 also asks for the smallest supported physical watch where possible.

**Order.** Work through the [owner physical-watch checklist](testflight.md#owner-physical-watch-checklist-required-not-replaced-by-simulator-tests) from top to bottom. It links the detailed TASK-14.3 and TASK-14.5 checklists at the right points.

1. **Install** with the runbook's [installation steps](testflight.md#watchos-beta-entry-path-and-installation) 1–3 and record the TestFlight version and build number and the install method. → TASK-14.6 AC #4.
2. **Offline launch:** the first checklist item (phone app not running, phone out of range, watch Airplane Mode with Wi-Fi, Bluetooth and cellular explicitly off). That item repeats practice, Morse and reference with no phone or network, so keep the watch offline for steps 3–5. → TASK-14.6 AC #4.
3. **Quick practice:** the second item. → TASK-14.6 AC #4.
4. **Morse:** the same-session three-style comparison in [TASK-14.3's owner hardware check](../testing/task-14.3-watch-morse.md#owner-hardware-check), steps 2–6: all three styles at 1, 1.5 and 2 WPM, the representative short, long and mixed letters, tone off with Silent Mode off and on, tone alone and with haptics, cancellation and the text alternative. → TASK-14.3 AC #2, and the style-comparison part of TASK-14.5 manual check 6.
5. **Alphabet reference:** the fourth item. → TASK-14.6 AC #4.
6. **Language and accessibility:** [TASK-14.5's owner manual checks](../testing/task-14.5-watch-a11y.md#owner-manual-checks--pending-do-not-mark-ac4-complete) 1–6 and its [additional listening points](../testing/task-14.5-watch-a11y.md#additional-owner-listening-points-from-the-review). For check 6, you can reuse step 4's style comparisons, but also run its cancellation checks during the 1.5-second speech lead-in as well as during playback; TASK-14.3 doesn't cover the lead-in. → TASK-14.5 AC #4, and the EN/FR part of TASK-14.6 AC #4.
7. **Memory and launch feel:** the last checklist item.

If any style, speed or letter is unreliable, record the details and leave TASK-14.3 AC #2 open; [step 6 of the hardware check](../testing/task-14.3-watch-morse.md#owner-hardware-check) explains the escalation. Don't change the default style; only the coordinator does that, from your observations.

Repeatable seeded Morse rounds (`-watchMorseSeed`, TASK-14.3 step 2) need a Debug install from Xcode. Do them only after the TestFlight checks, because TASK-14.6 AC #4 needs the TestFlight install.

## Sitting 3: Apple TV

Covers TASK-29 AC #1 and #2.

**Before the sitting**

- The coordinator gives you the build number of a processed internal tvOS TestFlight build from main ([Internal builds](#internal-builds-for-the-sittings)) that includes the TASK-29 merge (`0af1f08d`, PR #1030, 2026-10-25).
- You need a physical Apple TV (VoiceOver isn't available in the tvOS Simulator) with English and French voices installed.

**Steps.** Follow the [owner listening check (tvOS VoiceOver)](../accessibility.md#owner-listening-check-tvos-voiceover), steps 1–5.

- **AC #1:** the English pass (step 2). For each of the five cards (Bank, Sources, Attribution, Disclaimer, Privacy), record whether the title is read as a heading, whether the body is read as normal text, and whether the card is one focus stop. Step 4 says what each outcome means.
- **AC #2:** the French pass (step 3). Record whether every legal paragraph in **Attribution** and **Avis de non-responsabilité** is spoken with an English voice.
- A video with audio of each language pass (for example, filmed on a phone) is the most useful evidence.

AC #3 is not an owner step: if either check fails, the coordinator schedules the fix and the tvOS suite run that AC #3 describes.

## Sitting 4: iPhone Duo

Covers TASK-54 AC #2 and #4–#7, and the real-hardware test run that AC #3 needs. AC #1 is done ([step 4](#4-automated-tests-on-the-duo-ac-3)). No checklist existed for these, so the steps are below. Results marked **Expected (AC #n)** restate that TASK-54 criterion. Specific angles, hold times and repeat counts are a suggested procedure, not criteria. Items marked "also note" come from TASK-54's implementation notes; they are observations to record if you can, not extra criteria.

**Before the sitting**

- A real iPhone Duo on iOS 27.1 or later.
- A processed internal iOS TestFlight build from current main ([Internal builds](#internal-builds-for-the-sittings)); the coordinator gives you the build number. The Apple Watch sitting's build qualifies. Any build from main since 2026-10-19 contains the unfolded layout (TASK-15 part 1, PR #286, and TASK-60, PR #301) and the hinge peek (TASK-15 part 2, PR #292). It must be built with the iOS 27.1 or later SDK, because the hinge code is compiled out with the 27.0 SDK (TASK-15 AC #8).
- Add Screen Recording to Control Centre. Recordings are the timing evidence for AC #6.
- For the AC #3 test run only: the coordinator needs the Duo connected to the build host, with Developer Mode on. Do that part last, because running UI tests installs a development build that may replace the TestFlight app.

### 1. Back button with VoiceOver (AC #2)

On the iOS 27.2 Duo simulator, the lesson's back control is exposed only as an unlabelled Toolbar button with identifier `BackButton`, at `{{399, 179}, {38, 38}}` in a 466 × 678 pt window, near the right edge. In the accessibility tree it sits under the Toolbar element, not inside the NavigationBar element (TASK-54 notes). That is why `testHintToolLadderAndLessonLink` fails there.

1. Turn on VoiceOver (Settings > Accessibility > VoiceOver). Note whether the phone is folded or unfolded.
2. Start a Practice session and go to a question that shows a **Hint** button. Open Hint, reveal hints until **Review in lesson** appears, and activate it. This is the route the failing simulator test uses.
3. On the lesson, find the back control by swiping and by touch. **Expected (AC #2):** VoiceOver reaches it and its label is correct. Record exactly what VoiceOver says; an unlabelled control may be read as just "button". Also note (TASK-54 notes) where it sits on screen, for example at the leading end of the navigation bar or near the right edge as in the simulator; a screenshot with the VoiceOver cursor on it helps. Then activate it and note where it takes you.
4. Repeat on a results screen reached by navigation (one with a back button in the navigation bar), recording the same label and position. Record which screen you used.

AC #2 also allows Accessibility Inspector on a connected Mac instead of VoiceOver.

### 2. Unfolded layouts and fold/unfold state (AC #4)

Turn off rotation lock. In the app's Settings, set the practice mode to **Review later**, so a tapped answer stays selected without being graded (the automated fold/unfold tests use this mode).

1. **Unfolded landscape** (about 951 × 669 pt): unfold, hold the phone in landscape, start Practice and open the calculator. **Expected (AC #4):** the question and the exam-tools inspector appear side by side.
2. **Unfolded portrait** (about 669 × 951 pt): rotate to portrait and open the calculator. **Expected (AC #4):** the compact sheet, not the side-by-side layout.
3. **Fold and unfold during practice:** on a question, tap an answer and enter a value in the calculator (for example `123`). Fold the phone, then unfold it; then repeat starting unfolded. **Expected (AC #4):** after each change, the same question, the same selected answer and the same calculator value. The current app closes an open tool when the layout changes but keeps its value for reopening (TASK-63 description), so reopen the calculator to check the value. Note whether the calculator stayed open or closed; TASK-63 uses that.
4. **Also note:**
   - any brief flash of the compact layout before the side-by-side layout when launching while unfolded;
   - whether the calculator in the inspector scrolls and its keys are comfortably large (the notes ask for at least 44 pt);
   - if unfolded portrait shows the side-by-side layout, note whether the exam column is still usable; if unfolded landscape shows the compact sheet, note whether losing the inspector is acceptable. TASK-54's notes say either outcome may need a product follow-up;
   - the notes also ask for the reported size classes and the safe-area width in unfolded landscape. These need developer tools, so leave them to the coordinator unless you can read them.

### 3. Hint 1 hinge peek (AC #5–#7)

Use a Practice session, not a mock exam (mock exams never peek), on a question that shows a Hint button, with the Hint panel closed. Start a screen recording.

How the peek works (TASK-15 design notes): a peek opens Hint 1 in the normal Hint panel. Once you dismiss a peek, it doesn't come back until the phone has been fully closed or fully opened. A new question needs a fresh dwell. A peek-opened panel closes when the phone is fully opened or closed. Between attempts, fully close or fully open the phone and close any Hint panel.

Estimate angles by eye or with an angle guide such as a protractor, and say which method you used.

**Angle band (AC #5).** The implemented slight-open band is 20–35° by default.

- **Expected (AC #5):** Hint 1 peeks only inside the implemented band, never below or above it. Record the angle range you find comfortable for a deliberate peek.
- Suggested procedure (angles and repeat counts are not criteria):
  1. From closed, open slowly to about 10° and hold for about 2 seconds (below the band).
  2. Reset. Open to about 25–30° and hold for about 2 seconds (inside the band).
  3. Reset. Open quickly to about 45° without pausing in the band and hold for about 2 seconds (above the band).
  4. Approach the band slowly from below and from above, and note the angles where the peek starts and stops happening.
  5. For each probe, record the approximate angle and whether Hint 1 peeked.

**Dwell (AC #6).**

- **Expected (AC #6):** the phone must hold steady in the band for about 0.7 seconds before Hint 1 peeks, including with small jitter near the band edges. Record pass or fail with what you observed. In the TASK-15 design, moving more than about 3° restarts the dwell, and small jitter only keeps an already-shown peek open.
- Suggested procedure (these hold times and positions are not criteria):
  1. From closed, move into the band and hold still. Note roughly how long you held still before Hint 1 appeared.
  2. Several times, move into the band and back out before about half a second has passed. Note any peek.
  3. Hold near one edge of the band (about 20° or 35°) with small, natural hand wobble. Record whether and when it peeks, and whether a shown peek stays steady.

**Normal unfold (AC #7).**

- **Expected (AC #7):** a normal fold-to-unfold motion that passes quickly through the band never reveals Hint 1.
- Suggested procedure (the repeat count is not a criterion): from closed, unfold to fully open in one normal motion at your usual speed, several times (for example 10). Record the number of tries and any peek.

### 4. Automated tests on the Duo (AC #3)

AC #1 is done. On 2026-11-03 the coordinator ran the four named tests on the iOS 27.2 simulator (TASK-54 notes): all four failed only on the iPhone Duo device type, with the same assertions as on iOS 27.1. The same build passed 4/4 on iPhone 18 Pro and 4/4 on iPad Air 11-inch (M4), both on iOS 27.2. AC #3 depends on whether the failures also happen on real hardware, so the coordinator runs the same selection with the Duo connected to the build host. A device run needs development signing (see the [dedicated signing keychain](testflight.md#dedicated-signing-keychain-build-host)), so leave out `CODE_SIGNING_ALLOWED=NO`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=iOS,id=<iPhone Duo UDID>' \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testCalculatorAutoFocusesHardwareKeyboardOnOpen \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testCalculatorKeyboardInputIsFocusScoped \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testCalculatorValueResetsForNewMockExam \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testHintToolLadderAndLessonLink \
  test
```

Record per-test results with the device, OS version and commit. Reinstall the TestFlight build afterwards.

### After the sitting

- AC #3 is the coordinator's follow-up. If the failures reproduce on real hardware, product code is fixed without weakening tests. If they don't, the simulator limitation is documented and the TASK-15 tests stay unchanged.
- TASK-63 is follow-on product work that depends on these results; it isn't an owner check. See [Follow-on work](#follow-on-work-not-owner-checks).

## Sitting 5: signed-device iCloud (DebugCloudKit only)

Covers TASK-34 AC #1–#6. AC #4 is met by recording what you see in every step. The decisions for AC #6, #7 and #8 are in [Sitting 1](#task-34-decisions).

**Before the sitting**

- Use a `DebugCloudKit` build only. Install it from Xcode: open `apps/apple/CanadianHam.xcodeproj`, choose the `CanadianHam` scheme, set Product > Scheme > Edit Scheme > Run > Build Configuration to `DebugCloudKit`, choose the physical iPhone or My Mac, use your development signing, then Product > Run. Never archive or upload this configuration; the TestFlight lanes and Xcode Cloud archives always build Release ([Keeping DebugCloudKit out of uploads](testflight.md#keeping-debugcloudkit-out-of-uploads)). A development install may replace the TestFlight app on that device; reinstall from TestFlight afterwards.
- Confirm that the `iCloud.org.davidjensenius.CanadianHam` container is registered with iCloud (CloudKit) and Push Notifications (TASK-34's "registered iCloud container"). If it isn't, set it up first, as step 3 of the [TestFlight runbook's one-time setup](testflight.md#one-time-local-setup) describes.
- Two Apple Accounts (A and B) and a device where signing out of iCloud is acceptable; it affects other apps too.
- Access to CloudKit Console for the container. Don't export or keep CloudKit Console logs ([iCloud sync proposal](../proposals/icloud-sync.md)).
- Before turning sync on, create some local progress: answer questions, open a lesson, finish a mock exam. Screenshot the progress screens as a baseline and compare after every step; that comparison is the AC #4 evidence.
- The app's **iCloud Sync** setting takes effect after you restart the app.

**Steps**

1. **Baseline.** Sign in to account A with iCloud on. Turn on iCloud Sync and restart the app. Check in CloudKit Console that account A's private database now holds the app's synced progress; the Reset steps later check that it is deleted.
2. **Airplane mode (AC #5).** With sync on, turn on Airplane Mode (and Wi-Fi off), practise, force-quit and relaunch. Expected: progress stays local and usable. Turn the network back on and record whether sync resumes or stays off.
3. **iCloud off for the app (AC #3).** In system Settings, turn off iCloud access for Canadian Ham. Return to the app, relaunching if needed. Expected: local progress remains available and sync is disabled. Record what the app's iCloud Sync setting shows and any message. Then turn the app's iCloud access back on, turn iCloud Sync on again if needed, and restart.
4. **Sign out (AC #1).** With sync on, sign out of iCloud on the device. Expected: local progress remains available and sync is disabled. Record any system prompts and the choices you made.
5. **No iCloud account (AC #5).** While signed out, practise, force-quit and relaunch. Expected: progress stays local and usable, and sync stays off. If you try turning iCloud Sync on, record what happens.
6. **Switch account (AC #2).** Sign back in to account A, turn iCloud Sync on again if it is off, restart the app and let it sync. Then, with sync on, switch the device to account B (on an iPhone this means signing out of A and signing in to B). Expected: the app doesn't mirror into account A or account B until you opt in again. Check both accounts in CloudKit Console. Then turn iCloud Sync on under B and record what uploads; this informs the AC #7 decision.
7. **Reset (AC #6).** Every Reset also turns iCloud Sync off, so set up each case first: turn iCloud Sync on, restart the app, create some progress and confirm in CloudKit Console that it reached the signed-in account's private database.
   - **Reset with sync on:** use **Reset all data**. Expected: the iCloud zone is deleted; check CloudKit Console.
   - **Offline, then retry:** set up again. Go offline and Reset, then go back online and retry (relaunch, or Reset again). Expected: the iCloud zone ends up deleted. Record any message shown, and whether relaunching was enough or a second Reset was needed.
   - **Reset after sync was turned off:** set up again. Turn iCloud Sync off without using **Delete iCloud Progress**, restart the app so the change takes effect, and confirm in CloudKit Console that the cloud data is still there. Then Reset. Record what happens to the cloud and local data, and compare it with your AC #6 decision.
8. **Restore the device.** Sign back in to your usual account and reinstall from TestFlight.

**AC #4:** for every step, record whether local progress disappeared or changed without a Reset, i.e. whether SwiftData or CloudKit purged mirrored local data. The coordinator records the findings for the TASK-13.5 merge and deletion work, as AC #4 asks.

## Sitting 6: Xcode Cloud and App Store Connect setup (no device)

Owner only: agents never create or edit Xcode Cloud workflows or App Store Connect settings. TASK-86 (Done) prepared the scripts and docs; [distribution](distribution.md) is the source of truth, and this sitting only orders its owner steps. Reply with the dates, settings and decisions; the coordinator adds them to TASK-86's notes.

**Before the sitting**

- An App Store Connect Admin or App Manager role (needed for Next Build Number) and the Xcode release named in [Xcode Cloud setup](distribution.md#xcode-cloud-setup-owner-only) step 1.
- The current highest recorded uploads, from `apps/apple/ci_scripts/build-number-floors` on main ([floors file](distribution.md#floors-file)). Every Fastlane upload raises them, so ask the coordinator for the current lines. On 2026-11-03 all four were at version 1.0.0: iOS `202610271751`, macOS `202610271753`, tvOS `202610271756` and visionOS `202610271757`.

**Steps**

1. **Environment and repository:** [Xcode Cloud setup](distribution.md#xcode-cloud-setup-owner-only) steps 1–2.
2. **Build number, before any build** ([Build numbers](distribution.md#build-numbers)). In App Store Connect → the app → Xcode Cloud → Settings → Build Number, try a Next Build Number above the highest recorded upload, for example `202610271758` (option (a)). Nobody has tried a number this large for this app; some developers report that App Store Connect refuses numbers above 2,147,483,647.
   - **Accepted:** all four platforms continue at 1.0.0 from that number. While Fastlane uploads continue, raise Next Build Number above each one ([While Fastlane uploads continue](distribution.md#while-fastlane-uploads-continue)).
   - **Refused:** choose the fallback in [the owner decision](distribution.md#owner-decision-before-the-first-xcode-cloud-build). Option (b): iOS, iPadOS, tvOS and visionOS move to a new marketing version (for example 1.0.1) from a small Next Build Number that App Store Connect accepts; the coordinator raises `MARKETING_VERSION` in a pull request, and from that merge on, including its own upload, Fastlane stops for those platforms. Option (c), for the Mac app under (b): keep it on the Fastlane fallback for now, or ask Apple Developer Support. Overriding `CFBundleVersion` in a script is unverified and not recommended; use it only with an owner decision and a test (see [distribution](distribution.md#owner-decision-before-the-first-xcode-cloud-build)).
   - Reply with the option and the Next Build Number, e.g. "Owner decision 2026-11-05: option (a), Next Build Number 202610271758 accepted".
3. **Internal workflow:** [Xcode Cloud setup](distribution.md#xcode-cloud-setup-owner-only) step 4, with **TestFlight (Internal Testing Only)** for the internal team group only. Under option (b), leave out the macOS archive action.
4. **First run:** Xcode Cloud setup step 6. Give the coordinator each platform's TestFlight version and build number; that platform's internal builds then come from Xcode Cloud ([Internal builds](#internal-builds-for-the-sittings)). On the first macOS archive, confirm that it produces a native macOS app without the watch app, since Xcode Cloud can't pass the Fastlane mac lane's SDK overrides ([macOS SDK](distribution.md#differences-from-fastlane)). Xcode Cloud builds never include the internal-only official reference sheet.
5. **Later:** once Xcode Cloud has shipped all four platforms, decide how to retire Fastlane ([Retiring Fastlane](distribution.md#retiring-fastlane)). Create the distribution workflow (Xcode Cloud setup step 5) only after TASK-1.7 and TASK-85 are Done; external TestFlight and App Store submission also wait for the [release checklist](release-checklist.md#store-submission) and the [`CA92.1` sign-off](#task-85-sign-off-on-ca921-before-app-store-submission).

## Follow-on work (not owner checks)

- **TASK-63** (keep the open exam tool presented across size-class changes) depends on TASK-54. Its AC #1 uses the TASK-54 real-device findings, especially the fold/unfold observations in [Sitting 4](#2-unfolded-layouts-and-foldunfold-state-ac-4), to choose a restoration approach before any implementation.
- TASK-29 AC #3, TASK-54 AC #3 and any TASK-14.3 escalation are coordinator follow-ups after the owner's results.
- TASK-1.7 also waits on the TASK-1.6 release-candidate pass, which is not an owner-gate task.
