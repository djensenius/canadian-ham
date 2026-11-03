#!/usr/bin/env node
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, symlinkSync } from 'node:fs';
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
struct Stat { var stat = 0; var stats = [0]; var status = 1 }
func accuracy(_ stat: Stat?) -> Double {
    guard let stat, stat.stat > 0 else { return 0 }
    return Double(stat.stat) / Double(stat.stats.count) // UserDefaults after division is a comment
}
func latest(_ stat: Stat?) -> Stat? {
    guard let stat else { return nil }
    return stat
}
let lstatus = Stat().status; let restat = Stat().stats; let half = lstatus/2 // statfs(note)
let quotient = half/2; let path = "a/b" // UserDefaults after division and a string is a comment
let forced = Optional(4)!/2; let other = "c/d" // NSUserDefaults after a postfix operator is a comment
let word = /[a-z]+/ // activeInputModes after a bare regex is a comment
let escaped = /a\\/b/ ; let extended = #/[/*]/# // creationDateKey after an extended regex is a comment
let ratio = \`half\`/2; let slashed = "e/f" // UserDefaults after an escaped identifier and division is a comment
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
    if (typeof content === 'object' && !Buffer.isBuffer(content)) {
      symlinkSync(content.symlink, join(root, path));
    } else {
      writeFileSync(join(root, path), content);
    }
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
  'TV: uses NSPrivacyAccessedAPICategoryUserDefaults (User defaults) but apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: apps/apple/Shared/Settings.swift:3 AppStorage');
// Swift accepts a module-qualified attribute, with a line break before the `.`.
assertFail('@SwiftUI.AppStorage counts as user defaults', {
  ...tvManifest([[FILE_TIMESTAMP, ['C617.1']]]),
  'apps/apple/Shared/Settings.swift': `import SwiftUI
struct SettingsView: View {
    @SwiftUI.AppStorage("speed") private var speed = 20
    @SwiftUI
        .AppStorage("tone") private var tone = 600
    var body: some View { Text("\\(speed) \\(tone)") }
}
`,
}, 'TV: uses NSPrivacyAccessedAPICategoryUserDefaults (User defaults) but apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: apps/apple/Shared/Settings.swift:3 AppStorage; apps/apple/Shared/Settings.swift:5 AppStorage');
// Module-qualified spellings in every category, including a line break before `.`.
const TV_QUALIFIED = 'apps/apple/Platforms/tvOS/Qualified.swift';
const tvUndeclared = (category, label) => `TV: uses ${category} (${label}) but apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: `;
assertFail('module-qualified spellings', {
  ...tvManifest([]),
  [TV_QUALIFIED]: `import Foundation
let info = Darwin
    .stat
let defaults = Foundation.UserDefaults.standard, suite = Foundation.UserDefaults(suiteName: nil)
let uptime = Foundation.ProcessInfo.processInfo
    .systemUptime
let ticks = Darwin.mach_absolute_time()
let modified = try? Foundation.FileManager.default.attributesOfItem(atPath: "/")[Foundation.FileAttributeKey.modificationDate]
let free = Foundation.URLResourceKey.volumeAvailableCapacityForImportantUsageKey
let modes = UIKit.UITextInputMode.activeInputModes
`,
}, [
  // One usage per spelling and line, listed in line order.
  `${tvUndeclared(USER_DEFAULTS, 'User defaults')}${TV_QUALIFIED}:4 UserDefaults; apps/apple/Shared/Settings.swift:3 AppStorage`,
  `${tvUndeclared(BOOT_TIME, 'System boot time')}${TV_QUALIFIED}:6 systemUptime; ${TV_QUALIFIED}:7 mach_absolute_time`,
  `${tvUndeclared(FILE_TIMESTAMP, 'File timestamp')}${TV_QUALIFIED}:3 stat; ${TV_QUALIFIED}:8 modificationDate; packages/engine-swift/Sources/Engine/Files.swift:3 contentModificationDateKey`,
  `${tvUndeclared(DISK_SPACE, 'Disk space')}${TV_QUALIFIED}:9 volumeAvailableCapacity*`,
  `${tvUndeclared('NSPrivacyAccessedAPICategoryActiveKeyboards', 'Active keyboards')}${TV_QUALIFIED}:10 activeInputModes`,
]);
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

// C functions count as references too, not only as calls.
assertFail('file timestamp function references', {
  ...tvManifest(TV_WITH_PACKAGE),
  'apps/apple/Platforms/watchOS/References.swift': `import Darwin
