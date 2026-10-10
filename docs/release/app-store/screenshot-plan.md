# App Store screenshot capture plan

Status: draft for `task-1.9`. No screenshots are committed by this task. Capture screenshots only after the release gates permit App Store preparation, and build/run Apple targets through `xbuild` as required by [`../../../AGENTS.md`](../../../AGENTS.md).

## Global capture matrix

Capture each selected screen in both storefront languages and appearances before choosing the final App Store Connect set:

- Languages: English (`en-CA`) and French (`fr-CA`).
  - iPhone, iPad and Mac: use `-AppleLanguages (fr)` and `-AppleLocale fr_CA` for the French interface; use the on-screen question-language picker where a screenshot must show French question-bank text.
  - Apple TV and Vision Pro: use `-CanadianHamLanguage fr` for French question-bank text, plus `-AppleLanguages (fr)` / `-AppleLocale fr_CA` if the runtime supports localized system formatting in the capture harness.
- Appearance: light and dark.
  - iPhone, iPad and Mac: use `-CanadianHamTheme light` or `-CanadianHamTheme dark`.
  - Apple TV and Vision Pro: use `-CanadianHamAppearance light` or `-CanadianHamAppearance dark`.
- Reset state before each capture with `-CanadianHamResetDataOnLaunch` where persistent progress would otherwise leak between shots.
- Use deterministic seeds/limits from the existing DEBUG launch arguments to make screenshots repeatable.
- Do not show a guaranteed exam outcome, official endorsement, private repository URL or unreleased public URL in any screenshot.

## Shared DEBUG launch arguments to stage iPhone, iPad and Mac screens

These arguments are present in `RootView.swift` and the UI tests:

| Screen / state | Launch arguments |
|---|---|
| Home readiness / Basic overview | `-CanadianHamInitialScreen home` |
| Basic lessons list | `-CanadianHamInitialScreen learn` |
| Specific Basic lesson | `-CanadianHamInitialLessonID L-006-03` |
| Specific Basic lesson quiz | `-CanadianHamInitialLessonQuizID QZ-L-006-03-A -CanadianHamLessonQuizLimit 1 -CanadianHamLessonQuizSeed screenshot-basic-quiz` |
| Practice category list | `-CanadianHamInitialScreen practice` |
| Specific Basic practice question | `-CanadianHamInitialCategoryID B-001 -CanadianHamPracticeQuestionID B-001-002-002 -CanadianHamPracticeMode immediate -CanadianHamPracticeLimit 1 -CanadianHamPracticeSeed screenshot-basic-practice` |
| Mock exam start / mock state | `-CanadianHamInitialScreen mock -CanadianHamMockExamSeed screenshot-basic-mock` |
| Short mock for staged result screen | `-CanadianHamInitialScreen mock -CanadianHamMockExamSeed screenshot-basic-result -CanadianHamMockExamLimit 1` then answer and submit manually |
| Advanced course picker / settings | `-CanadianHamInitialScreen settings -CanadianHamCourseBankId advanced-2025-02-04` |
| Advanced lessons-unavailable state | `-CanadianHamInitialScreen learn -CanadianHamCourseBankId advanced-2025-02-04` |
| Advanced practice list | `-CanadianHamInitialScreen practice -CanadianHamCourseBankId advanced-2025-02-04` |
| Specific Advanced practice question | `-CanadianHamInitialCategoryID A-001 -CanadianHamPracticeQuestionID A-001-001-001 -CanadianHamCourseBankId advanced-2025-02-04 -CanadianHamPracticeMode immediate -CanadianHamPracticeLimit 1 -CanadianHamPracticeSeed screenshot-advanced-practice` |
| Advanced 50-question mock start | `-CanadianHamInitialScreen mock -CanadianHamCourseBankId advanced-2025-02-04 -CanadianHamMockExamSeed screenshot-advanced-mock` |
| Morse home / Quick listen | `-CanadianHamInitialScreen morse` |
| Morse Koch course deterministic lesson | `-CanadianHamInitialScreen morse -CanadianHamMorseCourseSeed screenshot-morse-course` |
| Morse copy/exam shortened playback | `-CanadianHamInitialScreen morse -CanadianHamMorseCopyPlaybackSeconds 0.1 -CanadianHamMorseExamPlaybackSeconds 0.1 -CanadianHamMorseExamReviewSeconds 1` |
| Morse sending practice | `-CanadianHamInitialScreen morse -CanadianHamMorseSendingDebugHook -CanadianHamMorseSendingExamSeconds 120` |
| About / privacy / attribution | `-CanadianHamInitialScreen about` |
| iPhone regular-width staged sidebar, if needed | add `-CanadianHamForceRegularHorizontalSizeClass` |

## Device-class plan

