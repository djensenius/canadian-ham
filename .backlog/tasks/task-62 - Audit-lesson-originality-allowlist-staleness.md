---
id: TASK-62
title: Audit lesson-originality allowlist staleness
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-19 13:14'
updated_date: '2026-10-20 04:05'
labels: []
dependencies: []
ordinal: 137000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-47 review noted that some originality allowlist entries may now be unnecessary after the numeric-overlap heuristic learned to suppress common dB/ratio false positives. Allowlisted blocks are skipped before numeric and near-verbatim checks, so stale entries can hide future regressions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Checker reports or tests identify allowlist entries that no longer suppress any issue
- [ ] #2 Unneeded allowlist entries are removed or justified with current checker output
- [ ] #3 All lesson originality checks still pass after the allowlist audit
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Evaluate allowlisted heading blocks with the unchanged originality rules, report entries that suppress no issues, and fail stale entries (audit the full allowlist for --all; scope partial runs to checked lessons). Add source-named regression tests.
2. Run the full audit, record the before/after entry lists and suppressed-issue evidence, remove every stale entry, and verify specific reasons on all survivors without changing lesson content.
3. Run the requested TypeScript/content checks, record evidence, finalize the task, and commit the focused change for required review before opening the requested PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented the stale-entry audit without changing numeric/near-verbatim thresholds or lesson prose. Allowlisted blocks are evaluated before suppression; the report identifies stale entries, and they fail the check. --all audits every allowlist entry, including missing lessons/headings. Partial runs audit only entries for checked lesson IDs, so unrelated modules do not fail. Duplicate keys are rejected instead of silently replacing an entry/reason. No intentionally stale guard exceptions are retained or supported.

Baseline before checker changes: 37 lesson files, 984 official questions, 44 skipped allowlisted blocks, 0 originality issues. First full audit with the new checker failed as intended: 28 effective entries, 16 stale entries, 0 unallowlisted issues. Empty-allowlist run reports 66 findings; every retained entry suppresses at least one. All 28 retained reasons now name the exact current source question IDs and issue types in addition to the content-specific justification.

Before allowlist (44 entries):
- L-005-04: Decibels as power ratios
- L-006-02: In the real world: reflected-power estimates
- L-006-01: In the real world: cutting coax does not change Z0
- L-006-01: Coaxial cable
- L-006-01: In the real world: TV coax and radio coax
- L-006-01: Try it
- L-006-01: Summary
- L-005-05: Resonance and tuned circuits
- L-002-01: Reference fact: ITU phonetic alphabet words used in this lesson
- L-002-01: Reference fact: voice calling patterns
- L-002-02: Reference fact: Morse calling patterns
- L-002-02: Reference fact: Morse procedural groups
- L-002-02: Reference fact: signal-report digits used in this lesson
- L-002-02: Reference fact: Q signals used and compared in this lesson
- L-002-03: Reference fact: priority terms in this lesson
- L-002-04: Reference fact: grid locator code length
- L-002-04: Reference fact: map and bearing relationships
- L-001-01: Reference facts: Authority and source roles
- L-001-01: Reference facts: Certificate records, addresses, and call-sign fees
- L-001-01: Reference facts: Offences, penalties, and process boundaries
- L-001-01: Reference facts: Basic eligibility, qualifications, exams, and accommodations
- L-001-02: Reference facts: Work done for another person
- L-001-02: Reference facts: Amateur service boundaries
- L-001-02: Reference facts: Communications that fit amateur radio
- L-001-02: Reference facts: Station privileges and construction
- L-001-02: Reference facts: Control operator and station owner
- L-001-03: Reference facts: Interference and shared bands
- L-001-03: Reference facts: Emergency, disaster, and public-service communication
- L-001-03: Reference facts: Privacy, payment, and message handling
- L-001-03: Reference facts: Station identification
- L-001-05: Reference facts: Third-party and visiting-operator communication
- L-001-04: Reference facts: Operator privileges and below-30-MHz access
- L-001-04: Reference facts: HF band ranges
- L-001-04: Reference facts: Bandwidth and mode-fit cues
- L-001-04: Reference facts: Power quantities and limits
- L-001-04: Reference facts: Repeaters, automatic transmissions, stability, and modulation quality
- L-001-05: Reference facts: International message purpose and regulatory source
- L-001-05: Reference facts: ITU regions and operating location
- L-001-05: Reference facts: United States and CEPT-style visits
- L-001-06: Reference facts: Antenna siting and public consultation
- L-001-06: Reference facts: Safety Code 6 and RF exposure
- L-001-06: Reference facts: EMCAB-2 interference criteria
- L-001-06: Summary
- L-006-05: Dipole patterns

Removed as stale (16 entries, each suppresses zero issues under current rules):
- L-006-02: In the real world: reflected-power estimates
- L-002-01: Reference fact: ITU phonetic alphabet words used in this lesson
- L-002-02: Reference fact: Morse procedural groups
- L-002-02: Reference fact: signal-report digits used in this lesson
- L-002-02: Reference fact: Q signals used and compared in this lesson
- L-002-03: Reference fact: priority terms in this lesson
- L-002-04: Reference fact: grid locator code length
- L-002-04: Reference fact: map and bearing relationships
- L-001-01: Reference facts: Authority and source roles
- L-001-01: Reference facts: Basic eligibility, qualifications, exams, and accommodations
- L-001-02: Reference facts: Amateur service boundaries
- L-001-02: Reference facts: Communications that fit amateur radio
- L-001-03: Reference facts: Station identification
- L-001-05: Reference facts: International message purpose and regulatory source
- L-001-05: Reference facts: ITU regions and operating location
- L-001-06: Reference facts: EMCAB-2 interference criteria

