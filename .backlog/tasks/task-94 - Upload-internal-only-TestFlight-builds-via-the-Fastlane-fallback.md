---
id: TASK-94
title: Upload internal-only TestFlight builds via the Fastlane fallback
status: In Progress
assignee:
  - '@coordinator'
created_date: '2026-11-05T13:29:00Z'
labels:
  - release
  - apple
  - owner-gate
dependencies:
  - TASK-93
references:
  - docs/release/testflight.md
  - docs/release/distribution.md
documentation:
  - docs/release/owner-gates.md
priority: high
type: chore
ordinal: 177000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-11-05 08:24: "Can you push a release that's ONLY eligible for internal testflight for now?" App Store-eligible uploads stay blocked until TASK-1.7, and the 2026-10-27 TestFlight builds (iOS 202610271751, macOS 202610271753, tvOS 202610271756, visionOS 202610271757) predate the new required-reason privacy manifests. The repository's temporary internal-only fallback (`fastlane <platform> beta distribution:false`) needs separate explicit owner authorization before any upload, which this request supplies. Builds are internal-only (`testFlightInternalTestingOnly`), include the official ISED reference sheet under owner decision 2A, and cannot be used for external testing or App Store submission. TASK-14.6 AC#4 and the owner device checks in docs/release/owner-gates.md depend on a processed build existing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Signed internal-only exports for iOS (with the embedded watch app), macOS, tvOS and visionOS are built from the accepted main commit with `distribution:false` and inspected before any upload: signing identity and team, `testFlightInternalTestingOnly` true, no iCloud/CloudKit/push entitlements, privacy manifests present, and the watch build number matching the phone.
- [ ] #2 Each inspected build is uploaded with `distribute_external:false` and reaches a processed VALID state in App Store Connect, verified read-only; no external group, public link, App Store submission, Xcode Cloud workflow or App Store Connect setting is created or changed.
- [ ] #3 The uploaded build numbers are recorded in `apps/apple/ci_scripts/build-number-floors` and the docs/release/distribution.md floor table through a merged PR, and the Xcode Cloud script checks pass.
- [ ] #4 Generated archives, exports and derived data are removed, and the outcome (build numbers, what the builds include, limitations and the owner install/hardware checks still outstanding) is recorded in the task.
<!-- AC:END -->
