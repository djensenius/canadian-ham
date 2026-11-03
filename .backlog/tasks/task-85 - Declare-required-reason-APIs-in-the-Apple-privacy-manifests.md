---
id: TASK-85
title: Declare required-reason APIs in the Apple privacy manifests
status: Done
assignee:
  - '@worker'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T09:06:00Z'
labels:
  - apple
  - privacy
  - release
milestone: m-0
dependencies: []
priority: high
type: bug
ordinal: 168000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-81 found that the Apple apps now read and write UserDefaults (Morse settings, language and bank selection through standard and persistentDomain(forName:) access, and local iCloud-sync helper keys) while both PrivacyInfo.xcprivacy manifests declare an empty NSPrivacyAccessedAPITypes array. Other required-reason categories are also used: ProcessInfo.systemUptime (system boot time) appears in the watch app (WatchMorsePlayback.swift), DuoPostureProvider.swift and StudyViews.swift, so the watch manifest cannot stay empty. App Store Connect rejects uploads that use required-reason APIs without approved reasons, so this blocks App Store distribution. Choose reasons from actual behaviour; for example, AppleLanguages domain access may not fit CA92.1. See docs/release/privacy-label-evidence.md, Required-reason review: OPEN.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every required-reason API category used by each shipped target (CanadianHam for iOS/iPadOS/macOS, CanadianHamTV, CanadianHamVision, CanadianHamWatch), including linked local packages, is identified against Apple's current documentation, and the rationale is recorded in docs/release/privacy-label-evidence.md
- [x] #2 Each shipped target's PrivacyInfo.xcprivacy declares those categories with Apple-approved reason codes that match the actual behaviour, and declares none the target does not use
- [x] #3 An automated check run in CI fails when Apple app or package sources use a required-reason API spelling that the relevant manifest does not declare
- [x] #4 Release builds made with xbuild for iOS (with the embedded watch app), macOS, tvOS and visionOS contain the expected manifests, confirmed by inspecting the built products
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fetch Apple's required-reason API docs; list categories and approved reason codes verbatim.
2. Inventory required-reason API usage per shipped target (CanadianHam iOS/macOS, CanadianHamTV, CanadianHamVision, CanadianHamWatch) incl. linked local Swift packages, using project.yml target membership.
3. Choose reason codes from actual behaviour; update the shared app manifest and watch manifest (propose per-target manifests + project.yml diff to coordinator if the shared manifest would over-declare).
4. Add scripts/check-apple-required-reasons.mjs + self-test with fixtures; add package.json scripts; report CI steps to coordinator.
5. Update docs/release/privacy-label-evidence.md with the completed review.
6. Validate: check + self-test, pnpm typecheck/test, network/icloud checks, Release xbuild compile-only builds for iOS (with watch), macOS, tvOS, visionOS; inspect built manifests with plutil -p.
7. Record evidence in notes, check verified ACs (AC3 waits for CI wiring), commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Worker evidence (2026-11-03 UTC, commit ff7d7c50):
- Apple docs: describing-use-of-required-reason-api, NSPrivacyAccessedAPIType and NSPrivacyAccessedAPITypeReasons, fetched 2026-11-03. Every category and reason is quoted in docs/release/privacy-label-evidence.md, 'Required-reason API review (TASK-85, 2026-11-03)'.
- Usage, from project.yml membership plus linked package Sources (no use in packages):
  - CanadianHam: UserDefaults and SystemBootTime (StudyViews:758 and DuoPostureProvider:296 systemUptime).
  - TV and Vision: UserDefaults only (MorseTrainerSettings.load()).
  - Watch: SystemBootTime only (WatchMorsePlayback:34).
- Manifests:
  - CanadianHam: UserDefaults [CA92.1] + SystemBootTime [35F9.1].
  - New Platforms/tvOS and Platforms/visionOS manifests: UserDefaults [CA92.1].
  - Watch: SystemBootTime [35F9.1].
  - Tracking stays false; tracking domains and collected data stay empty. plutil -lint OK on all four.
- AppleLanguages: the read uses persistentDomain(forName: bundle ID), the app's own domain only; the value is the user's per-app language choice. Declared CA92.1. The residual risk and remedies are documented as an owner decision point. No app code changed.
- Coordinator must apply: remove the explicit 'CanadianHam/Resources/PrivacyInfo.xcprivacy' (type: file, buildPhase: resources) source entries from CanadianHamTV and CanadianHamVision in apps/apple/project.yml, then regenerate with XcodeGen. Until then, pnpm check:apple-required-reasons fails ('found 2' manifests) and TV/Vision bundle the shared manifest, which over-declares SystemBootTime.
  - Verified on a /tmp scratch copy with that change: XcodeGen regenerated only the TV/Vision resource refs, the check passed, and the Release TV/Vision builds bundle only UserDefaults [CA92.1].
