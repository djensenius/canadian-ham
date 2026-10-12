# @canadian-ham/calculator-engine

Pure TypeScript basic-calculator engine for the in-exam calculator.

Semantics:

- Immediate-execution binary operations evaluate left to right, like a standard pocket calculator. For example, `2 + 3 × 4 =` displays `20`.
- Repeated `=` repeats the last binary operation using the same right operand.
- `%` follows the conventional pocket-calculator rule: with `+` or `-`, the displayed entry becomes that percentage of the left operand (`200 + 10 % =` displays `220`); with `×` or `÷`, the displayed entry becomes `entry / 100` (`200 × 10 % =` displays `20`). Without a pending operation, `%` also converts the displayed entry to `entry / 100`.
- `√` and `1/x` show `Error` for square root of a negative value or division by zero. A digit or `AC` starts a fresh calculation after `Error`.
- Display formatting uses about 12 significant digits, switches to scientific notation for very large or small results, and localizes the decimal separator for English (`.`) and French (`,`).
- State contains only the current calculation: current entry/result, pending operation, repeat-`=` operation, flags, and display. It does not retain formulas, text notes, or history.

The shared fixture file is `fixtures/calculator/sequences.json`; both this package and `packages/calculator-swift` run it.
