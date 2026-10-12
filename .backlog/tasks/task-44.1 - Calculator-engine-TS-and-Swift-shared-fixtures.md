---
id: TASK-44.1
title: 'Calculator engine (TS and Swift, shared fixtures)'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 14:38'
updated_date: '2026-10-12 15:24'
labels:
  - web
  - apple
dependencies: []
parent_task_id: TASK-44
priority: medium
ordinal: 94000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A pure, deterministic basic-calculator engine in TypeScript (packages/) and Swift (packages/): digits, decimal point, + - x ÷, √, x², 1/x, ±, %, clear, all-clear and backspace, with conventional immediate-execution behaviour like a basic calculator, sensible display formatting (significant digits, no binary float artefacts such as 0.1+0.2), error states (÷0, √ of a negative), locale-aware decimal separator for display. Shared JSON fixtures of key sequences and expected displays run in both test suites.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 TS and Swift engines pass the same shared fixture file (at least 60 cases including chained operations, repeated equals, backspace, sign, percent, errors and rounding)
- [x] #2 No storage of formulas or text; state is only the current calculation
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a pure calculator engine package pair under packages/calculator-ts and packages/calculator-swift with matching public key/state APIs and documented basic-calculator semantics (left-to-right chaining, repeated equals, percent rules, error recovery, display formatting).
2. Add one shared fixtures/calculator/sequences.json file with 60+ key-sequence cases and run it from both TS node tests and Swift XCTest.
3. Wire the TS package into pnpm root test/typecheck and CI; keep the Swift package standalone because UI tasks will link it later.
4. Run pnpm typecheck, TZ=UTC pnpm test, and DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/calculator-swift, then update task notes/ACs/final status.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented packages/calculator-ts and packages/calculator-swift, plus fixtures/calculator/sequences.json with 80 shared key-sequence cases. Documented left-to-right immediate execution, repeated equals, percent behaviour, errors, locale display and no formula/history storage. Wired @canadian-ham/calculator-engine into root pnpm test and CI. Validation: pnpm --filter @canadian-ham/calculator-engine test passed; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/calculator-swift passed; pnpm typecheck passed after pnpm install; TZ=UTC pnpm test passed. Apple app suites skipped because no app target/project.yml changes.

Review fix pass started for requested changes: relative cancellation only for +/-, platform-independent display rounding, 12-significant-digit entry cap, C/CE error clear, accessibility display payload, stale repeat-equals fixes, and added fixture coverage.

Review fixes: replaced global small-result zeroing with +/−-only relative cancellation, added platform-independent half-away display rounding, capped entries at 12 significant digits, made C/CE clear Error, added structured displayValue with localized EN/FR spoken strings, fixed stale repeat-equals after unary/clear keys, switched negative visual output to U+2212, and expanded the shared fixture to 103 cases covering small products/squares/reciprocals, rounding ties, entry limits, accessibility display values and low-gap cases. Validation: pnpm --filter @canadian-ham/calculator-engine typecheck passed; pnpm --filter @canadian-ham/calculator-engine test passed (105 tests); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/calculator-swift passed (2 XCTest tests).

Second review fix pass started: add pocket-calculator range clamps, total entry-length cap, typed-entry spoken display, typographic exponent minus, placeholder cleanup, and CI calculator test de-duplication/local-only comment update.

Second review fixes: added pocket-calculator range handling (|x| >= 1e100 -> Error; nonzero |x| < 1e-99 -> 0) before formatting/normalization, hardened decimalParts with finite/range guards and power-of-ten table scaling, capped entries at 12 significant digits or 15 total characters, made typed-entry displayValue/spoken strings reflect the entry on screen, switched visual exponent signs to U+2212, replaced the TS zero placeholder, removed the duplicate CI calculator test step, and noted calculator-swift in the local-only CI comment. Shared fixture now has 109 cases including range floor/underflow/overflow, total entry-length cap, and typed-entry spoken cases. Validation: pnpm --filter @canadian-ham/calculator-engine typecheck passed; pnpm --filter @canadian-ham/calculator-engine test passed (111 tests); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/calculator-swift passed (2 XCTest tests); git diff --check passed.

Round 3 review fix pass started: implement bounded display formatting rule, decimal-literal power tables, display-bound fixture/fuzz checks, and sign-excluded entry cap.

Round 3 fixes: implemented the requested display-length rule (fixed/scientific classification after 12-significant-digit rounding, scientific output with 10-digit mantissa, display ≤16 code points), changed power tables to decimal-literal parsing, made the 15-character entry cap exclude the sign so ± respects it, and added fixture/test assertions for the display bound. Added seeded fuzz tests using the same LCG: TS 50,000 keys and Swift 20,000 keys. Added the review's display-rule fixtures plus the power-table tie and sign-excluded entry-cap fixture. The review's power-table tie placeholder was corrected after verification against both engines: with the required 10-digit scientific mantissa it displays 1e−12, not 1.000000001e−12. Validation: pnpm --filter @canadian-ham/calculator-engine typecheck passed; pnpm --filter @canadian-ham/calculator-engine test passed (126 tests); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/calculator-swift passed (3 XCTest tests); git diff --check passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed round 3 review requests: calculator display output is bounded to 16 code points with the specified fixed/scientific rules, power tables parse decimal literals, entry length excludes the sign, shared fixtures cover the requested cases, and both TS/Swift suites include display-bound checks plus seeded fuzz tests. Verified with TS typecheck, TS tests, Swift package tests, and diff check.
<!-- SECTION:FINAL_SUMMARY:END -->
