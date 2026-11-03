#!/usr/bin/env node
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { spawnSync } from 'node:child_process';

const scriptPath = join(process.cwd(), 'scripts/check-apple-required-reasons.mjs');
let failures = 0;

function fail(message) {
  console.error(`required-reasons-test: FAIL: ${message}`);
  failures += 1;
}

const USER_DEFAULTS = 'NSPrivacyAccessedAPICategoryUserDefaults';
const BOOT_TIME = 'NSPrivacyAccessedAPICategorySystemBootTime';
const FILE_TIMESTAMP = 'NSPrivacyAccessedAPICategoryFileTimestamp';
const DISK_SPACE = 'NSPrivacyAccessedAPICategoryDiskSpace';

function manifest(entries) {
  const apiTypes = entries.map(([category, reasons]) => `\t\t<dict>
\t\t\t<key>NSPrivacyAccessedAPIType</key>
\t\t\t<string>${category}</string>
\t\t\t<key>NSPrivacyAccessedAPITypeReasons</key>
\t\t\t<array>
${reasons.map((reason) => `\t\t\t\t<string>${reason}</string>\n`).join('')}\t\t\t</array>
\t\t</dict>
`).join('');
  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>NSPrivacyAccessedAPITypes</key>
\t<array>
${apiTypes}\t</array>
\t<key>NSPrivacyCollectedDataTypes</key>
\t<array/>
\t<key>NSPrivacyTracking</key>
\t<false/>
\t<key>NSPrivacyTrackingDomains</key>
\t<array/>
</dict>
</plist>
`;
}

const APP_MANIFEST = [[USER_DEFAULTS, ['CA92.1']], [BOOT_TIME, ['35F9.1']], [FILE_TIMESTAMP, ['C617.1']]];
const WATCH_MANIFEST = [[BOOT_TIME, ['35F9.1']]];
const TV_MANIFEST = [[USER_DEFAULTS, ['CA92.1']]];

const PROJECT_YML = `name: Fixture
options:
  bundleIdPrefix: org.example # trailing comment
packages:
  EnginePkg:
    path: ../../packages/engine-swift
  UnlinkedPkg:
    path: ../../packages/unlinked-swift
targets:
  App:
    type: application
    platform: auto
    supportedDestinations: [iOS, macOS]
    sources:
      - path: App
        excludes:
          - "DebugOnly/**"
      - path: Shared/Settings.swift
      - path: ../../content/lessons
        type: folder
        buildPhase: resources
    dependencies:
      - package: EnginePkg
      - target: Watch
      - sdk: AVFoundation.framework
  AppTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - AppTests
      - path: App/DebugOnly
    dependencies:
      - target: App
  Watch:
    type: application
    platform: watchOS
    sources:
      - Platforms/watchOS
  TV:
    type: application
    platform: tvOS
    sources:
      - path: Platforms/tvOS
      - path: Shared/Settings.swift
    dependencies:
      - package: EnginePkg
`;

const PACKAGE_SWIFT = `// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Engine",
    products: [.library(name: "Engine", targets: ["Engine"])],
    targets: [
        .target(name: "Engine"),
        .testTarget(name: "EngineTests", dependencies: ["Engine"]),
    ]
)
`;

function baseFiles() {
  return {
    'apps/apple/project.yml': PROJECT_YML,
    'apps/apple/App/AppMain.swift': `import Foundation
// volumeAvailableCapacityKey is only mentioned in this comment.
/* Nested /* activeInputModes */ comments still hide mach_absolute_time() */
let defaults = UserDefaults.standard
let label = "string with no API" // creationDateKey in a trailing comment
`,
    'apps/apple/App/Timing.swift': `import Foundation
let link = "https://example.com/a"; let raw = #"x // "y" z"#; let started = ProcessInfo.processInfo.systemUptime
`,
    'apps/apple/App/Resources/PrivacyInfo.xcprivacy': manifest(APP_MANIFEST),
    'apps/apple/App/DebugOnly/DiskProbe.swift': `import Foundation
