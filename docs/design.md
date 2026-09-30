# Design language

Canadian Ham is a calm, offline-first study tool for the Canadian Amateur Radio Basic qualification. The visual family matches the owner's existing apps: sumi-e / ink-brush line art, black ink on warm cream paper, generous whitespace, handmade imperfection, and minimal chrome. It should feel focused and friendly rather than gamified.

The token source of truth is [`packages/design-tokens/tokens.json`](../packages/design-tokens/tokens.json). Generated outputs are intentionally not wired into apps yet: [`apps/web/src/styles/tokens.css`](../apps/web/src/styles/tokens.css) and [`apps/apple/CanadianHam/Design/Tokens.swift`](../apps/apple/CanadianHam/Design/Tokens.swift).

## Principles

1. **Ink on paper.** Use warm paper surfaces, strong ink text, and subtle paper borders. Avoid glossy gradients, heavy shadows, neon colours, and remote assets.
2. **Study-first calm.** One primary task per screen. Make progress visible without pressure. Exam mode is quiet and predictable.
3. **Accessibility from day one.** Follow the Definition of Done in [`docs/accessibility.md`](accessibility.md): keyboard, VoiceOver/screen reader, Dynamic Type/text zoom, colour-independent state, and reduced motion are required for every UI task.
4. **Local and offline.** No analytics, telemetry, network calls, remote fonts, remote images, or third-party runtime SDKs. Use system fonts and bundled assets only.
5. **Platform-native family, not identical pixels.** Web, iOS, iPadOS, macOS, visionOS, and tvOS share tokens and iconography while respecting each platform's layout, focus, and input conventions.

## Palette

The palette uses warm cream paper, near-black ink, and one restrained accent: **vermilion red**. Vermilion is justified because it fits the sumi-e family as a small, sparing accent, reads well beside black ink, and stays visually distinct from success/warning/error semantics. Do not use it as an error colour.

### Light theme

| Role | Token | Value | Use |
|---|---:|---:|---|
| Paper | `paper` | `#F6EEDC` | App background |
| Raised paper | `paperElevated` | `#FFF8EA` | Cards, sheets |
| Inset paper | `paperInset` | `#EFE3CB` | Answer wells, progress rails |
| Ink | `ink` | `#1F1A14` | Primary text and brush marks |
| Muted ink | `inkMuted` | `#5E5347` | Secondary text |
| Paper edge | `border` | `#8C7656` | Borders, dividers, UI boundaries |
| Accent | `accent` | `#A53A2A` | Links, selected state |
| Accent strong/focus | `accentStrong`, `focus` | `#8F2E1D` | Focus rings, active emphasis |

### Dark theme

Dark mode is **ink-dark paper**, not pure black. Text is warm off-white, and surfaces remain layered.

| Role | Token | Value | Use |
|---|---:|---:|---|
| Dark paper | `paper` | `#201B16` | App background |
| Raised dark paper | `paperElevated` | `#2A241D` | Cards, sheets |
| Inset dark paper | `paperInset` | `#181410` | Recessed areas |
| Warm light ink | `ink` | `#F3E8D2` | Primary text |
| Muted warm ink | `inkMuted` | `#CBBDA4` | Secondary text |
| Warm edge | `border` | `#8A7759` | Borders, dividers |
| Accent | `accent` | `#FF8A70` | Links, selected state |
| Focus | `focus` | `#FFB36B` | Focus rings |

### Semantic colours

Correct, incorrect, and warning states must never rely on colour alone. Pair all semantic colour with text, icon, shape, and screen-reader labels.

| State | Light tokens | Dark tokens | Required non-colour cue |
|---|---|---|---|
| Correct | `correctText #284C2B`, `correctBg #E8F1DD`, `correctBorder #5D8A48` | `correctText #DDF2D7`, `correctBg #1F3323`, `correctBorder #76B16B` | Checkmark icon, “Correct” text, VoiceOver announcement |
| Incorrect | `incorrectText #7F241B`, `incorrectBg #F4E2DE`, `incorrectBorder #B64A3B` | `incorrectText #FFD7CF`, `incorrectBg #3A211E`, `incorrectBorder #E27966` | X icon, “Incorrect” text, selected/correct answer text |
| Warning | `warningText #6B4B00`, `warningBg #F8E7B4`, `warningBorder #9B6A00` | `warningText #FFE3A3`, `warningBg #342B16`, `warningBorder #D3A13D` | Caution icon, explicit action copy |