- Checks:
  - pnpm test:apple-required-reasons: passed.
  - pnpm check:apple-required-reasons: fails on this branch only because of the expected 2-manifest error; passes on the scratch copy with the project.yml change.
  - pnpm typecheck, check:apple-network, test:apple-network, check:apple-icloud-gate, test:apple-icloud-gate, check:links: passed.
  - Test guard (bf775940...HEAD): passed.
- xbuild Release builds (derived data /tmp/ch-task85-dd), all BUILD SUCCEEDED:
  - iOS Simulator with embedded watch, macOS, tvOS and visionOS on the branch.
  - tvOS and visionOS again from the scratch project.
  - plutil -p and cmp on the built manifests match their sources.
  - strings/nm on the binaries agree with the per-target categories.
- Watch unit test testIndependentOfflineBundle now asserts the exact SystemBootTime [35F9.1] entry. The watch scheme passed build-for-testing; the targeted test was not run because simulator boots were not allowed.
- AC2 and AC4 are left unchecked until the project.yml change lands and TV/Vision are rebuilt and re-inspected on the branch.
- AC3 is left unchecked until CI runs pnpm test:apple-required-reasons and pnpm check:apple-required-reasons.

Doc drift follow-up (commit dc67a2ea, after coordinator b7877c4d): release-checklist.md required-reason item now points to the completed TASK-85 review (re-run pnpm check:apple-required-reasons and inspect bundled manifests on the release commit). privacy-label-evidence.md: dependency row lists all four local packages (CanadianHam links engine/content/morse/calculator; TV, Vision, Watch link engine/content/morse, verified in apps/apple/project.yml); recorded coordinator decision 2026-11-02 to keep CA92.1 for the app-domain AppleLanguages read, fallbacks retained; check row notes it passes on the branch since b7877c4d. Checker header now states the #if/string-literal limitation (already in the evidence doc). Checks: pnpm check:links -> 'Markdown relative links verified.'; pnpm check:apple-required-reasons -> passed (CanadianHam 53 files SystemBootTime [35F9.1], UserDefaults [CA92.1]; Watch 31 SystemBootTime [35F9.1]; TV 33 and Vision 32 UserDefaults [CA92.1]); pnpm test:apple-required-reasons -> 'passed self-test fixtures.'; git diff --check clean. No xbuild run (coordinator owns TV/Vision Release rebuild and watch test). AC2/AC3/AC4 left for the coordinator.

Coordinator native validation on b7877c4d+ (2026-11-02, xbuild, -derivedDataPath /tmp/ch-task85-dd): Release CanadianHamTV (generic tvOS Simulator) and CanadianHamVision (generic visionOS Simulator) built (exit 0); each .app contains exactly one PrivacyInfo.xcprivacy with NSPrivacyAccessedAPITypes = [UserDefaults CA92.1] only. iOS (with embedded watch) and macOS Release manifests were verified by the worker on the same sources (shared manifest unchanged by b7877c4d). Targeted watch test CanadianHamWatchTests/testIndependentOfflineBundle on Apple Watch Series 12 (42mm) OS 27.0: passed (1 test, 0 failures). pnpm check:apple-required-reasons passes for all four targets with exactly the used categories. AC3 waits for the CI steps (added in b7877c4d) to pass on the PR.

Review fixes (commit 498a7272): (1) check-apple-required-reasons.mjs now fails closed if a shipped target's sources or a linked local package's Sources contain .c/.m/.mm/.cpp/.cc/.cxx/.h/.hpp files (only Swift is scanned); test-only and unlinked-package C files stay allowed. (2) Every shipped manifest must have NSPrivacyTracking=false and present, empty NSPrivacyTrackingDomains and NSPrivacyCollectedDataTypes. Self-test adds 10 fixtures (tracking true/missing, tracking domain listed/missing, collected data type listed/missing, .m in TV, .mm in App, .h in Watch, .c in linked package); a mutation run removing the new logic made all 8 behaviour-specific fixtures fail. (3) Owner sign-off on AppleLanguages -> CA92.1 required before App Store submission: noted in privacy-label-evidence.md decision paragraph, release-checklist.md required-reason item, and TASK-1.7 notes (auto-commit 50bf4dbe). Evidence doc 'What fails' list updated. (4) #if limitation already documented; no change. Checks: pnpm test:apple-required-reasons -> 'passed self-test fixtures.'; pnpm check:apple-required-reasons -> passed (same per-target categories, now '... with approved app reasons, no tracking and no collected data.'); pnpm check:links -> 'Markdown relative links verified.'; git diff --check clean; node scripts/check-test-guard.mjs --base origin/main --head HEAD -> 'Test guard passed: no guarded changes found in 5abb6934...HEAD.' No xbuild run.