### iPhone 6.9"

Capture a compact iPhone set that emphasizes the full v1 scope available on iPhone:

1. Home readiness / Basic overview — `-CanadianHamInitialScreen home`.
2. Basic lesson or lesson quiz — `-CanadianHamInitialLessonID L-006-03` or the lesson-quiz arguments above.
3. Basic practice with feedback — Basic practice arguments above; answer one question before capture.
4. Basic mock exam / readiness result — staged short mock result for composition, then final release-candidate full-flow evidence separately.
5. Advanced practice or Advanced mock start — Advanced practice or mock arguments above; include caption text that Advanced lessons are not in v1.
6. Morse training — Morse home, Koch course, copy practice or sending, using the Morse arguments above.
7. About/privacy — `-CanadianHamInitialScreen about` if legal/privacy screenshot is needed for review rather than marketing.

Capture EN light, EN dark, FR light and FR dark variants, then choose the strongest localized set for App Store Connect.

### iPad 13"

Capture a regular-width iPad set that shows the split layout and larger study surfaces:

1. Sidebar with Home / Learn / Practice / Morse / Settings using `-CanadianHamForceRegularHorizontalSizeClass -CanadianHamInitialScreen home` if a simulator needs forcing.
2. Basic lesson reading surface — `-CanadianHamInitialLessonID L-006-03`.
3. Topic practice question and feedback — Basic practice arguments above.
4. Mock exam start or results — Basic mock arguments above.
5. Advanced practice or 50-question mock start — Advanced arguments above.
6. Morse Koch course / copy practice / sending — Morse arguments above.

Capture both appearances and both languages as in the global matrix.

### Mac

Capture Mac screenshots for the iPhone/iPad/Mac feature set:

1. Home readiness / Basic overview — `-CanadianHamInitialScreen home`.
2. Learn / lesson reading — `-CanadianHamInitialLessonID L-006-03`.
3. Basic practice — Basic practice arguments above.
4. Mock exam start/results — Basic mock arguments above.
5. Advanced practice / 50-question mock — Advanced arguments above.
6. Morse training — Morse course/copy/sending arguments above.
7. Settings or About privacy — `-CanadianHamInitialScreen settings` or `-CanadianHamInitialScreen about`.

Use `-CanadianHamTheme light` and `-CanadianHamTheme dark`; local progress screenshots should be reset or deliberately staged.

### Apple TV

Apple TV v1 does not include Advanced. Morse on Apple TV is Quick listen only. Use the platform launch arguments from `CanadianHamTVApp.swift` and the tvOS UI tests:

| Screen / state | Launch arguments |
|---|---|
| Basic category grid | `-CanadianHamPlatformInitialScreen categories -CanadianHamPlatformCategoryID B-001 -CanadianHamAppearance light` |
| Basic practice question | `-CanadianHamPlatformInitialScreen practice -CanadianHamPlatformCategoryID B-001 -CanadianHamPlatformQuestionID B-001-002-002 -CanadianHamAppearance light` |
| Answered practice feedback | add `-CanadianHamPlatformAnsweredSourceIndex 0` to the practice arguments |
| Morse Quick listen | `-CanadianHamPlatformInitialScreen morse -CanadianHamAppearance light` |
| About / privacy | `-CanadianHamPlatformInitialScreen about -CanadianHamAppearance light` |
| Focus evidence, if needed | add `-CanadianHamTVEvidenceFocus category`, `answer` or `language` |
| Reduce Motion evidence, if needed | add `-CanadianHamReduceMotion enabled` |

Repeat with `-CanadianHamAppearance dark` and with `-CanadianHamLanguage fr` for fr-CA question-bank screenshots.

### Vision Pro

Vision Pro v1 does not include Advanced. Morse on Vision Pro is Quick listen only. Use the platform launch arguments from `CanadianHamVisionApp.swift` and the visionOS UI tests:

| Screen / state | Launch arguments |
|---|---|
| Basic category grid | `-CanadianHamPlatformInitialScreen categories -CanadianHamPlatformCategoryID B-001 -CanadianHamAppearance light` |
| Basic practice question | `-CanadianHamPlatformInitialScreen practice -CanadianHamPlatformCategoryID B-001 -CanadianHamPlatformQuestionID B-001-002-002 -CanadianHamAppearance light` |
| Answered practice feedback | add `-CanadianHamPlatformAnsweredSourceIndex 0` to the practice arguments |
| Morse Quick listen | `-CanadianHamPlatformInitialScreen morse -CanadianHamAppearance light` |
| About / privacy | `-CanadianHamPlatformInitialScreen about -CanadianHamAppearance light` |

Repeat with `-CanadianHamAppearance dark` and with `-CanadianHamLanguage fr` for fr-CA question-bank screenshots.