## Contrast table

The design-token test computes these WCAG 2.2 ratios for every declared foreground/background pair. Body text requires at least 4.5:1; large text and UI boundaries/focus rings require at least 3:1. The table below is generated from `packages/design-tokens/tokens.json`; run `node packages/design-tokens/src/generate.ts` after token changes.

<!-- contrast-table:start -->
| Pair | Theme | Kind | Foreground | Background | Ratio | Min |
|---|---|---|---|---|---:|---:|
| light-body | light | body | ink #1F1A14 | paper #F6EEDC | 14.95 | 4.5 |
| light-muted | light | body | inkMuted #5E5347 | paper #F6EEDC | 6.48 | 4.5 |
| light-accent-link | light | body | accent #A53A2A | paper #F6EEDC | 5.61 | 4.5 |
| light-border | light | ui | border #8C7656 | paper #F6EEDC | 3.76 | 3.0 |
| light-focus | light | ui | focus #8F2E1D | paper #F6EEDC | 7.06 | 3.0 |
| light-card-body | light | body | ink #1F1A14 | paperElevated #FFF8EA | 16.34 | 4.5 |
| light-card-muted | light | body | inkMuted #5E5347 | paperElevated #FFF8EA | 7.08 | 4.5 |
| light-card-border | light | ui | border #8C7656 | paperElevated #FFF8EA | 4.10 | 3.0 |
| light-card-focus | light | ui | focus #8F2E1D | paperElevated #FFF8EA | 7.71 | 3.0 |
| light-inset-body | light | body | ink #1F1A14 | paperInset #EFE3CB | 13.58 | 4.5 |
| light-inset-muted | light | ui | inkMuted #5E5347 | paperInset #EFE3CB | 5.89 | 3.0 |
| light-inset-border | light | ui | border #8C7656 | paperInset #EFE3CB | 3.41 | 3.0 |
| light-inset-accent | light | body | accent #A53A2A | paperInset #EFE3CB | 5.10 | 4.5 |
| light-inset-focus | light | ui | focus #8F2E1D | paperInset #EFE3CB | 6.41 | 3.0 |
| light-primary-button-text | light | body | paper #F6EEDC | accent #A53A2A | 5.61 | 4.5 |
| light-correct-text | light | body | correctText #284C2B | correctBg #E8F1DD | 8.36 | 4.5 |
| light-correct-border | light | ui | correctBorder #5D8A48 | correctBg #E8F1DD | 3.48 | 3.0 |
| light-correct-focus | light | ui | focus #8F2E1D | correctBg #E8F1DD | 7.01 | 3.0 |
| light-incorrect-text | light | body | incorrectText #7F241B | incorrectBg #F4E2DE | 7.73 | 4.5 |
| light-incorrect-border | light | ui | incorrectBorder #B64A3B | incorrectBg #F4E2DE | 4.16 | 3.0 |
| light-incorrect-focus | light | ui | focus #8F2E1D | incorrectBg #F4E2DE | 6.51 | 3.0 |
| light-warning-text | light | body | warningText #6B4B00 | warningBg #F8E7B4 | 6.49 | 4.5 |
| light-warning-border | light | ui | warningBorder #9B6A00 | warningBg #F8E7B4 | 3.83 | 3.0 |
| light-warning-focus | light | ui | focus #8F2E1D | warningBg #F8E7B4 | 6.63 | 3.0 |
| dark-body | dark | body | ink #F3E8D2 | paper #201B16 | 14.05 | 4.5 |
| dark-muted | dark | body | inkMuted #CBBDA4 | paper #201B16 | 9.23 | 4.5 |
| dark-accent-link | dark | body | accent #FF8A70 | paper #201B16 | 7.42 | 4.5 |
| dark-border | dark | ui | border #8A7759 | paper #201B16 | 3.95 | 3.0 |
| dark-focus | dark | ui | focus #FFB36B | paper #201B16 | 9.69 | 3.0 |
| dark-card-body | dark | body | ink #F3E8D2 | paperElevated #2A241D | 12.63 | 4.5 |
| dark-card-muted | dark | body | inkMuted #CBBDA4 | paperElevated #2A241D | 8.30 | 4.5 |
| dark-card-border | dark | ui | border #8A7759 | paperElevated #2A241D | 3.55 | 3.0 |
| dark-card-focus | dark | ui | focus #FFB36B | paperElevated #2A241D | 8.70 | 3.0 |
| dark-inset-body | dark | body | ink #F3E8D2 | paperInset #181410 | 15.08 | 4.5 |
| dark-inset-muted | dark | ui | inkMuted #CBBDA4 | paperInset #181410 | 9.90 | 3.0 |
| dark-inset-border | dark | ui | border #8A7759 | paperInset #181410 | 4.24 | 3.0 |
| dark-inset-accent | dark | body | accent #FF8A70 | paperInset #181410 | 7.96 | 4.5 |
| dark-inset-focus | dark | ui | focus #FFB36B | paperInset #181410 | 10.39 | 3.0 |
| dark-primary-button-text | dark | body | paper #201B16 | accent #FF8A70 | 7.42 | 4.5 |
| dark-correct-text | dark | body | correctText #DDF2D7 | correctBg #1F3323 | 11.41 | 4.5 |
| dark-correct-border | dark | ui | correctBorder #76B16B | correctBg #1F3323 | 5.32 | 3.0 |
| dark-correct-focus | dark | ui | focus #FFB36B | correctBg #1F3323 | 7.66 | 3.0 |
| dark-incorrect-text | dark | body | incorrectText #FFD7CF | incorrectBg #3A211E | 11.21 | 4.5 |
| dark-incorrect-border | dark | ui | incorrectBorder #E27966 | incorrectBg #3A211E | 5.06 | 3.0 |
| dark-incorrect-focus | dark | ui | focus #FFB36B | incorrectBg #3A211E | 8.41 | 3.0 |
| dark-warning-text | dark | body | warningText #FFE3A3 | warningBg #342B16 | 11.16 | 4.5 |
| dark-warning-border | dark | ui | warningBorder #D3A13D | warningBg #342B16 | 5.94 | 3.0 |
| dark-warning-focus | dark | ui | focus #FFB36B | warningBg #342B16 | 7.92 | 3.0 |
<!-- contrast-table:end -->

