fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios register_bundle_ids

```sh
[bundle exec] fastlane ios register_bundle_ids
```

Register the universal Developer Portal bundle ID using the App Store Connect API key. Idempotent.

### ios create_app_record

```sh
[bundle exec] fastlane ios create_app_record
```

Create the App Store Connect app record for iOS, macOS, tvOS and visionOS. Requires Apple ID + 2FA; do not run non-interactively.

### ios asc_status

```sh
[bundle exec] fastlane ios asc_status
```

Print the App Store Connect app record and version states.

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Archive/export the iOS Release build with xbuild and upload it to internal TestFlight.

----


## Mac

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Archive/export the macOS Release build with xbuild and upload it to internal TestFlight.

----


## appletvos

### appletvos beta

```sh
[bundle exec] fastlane appletvos beta
```

Archive/export the tvOS Release build with xbuild and upload it to internal TestFlight.

----


## xros

### xros beta

```sh
[bundle exec] fastlane xros beta
```

Archive/export the visionOS Release build with xbuild and upload it to internal TestFlight.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
