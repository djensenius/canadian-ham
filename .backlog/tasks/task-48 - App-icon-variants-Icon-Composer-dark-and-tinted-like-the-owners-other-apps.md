---
id: TASK-48
title: >-
  App icon variants: Icon Composer, dark and tinted (like the owner's other
  apps)
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 22:38'
updated_date: '2026-10-13 00:01'
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
- [x] #1 AppIcon.icon and an appiconset with light, dark and tinted variants are wired via apps/apple/project.yml (XcodeGen deterministic) for the iOS/iPadOS/macOS app, matching the owner's other apps
- [x] #2 A preview sheet shows light, dark, tinted and clear renderings on iOS and macOS and the web favicon in light and dark; the owner approves it
- [x] #3 Builds pass for iOS and macOS, App Store validation of icon assets passes (actool), and the web favicon, PWA icons and manifest are updated
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Mirror owner Icon Composer/appiconset structure: inspect existing Apple assets, extend the deterministic renderer to keep the approved light icon unchanged while emitting foreground, dark/tinted, macOS, and preview exports.
2. Install generated Apple assets, add AppIcon.icon, update AppIcon.appiconset metadata, and wire AppIcon.icon/CFBundleIconName/all-icon-assets in apps/apple/project.yml; regenerate XcodeGen twice and verify the second run is clean.
3. Keep tvOS/visionOS layered assets unchanged in structure, update web SVG/PWA maskable icons/manifest links, and regenerate all checked-in icon consumers.
4. Validate with icon asset actool checks, targeted iOS/macOS xbuild builds, web build/audit/tests, then update Backlog notes/ACs (leaving AC #2 unchecked for owner approval) and push the branch.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented and pushed code/assets on branch task-48-icon-variants. AC #1 evidence: AppIcon.icon added at apps/apple/CanadianHam/Resources/AppIcon.icon; AppIcon.appiconset now has light/dark/tinted iOS 1024 images plus owner-style mac-*.png sizes; apps/apple/project.yml wires the .icon resource, CFBundleIconName=AppIcon, ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon, and ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS=YES; XcodeGen was run twice and the project.pbxproj SHA stayed f911d01adbe125fe4dacfec3e30a62ca4720cc82a0b1b2fd7f9c9c785d5c5dfb.
AC #3 evidence: actool iOS and macOS asset compilation passed with no warnings in /tmp/task48-actool-ios.log and /tmp/task48-actool-mac.log; iOS simulator build passed with xbuild for iPhone 17 Pro; macOS arm64 build passed with xbuild; pnpm --filter @canadian-ham/web test -- src/lib/pwa.test.ts passed (15 files/171 tests); pnpm build:web passed; pnpm --filter @canadian-ham/web audit:urls passed.
AC #2 remains unchecked by request: preview sheet is at design/app-icon/exports/variants-preview.png and still needs owner approval.

Review fix 2026-10-12: adjusted AppIcon.icon foreground so ictool-rendered dark/tinted/clear variants are legible, split PWA any icons from padded maskable icons, documented ictool preview dependency/fallback warning, added CFBundleIconName to the CloudKit iOS Info.plist, added design/app-icon/check_icon_assets.py to verify appiconset filenames and icon.json asset references, and reran validation: py_compile/render/check_icon_assets; actool iOS/macOS; pwa test/build/audit; iOS and macOS xbuild builds.

Owner approval recorded 2026-10-12: owner approved design/app-icon/exports/variants-preview.png at commit 9ec17d8, choosing option A; keep the Liquid Glass outline style in dark and tinted.
AC #2 evidence: owner visual approval 2026-10-12, option A, for the preview sheet at design/app-icon/exports/variants-preview.png.
AC #3 evidence after review fixes: python3 -m py_compile design/app-icon/render_icon.py design/app-icon/check_icon_assets.py && python3 design/app-icon/render_icon.py && python3 design/app-icon/check_icon_assets.py passed; actool iOS and macOS passed with no warnings; pnpm --filter @canadian-ham/web test -- src/lib/pwa.test.ts, pnpm build:web, and pnpm --filter @canadian-ham/web audit:urls passed; iOS and macOS xbuild builds passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented task-48 app icon variants. Added and wired AppIcon.icon and AppIcon.appiconset light/dark/tinted/mac fallback assets, kept tvOS and visionOS layered assets, updated web favicon/PWA icons with separate any and maskable manifest entries, added icon metadata validation, and documented the renderer/ictool workflow. Review request changes were fixed, and owner approved the preview on 2026-10-12 (option A: keep Liquid Glass outline style for dark/tinted). Verified with renderer and metadata checks, actool iOS/macOS, web test/build/audit, and iOS/macOS xbuild builds.
<!-- SECTION:FINAL_SUMMARY:END -->
