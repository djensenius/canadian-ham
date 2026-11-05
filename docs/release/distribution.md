# App Store distribution and Xcode Cloud

Status: TASK-86 preparation and TASK-93 packaging defaults. No upload is authorized by this preparation. Xcode Cloud is preferred; the owner connects/configures it and triggers builds. Fastlane defaults to App Store-eligible packaging for local export-only checks; its explicit internal-only mode remains a temporary, separately authorized fallback ([TestFlight runbook](testflight.md)). Use this with the [release checklist](release-checklist.md).

## Gates

- Internal team-member TestFlight is the only eligible delivery now (TASK-1.10 exception), not upload authorization. Merge or review approval and internal tester eligibility do not authorize uploads or release-workflow triggers. Agents must not automatically upload or trigger workflows, including after merges; any agent-run upload requires separate explicit owner authorization and all existing gates.
- External TestFlight testing, App Store submission and any upload of a distribution build (one without `testFlightInternalTestingOnly`) wait for both:
  - **TASK-1.7** and the release gates it depends on (ISED permission in TASK-1.1, the release-candidate pass in TASK-1.6 and the [release checklist](release-checklist.md#store-submission)); and
  - **TASK-85**: required-reason API declarations in every `PrivacyInfo.xcprivacy`. App Store Connect rejects uploads without them.
- TASK-85 is Done; TASK-1.7 is not. The default App Store-eligible beta export therefore cannot be uploaded, even for internal testers. Packaging eligibility grants no upload, submission or release authorization.
- Only the owner creates or edits Xcode Cloud workflows, App Store Connect settings, testers and groups, and triggers Xcode Cloud builds. Agents never do.
- Every archive, local or Xcode Cloud, uses the **Release** configuration. Never archive or distribute `DebugCloudKit`; v1 has no iCloud, CloudKit or push capability.

## What is in the repository

| Item | Purpose |
| --- | --- |
| `fastlane/ExportOptions.plist` | Legacy internal-only export (`testFlightInternalTestingOnly`). Used only with explicit `distribution:false`. |
| `fastlane/ExportOptions-AppStore.plist` | Default for every `beta` lane: App Store-eligible export, `app-store-connect`, automatic signing, team `9JALHNGRBQ`, no internal-only flag. Omitted `distribution` means `true`. |
| `apps/apple/ci_scripts/` | Xcode Cloud custom build scripts and the per-platform build-number floors (see [Xcode Cloud scripts](#xcode-cloud-scripts) and [Build numbers](#build-numbers)). |
| `scripts/test-xcode-cloud-ci-scripts.sh` | Local dry run of the Xcode Cloud scripts with simulated `CI_*` variables. |

## Fastlane distribution export (fallback and local check)

Every `beta` lane defaults to App Store-eligible packaging (`distribution:true`), which still requires `export_only:true` while the upload gates remain:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane ios beta export_only:true       # .ipa with Watch/CanadianHamWatch.app
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane mac beta export_only:true       # .pkg
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane appletvos beta export_only:true # .ipa
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane xros beta export_only:true      # .ipa
```

- Run one at a time. Each archives Release through `xbuild` with the dedicated build keychain, exactly like an internal beta.
- Exports use `ExportOptions-AppStore.plist` and **do not** add the internal-only official reference sheet (`-DOFFICIAL_REFERENCE_SHEET`).
- Artifacts go to `fastlane/archives/appstore/<platform>/` and `fastlane/builds/appstore/<platform>/<build>/`, apart from internal exports. Both folders are gitignored; delete them after inspection.
- The lane refuses default or explicit `distribution:true` without `export_only:true` before archiving, and refuses to upload an `artifact_path` under `fastlane/builds/appstore/`, including symlink/case aliases. Lifting that refusal is part of the work that clears TASK-1.7 and TASK-85, not something to work around; never move an artifact to bypass it.
- Explicit `distribution:false` retains legacy internal-only packaging and the official-sheet opt-in under decision 2A. Keep `export_only:true` for inspection; omitting it in this legacy mode uploads and requires separate explicit owner authorization plus all [fallback restrictions](testflight.md#internal-beta-lanes). Permitted fallback calls explicitly set `distribute_external:false`; no tester groups change.
- Both booleans accept true/false, yes/no or 1/0 (case-insensitive). Supplied empty/malformed values and unknown options fail closed; only omission selects a default.
- `pnpm test:fastlane` covers the option parsing and those refusals. It runs only locally on macOS (see [Release-tooling checks](#release-tooling-checks-github-ci-and-local)).

Inspect each export before relying on it:

```sh
codesign -dv --verbose=2 <App>.app                    # Authority=Apple Distribution: … (9JALHNGRBQ)
codesign -d --entitlements - --xml <App>.app          # no com.apple.developer.icloud*, ubiquity*, aps-environment
plutil -p fastlane/builds/appstore/<platform>/<build>/ExportOptions.plist   # testFlightInternalTestingOnly absent or false
pkgutil --check-signature CanadianHam.pkg             # macOS: 3rd Party Mac Developer Installer
```

For the iOS IPA, also confirm `Payload/CanadianHam.app/Watch/CanadianHamWatch.app` is present and signed the same way, with matching `CFBundleVersion`. No app may contain `official-basic-exam/`.

## Build numbers

Fastlane uploads use a timestamp build number (`%Y%m%d%H%M`, such as `202610271757`). Xcode Cloud instead stamps its own `CI_BUILD_NUMBER` into every build: an integer that starts at 1 and goes up by 1 per build. Apple's [Setting the next build number for Xcode Cloud builds](https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds) says:

- iOS, iPadOS, tvOS, visionOS and watchOS builds only need a unique pair of version (`CFBundleShortVersionString`) and build number (`CFBundleVersion`). A new version can start again at low build numbers.
- Mac build numbers must keep increasing, even across versions.
- An Admin or App Manager sets **Next Build Number** in **App Store Connect → the app → Xcode Cloud → Settings → Build Number**.
- Xcode Cloud build numbers are plain integers; it can't use hashes, timestamps or other strings. The page doesn't give a maximum.

Every Fastlane upload so far is version 1.0.0, and all of them are above 2,147,483,647, the largest signed 32-bit integer. Some developers report that App Store Connect won't accept a Next Build Number above that. Nobody has tried it for this app yet.

### Floors file

`apps/apple/ci_scripts/build-number-floors` records the highest Fastlane upload for each platform and marketing version, one `<platform> <version> <build>` line each (`ios` covers iPad and the embedded watch app). Versions must be exactly `x.y.z` (three numbers without leading zeros, such as `1.0.0`) here and in `MARKETING_VERSION`, so an entry like `1.0` can't silently miss `1.0.0`. The current entries come from App Store Connect:

| Platform | Version | Highest Fastlane upload |
| --- | --- | --- |
| `ios` | 1.0.0 | 202611050831 |
| `macos` | 1.0.0 | 202611050836 |
| `tvos` | 1.0.0 | 202611050840 |
| `visionos` | 1.0.0 | 202611050844 |

`ci_pre_xcodebuild.sh` reads the platform from Xcode Cloud's `CI_PRODUCT_PLATFORM` and the version from the plain `MARKETING_VERSION = x.y.z;` lines in `project.pbxproj`, which must all agree. It fails an archive when:

- **macOS:** `CI_BUILD_NUMBER` isn't above the highest `macos` entry of any version.
- **iOS, tvOS, visionOS:** `CI_BUILD_NUMBER` isn't above the entry for the version being built. A version with no entry has no Fastlane uploads, so small numbers pass. This restart applies only to these three platforms.
- The floors file has no entry at all for the platform being built. All four platforms already have App Store Connect uploads, so a missing platform line means the record is incomplete, not that the platform can start again from 1; for macOS that would let build numbers go backwards.
- The platform is missing or unknown, the version is missing, conflicting or not in `x.y.z` form, or the floors file is missing, unreadable, empty or malformed (including any version not in `x.y.z` form).

The check only stops mistakes early; App Store Connect still enforces its own rules.

### Owner decision before the first Xcode Cloud build

The owner prefers Xcode Cloud. In every option below, Fastlane is only a temporary fallback whose internal uploads need separate explicit owner authorization.

- **(a) One sequence for every platform.** Set Next Build Number to a plain integer above every floor, for example `202611050845`; Xcode Cloud then counts up by 1 from it. If App Store Connect accepts it, all four platforms continue at 1.0.0 from that number and nothing else changes.
- **(b) App Store Connect refuses it (probably the 32-bit limit).** iOS, iPadOS, tvOS and visionOS ship a new marketing version, for example 1.0.1, starting from small Xcode Cloud numbers:
  1. The coordinator raises `MARKETING_VERSION` in `apps/apple/project.yml` to a new `x.y.z` (all targets share it, including the watch app), regenerates the project and merges it in a pull request.
  2. **From that version-bump merge onward (including that merge), the coordinator stops Fastlane uploads for iOS, tvOS and visionOS.** Do not upload any Fastlane timestamp build of those platforms at the new version, even one exported earlier for inspection: it would sit above every small Xcode Cloud number for that version and block them. The merge authorizes no upload or workflow trigger. A macOS fallback under (c) is optional and separately authorized, not a post-merge step.
  3. The owner leaves Next Build Number at a small value that App Store Connect accepts.
  4. The owner-triggered Xcode Cloud workflows archive iOS, tvOS and visionOS only, and deliver their internal TestFlight builds from now on. Leave out the macOS archive action; the floor check fails it anyway (see (c)).
- **(c) macOS under (b).** Mac build numbers never go back, so Xcode Cloud can't build the Mac app until App Store Connect accepts a Next Build Number above `202611050836`. The owner chooses:
  - optionally keep the Mac app on the Fastlane export path for now (`fastlane mac beta export_only:true` for an App Store-eligible inspection). Any legacy internal-only `fastlane mac beta distribution:false` upload needs separate explicit owner authorization and must be recorded in the floors file; default distribution uploads remain gated; or
  - ask Apple Developer Support whether App Store Connect can accept a higher Next Build Number for this app, or which Apple-supported route to use.

  Overriding `CFBundleVersion` in a `ci_scripts` script is **unverified** and not recommended. Apple says App Store Connect uses the Xcode Cloud build number for builds it distributes, and nobody has tested whether an override survives Xcode Cloud's export. Don't use it without an owner decision and a test.

Record the decision and the Next Build Number used in TASK-86's notes.

### While Fastlane uploads continue

- Each separately authorized Fastlane fallback upload raises the real floor for its platform and version. Update that line of `build-number-floors` to the uploaded build number in a PR right after the upload, before the next Xcode Cloud archive (uploads run from the main checkout, and `main` only takes pull requests). Under (a), the owner also raises Next Build Number above that upload: Xcode Cloud adds only 1 per build, so a later Fastlane timestamp would otherwise jump ahead of it.
- Retire Fastlane uploads for each platform as soon as Xcode Cloud ships it, so the floors stop moving (see [Retiring Fastlane](#retiring-fastlane)). Under (b), iOS, tvOS and visionOS stop at the version-bump merge, before Xcode Cloud has shipped them.

## Xcode Cloud setup (owner only)

Agents don't do these steps. Record the date and settings in TASK-86's notes. The future standard is App Store-eligible TestFlight packaging with an internal-team-only post-action (step 5), **only after TASK-1.7 and TASK-85 are Done**. Before then, only the legacy internal-only workflow in step 4 is eligible; no default-packaging change authorizes a workflow edit or build trigger.

1. **Environment.** Use an Xcode release that includes the iOS, iPadOS, macOS, tvOS, visionOS and watchOS 27 SDKs (Xcode 27.2 builds locally) and the matching macOS image. Don't use a beta Xcode for distribution.
2. **Connect the repository.** In Xcode, open the project and create the first workflow from the Report navigator's Cloud tab. Choose the existing **Canadian Ham** app record, and grant Xcode Cloud access to `djensenius/canadian-ham`. Access doesn't change repository visibility; the repo stays private until TASK-1.7.
3. **Decide build numbers** before starting any build: try option (a) in [Build numbers](#build-numbers), and fall back to (b) and (c) if App Store Connect refuses the number.
4. **Legacy internal-only workflow** (for example, "Internal TestFlight"), the only eligible delivery before the distribution gates clear:
   - Start condition: manual. Apple suggests a start condition that never fires, such as a branch that doesn't exist, then **Start Build** by hand on `main`.
   - Environment: the Xcode above; **Clean** on. No custom environment variables or secrets are needed. Never add variables mentioning `ICLOUD_SYNC`, `DebugCloudKit`, CloudKit entitlements or `OFFICIAL_REFERENCE_SHEET`; the scripts fail the archive if one appears.
   - Four archive actions, each with **Deployment Preparation: TestFlight (Internal Testing Only)**:

     | Platform | Scheme | Notes |
     | --- | --- | --- |
     | iOS | `CanadianHam` | Embeds `CanadianHamWatch`; don't archive the watch scheme separately. |
     | macOS | `CanadianHam` | Same target as iOS (`platform: auto`). Leave out under [option (b)](#owner-decision-before-the-first-xcode-cloud-build) until App Store Connect accepts a Mac build number above `202611050836`. |
     | tvOS | `CanadianHamTV` | |
     | visionOS | `CanadianHamVision` | |

     Every shared scheme archives Release; there's no configuration to choose in the workflow.
   - Post-action: **TestFlight Internal Testing** to the internal team group only.
   - No test actions are needed: GitHub CI and the local `xbuild` merge-batch runs cover tests.
5. **Standard App Store-eligible TestFlight workflow** (for example, "TestFlight and App Store"), created or enabled by the owner only after TASK-1.7 and TASK-85 are Done:
   - General: **Restrict Editing** on (required for review-eligible builds).
   - Environment: **Clean** on, same Xcode.
   - The same four archive actions with **Deployment Preparation: TestFlight and App Store**.
   - Start condition: manual, triggered by the owner. A future `release`-tag start condition on `main` needs separate explicit owner authorization; it is not part of this setup.
   - Post-action: **TestFlight Internal Testing** to the internal team group only. App Store eligibility does not authorize external groups, public links or automatic submission.
   - These processed builds may later be selected for App Store review, but submission is a separate owner action after the [release checklist](release-checklist.md#store-submission) and the [TASK-85 `CA92.1` sign-off](owner-gates.md#task-85-sign-off-on-ca921-before-app-store-submission). External testing also requires separate authorization and its review gates; it is not part of this setup.
6. **First run.** Check each action's log for `canadian-ham-ci:` lines: the guards passed, the scheme uses Release, and the build number is above the floor (or, under option (b), the new version has no Fastlane uploads). Then confirm each platform's build processed in TestFlight. If the visionOS archive fails with `unsupported archive platform '<value>'`, Xcode Cloud reports a platform name the scripts don't know yet; add it to `ch_check_archive_scheme` in a pull request.

## Xcode Cloud scripts

Xcode Cloud runs scripts from `ci_scripts` next to the project (`apps/apple/ci_scripts/`). They are Bash 3.2 compatible, use `set -euo pipefail`, and share `canadian-ham-ci.sh`.

| Script | When | What it does |
| --- | --- | --- |
| `ci_post_clone.sh` | After the clone | Finds Node 26 (PATH, then Homebrew `node@26`, installing it if needed) and runs `check:apple-network`, `test:apple-network`, `check:apple-icloud-gate`, `test:apple-icloud-gate`, `check:apple-required-reasons` and `test:apple-required-reasons` with `node --run`. No `pnpm install` is needed. The required-reason self-test takes about 25 seconds. Because both scripts share `CH_GUARD_SCRIPTS`, every action that builds from source runs the guards twice, here and again in `ci_pre_xcodebuild.sh`, so about 50 seconds of self-test per action: post-clone fails a workflow before package resolution, and pre-xcodebuild guards the exact tree being built. `test-without-building` runners skip the guards and don't pay it. The guards run from the cloned repository with `APPLE_NO_NETWORK_ROOT`, `ICLOUD_GATE_ROOT` and `REQUIRED_REASONS_ROOT` unset, so a workflow environment variable can't point them at another tree. Fails if Node, Homebrew or a guard fails. |
| `ci_pre_xcodebuild.sh` | Before each `xcodebuild` | For `archive`: allows only `CanadianHam` (iOS/macOS), `CanadianHamTV` (tvOS) and `CanadianHamVision` (visionOS); requires the shared scheme's Archive configuration to be `Release`; rejects `CONFIGURATION` other than Release and any environment variable mentioning `ICLOUD_SYNC`, `DebugCloudKit`, CloudKit entitlements or `OFFICIAL_REFERENCE_SHEET`, naming the variable and marker but never the value (a branch, tag or pull request name such as `CI_BRANCH` can trigger it); checks `CI_BUILD_NUMBER` against `build-number-floors` for the platform and marketing version ([Build numbers](#build-numbers)). Then reruns the guards, including the required-reason check and its self-test, for every action that builds from source, so an archive fails if the privacy manifests no longer match the sources. `test-without-building` has no source, so it skips. |
| `ci_post_xcodebuild.sh` | After each `xcodebuild` | After an archive, reads the signed entitlements of every app and app extension (`.app` and `.appex`, including the embedded watch app and anything in `PlugIns` or `Extensions`) in `CI_ARCHIVE_PATH` and fails on iCloud, ubiquity, CloudKit or `aps-environment` entitlements, unreadable signatures, or a bundled `official-basic-exam/`. It skips only when `CI_XCODEBUILD_EXIT_CODE` is a non-zero exit code (a failed archive). An unset or empty value still runs the check, and any other value fails. |

Node 26 matches `.github/workflows/ci.yml`; update `CH_REQUIRED_NODE_MAJOR` in `canadian-ham-ci.sh` with it. `HOMEBREW_NO_AUTO_UPDATE` is deliberately not set for `brew install node@26`. Skipping the update would save time, but an image whose cached formula data predates `node@26` would then fail the build. The update only refreshes Homebrew's formula data, and the script still checks that it got Node 26. Xcode Cloud builds don't run the official-sheet opt-in, so Xcode Cloud builds never contain the internal-only reference sheet.

Dry run (macOS, Node 26 on PATH, no build, no real Homebrew calls):

```sh
pnpm test:xcode-cloud-scripts   # or: node --run test:xcode-cloud-scripts
```

It runs the real guards against the repository and checks the real floors file. It also simulates:

- archives for all four platforms;
- `build`, `analyze`, `build-for-testing` and `test-without-building` actions;
- `DebugCloudKit` and environment overrides, including branch, tag and pull request names;
- per-platform floors at the current and a new marketing version, plus broken versions, a platform with no floors entry, and missing, unreadable, empty or malformed floors files;
- failing and missing guards, including a failing required-reason check and a failing required-reason self-test;
- Node discovery with a stub Homebrew, and with Homebrew hidden by `sandbox-exec` (skipped if the sandbox can't hide it);
- unset, empty and invalid exit codes;
- ad-hoc signed fake archives and app extensions, with and without push or iCloud entitlements. Run `pnpm check:shell` after editing the scripts. This dry run is macOS-only, so it's not part of `pnpm test` or GitHub CI.

## Release-tooling checks: GitHub CI and local

GitHub CI runs on `ubuntu-latest`, so it runs only the checks that don't need macOS tools:

| Check | Where it runs | Notes |
| --- | --- | --- |
| `pnpm check:shell` | GitHub CI and locally | `bash -n` and `shellcheck -x` on every tracked `*.sh` under `scripts/` and `apps/apple/ci_scripts/`. Fails if ShellCheck is missing or any script has a finding. |
| `pnpm check:apple-network`, `pnpm test:apple-network`, `pnpm check:apple-icloud-gate`, `pnpm test:apple-icloud-gate` | GitHub CI, locally and in the Xcode Cloud scripts | The no-network and iCloud guards. |
| `pnpm check:apple-required-reasons`, `pnpm test:apple-required-reasons` | GitHub CI, locally and in the Xcode Cloud scripts | The privacy-manifest required-reason check and its self-test (about 25 seconds). |
| `pnpm test:fastlane` | Locally on macOS only | Needs `plutil` and Ruby 3.0 or later. |
| `pnpm test:xcode-cloud-scripts` | Locally on macOS only | Needs `codesign`, `xmllint`, `sandbox-exec` and Node 26. |

Run the two macOS-only harnesses yourself after changing the Fastlane lanes, `ExportOptions*.plist`, `apps/apple/ci_scripts/` or the harnesses, and list their results in the pull request. Running them in GitHub CI needs a macOS runner; adding one is an owner decision (cost and policy).

## Differences from Fastlane

- **macOS SDK.** The Fastlane mac lane passes `SDKROOT=macosx SUPPORTED_PLATFORMS=macosx`; Xcode Cloud can't pass build settings. On 2026-11-02 a local `xbuild` Release build of `CanadianHam` for `generic/platform=macOS` without those overrides (unsigned, separate derived data) succeeded and produced a native macOS 27 app without the watch app, so no project change is expected. Confirm on the first Xcode Cloud macOS archive.
- **Official reference sheet.** Owner decision 2A allows it only in explicit `distribution:false` internal Fastlane betas. Default beta exports (`distribution:true`) and Xcode Cloud archives never include it.
- **Build numbers.** Timestamps for Fastlane, an incrementing integer for Xcode Cloud (see above).

## Retiring Fastlane

Fastlane is a temporary fallback; keeping its lanes working does not authorize uploads. Keep the Fastlane `beta` lanes working until one Xcode Cloud build has archived and processed **all four platforms** (iOS with the watch, macOS, tvOS and visionOS) in TestFlight. Under [option (c)](#owner-decision-before-the-first-xcode-cloud-build), the Mac app may use the separately authorized fallback until App Store Connect accepts a valid Mac build number. Stop Fastlane uploads for each platform as soon as Xcode Cloud ships it; under option (b), iOS, tvOS and visionOS stop at the version-bump merge. Once all four are on Xcode Cloud, the owner decides how to retire the lanes:

- The owner starts the internal Xcode Cloud workflow; the coordinator neither uploads nor triggers it automatically after merges.
- Xcode Cloud and default Fastlane exports omit the official reference sheet; only the explicit `distribution:false` Fastlane fallback retains it (owner decision 2A), subject to separate upload authorization and the platform restrictions above.
- Removing the lanes, `ExportOptions*.plist` and the build keychain is a separate Backlog task. `asc_status`, `register_bundle_ids` and the signing lanes may stay for maintenance.
- Until then, every separately authorized Fastlane fallback upload raises the floor: update `build-number-floors` in a PR right after the upload, before the next Xcode Cloud archive (see [While Fastlane uploads continue](#while-fastlane-uploads-continue)).

## References

- [Writing custom build scripts](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- [Environment variable reference](https://developer.apple.com/documentation/xcode/environment-variable-reference)
- [Making dependencies available to Xcode Cloud](https://developer.apple.com/documentation/xcode/making-dependencies-available-to-xcode-cloud)
- [Setting the next build number for Xcode Cloud builds](https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds)
- [Creating a workflow that builds your app for distribution](https://developer.apple.com/documentation/xcode/creating-a-workflow-that-builds-your-app-for-distribution)
- [Configuring your Xcode Cloud workflow's actions](https://developer.apple.com/documentation/xcode/configuring-your-xcode-cloud-workflow-s-actions)
- [Xcode Cloud workflow reference](https://developer.apple.com/documentation/xcode/xcode-cloud-workflow-reference)
- [Distributing your Xcode Cloud builds through TestFlight](https://developer.apple.com/documentation/xcode/distributing-your-xcode-cloud-builds-through-testflight)
