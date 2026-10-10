# App Store screenshot capture plan

Status: draft for `task-1.9`. No screenshots are committed by this task. Capture screenshots only after the release gates permit App Store preparation, and build/run Apple targets through `xbuild` as required by [`../../../AGENTS.md`](../../../AGENTS.md).

## Device names and capture commands

Use one simulator/device class at a time:

| App Store class | Simulator/device name | Bundle identifier |
|---|---|---|
| iPhone 6.9" | `iPhone 17 Pro Max` | `com.djensenius.CanadianHam` |
| iPad 13" | `iPad Pro 13-inch (M4) (or the current 13-inch iPad Pro listed by `xcrun simctl list devices`)` | `com.djensenius.CanadianHam` |
| Mac | local Mac app build | `com.djensenius.CanadianHam` |
| Apple TV | `Apple TV 4K (3rd generation)` | `com.djensenius.CanadianHam.TV` |
| Vision Pro | `Apple Vision Pro` | `com.djensenius.CanadianHam.Vision` |

After building/installing the app through `xbuild`, capture simulator screenshots with this pattern, replacing the device, app bundle path, output path and launch arguments for each planned shot:

```sh
DEVICE="iPhone 17 Pro Max"
xcrun simctl boot "$DEVICE" || true
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl install "$DEVICE" /path/to/CanadianHam.app
xcrun simctl launch --terminate-running-process "$DEVICE" com.djensenius.CanadianHam \
  -CanadianHamResetDataOnLaunch \
  -CanadianHamInitialScreen home \
  -CanadianHamTheme light
xcrun simctl io "$DEVICE" screenshot screenshots/iphone-home-en-light.png
```

For French iPhone/iPad/Mac simulator captures, add these launch arguments before the `-CanadianHam…` app arguments:

```sh
-AppleLanguages '(fr)' -AppleLocale fr_CA
```

These arguments change the interface language only. The question language is a separate stored preference (default English) with no launch argument on iPhone/iPad/Mac, and `-CanadianHamResetDataOnLaunch` resets it. For French question text: launch once with the reset flag, set Settings → Langue des questions → Français, then relaunch **without** `-CanadianHamResetDataOnLaunch` for the French practice, mock and quiz shots.

For Apple TV and Vision Pro French screenshots, add both `-CanadianHamLanguage fr` (question bank) and `-AppleLanguages '(fr)' -AppleLocale fr_CA` (interface); both are required.

For Mac screenshots, launch the built app and capture its window. **`-CanadianHamResetDataOnLaunch` wipes the local Canadian Ham store on this Mac, so export your progress first** (Settings → Data → Export). Capture a single window with `screencapture -w` (or `-l <windowid>`), then resize to an App Store Mac screenshot size (for example 2880×1800):

```sh
APP="/path/to/CanadianHam.app"
open -n "$APP" --args -CanadianHamResetDataOnLaunch -CanadianHamInitialScreen home -CanadianHamTheme light
screencapture -x -w screenshots/mac-home-en-light.png
```

Mac Settings are a native Settings scene, not the sidebar Settings screen. `-CanadianHamInitialScreen settings` intentionally opens Home on macOS. To capture Mac Settings, launch a normal Mac shot first, then open the native Settings window and capture it:

```sh
APP="/path/to/CanadianHam.app"
open -n "$APP" --args -CanadianHamResetDataOnLaunch -CanadianHamCourseBankId advanced-2025-02-04 -CanadianHamTheme light
sleep 2
# Needs Accessibility permission for the terminal running this.
osascript -e 'tell application "CanadianHam" to activate' -e 'delay 1' -e 'tell application "System Events" to keystroke "," using command down'
sleep 1
screencapture -x -w screenshots/mac-settings-en-light.png
```

Repeat each selected screenshot in light and dark appearance:

- iPhone, iPad and Mac: `-CanadianHamTheme light` or `-CanadianHamTheme dark`.
- Apple TV and Vision Pro: `-CanadianHamAppearance light` or `-CanadianHamAppearance dark`.

