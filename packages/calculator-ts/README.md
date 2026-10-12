# @canadian-ham/calculator-engine

Pure TypeScript basic-calculator engine for the in-exam calculator.

Semantics:

- Immediate-execution binary operations evaluate left to right, like a standard pocket calculator. For example, `2 + 3 × 4 =` displays `20`.
- Repeated `=` repeats the last binary operation using the same right operand until a fresh entry, clear, percent or unary operation starts a new current calculation.
- `%` follows the conventional pocket-calculator rule: with `+` or `-`, the displayed entry becomes that percentage of the left operand (`200 + 10 % =` displays `220`); with `×` or `÷`, the displayed entry becomes `entry / 100` (`200 × 10 % =` displays `20`). Without a pending operation, `%` also converts the displayed entry to `entry / 100`.
- `√` and `1/x` show `Error` for square root of a negative value or division by zero. A digit, `C/CE` or `AC` starts a fresh calculation after `Error`.
- Entries accept at most 12 significant digits and 15 total characters excluding the sign, including leading zeroes and the decimal point. Further digits are ignored, and `±` may add a sign without reducing the entry budget.
- The pocket-calculator numeric range is `1e−99 ... < 1e100`: any result or entry with absolute value at least `1e100` shows `Error`, and any nonzero value below `1e−99` becomes `0`.
- Result cleanup cancels near-zero additive/subtractive cancellation only for `+` and `-`, relative to the operands (`max(|left|, |right|) × 1e-14`). Small products, quotients, squares and reciprocals are preserved down to the calculator range floor.
- Display formatting is bounded to 16 Unicode code points: fixed notation uses up to 12 significant digits within the decimal-place rule, scientific notation uses a 10-digit mantissa, and both use platform-independent half-away-from-zero rounding. Negative visual output and exponent signs use a typographic minus (`−`), and decimal separators localize for English (`.`) and French (`,`).
- `displayValue` exposes a structured accessibility-friendly value (`mantissa`, `exponent`, `isNegative`, `isError`, `visual`) plus localized spoken strings in English and French. While typing, the spoken strings match the entry on screen rather than converting to scientific notation.
- State contains only the current calculation: current entry/result, pending operation, repeat-`=` operation, flags, display, and accessibility display value. It does not retain formulas, text notes, or history.

The shared fixture file is `fixtures/calculator/sequences.json`; both this package and `packages/calculator-swift` run it.
