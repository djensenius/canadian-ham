# Lesson review, October 2026 (task-45)

Four independent reviewers scored all 36 Basic lessons against the 14-criterion rubric in [docs/lesson-review-rubric.md](../lesson-review-rubric.md). They checked every claim against the ISED bank and recomputed every number. Full reports:

- [M5 and M4](m5-m4.md)
- [M6 and M3](m6-m3.md)
- [M7 and M8](m7-m8.md)
- [M1 and M2](m1-m2.md)

## Summary

**Accuracy is strong.** Every recomputed calculation is correct and no lesson keys a wrong answer. The real problems are below.

### High: errors and untaught exam content (fix now)

- **Wrong or misleading statements:**
  - L-006-01 says to put the balun at the radio end, which contradicts the bank.
  - L-007-02 gives the wrong reason oblique paths work above the critical frequency.
  - L-001-03's distress row reads backwards ("the station" vs "your station").
  - L-001-04 frames the 29.5 MHz repeater output as if Basic-only holders could transmit below 30 MHz.
  - L-005-05 says permanent magnets are usually steel.
  - L-008-01 offers an attenuator as an equal first cure, which steers learners to a distractor.
  - L-008-01 and L-008-02 define spurious and out-of-band emissions so that they overlap.
- **About 35 covered questions are untaught or answer-key only.** Examples include velocity factor, foam and solid dielectric, the Z0 ratio, standing waves, the dB-adding method, transformer impedance, solar flux at 10.7 cm, particle radiation, tropospheric waves, high-pass filters in L-008-01, and the default public-consultation process. Each report lists the question IDs.
- **No lesson teaches band names as frequencies,** yet M7 and M8 rely on them. The only band table is in M1, which comes last.

### Cross-cutting learnability gaps (all modules)

1. **No real retrieval practice.** Every "Try it" shows its answer on the same line.
2. **No faded practice** (partly worked problems) anywhere, and several "worked examples" are really stories.
3. **No interleaving.** No quiz reuses earlier material.
4. **Weak concept checks.** Many M6 checks are giveaways; M1 and M2 have none; each check has only one generic explanation.
5. **Few diagrams yet.** Task-38 is adding them.
6. **Prerequisites stop at module boundaries,** and the front matter hides real cross-module dependencies.
7. **Some lessons are overloaded:** L-005-04, L-008-01 (about 3 000 words), L-003-08, and L-001-03 (46 quiz items).
8. **M1's reference style mirrors the answer key.** It has one table row per bank question, prose that describes the tables, and quizzes of 33 to 46 items with no retrieval practice before them.
9. **Summaries list bullets instead of synthesizing,** and there is little Canadian specificity in M7 and M8.

### Decisions for the owner

- Restructure M1 around a few principles, with a qualifications-by-privileges matrix, a "Why" column and an M1 numbers board.
- Move M2 from reference style to the explanatory format. Approved 2026-10-12 and implemented in TASK-46.9; see the [before/after taught-facts comparison](m2-explanatory-taught-facts.md).
- Split or move lesson coverage: L-005-04 into AC and dB versus reactance and resonance; M8 into receiver-side versus transmitter-side; B-001-014 into L-001-05; L-004-03 taught first in M4.
- Declare cross-module prerequisites in lesson front matter.