let readAttributes = Darwin.fstat
let attributes: @convention(c) (UnsafePointer<CChar>?, UnsafeMutablePointer<stat>?) -> Int32 = stat
let qualified = Darwin.stat
`,
}, [
  'Watch: uses NSPrivacyAccessedAPICategoryFileTimestamp (File timestamp)',
  'apps/apple/Platforms/watchOS/References.swift:2 fstat/lstat/fstatat',
  'apps/apple/Platforms/watchOS/References.swift:3 stat',
  'apps/apple/Platforms/watchOS/References.swift:4 stat',
]);
assertFail('disk space function references', {
  ...tvManifest(TV_WITH_PACKAGE),
  'apps/apple/Platforms/watchOS/References.swift': `import Darwin
let volumeInfo = Darwin.statfs
let fileSystem = fstatvfs
let attributeList = getattrlist
`,
}, [
  'Watch: uses NSPrivacyAccessedAPICategoryDiskSpace (Disk space)',
  'apps/apple/Platforms/watchOS/References.swift:2 statfs/statvfs/fstatfs/fstatvfs',
  'apps/apple/Platforms/watchOS/References.swift:3 statfs/statvfs/fstatfs/fstatvfs',
  'apps/apple/Platforms/watchOS/References.swift:4 getattrlist family',
  'Watch: uses NSPrivacyAccessedAPICategoryFileTimestamp (File timestamp)',
]);

// Whole-file matching: spellings split across lines count, reported on the API's line.
// (swiftc parses a `(` at the start of a line as a new expression, not a call,
// so `stat` then `(path, &buf)` is matched conservatively.)
const WATCH_MULTI_LINE = 'apps/apple/Platforms/watchOS/MultiLine.swift';
assertFail('multi-line stat spellings', {
  ...tvManifest(TV_WITH_PACKAGE),
  [WATCH_MULTI_LINE]: `import Darwin
func probe(_ path: String, _ buf: inout stat) {
    stat
    (path, &buf)
    let assigned =
        stat
    let qualified = Darwin
        .stat
    let volume = Glibc
        .statfs
}
`,
}, [
  `Watch: uses ${FILE_TIMESTAMP} (File timestamp) but apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: ${WATCH_MULTI_LINE}:3 stat; ${WATCH_MULTI_LINE}:6 stat; ${WATCH_MULTI_LINE}:8 stat`,
  `Watch: uses ${DISK_SPACE} (Disk space) but apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: ${WATCH_MULTI_LINE}:10 statfs/statvfs/fstatfs/fstatvfs`,
]);
assertFail('multi-line spellings in other categories', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...appManifest([[USER_DEFAULTS, ['CA92.1']]]),
  'apps/apple/App/Dates.swift': `import Foundation
let attributes = try? FileManager.default.attributesOfItem(atPath: "/")[FileAttributeKey
    .creationDate]
let started = ProcessInfo
    .processInfo
    .systemUptime
`,
}, [
  `App: uses ${FILE_TIMESTAMP} (File timestamp) but apps/apple/App/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: apps/apple/App/Dates.swift:3 creationDate`,
  `App: uses ${BOOT_TIME} (System boot time) but apps/apple/App/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: apps/apple/App/Dates.swift:6 systemUptime; apps/apple/App/Timing.swift:2 systemUptime`,
]);

// Backtick-escaped identifiers are normalised before matching, in every
// category; a raw identifier containing `//` does not start a comment.
const TV_ESCAPED = 'apps/apple/Platforms/tvOS/Escaped.swift';
assertFail('backtick-escaped identifiers', {
  ...tvManifest([]),
  [TV_ESCAPED]: `import Foundation
let created = attributes[FileAttributeKey.\`creationDate\`]
let free = URLResourceKey.\`volumeAvailableCapacityKey\`, size = attributes[.\`systemFreeSize\`]
let defaults = \`UserDefaults\`.standard
func probe(_ path: String, _ buf: inout stat) -> Int32 { \`stat\`(path, &buf) }
let \`a // b\` = ProcessInfo.processInfo.\`systemUptime\`
let modes = UITextInputMode.\`activeInputModes\`
`,
}, [
  `${tvUndeclared(USER_DEFAULTS, 'User defaults')}${TV_ESCAPED}:4 UserDefaults; apps/apple/Shared/Settings.swift:3 AppStorage`,
  `${tvUndeclared(BOOT_TIME, 'System boot time')}${TV_ESCAPED}:6 systemUptime`,
  `${tvUndeclared(FILE_TIMESTAMP, 'File timestamp')}${TV_ESCAPED}:2 creationDate; ${TV_ESCAPED}:5 stat; packages/engine-swift/Sources/Engine/Files.swift:3 contentModificationDateKey`,
  `${tvUndeclared(DISK_SPACE, 'Disk space')}${TV_ESCAPED}:3 volumeAvailableCapacity*; ${TV_ESCAPED}:3 systemFreeSize`,
  `${tvUndeclared('NSPrivacyAccessedAPICategoryActiveKeyboards', 'Active keyboards')}${TV_ESCAPED}:7 activeInputModes`,
]);
const WATCH_ESCAPED = 'apps/apple/Platforms/watchOS/EscapedStat.swift';
assertFail('backtick-escaped stat references', {
  ...tvManifest(TV_WITH_PACKAGE),
  [WATCH_ESCAPED]: `import Darwin
let qualified = Darwin.\`stat\`, assigned = 0; let reference =
    \`stat\`
let call = \`stat\`
    (path, &buf)
`,
}, `Watch: uses ${FILE_TIMESTAMP} (File timestamp) but apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy does not declare it. Evidence: ${WATCH_ESCAPED}:2 stat; ${WATCH_ESCAPED}:3 stat; ${WATCH_ESCAPED}:4 stat`);

// Key paths, type aliases and string-based access (key-value coding,
// selectors, `@_silgen_name`, URLResourceKey raw values) still name the API.
const TV_INDIRECT = 'apps/apple/Platforms/tvOS/Indirect.swift';
assertFail('key paths, aliases and string-based access', {
  ...tvManifest([]),
  [TV_INDIRECT]: `import Foundation
let created = \\URLResourceValues.creationDate
let free: KeyPath<URLResourceValues, Int?> = \\.volumeAvailableCapacity
typealias Defaults = UserDefaults
let clock = ProcessInfo.processInfo; let uptimeReader = \\ProcessInfo.systemUptime
let kvc = attributes.value(forKey: "modificationDate")
@_silgen_name("stat") func rawStat(_ path: UnsafePointer<CChar>, _ buf: UnsafeMutableRawPointer) -> Int32
let raw = URLResourceKey(rawValue: "NSURLVolumeTotalCapacityKey"); let fs = attributes.value(forKey: "systemFreeSize")
let selector = NSSelectorFromString("activeInputModes")
`,
}, [
  `${tvUndeclared(USER_DEFAULTS, 'User defaults')}${TV_INDIRECT}:4 UserDefaults; apps/apple/Shared/Settings.swift:3 AppStorage`,
  `${tvUndeclared(BOOT_TIME, 'System boot time')}${TV_INDIRECT}:5 systemUptime`,
  `${tvUndeclared(FILE_TIMESTAMP, 'File timestamp')}${TV_INDIRECT}:2 creationDate; ${TV_INDIRECT}:6 API name string literal; ${TV_INDIRECT}:7 API name string literal`,
  `${tvUndeclared(DISK_SPACE, 'Disk space')}${TV_INDIRECT}:3 volumeAvailableCapacity*; ${TV_INDIRECT}:8 NSURLVolume*CapacityKey; ${TV_INDIRECT}:8 API name string literal`,
  `${tvUndeclared('NSPrivacyAccessedAPICategoryActiveKeyboards', 'Active keyboards')}${TV_INDIRECT}:9 activeInputModes`,
]);

// Regex literals: comment markers inside them must not hide later code.
const TV_REGEX = 'apps/apple/Platforms/tvOS/Patterns.swift';
const TV_BOOT_TIME = `TV: uses ${BOOT_TIME} (System boot time) but apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy does not declare it.`;
assertFail('extended regex literal containing /*', { ...tvManifest(TV_WITH_PACKAGE), [TV_REGEX]: `let punctuation = #/[/*]/#
let started = ProcessInfo.processInfo.systemUptime
` }, [TV_BOOT_TIME, `${TV_REGEX}:2 systemUptime`]);
assertFail('multi-line extended regex literal', { ...tvManifest(TV_WITH_PACKAGE), [TV_REGEX]: `let pattern = ##/
  [/*] // not a comment
/##
let started = ProcessInfo.processInfo.systemUptime
` }, [TV_BOOT_TIME, `${TV_REGEX}:4 systemUptime`]);
assertFail('bare regex literals with escaped slashes', { ...tvManifest(TV_WITH_PACKAGE), [TV_REGEX]: `let slash = /\\//; let started = ProcessInfo.processInfo.systemUptime
let slashStar = /a\\/*b/
let later = ProcessInfo.processInfo.systemUptime
` }, [TV_BOOT_TIME, `${TV_REGEX}:1 systemUptime`, `${TV_REGEX}:3 systemUptime`]);
assertFail('bare regex literal after a keyword', { ...tvManifest(TV_WITH_PACKAGE), [TV_REGEX]: `func pattern() -> Regex<Substring> { return/a\\/*b/ }
let later = ProcessInfo.processInfo.systemUptime
` }, [TV_BOOT_TIME, `${TV_REGEX}:2 systemUptime`]);
assertFail('undelimited regex fails closed', { ...tvManifest(TV_WITH_PACKAGE), [TV_REGEX]: `let ratio = total()/a\\/*b/
` }, `${TV_REGEX}:1: comment marker /* straight after "\\" looks like an escaped slash in a regex literal the checker could not delimit`);
assertFail('unterminated block comment fails closed', { ...tvManifest(TV_WITH_PACKAGE), [TV_REGEX]: `let a = 1 /* never closed
let later = ProcessInfo.processInfo.systemUptime
` }, `${TV_REGEX}:1: unterminated block comment`);
assertFail('unterminated extended regex fails closed', { ...tvManifest(TV_WITH_PACKAGE), [TV_REGEX]: `let r = #/abc
let later = 1
` }, `${TV_REGEX}:1: unterminated extended regex literal`);

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
assertFail('assembly and C++ inline sources', {
  ...tvManifest(TV_WITH_PACKAGE),
  'apps/apple/Platforms/watchOS/uptime.S': '.globl _uptime\n',
  'packages/engine-swift/Sources/CEngine/engine.ipp': 'inline int f() { return 0; }\n',
}, [
  'Watch: apps/apple/Platforms/watchOS/uptime.S is not Swift; only Swift sources are scanned; extend scripts/check-apple-required-reasons.mjs to scan C/Objective-C/C++/assembly',
  'package EnginePkg: packages/engine-swift/Sources/CEngine/engine.ipp is not Swift',
]);

// Manifest bundling.
assertFail('missing manifest', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy': null },
  'Watch: expected exactly one bundled PrivacyInfo.xcprivacy, found 0.');
assertFail('two manifests in one target', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('      - path: Shared/Settings.swift\n    dependencies:\n      - package: EnginePkg\n', '      - path: Shared/Settings.swift\n      - path: App/Resources/PrivacyInfo.xcprivacy\n        type: file\n        buildPhase: resources\n    dependencies:\n      - package: EnginePkg\n')) },
  'TV: expected exactly one bundled PrivacyInfo.xcprivacy, found 2 (apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy, apps/apple/App/Resources/PrivacyInfo.xcprivacy).');

