---
id: TASK-38.1
title: 'Figure pipeline, hide placeholders, Ohm''s law set'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-11 09:59'
labels:
  - content
  - apple
  - web
dependencies: []
parent_task_id: TASK-38
priority: medium
ordinal: 79000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build the shared figure pipeline and prove it with the Ohm's law set. Figures are original SVG sources under content/figures/ referenced from lesson Markdown (alt text kept from the brief). Web renders them themed for light/dark; Apple renders the same sources (e.g. generated asset catalog with preserved vector data or build-time conversion), lessons only on iOS/iPadOS/macOS. Until a lesson has a figure, learners see nothing (the brief stays in source for authors).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Lessons without a drawn figure no longer show an 'Illustration placeholder'/'Illustration brief' card on web or Apple (brief kept in source; tests assert it)
- [x] #2 Documented pipeline: SVG source location and naming, how lessons reference figures, how web and Apple render them, light/dark theming via design tokens, and a check that every referenced figure exists and every figure has alt text
- [x] #3 Figures: Ohm's law triangle (E over I x R), power triangle (P over I x E), and Ohm's law/power wheel (P, E, I, R, 12 formulas) in the power/Ohm's law lesson; the wheel has a full text equivalent (formulas grouped by unknown) available to screen readers
- [x] #4 Accessibility: text in figures meets 4.5:1 and graphics 3:1 in light and dark; figures scale with width and stay legible at the largest text sizes (zoom or enlarged view where needed); no meaning by colour alone; audits pass on the lesson screen in light and dark
- [x] #5 Figures are original work (not traced from ISED reference material); an originality note is recorded
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a small lesson figure Markdown directive, keep Illustration brief sections parsed for authors but render them as hidden/no-op learner output on web and Apple, and add regression tests.
2. Add original SVG sources for the L-005-02 Ohm's law triangle, power triangle, and combined formula wheel under content/figures/, then reference them from the lesson with alt text and the wheel text equivalent.
3. Add web rendering that inlines referenced SVGs using currentColor/design-token styling plus details text equivalents.
4. Add an Apple asset-generation/check pipeline that copies the SVGs into a generated vector asset catalog, wire the catalog into the iOS/macOS target, and render lesson figures with template tint plus optional disclosure text/enlarged view.
5. Document the pipeline and add a CI/package check that validates figure references, alt text, SVG ids, and generated Apple assets.
6. Run targeted checks, regenerate the Apple project twice, then run the required final web, content, localization, and iOS/macOS Apple suites.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented figure directive pipeline and Ohm’s law figure set. Evidence: web hides author Illustration brief cards and renders the three L-005-02 figures; Apple hides .illustrationBrief blocks and renders generated template SVG assets. Pipeline documented in docs/figures.md; generated assets checked by pnpm check:figures.

Validation passed: pnpm typecheck; TZ=UTC pnpm test (content-tools 108, morse-engine 21, web 153); pnpm check:schemas; pnpm import:check; pnpm check:figures; pnpm check:links; pnpm build:web; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift (19); full iOS xbuild suite (76 UI tests, including light/dark Ohm’s law figure accessibility audits) result bundle /tmp/task381-ios-full.xcresult; full macOS xbuild suite (72 unit tests) result bundle /tmp/task381-macos-full.xcresult; node scripts/check-apple-text-sources.ts.

Validation blocked: pnpm check:apple-l10n fails because xbuild export rewrites unrelated existing Localizable.xcstrings entries. Per supervisor decision, did not commit the export churn. Export saved at /tmp/task381-xcstrings-export.json; key-level drift summary at /tmp/task381-l10n-drift.txt (0 added/removed keys, 5 existing keys changed by export; none introduced by task-38.1 except the committed Figure text equivalent key, which already has French).

Originality: Ohm’s law triangle, power triangle, and wheel were drawn from scratch as simple ink-style formula aids using the standard formulas already taught in the lesson, not traced from ISED or third-party art. Contrast evidence and themed web/iOS source previews are under docs/evidence/task-38.1/.