let keys: Set<URLResourceKey> = [.volumeAvailableCapacityKey]
`,
    'apps/apple/AppTests/AppTests.swift': `import Foundation
let testUptime = ProcessInfo.processInfo.systemUptime
let testAttributes = try? FileManager.default.attributesOfItem(atPath: "/")[.modificationDate]
`,
    'apps/apple/Shared/Settings.swift': `import SwiftUI
struct SettingsView: View {
    @AppStorage("speed") private var speed = 20
    var body: some View { Text("\\(speed)") }
}
`,
    'apps/apple/Platforms/watchOS/WatchMain.swift': `import Foundation
let watchNow = ProcessInfo.processInfo.systemUptime
`,
    'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy': manifest(WATCH_MANIFEST),
    'apps/apple/Platforms/tvOS/TVMain.swift': `import Foundation
let tvTitle = "Canadian Ham"
`,
    'apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy': manifest(TV_MANIFEST),
    'apps/apple/CanadianHam.xcodeproj/project.pbxproj': '// generated; ignored by the checker\n',
    'apps/apple/CanadianHam.xcodeproj/Generated.swift': 'let ignored = ProcessInfo.processInfo.systemUptime\n',
    'packages/engine-swift/Package.swift': PACKAGE_SWIFT,
    'packages/engine-swift/Sources/Engine/Files.swift': `import Foundation
public func contentDate(_ url: URL) -> Date? {
    try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
}
`,
    'packages/engine-swift/Tests/EngineTests/EngineTests.swift': `import UIKit
let modes = UITextInputMode.activeInputModes
`,
    'packages/unlinked-swift/Package.swift': PACKAGE_SWIFT,
    'packages/unlinked-swift/Sources/Engine/Disk.swift': `import Darwin
