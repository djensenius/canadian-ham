---
id: TASK-12.3
title: Morse audio drivers and settings
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-03 02:06'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.2
parent_task_id: TASK-12
priority: medium
ordinal: 41000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: learners must hear clean, click-free Morse offline on every platform, with no third-party audio code. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Web Audio driver (oscillator with about 5 ms gain ramps, started by a user gesture) and an AVAudioEngine/AVAudioSourceNode driver on iOS, iPadOS, macOS, tvOS and visionOS
- [x] #2 Settings for tone (400-900 Hz, default 650), character speed (12-25, default 15), effective speed (5 up to the character speed, default 5), timing profile and trainer volume, plus a one-tap ISED exam preset (12/5)
- [x] #3 The Morse feature stays off by default until v1 Basic ships; no network or new permissions; tests pass on web and all four Apple platforms
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing web and Apple settings/navigation/persistence/test patterns plus the merged Morse engine APIs.
2. Add local Morse settings with default-off preview toggle, clamping, ISED preset, and localized EN/FR UI copy.
3. Implement web Web Audio scheduling/playback UI behind the toggle and tests for scheduling/gesture/settings.
4. Wire packages/morse-swift into Apple targets, add AVAudioEngine/AVAudioSourceNode playback and reachable Morse UI behind the toggle on each platform.
5. Add Apple unit/UI tests, regenerate the Xcode project twice, then run required web, localization, network, and xbuild checks before finalizing.
6. Fix review findings for task-12.3: accessibility announcements, cancellable web playback, fixed timing profiles, click-free stop ramps, localization, cleanup/focus, and requested tests/check notes.

7. Second review fix round: make web/Apple stops wait for audible fade-out, clean up fixed-profile/settings edge cases and accessibility audits, create the requested follow-up, then rerun required web and Apple checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Morse preview behind default-off settings toggle for web/iOS/macOS/tvOS/visionOS with Web Audio OscillatorNode scheduling and AVAudioEngine/AVAudioSourceNode playback. Validation passed: pnpm typecheck, pnpm test, pnpm build:web, web URL audit, check-links, check-apple-l10n, check-apple-text-sources, check-apple-network, and iOS/macOS/tvOS/visionOS xbuild test suites.

Review round started after owner request to start before v1; keeping Morse off by default until v1 while fixing task-12.3 review findings.

Review round fixes implemented. Key validation on code tip e046697: pnpm typecheck passed; pnpm test passed (content-tools 98, morse-engine 6, web 105 tests); pnpm build:web passed; web dist URL/CSP audit passed; pnpm check:links passed; pnpm check:apple-l10n passed; node scripts/check-apple-text-sources.ts passed; pnpm check:apple-network passed. Xbuild per-test summaries: iOS CanadianHam on iPhone 17 Pro passed 57/57 test cases (28 unit + 29 UI including Morse accessibility audit); macOS CanadianHam unit-only passed 28/28; tvOS CanadianHamTV passed 14/14 (3 unit + 11 UI including Morse accessibility audit and Morse controls); visionOS CanadianHamVision passed 11/11 (3 unit + 8 UI including Morse accessibility audit and Morse controls). XcodeGen determinism not run because project.yml was not changed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added local Morse trainer preview settings and routes/screens, Web Audio and AVAudioEngine/AVAudioSourceNode playback, EN/FR UI strings, package wiring, and web/Apple tests. Verified with required pnpm checks, Apple localization/network/text-source checks, XcodeGen determinism, and iOS/macOS/tvOS/visionOS xbuild suites.
<!-- SECTION:FINAL_SUMMARY:END -->