Reset state before each capture with `-CanadianHamResetDataOnLaunch` where persistent progress would otherwise leak between shots. Use deterministic seeds from the existing DEBUG launch arguments to make screenshots repeatable. Never use the question/session limit or timing arguments (`-CanadianHamLessonQuizLimit`, `-CanadianHamPracticeLimit`, `-CanadianHamMockExamLimit`, `-CanadianHamMorse*PlaybackSeconds`, `-CanadianHamMorseExamReviewSeconds`) or `-CanadianHamForceRegularHorizontalSizeClass` on iPhone: they visibly change totals, controls or layout into states the release app never shows. Do not show a guaranteed exam outcome, official endorsement, private repository URL or unreleased public URL in any screenshot.

## Shared DEBUG launch arguments to stage iPhone, iPad and Mac screens

These arguments are present in `RootView.swift` and the UI tests:

| Screen / state | Launch arguments |
|---|---|
| Home readiness / Basic overview | `-CanadianHamInitialScreen home` |
| Basic lessons list | `-CanadianHamInitialScreen learn` |
| Specific Basic lesson | `-CanadianHamInitialLessonID L-006-03` |
| Specific Basic lesson quiz | `-CanadianHamInitialLessonQuizID QZ-L-006-03-A -CanadianHamLessonQuizSeed screenshot-basic-quiz` |
| Practice category list | `-CanadianHamInitialScreen practice` |
| Specific Basic practice question | `-CanadianHamInitialCategoryID B-001 -CanadianHamPracticeQuestionID B-001-002-002 -CanadianHamPracticeMode immediate -CanadianHamPracticeSeed screenshot-basic-practice` |
| Mock exam start / mock state | `-CanadianHamInitialScreen mock -CanadianHamMockExamSeed screenshot-basic-mock` |
| Mock exam result screen | `-CanadianHamInitialScreen mock -CanadianHamMockExamSeed screenshot-basic-result`, then answer all 100 questions and submit (a real result; no limit argument) |
| Advanced course picker on iPhone/iPad | `-CanadianHamInitialScreen settings -CanadianHamCourseBankId advanced-2025-02-04` |
| Advanced course picker on Mac | Open the native Settings window with `-CanadianHamCourseBankId advanced-2025-02-04`; do not use `-CanadianHamInitialScreen settings` on macOS |
| Advanced lessons-unavailable state | `-CanadianHamInitialScreen learn -CanadianHamCourseBankId advanced-2025-02-04` |
| Advanced practice list | `-CanadianHamInitialScreen practice -CanadianHamCourseBankId advanced-2025-02-04` |
| Specific Advanced practice question | `-CanadianHamInitialCategoryID A-001 -CanadianHamPracticeQuestionID A-001-001-001 -CanadianHamCourseBankId advanced-2025-02-04 -CanadianHamPracticeMode immediate -CanadianHamPracticeSeed screenshot-advanced-practice` |
| Advanced 50-question mock start | `-CanadianHamInitialScreen mock -CanadianHamCourseBankId advanced-2025-02-04 -CanadianHamMockExamSeed screenshot-advanced-mock` |
| Morse home / Quick listen | `-CanadianHamInitialScreen morse` |
| Morse Koch course deterministic lesson | `-CanadianHamInitialScreen morse -CanadianHamMorseCourseSeed screenshot-morse-course` |
| Morse copy practice / exam | `-CanadianHamInitialScreen morse` with real timing. Capture the start screen, or the results after a real run. Never use the DEBUG playback or review-duration overrides: they change the visible countdown and announcements |
| Morse sending practice | `-CanadianHamInitialScreen morse -CanadianHamMorseSendingExamSeconds 120`; stage the sending screen manually and do not use the sending debug-hook flag, because it shows a debug-only button |
| About / privacy / attribution | `-CanadianHamInitialScreen about` |
| iPad sidebar layout | iPad only: the regular size class is native there; don't force it on iPhone |

## Device-class plan

### iPhone 6.9"

Capture on `iPhone 17 Pro Max` with `xcrun simctl launch` and `xcrun simctl io … screenshot`. A compact iPhone set should emphasize the full v1 scope available on iPhone:

