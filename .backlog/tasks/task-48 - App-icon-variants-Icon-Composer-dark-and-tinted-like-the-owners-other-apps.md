---
id: TASK-48
title: >-
  App icon variants: Icon Composer, dark and tinted (like the owner's other
  apps)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 22:38'
updated_date: '2026-10-12 22:39'
labels:
  - apple
  - web
  - design
dependencies: []
priority: medium
ordinal: 112000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-10-12: add dark-mode and other icon variants, matching the owner's other apps (Art/FluxKlang, Art/Telephone-Booth): an Icon Composer AppIcon.icon (brushstroke foreground layer on a cream gradient fill, glass on, individual lighting, layer-colour shadow) giving Liquid Glass light/dark/clear/tinted on iOS/iPadOS/macOS 26+, plus an AppIcon.appiconset fallback with light, dark and tinted 1024 images and macOS sizes. Keep the existing Yagi brush design (design/app-icon). tvOS layered icons and the visionOS solid image stack stay as they are unless a dark variant is supported. Web: dark-scheme favicon (SVG prefers-color-scheme) and maskable PWA icon. Visual result needs owner approval from a preview sheet before merge.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 AppIcon.icon and an appiconset with light, dark and tinted variants are wired via apps/apple/project.yml (XcodeGen deterministic) for the iOS/iPadOS/macOS app, matching the owner's other apps
- [ ] #2 A preview sheet shows light, dark, tinted and clear renderings on iOS and macOS and the web favicon in light and dark; the owner approves it
- [ ] #3 Builds pass for iOS and macOS, App Store validation of icon assets passes (actool), and the web favicon, PWA icons and manifest are updated
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Mirror owner Icon Composer/appiconset structure: inspect existing Apple assets, extend the deterministic renderer to keep the approved light icon unchanged while emitting foreground, dark/tinted, macOS, and preview exports.
2. Install generated Apple assets, add AppIcon.icon, update AppIcon.appiconset metadata, and wire AppIcon.icon/CFBundleIconName/all-icon-assets in apps/apple/project.yml; regenerate XcodeGen twice and verify the second run is clean.
3. Keep tvOS/visionOS layered assets unchanged in structure, update web SVG/PWA maskable icons/manifest links, and regenerate all checked-in icon consumers.
4. Validate with icon asset actool checks, targeted iOS/macOS xbuild builds, web build/audit/tests, then update Backlog notes/ACs (leaving AC #2 unchecked for owner approval) and push the branch.
<!-- SECTION:PLAN:END -->