Review fix: redesigned the Ohm’s law/power wheel layout so quadrant labels/formulas sit clear of divider strokes, removed triangle decorative arcs and shortened the Ohm’s law triangle caption so all text stays inside the viewBox, regenerated Apple figure assets and refreshed light/dark evidence. Added an approximate SVG <text> bounds check to scripts/check-figures.mjs. Removed stale Apple localization keys for the now-hidden Illustration brief/Alt text placeholder UI; remaining check:apple-l10n drift is limited to the two unrelated Morse count keys under investigation separately.

Review-fix validation passed: pnpm check:figures; TZ=UTC pnpm --filter @canadian-ham/web test (153 tests); node scripts/check-apple-text-sources.ts; targeted iOS xbuild tests testOhmsLawLessonFiguresAndAccessibilityLight and testOhmsLawLessonFiguresAndAccessibilityDark (2 tests) with result bundle /tmp/task381-ohms-targeted.xcresult. Render evidence refreshed under docs/evidence/task-38.1/, including qlmanage 800px and 1600px PNG renders.

Localization follow-up: pnpm check:apple-l10n now passes on the branch. Catalog update removes the three stale placeholder keys (Alt text:, Illustration brief, Illustration brief.) and matches Xcode export for the two Morse plural keys by preserving their values while using the exported plural-variant ordering.

Review r1 fixes: aligned web/Swift figure directive parsing with shared fixtures; added SVG safety/text-bounds/self-test checks; generated Apple figure metadata from viewBox; removed per-id sizing and fit figures to available width; added enlarged figure sheet; refreshed docs and real-app screenshot evidence under docs/evidence/task-38.1/app/. Removed dead web placeholder i18n/CSS and added compact navigation bar background to avoid translucent contrast issues.

Validation after r1 fixes: pnpm typecheck; TZ=UTC pnpm --filter @canadian-ham/web test (161 tests); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift (20 tests); pnpm check:figures; node scripts/check-figures.mjs --self-test; node scripts/check-apple-text-sources.ts; pnpm check:apple-l10n; targeted iOS xbuild figure tests testOhmsLawLessonFiguresAndAccessibilityLight/Dark plus placeholder assertion (3 tests) in /tmp/task381-r1-screens.xcresult; targeted largest-text/enlarge iOS test testOhmsLawWheelFitsAndEnlargesAtLargestAccessibilityTextSize in /tmp/task381-large.xcresult. Full iOS/macOS reruns intentionally skipped per coordinator owner-decision testing policy update; full affected-platform suites run once before merge.

Follow-up fixes: increased wheel formula SVG font sizes to satisfy the 11 pt at 300 pt display-width rule, added that minimum to scripts/check-figures.mjs and docs/figures.md, regenerated Apple assets/evidence, and retook real iOS app screenshots under docs/evidence/task-38.1/app/ including default light/dark, enlarged views, and a largest-accessibility-text wheel screenshot.

Follow-up validation: pnpm check:figures; node scripts/check-figures.mjs --self-test; TZ=UTC pnpm --filter @canadian-ham/web test (161 tests); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift (20 tests); node scripts/check-apple-text-sources.ts; targeted iOS xbuild tests: testLessonIllustrationBriefsAreHiddenInEnglishAndFrench plus testOhmsLawLessonFiguresAndAccessibilityLight/Dark in /tmp/task381-r7-screens.xcresult (3 tests passed), and testOhmsLawWheelFitsAndEnlargesAtLargestAccessibilityTextSize in /tmp/task381-large4.xcresult (1 test passed). Full platform suites remain deferred to pre-merge per updated policy.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented task-38.1 and follow-up review fixes: hidden author illustration briefs, shared and checked SVG figure pipeline, Ohm’s law triangle/power triangle/wheel with text equivalent, parser parity fixtures for web and Swift, generated Apple assets and metadata, width-fitting Apple figures with enlarged view, robust figure checker and docs, refreshed real-app screenshot evidence, and localized UI strings. Verified with figure checks/self-test, web tests, content-swift tests, Apple text/l10n checks, and targeted iOS figure/placeholder/large-text tests. Full iOS/macOS suites are deferred to pre-merge under the updated owner testing policy.
<!-- SECTION:FINAL_SUMMARY:END -->