After allowlist (28 entries), with current suppressed-issue evidence:
- L-005-04: Decibels as power ratios — B-005-008-011 (numeric-overlap)
- L-006-01: In the real world: cutting coax does not change Z0 — B-006-001-006 (numeric-overlap)
- L-006-01: Coaxial cable — B-006-001-006 (numeric-overlap)
- L-006-01: In the real world: TV coax and radio coax — B-006-001-006 (numeric-overlap)
- L-006-01: Try it — B-006-001-006 (numeric-overlap)
- L-006-01: Summary — B-006-001-006 (numeric-overlap)
- L-005-05: Resonance and tuned circuits — B-005-012-001 (five-gram-overlap), B-005-012-010 (five-gram-overlap)
- L-002-01: Reference fact: voice calling patterns — B-002-003-002 (five-gram-overlap)
- L-002-02: Reference fact: Morse calling patterns — B-002-005-002 (five-gram-overlap)
- L-001-01: Reference facts: Certificate records, addresses, and call-sign fees — B-001-002-009 (numeric-overlap), B-001-002-001 (five-gram-overlap), B-001-002-008 (five-gram-overlap)
- L-001-01: Reference facts: Offences, penalties, and process boundaries — B-001-003-001 (five-gram-overlap)
- L-001-02: Reference facts: Work done for another person — B-001-005-006 (five-gram-overlap)
- L-001-02: Reference facts: Station privileges and construction — B-001-008-003 (five-gram-overlap), B-001-008-005 (five-gram-overlap), B-001-008-006 (five-gram-overlap), B-001-008-008 (five-gram-overlap)
- L-001-02: Reference facts: Control operator and station owner — B-001-009-001 (five-gram-overlap), B-001-009-003 (five-gram-overlap), B-001-009-004 (five-gram-overlap), B-001-009-005 (five-gram-overlap), B-001-009-009 (five-gram-overlap)
- L-001-03: Reference facts: Interference and shared bands — B-001-010-004 (five-gram-overlap), B-001-010-010 (five-gram-overlap)
- L-001-03: Reference facts: Emergency, disaster, and public-service communication — B-001-011-004 (five-gram-overlap), B-001-011-005 (five-gram-overlap), B-001-011-010 (five-gram-overlap)
- L-001-03: Reference facts: Privacy, payment, and message handling — B-001-012-001 (five-gram-overlap)
- L-001-05: Reference facts: Third-party and visiting-operator communication — B-001-014-006 (five-gram-overlap)
- L-001-04: Reference facts: Operator privileges and below-30-MHz access — B-001-015-003 (numeric-overlap)
- L-001-04: Reference facts: HF band ranges — B-001-015-005 (numeric-overlap), B-001-015-006 (numeric-overlap), B-001-015-007 (numeric-overlap), B-001-015-008 (numeric-overlap), B-001-015-009 (numeric-overlap), B-001-015-010 (numeric-overlap), B-001-016-002 (numeric-overlap)
- L-001-04: Reference facts: Bandwidth and mode-fit cues — B-001-015-010 (numeric-overlap), B-001-016-001 (numeric-overlap), B-001-016-002 (numeric-overlap), B-001-016-003 (numeric-overlap), B-001-016-004 (numeric-overlap), B-001-016-005 (numeric-overlap), B-001-016-006 (numeric-overlap), B-001-016-006 (five-gram-overlap)
- L-001-04: Reference facts: Power quantities and limits — B-001-017-004 (numeric-overlap), B-001-017-005 (numeric-overlap), B-001-017-006 (numeric-overlap), B-001-017-003 (five-gram-overlap)
- L-001-04: Reference facts: Repeaters, automatic transmissions, stability, and modulation quality — B-001-018-001 (five-gram-overlap), B-001-018-002 (five-gram-overlap)
- L-001-05: Reference facts: United States and CEPT-style visits — B-001-021-009 (five-gram-overlap)
- L-001-06: Reference facts: Antenna siting and public consultation — B-001-023-003 (five-gram-overlap), B-001-023-006 (five-gram-overlap), B-001-023-009 (five-gram-overlap), B-001-023-010 (five-gram-overlap)
- L-001-06: Reference facts: Safety Code 6 and RF exposure — B-001-024-003 (numeric-overlap), B-001-024-010 (numeric-overlap), B-001-024-001 (five-gram-overlap), B-001-024-002 (five-gram-overlap), B-001-024-004 (five-gram-overlap), B-001-024-005 (five-gram-overlap)
- L-001-06: Summary — B-001-024-010 (numeric-overlap)
- L-006-05: Dipole patterns — B-006-012-004 (numeric-overlap)

Post-prune all-lessons check: 37 lesson files, 984 official questions, 28 effective entries, 0 stale entries, 0 issues. M5-only check: 6 lesson files, 2 effective entries, 0 stale entries, 0 issues; entries for other modules are not falsely reported. Targeted originality tests: 37/37 passed, including nine new allowlist regression tests. Content-tools typecheck and git diff --check passed.
<!-- SECTION:NOTES:END -->
