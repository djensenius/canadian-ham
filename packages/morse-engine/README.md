# packages/morse-engine

TypeScript implementation of the Canadian Morse timing and grading engine. It is intentionally offline-only and has no runtime dependencies.

## Product

The package exposes `@canadian-ham/morse-engine` from `./src/index.ts` for workspace consumers.

Core APIs:

- `farnsworthTiming({ characterWpm, effectiveWpm })` for the ARRL/Bloom Farnsworth formula. Effective speed is clamped to the character speed.
- `profileForName("isedParis")` for the PARIS-calibrated 12/5 profile and `profileForName("ric1Literal")` for RIC-1 literal 0.7 s / 1.7 s spacing.
- `textToTimedMorse(text, profile)` for dot, dash, intra-character gap, inter-character gap, and word-gap timing symbols.
- `validateMorseText` and `weightedCharacterCount` for the RIC-1 section 8.2 character set and section 8.2 word weighting.
- `scoreMorseCopy` for RIC-1 section 8.7 / RIC-3 section 5.2 style edit-distance scoring: wrong, missing, and inserted characters are one error each; five errors or fewer passes.

## Fixture contract

The TypeScript and Swift Morse packages both load the shared JSON fixtures under [`../../fixtures/morse/`](../../fixtures/morse/). These pin the PARIS timing totals, the RIC-1 section 8.2 character set, the synthetic 78-weight RIC-1 section 8.3 sample stand-in, and grading boundaries.

## Local checks

```sh
pnpm --filter @canadian-ham/morse-engine typecheck
pnpm --filter @canadian-ham/morse-engine test
```