// Target and source mapping.
assertFail('unmapped Swift file', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/NewFeature/Feature.swift': 'let feature = 1\n' },
  'apps/apple/NewFeature/Feature.swift is not compiled by any project.yml target');
// XcodeGen compiles hidden files and directories, so they are scanned too.
assertFail('hidden Swift sources in a target', {
  ...tvManifest(TV_WITH_PACKAGE),
  'apps/apple/Platforms/tvOS/.Hidden.swift': 'let started = ProcessInfo.processInfo.systemUptime\n',
  'apps/apple/Platforms/tvOS/.generated/Inner.swift': 'let later = ProcessInfo.processInfo.systemUptime\n',
}, [TV_BOOT_TIME, 'apps/apple/Platforms/tvOS/.Hidden.swift:1 systemUptime', 'apps/apple/Platforms/tvOS/.generated/Inner.swift:1 systemUptime']);
// Symbolic links are not followed, so they fail instead of being skipped.
assertFail('symlinked Swift file in a target', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Platforms/tvOS/Linked.swift': { symlink: '../../Shared/Settings.swift' } },
  'apps/apple/Platforms/tvOS/Linked.swift is a symbolic link; the checker does not follow links');
assertFail('symlinked package source directory', { ...tvManifest(TV_WITH_PACKAGE), 'packages/engine-swift/Sources/Engine/Linked': { symlink: '../../../unlinked-swift/Sources/Engine' } },
  'packages/engine-swift/Sources/Engine/Linked is a symbolic link');