PR #1064 Copilot fixes (commit 32c31959): (1) Function references: fstat/lstat/fstatat, statfs/statvfs/fstatfs/fstatvfs and getattrlist family now match as word-bounded identifiers (no '(' needed), so 'let read = Darwin.fstat' counts; bare 'stat' matches only as a call, a C-module-qualified name (Darwin/Glibc/SwiftGlibc/Musl/Foundation/ucrt .stat) or the whole RHS of an assignment, so Swift vars named stat (e.g. morse-swift MorseCourse.swift) do not match. (2) Regex literals: comment stripper now keeps extended #/.../# (multi-line, escapes skipped) and bare /.../ literals following Swift 6 lexer behaviour verified with 'swiftc -swift-version 6 -dump-parse' probes (left-bound division incl. postfix !, keyword exception e.g. return/case, first unescaped / closes, / followed by / or * is a comment, no closing after whitespace). Fails closed on a comment marker straight after a backslash, an unterminated block comment, or an unterminated extended regex. (3) Added .hh/.hxx/.inl/.ipp/.s/.S to the non-Swift list. Self-test: 10 new failing fixtures plus stat-identifier and division/regex trailing-comment lines in the clean fixture; the HEAD (pre-fix) checker fails all 10 new fixtures, and 8 targeted mutations (loose stat, no left-bound, no keyword exception, no backslash guard, no unterminated report, no extended regex, no bare regex, old C list) each fail at least one fixture. Real-tree --verbose evidence is identical before/after (43 call-site lines). Checks: pnpm test:apple-required-reasons -> 'passed self-test fixtures.'; pnpm check:apple-required-reasons -> passed (CanadianHam 53 SystemBootTime [35F9.1], UserDefaults [CA92.1]; Watch 31 SystemBootTime [35F9.1]; TV 33 / Vision 32 UserDefaults [CA92.1]); pnpm check:links passed; git diff --check clean; test guard 'Test guard passed: no guarded changes found in 5abb6934...HEAD.' No xbuild run.

PR #1064 Copilot round 3 (commit 1bf0a0a1a2739129d0bc6f4a61e7f253bb43933d). (1) Module-qualified bypass: the UserDefaults pattern '@AppStorage' missed '@SwiftUI.AppStorage'; it now matches the name AppStorage, covering @SwiftUI.AppStorage, a '@SwiftUI' qualifier with '.AppStorage' on the next line, and AppStorage(wrappedValue:_:) (swiftc -swift-version 6 accepts the qualified forms and rejects '@ AppStorage' and a '(' on the next line). Audit of the other patterns: Foundation.UserDefaults, Foundation.ProcessInfo...systemUptime, Darwin.mach_absolute_time, Foundation.FileAttributeKey.modificationDate, Foundation.URLResourceKey.volumeAvailableCapacity*Key and UIKit.UITextInputMode.activeInputModes were already matched (whole-word names); the only other gap was module-qualified stat with a line break before the '.', fixed below. swiftc rejects whitespace after '.', so no pattern needs it. (2) Multi-line: apiUsage now runs every pattern (flags gm) over the whole comment-stripped file and reports each usage on the line where the match starts (binary search over line offsets), once per spelling and line, sorted by line then pattern, so the evidence order is unchanged. Qualified stat allows whitespace or a line break before the '.', and lookbehinds keep the reported line on 'stat'. The comment/regex stripper is unchanged. Note: swiftc -dump-parse shows 'stat' followed by '(path, ptr)' on the next line is an unapplied reference plus a separate tuple, not a call; it is still matched conservatively. (3) Evidence doc: Scanning/Self-test text updated, and the Limitations now list the bare-stat value uses that are not flagged (apply(stat), return stat, [stat], x ?? stat). Fixtures: @SwiftUI.AppStorage (including the multi-line form); module-qualified spellings in all five categories (checks line order and per-line dedupe); multi-line stat spellings (stat then '(' on the next line, '=' then 'stat' on the next line, Darwin then '.stat', Glibc then '.statfs'); multi-line creationDate/systemUptime; a 'return stat' false-positive guard in the clean fixture. Mutations: the HEAD checker fails the four new or changed fixtures. Each of line-based matching, the qualified stat without a line break, @AppStorage-only, no line sort, no per-line dedupe, an off-by-one line number, and no m flag fails at least one fixture. The real-tree --verbose output is identical before and after (43 evidence lines). Checks: node scripts/test-check-apple-required-reasons.mjs -> 'passed self-test fixtures.'; node scripts/check-apple-required-reasons.mjs -> passed (CanadianHam 53 SystemBootTime [35F9.1], UserDefaults [CA92.1]; Watch 31 SystemBootTime [35F9.1]; TV 33 / Vision 32 UserDefaults [CA92.1]); pnpm typecheck exit 0; pnpm test exit 0 (Vitest 2 files / 23 tests and 18 files / 283 tests passed); pnpm check:links 'Markdown relative links verified.'; git diff --check clean; test guard 'Test guard passed: no guarded changes found in ae1449ad...HEAD.' No xbuild run; AC2-AC4 left to the coordinator.