## Typography

Use system stacks only. Do not download fonts. French UI copy follows the Canadian federal typography and terminology rules in [`docs/french-style.md`](french-style.md).

- Display/headings: `ui-serif`, New York on Apple platforms, falling back to Iowan Old Style/Georgia/serif.
- Body/UI: system sans (`system-ui`, SF Pro, Segoe UI fallback).
- Code/formulas: system monospace.

The web scale is rem-based and must respect user text settings. Apple uses Dynamic Type-relative SwiftUI `Font` values generated from the same scale.

| Token | Size | Line height | Use |
|---|---:|---:|---|
| `caption` | `0.8125rem` | 1.35 | Labels, metadata |
| `body` | `1rem` | 1.55 | Reading text, answer choices |
| `bodyLarge` | `1.125rem` | 1.5 | Question stems |
| `title` | `1.5rem` | 1.25 | Card and screen titles |
| `headline` | `2rem` | 1.15 | Main headings |
| `display` | `2.75rem` | 1.05 | Home hero only |

## Spacing, radius, and elevation

Spacing tokens are 4/8/12/16/24/32/48 px equivalents. Prefer generous whitespace over dense dashboards.

- Phone page padding: 16 px minimum, 24 px when available.
- Desktop content width: 72 rem max for dashboards; 42-48 rem for lesson reading.
- tvOS: honour overscan-safe margins. Use at least `tvSafe` (96 px) from physical edges and focusable spacing large enough for remote navigation.
- visionOS: keep windows airy; use `visionDepth` for layered ornaments/depth spacing when platform APIs are available.
- Radius: 10 px for small controls, 16 px for cards, 24 px for large paper sheets, pill for segmented controls.
- Elevation: use 1 px paper-like borders and very soft shadows only where platform-native depth needs it. Avoid dark drop shadows on light paper.

## Motion