assertFail('symlink outside any target', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Loose.swift': { symlink: 'Shared/Settings.swift' } },
  'apps/apple/Loose.swift is a symbolic link');
// Module maps and prebuilt code in a shipped target fail closed.
assertFail('module map in a shipped target', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Platforms/tvOS/module.modulemap': 'module Shim { header "shim.h" }\n' },
  'TV: apps/apple/Platforms/tvOS/module.modulemap is not Swift; only Swift sources are scanned; extend scripts/check-apple-required-reasons.mjs to scan C/Objective-C/C++/assembly, module maps and API notes');
assertFail('prebuilt code in a shipped target', {
  ...tvManifest(TV_WITH_PACKAGE),
  'apps/apple/Platforms/tvOS/libVendor.a': '!<arch>\n',
  'apps/apple/Platforms/watchOS/Vendor.framework/Info.plist': '<plist/>\n',
  'apps/apple/App/Resources/helper': Buffer.from('cffaedfe0c000001', 'hex'),
  'packages/engine-swift/Sources/Engine/Resources/libHelper.dylib': 'not really a dylib\n',
}, [
  'TV: apps/apple/Platforms/tvOS/libVendor.a is prebuilt code',
  'Watch: apps/apple/Platforms/watchOS/Vendor.framework/Info.plist is prebuilt code',
  'App: apps/apple/App/Resources/helper is prebuilt code',
  'package EnginePkg: packages/engine-swift/Sources/Engine/Resources/libHelper.dylib is prebuilt code',
]);
// Build scripts, scheme pre-actions, xcconfig files, headers, search paths and
// compiler or linker flags can add code the checker does not scan.
assertFail('pre-build script on a shipped target', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('  TV:\n    type: application\n', '  TV:\n    type: application\n    preBuildScripts:\n      - name: Generate\n        script: ./generate.sh\n')) },
  'TV: uses XcodeGen target keys the checker does not model (preBuildScripts)');