var info = statfs(); let status = statfs("/", &info)
`,
    // C-family files outside shipped targets and linked packages are not scanned and do not fail.
    'apps/apple/AppTests/AppTests-Bridging-Header.h': '#import <sys/stat.h>\n',
    'packages/unlinked-swift/Sources/Engine/shim.c': '#include <sys/stat.h>\n',
  };
}

function writeFixture(changes = {}) {
  const root = mkdtempSync(join(tmpdir(), 'required-reasons-test.'));
  const files = { ...baseFiles(), ...changes };
  for (const [path, content] of Object.entries(files)) {
    if (content === null) continue;
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), content);
  }
  return root;
}

function runCheck(root) {
  return spawnSync(process.execPath, [scriptPath], {
    cwd: process.cwd(),
    env: { ...process.env, REQUIRED_REASONS_ROOT: root },
    encoding: 'utf8',
  });
}

function assertPass(name, changes, expected = []) {
  const root = writeFixture(changes);
  try {
    const result = runCheck(root);
    const output = `${result.stderr}${result.stdout}`;
    if (result.status !== 0) {
      fail(`${name} expected pass but failed:\n${output}`);
      return;
    }
    for (const text of expected) {
      if (!output.includes(text)) fail(`${name} missed expected output ${JSON.stringify(text)}:\n${output}`);
    }
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

function assertFail(name, changes, expected) {
  const root = writeFixture(changes);
  try {
    const result = runCheck(root);
    const output = `${result.stderr}${result.stdout}`;
    if (result.status === 0) {
      fail(`${name} expected failure but passed:\n${output}`);
      return;
    }
    for (const text of [expected].flat()) {
      if (!output.includes(text)) fail(`${name} missed expected output ${JSON.stringify(text)}:\n${output}`);
    }
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

const tvManifest = (entries) => ({ 'apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy': manifest(entries) });
const appManifest = (entries) => ({ 'apps/apple/App/Resources/PrivacyInfo.xcprivacy': manifest(entries) });
const projectYml = (text) => ({ 'apps/apple/project.yml': text });
const TV_WITH_PACKAGE = [[USER_DEFAULTS, ['CA92.1']], [FILE_TIMESTAMP, ['C617.1']]];

// Clean fixture: comments, excluded/test-only sources, unlinked packages and
// package tests do not count; strings containing "//" do not hide later code.
assertPass('clean fixture', tvManifest(TV_WITH_PACKAGE), [
  'App: 4 Swift files; apps/apple/App/Resources/PrivacyInfo.xcprivacy; categories: FileTimestamp [C617.1], SystemBootTime [35F9.1], UserDefaults [CA92.1]',
  'Watch: 1 Swift files; apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy; categories: SystemBootTime [35F9.1]',
  'TV: 3 Swift files; apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy; categories: FileTimestamp [C617.1], UserDefaults [CA92.1]',
  'Apple required-reason API check passed',
]);

// Linked package usage counts for every app target that links the package.
assertFail('package usage undeclared', {}, [
  'TV: uses NSPrivacyAccessedAPICategoryFileTimestamp (File timestamp) but apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy does not declare it.',
  'packages/engine-swift/Sources/Engine/Files.swift:3 contentModificationDateKey',
]);
assertFail('app usage undeclared', { ...tvManifest(TV_WITH_PACKAGE), ...appManifest([[BOOT_TIME, ['35F9.1']], [FILE_TIMESTAMP, ['C617.1']]]) },
  'App: uses NSPrivacyAccessedAPICategoryUserDefaults (User defaults) but apps/apple/App/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: apps/apple/App/AppMain.swift:4 UserDefaults');
assertFail('@AppStorage counts as user defaults', { ...tvManifest([[FILE_TIMESTAMP, ['C617.1']]]) },
  'TV: uses NSPrivacyAccessedAPICategoryUserDefaults (User defaults) but apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: apps/apple/Shared/Settings.swift:3 @AppStorage');
assertFail('code after a string containing // is scanned', { ...tvManifest(TV_WITH_PACKAGE), ...appManifest([[USER_DEFAULTS, ['CA92.1']], [FILE_TIMESTAMP, ['C617.1']]]) },
  'Evidence: apps/apple/App/Timing.swift:2 systemUptime');
assertFail('declared category unused', tvManifest([...TV_WITH_PACKAGE, [DISK_SPACE, ['E174.1']]]),
  'TV: apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy declares NSPrivacyAccessedAPICategoryDiskSpace (Disk space) but no Swift source compiled into TV or its linked local packages uses it.');
assertFail('excludes removed', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('        excludes:\n          - "DebugOnly/**"\n', '')) },
  'App: uses NSPrivacyAccessedAPICategoryDiskSpace (Disk space)');
assertFail('getattrlist needs file timestamp and disk space', {
  ...tvManifest(TV_WITH_PACKAGE),
  'apps/apple/Platforms/watchOS/Attributes.swift': 'import Darwin\nlet status = getattrlist(path, &list, &buffer, size, 0)\n',
}, [
  'Watch: uses NSPrivacyAccessedAPICategoryFileTimestamp (File timestamp)',
  'Watch: uses NSPrivacyAccessedAPICategoryDiskSpace (Disk space)',
  'apps/apple/Platforms/watchOS/Attributes.swift:2 getattrlist family',
]);

// Reason validation.
assertFail('unknown reason', { ...tvManifest(TV_WITH_PACKAGE), ...appManifest([[USER_DEFAULTS, ['XXXX.1']], [BOOT_TIME, ['35F9.1']], [FILE_TIMESTAMP, ['C617.1']]]) },
  '"XXXX.1" is not an approved reason for NSPrivacyAccessedAPICategoryUserDefaults');
assertFail('reason from another category', { ...tvManifest(TV_WITH_PACKAGE), ...appManifest([[USER_DEFAULTS, ['CA92.1']], [BOOT_TIME, ['C617.1']], [FILE_TIMESTAMP, ['C617.1']]]) },
  '"C617.1" is not an approved reason for NSPrivacyAccessedAPICategorySystemBootTime');
assertFail('SDK-only reason', tvManifest([[USER_DEFAULTS, ['C56D.1']], [FILE_TIMESTAMP, ['C617.1']]]),
  'C56D.1 may only be declared by third-party SDKs');
assertFail('empty reasons', tvManifest([[USER_DEFAULTS, []], [FILE_TIMESTAMP, ['C617.1']]]),
  'NSPrivacyAccessedAPICategoryUserDefaults must list at least one NSPrivacyAccessedAPITypeReasons code');
assertFail('duplicate reason', tvManifest([[USER_DEFAULTS, ['CA92.1', 'CA92.1']], [FILE_TIMESTAMP, ['C617.1']]]),
  'NSPrivacyAccessedAPICategoryUserDefaults lists a reason more than once');
assertFail('unknown category', tvManifest([...TV_WITH_PACKAGE, ['NSPrivacyAccessedAPICategoryMadeUp', ['CA92.1']]]),
  'unknown NSPrivacyAccessedAPIType "NSPrivacyAccessedAPICategoryMadeUp"');
assertFail('duplicate category', tvManifest([...TV_WITH_PACKAGE, [USER_DEFAULTS, ['CA92.1']]]),
  'NSPrivacyAccessedAPICategoryUserDefaults is declared more than once');
assertFail('invalid manifest', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy': '<plist><dict><key>NSPrivacyAccessedAPITypes</key></dict></plist>' },
  'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy: invalid property list');

// No tracking and no collected data in any shipped manifest.
const TV_MANIFEST_PATH = 'apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy';
const tvManifestEdited = (from, to) => ({ [TV_MANIFEST_PATH]: manifest(TV_WITH_PACKAGE).replace(from, to) });
const TRACKING_FALSE = '\t<key>NSPrivacyTracking</key>\n\t<false/>\n';
const TRACKING_DOMAINS_EMPTY = '\t<key>NSPrivacyTrackingDomains</key>\n\t<array/>\n';
const COLLECTED_EMPTY = '\t<key>NSPrivacyCollectedDataTypes</key>\n\t<array/>\n';
assertFail('tracking enabled', tvManifestEdited(TRACKING_FALSE, '\t<key>NSPrivacyTracking</key>\n\t<true/>\n'),
  `${TV_MANIFEST_PATH} (TV): NSPrivacyTracking must be present and false`);
assertFail('tracking key missing', tvManifestEdited(TRACKING_FALSE, ''),
  `${TV_MANIFEST_PATH} (TV): NSPrivacyTracking must be present and false`);
assertFail('tracking domain listed', tvManifestEdited(TRACKING_DOMAINS_EMPTY, '\t<key>NSPrivacyTrackingDomains</key>\n\t<array>\n\t\t<string>tracker.example.com</string>\n\t</array>\n'),
  `${TV_MANIFEST_PATH} (TV): NSPrivacyTrackingDomains must be present and an empty array`);
assertFail('tracking domains key missing', tvManifestEdited(TRACKING_DOMAINS_EMPTY, ''),
  `${TV_MANIFEST_PATH} (TV): NSPrivacyTrackingDomains must be present and an empty array`);
assertFail('collected data type listed', tvManifestEdited(COLLECTED_EMPTY, '\t<key>NSPrivacyCollectedDataTypes</key>\n\t<array>\n\t\t<dict>\n\t\t\t<key>NSPrivacyCollectedDataType</key>\n\t\t\t<string>NSPrivacyCollectedDataTypeDeviceID</string>\n\t\t</dict>\n\t</array>\n'),
  `${TV_MANIFEST_PATH} (TV): NSPrivacyCollectedDataTypes must be present and an empty array`);
assertFail('collected data types key missing', tvManifestEdited(COLLECTED_EMPTY, ''),
  `${TV_MANIFEST_PATH} (TV): NSPrivacyCollectedDataTypes must be present and an empty array`);

// Only Swift is scanned: C-family sources in shipped targets or linked packages fail closed.
assertFail('Objective-C source in a shipped target', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Platforms/tvOS/Legacy.m': '#import <Foundation/Foundation.h>\n' },
  'TV: apps/apple/Platforms/tvOS/Legacy.m is not Swift; only Swift sources are scanned; extend scripts/check-apple-required-reasons.mjs');
assertFail('C++ source in a shipped target', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/App/Bridge.mm': '#include <sys/stat.h>\n' },
  'App: apps/apple/App/Bridge.mm is not Swift');
assertFail('C header in a shipped target', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Platforms/watchOS/Shim.h': '#include <mach/mach_time.h>\n' },
  'Watch: apps/apple/Platforms/watchOS/Shim.h is not Swift');
assertFail('C source in a linked package', { ...tvManifest(TV_WITH_PACKAGE), 'packages/engine-swift/Sources/CEngine/shim.c': '#include <sys/stat.h>\n' },
  'package EnginePkg: packages/engine-swift/Sources/CEngine/shim.c is not Swift; only Swift sources are scanned');

// Manifest bundling.
assertFail('missing manifest', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy': null },
  'Watch: expected exactly one bundled PrivacyInfo.xcprivacy, found 0.');
assertFail('two manifests in one target', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('      - path: Shared/Settings.swift\n    dependencies:\n      - package: EnginePkg\n', '      - path: Shared/Settings.swift\n      - path: App/Resources/PrivacyInfo.xcprivacy\n        type: file\n        buildPhase: resources\n    dependencies:\n      - package: EnginePkg\n')) },
  'TV: expected exactly one bundled PrivacyInfo.xcprivacy, found 2 (apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy, apps/apple/App/Resources/PrivacyInfo.xcprivacy).');

// Target and source mapping.
assertFail('unmapped Swift file', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/NewFeature/Feature.swift': 'let feature = 1\n' },
  'apps/apple/NewFeature/Feature.swift is not compiled by any project.yml target');
assertFail('missing compiled source path', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Shared/Settings.swift': null },
  'App: sources path Shared/Settings.swift does not exist.');
assertFail('unsupported sources key', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('      - Platforms/watchOS\n', '      - path: Platforms/watchOS\n        includes:\n          - "*.swift"\n')) },
  'Watch: sources entry Platforms/watchOS uses unsupported XcodeGen keys (includes)');
assertFail('unsupported target type', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(`${PROJECT_YML}  Kit:\n    type: framework\n    platform: iOS\n    sources:\n      - Shared\n`) },
  'Kit: target type "framework" is not supported');
assertFail('unsupported dependency', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('      - sdk: AVFoundation.framework\n', '      - framework: Vendor/Analytics.xcframework\n')) },
  'App: unsupported dependency {"framework":"Vendor/Analytics.xcframework"}');
assertFail('remote package', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('    path: ../../packages/engine-swift\n', '    url: https://example.com/engine.git\n    from: 1.0.0\n')) },
  'project.yml package EnginePkg is not a local path package');
assertFail('package with custom paths', { ...tvManifest(TV_WITH_PACKAGE), 'packages/engine-swift/Package.swift': PACKAGE_SWIFT.replace('.target(name: "Engine")', '.target(name: "Engine", path: "Elsewhere")') },
  'packages/engine-swift/Package.swift uses custom target paths');
assertFail('target templates', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('  Watch:\n    type: application\n', '  Watch:\n    templates: [Base]\n    type: application\n')) },
  'Watch: target templates are not supported');
assertFail('unsupported YAML', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('    platform: watchOS\n', '    platform: *watch\n')) },
  'anchors, aliases and tags are not supported');

if (failures !== 0) {
  console.error(`required-reasons-test: failed with ${failures} failure(s).`);
  process.exit(1);
}
console.log('required-reasons-test: passed self-test fixtures.');