1. Home readiness / Basic overview — `-CanadianHamInitialScreen home`.
2. Basic lesson or lesson quiz — `-CanadianHamInitialLessonID L-006-03` or the lesson-quiz arguments above.
3. Basic practice with feedback — Basic practice arguments above; answer one question before capture.
4. Basic mock exam / readiness result — a real 100-question mock submitted in the release-like build (no limit argument).
5. Advanced practice or Advanced mock start — Advanced practice or mock arguments above; include caption text that Advanced lessons are not in v1.
6. Morse training — Morse home, Koch course, copy practice or sending, using the Morse arguments above and without debug-only hooks.
7. About/privacy — `-CanadianHamInitialScreen about` if legal/privacy screenshot is needed for review rather than marketing.

Capture EN light, EN dark, FR light and FR dark variants, then choose the strongest localized set for App Store Connect.

### iPad 13"

Capture on `iPad Pro 13-inch (M4)` with `xcrun simctl launch` and `xcrun simctl io … screenshot`. A regular-width iPad set should show the split layout and larger study surfaces:

1. Sidebar with Home / Learn / Practice / Morse / Settings using `-CanadianHamInitialScreen home` (iPad is regular width natively; never force the size class).
2. Basic lesson reading surface — `-CanadianHamInitialLessonID L-006-03`.
3. Topic practice question and feedback — Basic practice arguments above.
4. Mock exam start or results — Basic mock arguments above.
5. Advanced practice or 50-question mock start — Advanced arguments above.
6. Morse Koch course / copy practice / sending — Morse arguments above and without debug-only hooks.

Capture both appearances and both languages as in the global matrix.

### Mac

Capture the local Mac app build with `open -n … --args` and `screencapture`. The Mac feature set matches iPhone/iPad, including Basic lessons, quizzes, 100-question mocks, readiness, Advanced practice/mocks and full Morse training:

1. Home readiness / Basic overview — `-CanadianHamInitialScreen home`.
2. Learn / lesson reading — `-CanadianHamInitialLessonID L-006-03`.
3. Basic practice — Basic practice arguments above.
4. Mock exam start/results — Basic mock arguments above.
5. Advanced practice / 50-question mock — Advanced arguments above.
6. Morse training — Morse course/copy/sending arguments above and without debug-only hooks.
7. Native Settings or About privacy — for Settings, launch with the desired `-CanadianHamCourseBankId` / `-CanadianHamTheme`, press Command-comma (or choose the app menu's Settings item), then capture the native Settings window; for About, use `-CanadianHamInitialScreen about`.

Use `-CanadianHamTheme light` and `-CanadianHamTheme dark`; local progress screenshots should be reset or deliberately staged.

### Apple TV

Capture on `Apple TV 4K (3rd generation)` with `xcrun simctl launch --terminate-running-process` and `xcrun simctl io … screenshot`. Apple TV v1 does not include lessons, mock exams, readiness or Advanced. Morse on Apple TV is Quick listen only. Use the platform launch arguments from `CanadianHamTVApp.swift` and the tvOS UI tests:

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

Capture on `Apple Vision Pro` with `xcrun simctl launch --terminate-running-process` and `xcrun simctl io … screenshot`. Vision Pro v1 does not include lessons, mock exams, readiness or Advanced. Morse on Vision Pro is Quick listen only. Use the platform launch arguments from `CanadianHamVisionApp.swift` and the visionOS UI tests:

| Screen / state | Launch arguments |
|---|---|
| Basic category grid | `-CanadianHamPlatformInitialScreen categories -CanadianHamPlatformCategoryID B-001 -CanadianHamAppearance light` |
| Basic practice question | `-CanadianHamPlatformInitialScreen practice -CanadianHamPlatformCategoryID B-001 -CanadianHamPlatformQuestionID B-001-002-002 -CanadianHamAppearance light` |
| Answered practice feedback | add `-CanadianHamPlatformAnsweredSourceIndex 0` to the practice arguments |
| Morse Quick listen | `-CanadianHamPlatformInitialScreen morse -CanadianHamAppearance light` |
| About / privacy | `-CanadianHamPlatformInitialScreen about -CanadianHamAppearance light` |

Repeat with `-CanadianHamAppearance dark` and with `-CanadianHamLanguage fr` for fr-CA question-bank screenshots.