assertFail('scheme pre-actions', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(`${PROJECT_YML}schemes:\n  App:\n    build:\n      targets:\n        App: all\n      preActions:\n        - script: ./generate.sh\n`) },
  'project.yml schemes use preActions');
assertFail('project config files', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('packages:\n', 'configFiles:\n  Debug: Debug.xcconfig\npackages:\n')) },
  'project.yml uses top-level configFiles');
assertFail('bridging header and linker flags', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('    platform: watchOS\n', '    platform: watchOS\n    settings:\n      base:\n        SWIFT_OBJC_BRIDGING_HEADER: Shim.h\n      configs:\n        Release:\n          OTHER_LDFLAGS[sdk=watchos*]: $(inherited) -lvendor\n')) }, [
  'Watch: build setting SWIFT_OBJC_BRIDGING_HEADER can compile, import or link code the checker does not scan',
  'Watch: build setting OTHER_LDFLAGS[sdk=watchos*] can compile, import or link code the checker does not scan',
]);
const SWIFT_FLAGS = 'settings:\n  configs:\n    Debug:\n      OTHER_SWIFT_FLAGS: $(inherited) -DDEBUG_MENU\n    Release:\n      OTHER_SWIFT_FLAGS: "$(inherited) -DOFFICIAL_REFERENCE_SHEET"\ntargets:\n';
assertPass('-D conditions in Swift flags', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('targets:\n', SWIFT_FLAGS).replace('    platform: tvOS\n', '    platform: tvOS\n    settings:\n      base:\n        OTHER_SWIFT_FLAGS: ""\n')) });
assertFail('other Swift flags', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('targets:\n', SWIFT_FLAGS.replace('-DDEBUG_MENU', '-DDEBUG_MENU -Xcc -include -Xcc shim.h'))) },
  'project.yml settings: OTHER_SWIFT_FLAGS -Xcc -include -Xcc shim.h is not a -D condition');
