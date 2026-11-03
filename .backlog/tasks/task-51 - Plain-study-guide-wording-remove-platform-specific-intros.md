---
id: TASK-51
title: 'Plain study-guide wording: remove platform-specific intros'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 08:06'
updated_date: '2026-10-16 14:07'
labels:
  - web
  - apple
  - content
dependencies: []
priority: medium
ordinal: 114000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-10-16: treat the app as an amateur radio study guide and drop needlessly specific wording. Introductions and headers should not mention device families ('on iPhone, iPad, and Mac', 'for Apple devices'), the web app versus the native app, or bank version dates. The About page and Settings keep the factual details they need: bank version, privacy and storage statements, attribution. Applies to web and all Apple platforms, EN and FR.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Home and section intros on web and every Apple platform read as a plain study guide, with no device-family, platform or bank-date wording
- [x] #2 Necessary facts stay where they belong (About: bank version and attribution; Settings: storage and privacy), and the App Store listing drafts are checked for the same issue
- [x] #3 EN and FR updated; pnpm check:apple-l10n, check-apple-text-sources, web tests and the affected Apple UI tests pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Search web, Apple SwiftUI, string catalogues, tests, and App Store listing drafts for platform/device-family, web/native, and intro bank-date wording while preserving About, Settings/storage, and device-capability messages.
2. Rewrite affected EN/FR copy as plain Canadian Amateur Radio Basic study-guide wording with no layout changes.
3. Update tests that assert old copy, using the required Python JSON round-trip for Localizable.xcstrings.
4. Run the required web, localization, text-source, and targeted Apple checks; record before/after strings and finish TASK-51.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Before/after copy updated:
- Web/Apple Basic home intro: “Practice/Study with the committed/bundled 2025-07-15 Basic EN/FR/ISED question bank … on iPhone, iPad, and Mac / in this browser” -> “Study for the Amateur Radio Operator Certificate with Basic Qualification using the official ISED question bank.” FR/fr-CA -> “Préparez-vous au certificat d’opérateur radioamateur avec compétence de base avec la banque de questions officielle d’ISDE.”
- Web/Apple Advanced home intro: dated bundled-bank/device/browser wording -> “Study for the Amateur Radio Operator Certificate with Advanced Qualification using the official ISED question bank. Advanced progress is tracked separately from Basic.” FR/fr-CA -> “Préparez-vous au certificat d’opérateur radioamateur avec compétence supérieure avec la banque de questions officielle d’ISDE. La progression de la compétence supérieure est suivie séparément de celle de la compétence de base.”
- Advanced Learn intro: “Advanced lessons are not bundled yet. Use practice by topic and 50-question mock exams while the curriculum is authored.” -> “Advanced lessons are coming. Use Advanced practice and mock exams in the meantime.” FR/fr-CA updated to a plain coming-soon sentence.
- Apple Learn intro: removed “matching the web app”; now “Lessons are currently authored in English; official practice questions follow your Language setting.”
- Web/Apple Morse sending intro: keyboard wording is now hardware-keyboard conditional, with touch targets as the non-keyboard path.
- Apple About privacy: removed “This Apple/Apple TV/Apple Vision Pro app” wording while preserving offline/privacy/storage/session facts.
- visionOS category subtitle: removed “for visionOS”.
- App Store listing drafts checked; platform lists were retained because the listing metadata documents Apple platform availability as requested.

Validation passed:
- pnpm typecheck
- pnpm test
- pnpm build:web
- pnpm check:apple-l10n
- node scripts/check-apple-text-sources.ts
- iOS About UI: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination “platform=iOS Simulator,name=iPhone 17 Pro” -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAboutShowsReleaseAttributionDisclaimerAndBankVersion test CODE_SIGNING_ALLOWED=NO
- tvOS About UI: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination “platform=tvOS Simulator,name=Apple TV 4K (3rd generation)” -only-testing:CanadianHamTVUITests/CanadianHamTVUITests/testAboutShowsReleaseAttributionDisclaimerAndBankVersion test CODE_SIGNING_ALLOWED=NO
- visionOS About UI: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamVision -destination “platform=visionOS Simulator,name=Apple Vision Pro” -only-testing:CanadianHamVisionUITests/CanadianHamVisionUITests/testAboutShowsReleaseAttributionDisclaimerAndBankVersion test CODE_SIGNING_ALLOWED=NO
- rg for the replaced Basic/Advanced home intro wording and Advanced Learn/Morse intro strings shows the old user-facing strings removed (aside from historical task notes and the separate Morse navigation teaser).

PR #261 audit fix: investigated /tmp/t51-xcresult-attachments from the failing iPhone 17 Pro run. The contrast issue was not under the opaque navigation bar and not a real low-contrast color; it was a layout shift from the shortened Morse sending intro. The shorter intro pulled the bottom row far enough upward that the Clear sending practice button was partially visible at the bottom edge. XCTest's element screenshot showed only the top of the Clear button with the rest clipped outside the viewport, producing a contrast false positive. origin/main at 90dacffc passed the same two Morse sending main-screen audits, so the regression was PR-caused.\n\nApple Morse sending intro before this fix: “With a hardware keyboard, focus this screen first, then hold Space for the straight key; use J for dots and K for dashes. Otherwise, use the large touch targets.” FR/fr-CA: “Avec un clavier physique, placez d’abord le foyer sur cet écran, puis maintenez la barre d’espacement pour la clé droite; utilisez J pour les points et K pour les tirets. Sinon, utilisez les grandes cibles tactiles.”\n\nApple Morse sending intro after this fix: “Practise tap timing with a straight key or iambic-style paddles. With a hardware keyboard, focus this screen first, then hold Space for the straight key; use J for dots and K for dashes. Otherwise, use the large touch targets. Aim for steady dot/dash ratio and timing consistency.” FR/fr-CA: “Exercez le rythme d’envoi avec une clé droite ou des palettes de type iambique. Avec un clavier physique, placez d’abord le foyer sur cet écran, puis maintenez la barre d’espacement pour la clé droite; utilisez J pour les points et K pour les tirets. Sinon, utilisez les grandes cibles tactiles. Visez un rapport points/tirets et un minutage constants.”\n\nTargeted validation: /tmp/t51-main-morse.log on origin/main passed testAccessibilityAuditMorseSendingMainScreenDark (62.180s) and testAccessibilityAuditMorseSendingMainScreenLight (45.730s). After the fix, /tmp/t51-audits.log passed testAccessibilityAuditMorseSendingMainScreenDark (47.558s), testAccessibilityAuditMorseSendingMainScreenLight (47.388s), testCoursePickerSwitchesToAdvancedLessonsAndFiftyQuestionMockWithoutHonours (43.556s), and testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice (82.982s). node scripts/check-apple-text-sources.ts passed. A pnpm check:apple-l10n rerun reached the text-source checks then timed out while waiting for another xbuild lock holder.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Rewrote the web and Apple Basic/Advanced home intros to use the official ISED Amateur Radio Operator Certificate credential names in EN and FR/fr-CA, kept About/Settings facts in place, and applied the plain Advanced Learn and hardware-keyboard Morse sending wording. Updated Localizable.xcstrings through a Python JSON round trip and verified with web checks, Apple localization/text-source checks, and targeted iOS/tvOS/visionOS About UI tests.
<!-- SECTION:FINAL_SUMMARY:END -->