Coordinator 2026-11-03: AC #3 evidence. CI run 41574255809 on PR #1064 at e343e7c8 ran 'Test Apple required-reason checker' and 'Apple required-reason API check' in the 'Node and content checks' job; both succeeded. Delta review 3 (1bf0a0a1/fd395c79) was approved with notes. Two low notes were accepted without change: a variable named stat can be over-matched at end of line (for example 'return a == stat', or '= stat' followed by '.member' on the next line), and AppStorage matches inside string literals. Both can only add a failure, never hide a use, and nothing in the tree matches today. Merged origin/main 31420c0b (TASK-86, TASK-54 record) cleanly.

PR #1064 review round 4 (commit 425681145d0b6a03d094db685f53c75fe55df3bf, from head d8333100):
- Symlinks (PRRT_kwDOUxZq_M6y-gie): no symbolic links or hidden entries exist under apps/apple or packages/*-swift/Sources, tracked or untracked. walk now fails closed on any symbolic link, for target sources, package Sources and the unmapped-file walk. It also scans hidden files and directories like XcodeGen does, skipping only .DS_Store. Fixtures: symlinked target file, symlinked package directory, symlink outside any target, hidden file and hidden directory.
- Backticks (PRRT_kwDOUxZq_M6y-giq): the stripper lexes a backtick-escaped identifier as one token, so a raw identifier containing // is not a comment. After lexing it rewrites each escaped plain identifier as the bare name plus two spaces, keeping offsets and lines; string and regex contents are untouched. It also checks the stripped length. Fixtures cover File timestamp (.`creationDate`, `stat`( ), Darwin.`stat`, an assignment with `stat` on its own line, a call with ( on the next line), Disk space, User defaults, System boot time and Active keyboards, plus a division-after-escaped-name pass guard.
- Bypass sweep: covered by fixtures are key paths, typealias and let aliases, string literals naming APIs (new: "creationDate", "modificationDate", "stat", "systemFreeSize", "systemSize" and NSURLVolume*CapacityKey raw values) and @_silgen_name. These now fail closed: module maps, API notes, prebuilt code (by extension or Mach-O/universal/ar magic, in target sources and package Sources), shipped-target keys outside an allow-list (preBuildScripts, buildRules, scheme, configFiles, ...), per-file compilerFlags, top-level settingGroups and configFiles, scheme preActions, header/search-path/linker/module-map build settings, non -D OTHER_SWIFT_FLAGS, and Package.swift plugins, macros, system libraries and unsafeFlags. Documented as limitations: run-time-built names (dlsym, computed KVC or selectors), wholesale attribute reads, postBuildScripts, Xcode Cloud ci_scripts, Interface Builder bindings and #if over-declaration. The full table is in docs/release/privacy-label-evidence.md.
- Walk verification: the checker's per-target Swift lists equal the PBXSourcesBuildPhase files in the committed xcodeproj (CanadianHam 32, Watch 11, TV 13, Vision 12). Each package Sources walk equals swift package describe (calculator 1, content 8, engine 10, morse 2).
- Every new check was mutation-tested: each of 23 mutations was killed by its fixture.
- Real-tree --verbose output is byte-identical to d8333100.
- Checks: node scripts/test-check-apple-required-reasons.mjs passed; node scripts/check-apple-required-reasons.mjs passed; pnpm typecheck passed; pnpm test passed; pnpm check:links passed; git diff --check is clean; the test guard passed. No xbuild (script and docs only).
- Follow-up for the coordinator: apps/apple/ci_scripts/canadian-ham-ci.sh CH_GUARD_SCRIPTS (the Xcode Cloud guards) does not include check:apple-required-reasons or test:apple-required-reasons; this was left unchanged as out of scope.

PR #1064 review round 4b (commit 5f3d18d83b34eb89a3caef40ef4d4eeed2552dc6, from 4d60a844):
- project.yml sources paths, package directories and package Sources are now checked with lstat, including every directory between the repository root and them. Each fails closed with the same symbolic-link error the walk uses. Fixtures: symlinked package directory, symlinked package Sources, a symlinked sources path outside apps/apple, and a linked parent directory.
- OTHER_SWIFT_FLAGS "-D FOO" is still rejected, now with a message to use the -DFOO form. Fixture: split -D condition.
- docs/release/privacy-label-evidence.md: the Limitations section now notes that Codable or dictionary keys with a listed name are flagged (rename the key or justify an exception). The symbolic-link and Swift-flag bullets and the bypass table are updated to match.
- Each new check was mutation-tested: 5 of 5 mutations were killed.
- Real-tree --verbose output is byte-identical to 4d60a844.
- Checks: self-test passed; checker passed; pnpm check:links passed; git diff --check clean; test guard passed. No xbuild.

PR #1064 review round 5 (commit c3b38cb6b7061da7a5ab1e243b1a25ed1f505f47, from 1f26dded): (1) folder references (type: folder) and buildPhase: none entries now must exist unless optional, may not be or contain symlinks, and are scanned whole (including asset catalogues, ignoring excludes) for prebuilt code by extension and Mach-O/universal/ar magic; their Swift files are not counted as compiled and nested PrivacyInfo.xcprivacy files are not taken as the target manifest. Real tree: 6 shipped content/ folder refs, 2,059 files (2,010 JSON, 49 Markdown), no prebuilt code, links or buildPhase: none entries. (2)+(3) replaced the manifest parser with a strict typed XML plist parser: data/date/integer/real values, wrong types for categories/reasons/tracking/arrays, duplicate keys, keys without values, unknown top-level or entry keys, empty or whitespace-padded codes, unknown entities, CDATA, comments inside text, processing instructions, attributes, other DOCTYPEs, missing root, trailing content, binary/JSON/non-UTF-8 plists and non-dict roots fail closed; equivalent forms Apple reads the same (BOM, no XML declaration, older Apple Computer DOCTYPE, comments between elements, character references, <false></false>, <array></array>) pass. Behaviour chosen from plutil -convert json probes. Fixtures added for each case; 23/23 mutations killed. Evidence doc: scope, manifest parsing, what-fails, bypass table (3 rows), limitations and evidence row updated. Checks: self-test passed; real-tree --verbose output byte-identical to 1f26dded; check passed (same 4 targets/categories); pnpm typecheck passed; pnpm test passed (vitest 23 + 283, node 250 + 127, 0 failed); check:links passed; check:shell passed (12 files); git diff --check clean; test guard passed. No xbuild. Final summary updated for folder refs and typed parser.

PR #1064 round 6 (commit 0b444a41d0b175e7913730db54a660a0a75c9ae0), from ef183642:
- Copilot PRRT_kwDOUxZq_M6y_bNx: BINARY_MAGIC adds cafebabf/bfbafeca (universal 64-bit), plus thin archives (!<thin>), LLVM bitcode (BC\xC0\xDE) and its wrapper (0x0B17C0DE), and binary .swiftmodule (e29ca80e). By name: .app bundles, .swiftmodule (file or directory), .tbd and .swiftinterface. .pch, .ll and module.map fail as unscanned sources. Fixtures cover all 13 magic values and every name.
- Copilot PRRT_kwDOUxZq_M6y_bOM: ordinary target and package walks now traverse .xcassets/.icon/.xcstrings for prebuilt code, links and special files, without counting their Swift, headers or nested manifests. Fixtures cover target and package catalogues.
- Pruning sweep:
  - .DS_Store is no longer skipped.
  - Excluded paths are still scanned for binaries and links; exclude wildcards never match a leading dot; unmodelled glob syntax fails.
  - Source type and buildPhase are allow-listed (syncedFolder and frameworks fail).
  - Only a manifest copied flat to the bundle root counts (not copyFiles, headers, type: file directories, .lproj or bundles).
  - FIFOs and other special files fail inside walks and as entry paths (test harness timeout added).
  - `..` in Package.swift fails.
  - The unmapped walk ignores catalogue Swift.
- The evidence doc has a pruning-point table, a native-format table (ELF, wasm, scripts, zip/tar, Metal, .pcm/.gch left out, with reasons), new bypass rows, limitations and a round 6 evidence row.
- Mutation testing: 43/43 mutants killed.
- Checks:
  - node scripts/test-check-apple-required-reasons.mjs passed;
  - node scripts/check-apple-required-reasons.mjs passed, with --verbose output byte-identical to ef183642 (about 0.5 s);
  - pnpm typecheck passed;
  - pnpm test passed (283 tests);
  - pnpm check:links passed;
  - pnpm check:shell passed (12 files);
  - git diff --check was clean;
  - the test guard passed.
- No xbuild was run.

Round 7 (PR #1064, Copilot thread PRRT_kwDOUxZq_M6y_3uM plus a full parser sweep), commit 591c70fc76046c0c1ad61e19cf258d75782b4d5c:
- Replaced the project.yml reader with a strict YAML subset. Double-quoted escapes other than \\ and \" fail, so "OTHER\u005fLDFLAGS" can no longer bypass checkBuildSettings. Mappings have no prototype. Duplicate keys, merge and complex keys, anchors, aliases, tags, document markers, directives, multi-line scalars, multi-line or nested flow collections, flow mappings other than {}, block scalar indicators, tabs, non-ASCII, a lone CR, include, ${VAR} outside script values, $ in sources paths, platform lists, dependencies with more than one kind and remote package keys all fail closed. Plain values keep their YAML 1.1 types; optional counts only as boolean true.
- Each linked Package.swift is read with a strict grammar. These fail: raw, escaped, interpolated and multi-line strings, #if, variables, helpers, type-qualified members, .map, operators, extra imports and statements, Package@swift-*.swift manifests and other SwiftPM source roots.
- Fixtures cover every case; the self-test passes. All 65 mutations of the new checks were killed (2 defence-in-depth survivors are already covered by mappings without a prototype).
- Real tree: same parse structure. Only value types and the script text changed, and the checker reads none of them. --verbose output is byte-identical to round 6, at about 0.4–0.5 s.
- The evidence doc has a parsing step, a parser row group in the bypass table and Limitations text.
- Checks: self-test, checker, pnpm typecheck, pnpm test, check:links, check:shell, git diff --check and the test guard all pass.

Round 7 follow-up, commit defd3273a2e1f55b1756ab78fc6bdabad3188b2b: added fixtures for anchors, tags and %TAG directives (fail), a plain key holding ': ' (fail), a quoted key holding ': ' (read as one key, then caught by the build-setting check) and a key starting with '-' (a plain key, as Yams reads it). 7 more mutations were all killed (72 in total for round 7). The self-test, checker, check:links, git diff --check and the test guard pass.

PR #1064 round 7b (afb8718b8498172bae173f81811678f577db4a9e): replaced the project.yml denylist with an allowlist, PROJECT_SHAPE and TARGET_SHAPE, of exactly the keys the real file uses, plus the modelled sdk dependency. Allowed: top-level name, options (bundleIdPrefix, deploymentTarget, developmentLanguage, knownRegions, createIntermediateGroups), configs, packages, settings (base and configs only), targets and schemes (build.targets; test gatherCoverageData, testPlans path/defaultPlan, targets as strings); target type, platform, supportedDestinations, deploymentTarget, sources, dependencies, settings and postBuildScripts (name, script string, basedOnDependencyAnalysis, inputFiles, outputFiles); dependency target, package, sdk, product, embed and destinationFilters.
- Any other key fails with apps/apple/project.yml:<line>, as do wrong value shapes. Fixtures cover projectReferences, options.pre/postGenCommand, targetTemplates/templates/schemeTemplates, aggregateTargets, fileGroups, localPackages, configFiles (no .xcconfig files exist, so fail closed), settingGroups/settings groups/flat settings, scheme pre/post-actions and run/profile/analyze/archive, target scheme, buildToolPlugins, buildRules, pre-build and post-compile scripts, script files and shells, and dependency link/weak/codeSign/copy/root.
- target: dependencies must be defined in project.yml (cross-project Project/Target fails), and shipped targets may depend only on shipped targets. sdk: must be a bare .framework or .tbd name.
- Sources and package paths are compared component by component with on-disk names, so a wrong-case (optional) path fails on both macOS and Linux.
- Docs: allowlist table with a justification per key, maintenance rule, pruning, bypass and Limitations rows, and a round 7b Evidence row.
- Checks: self-test passes; 41/41 mutants killed. Real-tree --verbose output is byte-identical (about 0.4-0.5 s). pnpm typecheck, pnpm test (283 passed), check:links, check:shell, git diff --check and the test guard all pass.

PR #1064 round 7c (reviewer REQUEST CHANGES on 9ec9afb6..96ac971b), commit 8fefd3027232d2929218f0715b91499d35d8a6b9:
- Build settings in the project and shipped targets (base, every configs entry, [sdk=]/[arch=] variants matched on the base name) are now an exact-name allowlist of the 37 names the real project.yml uses, each with a value rule. INFOPLIST_FILE and CODE_SIGN_ENTITLEMENTS must be relative paths to existing regular .plist or .entitlements files with no link and the exact case; OTHER_SWIFT_FLAGS keeps the -D-only rule. Unknown settings and unmodelled key forms fail with file:line. Test-target settings stay unchecked (BUNDLE_LOADER and TEST_HOST appear only on CanadianHamTests).
- Sweep: Package.swift labels, members and strings are allowlisted (the regex denylist is removed); shipped and package sources may hold only Swift and five inert data types (.json, .strings, .xcstrings, .entitlements, .xcprivacy) in every phase; the shipped target type is application only; sources and package paths must fit the modelled relative form; a missing non-optional path fails in every phase.
- Doc: build-setting allowlist table, corrected post-build script wording (after link but before signing; reviewed by hand, binary inspection cross-checks), bypass rows, Limitations (working tree vs xcodeproj, clean-checkout releases) and a round 7c Evidence row.
- Checks: self-test passed; real-tree --verbose byte-identical to 96ac971b (0.38 s); every allowlist entry, label, member and data type is needed by the real tree; 89/89 mutations killed (no-op control survives); pnpm typecheck, pnpm test (283 web tests plus packages), check:links, check:shell, git diff --check and the test guard passed.

PR #1064 round 7c follow-up (reviewer APPROVE WITH NOTES), commit f7bb6d17cefbd28d6bec923c2dcb4aaf30c9c8d2: rewrote the stale comment above checkSwiftFlags (exact-name allowlist with a value rule per setting, base and configs only, conditional keys matched on the name before [). Added a Limitations sentence: INFOPLIST_FILE and CODE_SIGN_ENTITLEMENTS are checked for path and file type, not contents (LSEnvironment DYLD_*, library-validation entitlements); a bundled library is still rejected as prebuilt code; the project does not set ENABLE_HARDENED_RUNTIME, so that is not relied on; the iCloud gate allowlists the CloudKit entitlements keys and checks the default macOS entitlements only for iCloud/push/background-mode keys, so other content is reviewed by hand. Checks: self-test passed; real-tree --verbose byte-identical to b2c359dc; check:links and git diff --check passed.

Round 8 (Copilot PRRT_kwDOUxZq_M6zB6pw, PRRT_kwDOUxZq_M6zB6qM; commit e0b916eda813ae57513b54e6e25bb7c7dc613738): the Swift scanner now lexes as swiftc 6.4.2 does, verified with xcrun swiftc -typecheck and compiled probes. CR and CRLF become LF before lexing (comments end and file:line counts match Swift); a leading BOM is skipped; invalid UTF-8, VT/FF/NEL/U+2028/U+2029/NUL/DEL/C0 controls and non-ASCII code (NFD, KELVIN SIGN, zero-width, NBSP, stray BOM, backticks) fail closed. String literals are decoded (\u{1-8 hex}, \0 \\ \t \n \r \" \', raw-string delimiters, multi-line continuations and indentation), literal-only interpolations inlined and + joins of literals chained, then matched as well as the raw text; a decoded NUL ends an exact name and U+212A/U+037E/U+1FEF read as ASCII; unsupported escapes fail closed. Selector, key-path, #if and #sourceLocation forms were already covered (fixtures added). Names built from variables, calls, +=, joined() or non-literal interpolations stay a documented limitation. Checks: self-test passed; real-tree --verbose output byte-identical (48 lines, 0.38 s); 39 mutations, 38 killed after tightening two fixtures, 1 message-only survivor, no-op control passes; pnpm typecheck, pnpm test (one unrelated web test failed once, then passed on two reruns), check:links, check:shell, git diff --check and the test guard pass.

Round 8 review note (docs only): the lexing step and the run-time-name limitation now name casts (`("system" as String) + "Uptime"`) and initialiser or other calls around the literal after the `+` (`"system" + String("Uptime")`), which end a literal join. A probe of the current lexer shows that the look-back skips a closing `)`, so `f("system") + "Uptime"` and `String("system") + "Uptime"` are joined and matched. This only adds matches for names matched anywhere in a string. It can hide one exact-name case: an escaped name as a call's last argument followed by `+` and a literal (`k("st\u{61}t") + "x"` is read as "statx"). The plain `k("stat") + "x"` is still matched by the raw scan. This is documented; the code is unchanged. pnpm check:links and git diff --check pass.

Round 8 review follow-up (commit e1cac7f53cf3984ac898fe2eba0f51fb57bfdbb8): every decoded string literal is now also matched on its own, with every pattern, as well as in chains of two or more. The join's look-back skips a call's closing `)`, so `k("st\u{61}t") + "x"` (exact name) and `k("system\u{55}ptime") + "x"` (whole-word name) were missed before; both are now caught, and a join can only add matches. New fixtures: escaped, raw and multi-line call arguments before a join (fail), the whole-word case (fail), and literals holding only part of an exact name (pass). The previous checker fails exactly the two new fail fixtures; four mutations of the change are all killed and the no-op control passes. Self-test passed; real-tree --verbose output byte-identical; pnpm typecheck, pnpm check:links, git diff --check and the test guard pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Declares Apple required-reason API usage for every shipped target and enforces it in CI.

- PrivacyInfo.xcprivacy for CanadianHam (iOS/iPadOS/macOS), CanadianHamTV, CanadianHamVision and CanadianHamWatch declare only the categories each target uses: UserDefaults CA92.1 (app, TV, Vision) and SystemBootTime 35F9.1 (app, Watch). NSPrivacyTracking is false, with no tracking domains or collected data. Linked local packages are included.
- docs/release/privacy-label-evidence.md records:
  - the per-target rationale against Apple's current required-reason list;
  - how scanning works and what fails;
  - the project.yml key allowlist and the build-setting allowlist, with a justification and value rule for each entry and the maintenance rule;
  - a table of bypass classes, each covered, failing closed or listed as a limitation;
  - tables of every pruning point and every native-code format, with the formats left out and why;
  - verification that the walk matches the committed project and SwiftPM.
- scripts/check-apple-required-reasons.mjs runs in CI with its self-test. It fails when shipped target or linked package sources use an undeclared required-reason spelling. It also fails closed on:
  - file types outside an allowlist of Swift and five inert data types (so C-family, assembly, module maps, Metal, lex/yacc/MIG, Interface Builder, Core Data and similar fail), and prebuilt code (Mach-O, universal 32/64, ar and thin archives, LLVM bitcode, Swift modules and interfaces, text stubs, code bundles), including inside folder references, buildPhase: none entries, excluded paths and resource catalogues;
  - symbolic links, special files, missing non-optional sources paths in any phase, sources or package paths outside the modelled relative form, and paths that differ from the disk only in letter case;
  - project and shipped-target build settings outside an exact-name allowlist of the 37 names the real file uses, or with a value outside the entry's rule (linker, compiler, search-path, tool-path and plugin settings all fail; OTHER_SWIFT_FLAGS may hold only -D conditions);
  - project.yml keys outside an allowlist of the keys the real file uses, reported with file:line (scripts other than post-build, templates, xcconfig files, scheme actions, setting groups, project references and others); target types other than application; cross-project, undefined or test-target dependencies of shipped targets; and sdk paths;
  - Package.swift labels, members and strings outside an allowlist of what the real manifests use (custom paths, resources, excludes, C and linker settings, unsafe flags, plugins, macros, binary or system targets, dynamic products, package dependencies);
  - project.yml outside a strict YAML subset (unmodelled escapes, duplicate or prototype-style keys, anchors, merge keys, document markers, multi-line scalars, include, ${VAR} outside scripts, $platform and multi-platform targets), and Package.swift outside a strict grammar (raw, escaped, interpolated or multi-line strings, #if, variables, helpers, .map, version-specific manifests, other source roots);
  - unknown targets, and targets without exactly one manifest copied to the bundle root;
  - manifests that track, have unknown or duplicate keys, use the wrong plist value types or padded codes, or fall outside the XML plist subset Xcode writes (strict typed parser).
- Matching covers module-qualified, multi-line and backtick-escaped spellings, key paths, selectors, aliases, API-name string literals, the whole word for C names, Swift 6 regex literals and comments. Swift files are read as swiftc reads them: CR, LF and CRLF line endings, a skipped leading BOM, and string literals decoded (Unicode and simple escapes, raw strings, multi-line continuations, literal-only interpolations and + joins of literals) and matched as well as the raw text. Invalid UTF-8, control and Unicode line-separator characters, non-ASCII code and unsupported escapes fail closed; names built at run time from variables or calls remain a documented limitation.
- Release xbuild products for iOS (with the embedded watch app), macOS, tvOS and visionOS contain the expected manifests.

Verification: the self-test passes, as does the checker on the real tree (same categories before and after each round). Every new check is mutation-tested. pnpm typecheck, pnpm test, check:links, check:shell and the test guard pass. CI ran both required-reason steps green.

Owner follow-up: sign off on the AppleLanguages read under CA92.1 before App Store submission (noted on TASK-1.7). Post-build script text is reviewed by hand, with binary inspection as the cross-check.
<!-- SECTION:FINAL_SUMMARY:END -->