Motion should be gentle and useful: brief card reveals, progress transitions, focus lifts, and answer feedback. Durations: 120 ms fast, 180 ms normal, 280 ms slow. Always honour `prefers-reduced-motion` on web and Reduce Motion on Apple. Reduced motion should remove parallax, springy answer jumps, animated timers, and non-essential transitions while preserving state changes.

## Iconography and illustration

- App identity: one bold ink-brush mark on warm cream. The mark should still read at 60 px.
- UI chrome: SF Symbols are acceptable on Apple; web may use simple inline SVG equivalents. Keep line weight calm and avoid third-party icon fonts.
- Lesson illustrations: original ink-brush diagrams for antennas, waves, and circuits. Use text labels for all formulas and values; diagrams are supplemental and need alt text/captions.
- Brush style: tapered filled paths, variable width, slight asymmetry, and breathing room. Avoid uniform technical strokes for brand art; use precise diagrams only when teaching requires precision.

## Platform notes

### Web

- Use generated CSS custom properties.
- Support `[data-theme="light"]` and `[data-theme="dark"]` overrides; otherwise follow `prefers-color-scheme`.
- Keep layouts functional at 320 CSS px and at 200% text zoom.

### iOS, iPadOS, and macOS

- Use SwiftUI Dynamic Type, system controls, and generated `DesignTokens` values when the later styling lane wires them in.
- Prefer platform navigation patterns over custom navigation chrome.

### tvOS

- Design for a 10-foot UI: fewer elements, larger type, larger cards, and clear focus targets.
- Every interactive element needs an obvious focused state with scale or border plus text/icon state. Do not rely on hover.
- Keep content within overscan-safe margins and avoid small explanatory text on the main TV practice screen; move dense review detail into readable panels.

### visionOS

- Use warm paper surfaces inside native windows with glass/material surroundings rather than flat full-screen panels.
- Layer diagrams and progress ornaments subtly in depth; never let depth obscure text.
- Use hover effects and ornaments as secondary affordances. Core navigation must remain clear through labels and focus/selection state.

## Component specs

### Category card

- Surface: `paperElevated`, 1 px `border`, radius `md`.
- Contents: category number/name, subsection count, progress summary, and one clear primary action.
- State: selected/current uses accent left brush bar plus accessible label; weak category uses warning panel copy, not colour alone.
- tvOS: focus scale 1.04 and thick focus ring; card min height suitable for remote selection.

### Question card

- One question per screen for practice/exam. Use `bodyLarge` for stem and keep source category/subsection metadata visible.
- Official ISED text is displayed verbatim. Project explanations stay separate.
- Long formulas remain selectable/readable text, not images.

### Answer choice

| State | Visual | Accessibility |
|---|---|---|
| Default | Paper inset/elevated row, border, letter marker | Radio/button semantics; full answer text in label |
| Hover | Slight paper lift on pointer platforms only | No hover-only information |
| Focus | 2-3 px focus ring using `focus` plus offset | Keyboard/remote focus visible |
| Selected | Accent border, filled letter marker, selected text | `aria-checked`/selected state |
| Correct | Correct border/background, checkmark, “Correct answer” text | Announce politely after submission |
| Incorrect | Incorrect border/background, X icon, “Your answer” and correct answer text | Identify both selected and correct answers |
| Disabled | Muted border/text but still readable | Do not remove submitted answers from accessibility tree |

### Feedback panel

- Appears below the answered question or as a sheet on small screens.
- Starts with explicit result text, then explanation and source/category metadata.
- Include “Continue”, “Review lesson”, and “Practice this subsection” actions only when relevant.

### Progress and score display

- Use fractions and labels (`72 / 100`, `72%`, `Pass threshold 70%`, `Honours 80%`) rather than colour bars alone.
- Category breakdown should include correct/total, percent, and weak-subsection list.
- Progress rings must have text equivalents.

### Exam timer

- Timer is optional/off by default.
- If enabled, display remaining time as text and announce threshold changes politely.
- Timer can be paused/extended as specified in accessibility requirements.

### Lesson page

- Reading width 42-48 rem desktop; no more than one major concept per section.
- Diagrams have captions, alt text, and nearby text equivalents.
- Previous/next/module overview controls are visible and keyboard reachable.

### Buttons