assertFail('missing compiled source path', { ...tvManifest(TV_WITH_PACKAGE), 'apps/apple/Shared/Settings.swift': null },
  'App: sources path Shared/Settings.swift does not exist.');
assertFail('unsupported sources key', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('      - Platforms/watchOS\n', '      - path: Platforms/watchOS\n        includes:\n          - "*.swift"\n')) },
  'Watch: sources entry Platforms/watchOS uses unsupported XcodeGen keys (includes)');
assertFail('per-file compiler flags', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n        compilerFlags: ["-Xcc", "-include"]\n')) },
  'TV: sources entry Platforms/tvOS uses unsupported XcodeGen keys (compilerFlags)');
assertFail('unsupported target type', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(`${PROJECT_YML}  Kit:\n    type: framework\n    platform: iOS\n    sources:\n      - Shared\n`) },
  'Kit: target type "framework" is not supported');
assertFail('unsupported dependency', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('      - sdk: AVFoundation.framework\n', '      - framework: Vendor/Analytics.xcframework\n')) },
  'App: unsupported dependency {"framework":"Vendor/Analytics.xcframework"}');
assertFail('remote package', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('    path: ../../packages/engine-swift\n', '    url: https://example.com/engine.git\n    from: 1.0.0\n')) },
  'project.yml package EnginePkg is not a local path package');
assertFail('package with custom paths', { ...tvManifest(TV_WITH_PACKAGE), 'packages/engine-swift/Package.swift': PACKAGE_SWIFT.replace('.target(name: "Engine")', '.target(name: "Engine", path: "Elsewhere")') },
  'packages/engine-swift/Package.swift uses custom target paths');
assertFail('package plugins, macros, system libraries and unsafe flags', {
  ...tvManifest(TV_WITH_PACKAGE),
  'packages/engine-swift/Package.swift': PACKAGE_SWIFT.replace('.target(name: "Engine")', '.target(name: "Engine", swiftSettings: [.unsafeFlags(["-Xcc", "-include"])], plugins: ["Gen"]),\n        .plugin(name: "Gen", capability: .buildTool()),\n        .macro(name: "EngineMacros"),\n        .systemLibrary(name: "CShim")'),
}, [
  'packages/engine-swift/Package.swift uses plugins (build tool plugins generate code the checker cannot scan)',
  'packages/engine-swift/Package.swift uses macro targets',
  'packages/engine-swift/Package.swift uses system library targets',
  'packages/engine-swift/Package.swift uses unsafe compiler or linker flags',
]);
assertFail('target templates', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('  Watch:\n    type: application\n', '  Watch:\n    templates: [Base]\n    type: application\n')) },
  'Watch: target templates are not supported');
assertFail('unsupported YAML', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('    platform: watchOS\n', '    platform: *watch\n')) },
  'anchors, aliases and tags are not supported');

if (failures !== 0) {
  console.error(`required-reasons-test: failed with ${failures} failure(s).`);
  process.exit(1);
}
console.log('required-reasons-test: passed self-test fixtures.');
