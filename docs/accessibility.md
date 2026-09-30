# Accessibility specification and Definition of Done

Accessibility is a day-1 product requirement for Canadian Ham, not polish. Every web and Apple UI task must meet this Definition of Done before it is considered complete. The target is WCAG 2.2 AA plus Apple Human Interface Guidelines for iOS, iPadOS, macOS, visionOS, and tvOS.

## Definition of Done for every UI task

A UI change is done only when all applicable items are true:

- Keyboard-only use works on web and macOS with a logical focus order and no traps.
- Focus is always visible and has at least 3:1 contrast against adjacent colours.
- Screen reader names, roles, values, hints, and state changes are meaningful in VoiceOver; web also considers NVDA/JAWS basics.
- Text supports Dynamic Type on Apple and browser text zoom to 200% with no loss of content or function.
- Layout reflows at 320 CSS px on web without horizontal scrolling except for intentionally scrollable tables/diagrams.
- Colour is never the only indicator of state, correctness, warnings, or progress.
- Motion honours `prefers-reduced-motion` and Apple Reduce Motion.
- Touch/pointer targets are at least 24 x 24 CSS px on web and 44 x 44 pt on iOS/iPadOS; tvOS focus targets are large enough for remote navigation.
- Timed exam behaviour, if enabled, can be paused/extended and has polite announcements.
- Error-prone actions prevent mistakes: exam submit and data reset require review/confirmation.
- Diagrams have captions and alt text; formulas/math are real text, not images.
- No analytics, telemetry, remote fonts, remote assets, or third-party runtime SDKs are introduced.

## Keyboard and focus

- Web supports Tab/Shift+Tab for all controls, Enter/Space activation where expected, arrow-key navigation for radio groups/segmented controls, and Escape to close dismissible dialogs.
- Focus order follows visual/task order: navigation, main heading, question stem, answers, primary action, secondary actions, then supporting panels.
- Focus indicators use the design-token focus colour and a shape/border change; do not hide native focus without an accessible replacement.
- Disabled controls remain understandable. If a disabled action blocks progress, provide explanatory text.
- tvOS uses the focus engine: focused cards/buttons must be visibly distinct via scale/border/material and must not depend on hover.

## Screen readers

- Primary validation: VoiceOver on iOS, iPadOS, macOS, visionOS, and tvOS as applicable.
- Web sanity checks also consider NVDA/JAWS patterns: semantic HTML first, landmarks, headings, buttons/links with accessible names, fieldsets/radio groups for answer choices.
- Announce practice feedback politely after answer submission. Do not interrupt while the user is reading.
- Mock exam progress should be available as text, e.g. “Question 18 of 100, answered”.
- Results must identify score, pass/honours status, and category breakdown in text.

## Language and bilingual text

- Web content that displays French official text uses `lang="fr-CA"`; English content uses `lang="en-CA"`.
- Mixed-language question text should mark the smallest practical container with the correct language.
- Apple views should use localized strings and platform language APIs when French UI ships; official French question text must not be machine-translated by the project.
- The EN/FR toggle has visible labels and an accessible selected state.

## Text sizing, zoom, and reflow

- Web must work at 200% browser text zoom and at 320 CSS px wide.
- Apple views use Dynamic Type-relative fonts and should pass a largest-accessibility-size UI run.
- Avoid fixed-height text containers. Cards can grow vertically.
- Tables must reflow to cards or provide an accessible horizontal scroll region with a label.

## Reduced motion

- Honour `prefers-reduced-motion: reduce` on web and Reduce Motion on Apple.
- Remove parallax, decorative brush animations, spring bounces, and timer ticking animations when reduced motion is enabled.
- State changes still need immediate non-animated feedback.

## Colour independence and contrast

- Follow the ratios declared and tested in [`docs/design.md`](design.md#contrast-table).
- Correct/incorrect/warning states require text and icon cues in addition to colour.
- Progress and score displays require numeric text. Bars/rings are supplemental.

## Target sizes

- Web: 24 x 24 CSS px minimum for pointer targets, with larger targets preferred for primary actions and answer choices.
- iOS/iPadOS: 44 x 44 pt minimum.
- macOS: keep controls keyboard reachable and pointer targets comfortable; avoid tiny custom hit areas.
- tvOS: use large focusable cards/buttons, spaced far enough that focus movement is predictable.
- visionOS: support comfortable gaze/indirect input targets with adequate spacing in depth.

## Timed exams

The mock exam timer is optional and off by default.

- A user can pause or extend the timer.
- Timer state is visible as text, not colour alone.
- Screen readers receive polite announcements at meaningful thresholds, not every second.
- Timer expiration must not cause sudden data loss; users can review before submit.

## Error prevention

- Exam submit shows unanswered count, score implications (“unanswered count as incorrect”), and a confirm action.
- Reset all data requires confirmation and states that local progress will be deleted.
- Import/export actions validate file shape and show recoverable errors in text.

## Math, formulas, and diagrams

- Formulas are selectable text and accessible to screen readers. Do not bake formulas into images.
- Diagrams are supplemental. Provide concise alt text plus captions that describe the teaching point.
- Complex diagrams may include a text transcript or nearby step-by-step explanation.

## Cognitive load

- Practice and mock exam flows present one question per screen.
- Progress is clear: current question, total, answered/unanswered state, and next action.
- Avoid simultaneous feedback panels, modal prompts, and unrelated recommendations.
- Use plain language and consistent labels across web and Apple.

## Automated checks

### Web

- Component tests use axe-core in Vitest when UI components are added.
- A later Playwright + axe smoke test covers home, practice, mock exam, exam results, lesson, settings, and language switching.
- Tests include keyboard traversal for answer selection and exam submit.

### Apple

- XCUITest runs `performAccessibilityAudit` on every iOS, tvOS, and visionOS screen when screen UI exists.
- The macOS UI suite is intentionally skipped for speed; macOS keyboard and Full Keyboard Access coverage is verified in the manual release checklist below.
- A largest-Dynamic-Type UI run validates no clipped essential text and no unreachable actions.
- VoiceOver manual smoke covers practice, mock exam, results, lessons, import/export, and reset.

## Manual release checklist

- Keyboard-only web walkthrough completed.
- macOS keyboard walkthrough completed with Full Keyboard Access enabled: open System Settings > Accessibility > Keyboard, turn on Full Keyboard Access, launch Canadian Ham, then use Tab/Shift-Tab, arrow keys, Space, Enter, and Escape to traverse Home, Practice, Mock exam, Results, Learn, Settings, import/export, and reset without a pointer; confirm focus remains visible, ordered, and trap-free.
- VoiceOver walkthrough completed on at least one iOS/iPadOS device or simulator and macOS.
- tvOS focus walkthrough completed when tvOS app is present.
- visionOS window/readability walkthrough completed when visionOS app is present.
- 200% text zoom and 320 CSS px reflow checked on web.
- Largest Dynamic Type checked on Apple.
- Reduced Motion checked.
- Colour-independence checked by reviewing grayscale/high-contrast screenshots or equivalent.
- No telemetry/network/remote asset regression found in privacy audit.