- Primary: ink text on paper with accent border or accent fill only for the one main action.
- Secondary: paper surface with border.
- Destructive: avoid red fill; use explicit warning copy and confirmation for data reset or exam submit.
- Minimum target: 24 x 24 CSS px and 44 x 44 pt on touch Apple platforms.

### Toggles and EN/FR switch

- Use segmented controls or platform toggles with visible labels (`English`, `Français`).
- Persist language preference locally only.
- Ensure `lang` changes on web content and VoiceOver language is correct where platform APIs allow.

## Wireframes

### Home/dashboard

Phone:

```text
┌────────────────────────┐
│ Canadian Ham           │
│ Ink antenna mark       │
│ Ready for Basic?       │
│ [Start practice]       │
│ [Mock exam]            │
├────────────────────────┤
│ Progress paper card    │
│ 72/100 recent score    │
│ Honours target: 80%    │
├────────────────────────┤
│ Categories             │
│ [B-001 Regulations]    │
│ [B-002 Operating]      │
│ ...                    │
└────────────────────────┘
```

Desktop:

```text
┌────────────────────────────────────────────────────────────┐
│ Canadian Ham                         Practice Mock Lessons │
├──────────────────────┬─────────────────────────────────────┤
│ Hero: ink mast mark  │ Readiness card + next best action   │
│ Basic with Honours   │ Recent exams / due review           │
├──────────────────────┴─────────────────────────────────────┤
│ 8 category cards in a generous grid                         │
└────────────────────────────────────────────────────────────┘
```

### Practice

Phone:

```text
┌────────────────────────┐
│ B-006 Antennas   3/10  │
├────────────────────────┤
│ Question stem          │
│ ...                    │
├────────────────────────┤
│ ○ A answer text        │
│ ○ B answer text        │
│ ○ C answer text        │
│ ○ D answer text        │
│ [Check answer]         │
└────────────────────────┘
```

Desktop:

```text
┌──────────────────┬─────────────────────────────────────────┐
│ Session outline  │ Question card                           │
│ progress         │ Answer choices                          │
│ weak areas       │ Feedback panel below after answer        │
└──────────────────┴─────────────────────────────────────────┘
```

### Mock exam

Phone:

```text
┌────────────────────────┐
│ Mock exam  18/100      │
│ Timer off  [Options]   │
├────────────────────────┤
│ Question stem          │
│ answer choices         │
├────────────────────────┤
│ [Previous] [Next]      │
│ [Review & submit]      │
└────────────────────────┘
```

Desktop:

```text
┌────────────────────────────────────────────────────────────┐
│ Mock exam 18/100 | Timer off | Submit                    │
├───────────────┬────────────────────────────────────────────┤
│ Question map  │ Question card and answer choices           │
│ answered flag │                                            │
└───────────────┴────────────────────────────────────────────┘
```

Design decision: compact-width mock exams open the question navigator in a sheet from the header `Questions` button; the header keeps Flag, Questions, and optional timer controls in one row that wraps before content is hidden at large Dynamic Type sizes.

### Exam results with category breakdown

Phone:

```text
┌────────────────────────┐
│ Result: 82% Honours    │
│ 82 / 100 correct       │
├────────────────────────┤
│ Category breakdown     │
│ B-001 20/25 Review     │
│ B-002  8/9 Strong      │
│ ...                    │
├────────────────────────┤
│ [Practice weak areas]  │
│ [Review answers]       │
└────────────────────────┘
```

Desktop:

```text
┌─────────────────┬──────────────────────────────────────────┐
│ Score summary   │ Category table: correct/total/%/status   │
│ Pass/Honours    │ Weak subsections and next lesson links    │
└─────────────────┴──────────────────────────────────────────┘
```

### Lesson

Phone:

```text
┌────────────────────────┐
│ Lesson title           │
│ 25 min · B-005         │
├────────────────────────┤
│ Paragraph text         │
│ Ink diagram + caption  │
│ Formula as text        │
├────────────────────────┤
│ Concept check          │
│ [Previous] [Next]      │
└────────────────────────┘
```

Desktop:

```text
┌───────────────┬──────────────────────────────┬─────────────┐
│ Module nav    │ Lesson article, 42-48rem max │ Key formulas │
│ prerequisites │ diagrams/captions/quizzes    │ related qs   │
└───────────────┴──────────────────────────────┴─────────────┘
```
