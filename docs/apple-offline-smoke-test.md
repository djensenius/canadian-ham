# Apple airplane-mode smoke test plan

This manual plan verifies the Apple app remains usable with no network path and does not depend on accounts, analytics, telemetry, iCloud, or remote content. It supports the privacy posture in [privacy.md](privacy.md) and the Apple app notes in [apps/apple/README.md](../apps/apple/README.md).

Run this plan after the relevant `xbuild` command for the platform under test and after `pnpm check:apple-network` passes.

## Test setup

1. Install a fresh build on the device or simulator under test.
2. Disable all network interfaces before first launch:
   - iPhone/iPad: enable Airplane Mode, then confirm Wi-Fi and Bluetooth remain off.
   - Mac: turn Wi-Fi off and disconnect Ethernet/VPN or other network services.
   - Apple TV: disconnect Wi-Fi/Ethernet from Settings or use a simulator/network profile with no connectivity.
   - Apple Vision Pro: enable Airplane Mode or disable Wi-Fi before launch.
3. Leave the device offline for the full run. Do not sign in, enable iCloud, or attach a debugger feature that provides network access.
4. Start from a clean local data state when possible. If reusing an install, perform the reset step first, force-quit, relaunch, and then repeat the plan.
5. Record platform, OS/runtime, build commit, date, tester, and pass/fail notes for each section.

## Pass criteria

- The app launches and remains usable while offline.
- Bundled question-bank, lesson, quiz, explanation, and progress screens load without remote fetches.
- Practice, mock exam, Learn, lesson quiz, export/import, and reset either pass on the platform or are recorded as a platform-specific product gap requiring follow-up before release.
- Progress changes persist locally across force-quit and relaunch.
- Export/import uses only a user-selected local file/share destination and does not require iCloud.
- No prompts appear for network, local-network discovery, push notifications, analytics consent, account login, or iCloud sync.

## Smoke matrix

Repeat the checklist for each platform: iPhone, iPad, Mac, Apple TV, and Apple Vision Pro.

### 1. Launch and offline baseline

1. With the device offline, launch the app.
2. Confirm the home or platform landing screen appears without an error caused by missing network access.
3. Confirm the active bank/version and privacy/offline messaging are visible where the platform exposes About or Settings.
4. Force-quit and relaunch while still offline.
5. Confirm the app returns to a usable screen and does not request network, account, analytics, or iCloud access.

Expected result: launch succeeds from bundled resources only.

### 2. Practice

1. Open Practice.
2. Start an all-questions or category practice session.
3. Answer at least three questions, including one correct and one incorrect answer when possible.
4. Verify answer feedback and review state render offline.
5. Leave the session, force-quit, relaunch, and verify local progress/readiness reflects the answered questions where the platform supports persisted progress.

Expected result: practice works entirely offline and persists local progress on platforms with progress storage.

### 3. Mock exam

1. Open Mock Exam.
2. Start a mock exam while offline.
3. Answer several questions, flag or navigate between questions if the platform supports it, and submit the exam.
4. Verify score, pass/honours messaging, category breakdown, and wrong-answer review render without network access.
5. Force-quit, relaunch, and verify the completed attempt contributes to local readiness where supported.

Expected result: mock exam generation, scoring, review, and persistence are local-only. If Mock Exam is absent on a platform, record that as a platform gap rather than a pass.

### 4. Learn lesson reading

1. Open Learn.
2. Open a module and lesson.
3. Navigate previous/next or back to the module overview.
4. Verify lesson body content, tables, citations, and explanation links render from bundled content while offline.
5. If an RBR-4 citation link is shown, confirm it is visibly user-activated; do not tap it during the offline smoke run unless explicitly testing that external navigation fails outside the app without breaking local study.
6. Force-quit, relaunch, and verify lesson read progress persists where supported.

Expected result: lessons and metadata load from bundled files only. If Learn is absent on a platform, record that as a platform gap rather than a pass.

### 5. Lesson quiz

1. From a lesson with a quiz, open the lesson quiz.
2. Answer all quiz questions.
3. Verify shuffled answer choices, score, retry option, and local quiz history where supported.
4. Retry the quiz and confirm the retry works offline without erasing prior local history unless the UI explicitly says it will.

Expected result: quizzes work from bundled content only. If lesson quizzes are absent on a platform, record that as a platform gap rather than a pass.

### 6. Export and import

1. Open Settings or the platform equivalent.
2. Export progress to a local file or local share destination. Avoid iCloud Drive for this smoke test.
3. Reset local data using the reset flow below or install on a second offline device/simulator.
4. Import the exported JSON from the local file location.
5. Verify known practice/exam/lesson/quiz progress returns after import.
6. Force-quit and relaunch while offline, then verify imported progress persists.

Expected result: export and import are user-initiated local file operations and do not require network or iCloud. If export/import is absent on a platform, record that as a platform gap rather than a pass.

### 7. Reset all data

1. Open Settings or the platform equivalent.
2. Trigger Reset all data.
3. Confirm the destructive action in the UI.
4. Verify practice progress, mock exam attempts, lesson progress, quiz history, and local preferences return to their initial state.
5. Force-quit and relaunch while offline.
6. Confirm reset state remains reset and bundled content still loads.

Expected result: reset deletes local user progress only and does not depend on remote services. If reset is absent on a platform, record that as a platform gap rather than a pass.

## Per-platform notes to capture

For each of iPhone, iPad, Mac, Apple TV, and Apple Vision Pro, record:

- Device/simulator model and OS/runtime.
- Build branch and commit.
- Network-off method used.
- Practice result.
- Mock exam result.
- Learn result.
- Lesson quiz result.
- Export/import result.
- Reset result.
- Any unexpected prompts, errors, logs, or missing platform features.

A platform passes only when every applicable flow works offline and every absent required flow is either already an approved platform-scope exception or has a tracked follow-up before release.
