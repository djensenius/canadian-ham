#!/usr/bin/env node
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, symlinkSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { execFileSync, spawnSync } from 'node:child_process';

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
    // The App target's folder reference: copied as data, never compiled.
    'content/lessons/m1/lesson.md': '# Lesson\n',
  };
}

function writeFixture(changes = {}) {
  const root = mkdtempSync(join(tmpdir(), 'required-reasons-test.'));
  const files = { ...baseFiles(), ...changes };
  for (const [path, content] of Object.entries(files)) {
    if (content === null) continue;
    mkdirSync(dirname(join(root, path)), { recursive: true });
    if (typeof content === 'object' && content.fifo) {
      execFileSync('mkfifo', [join(root, path)]);
    } else if (typeof content === 'object' && !Buffer.isBuffer(content)) {
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
    // Opening a FIFO blocks, so a checker that reads one must not hang the test.
    timeout: 60_000,
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

// Plist values keep their types, and only the XML subset Xcode writes is read.
const TV_ITEM = `${TV_MANIFEST_PATH} (TV): NSPrivacyAccessedAPITypes item`;
const tvSyntax = (line, text) => `${TV_MANIFEST_PATH}: invalid property list at line ${line}: ${text}`;
const CA92 = '<string>CA92.1</string>';
const USER_DEFAULTS_TYPE = `<string>${USER_DEFAULTS}</string>`;
const API_TYPES_OPEN = '\t<key>NSPrivacyAccessedAPITypes</key>\n\t<array>\n';
// Value types privacy manifests never use are rejected, not read as strings.
for (const [element, value] of [['data', 'CA92.1'], ['date', '2026-11-03T00:00:00Z'], ['integer', '921'], ['real', '92.1']]) {
  assertFail(`<${element}> reason`, tvManifestEdited(CA92, `<${element}>${value}</${element}>`),
    tvSyntax(12, `<${element}> values are not supported; privacy manifests use only dict, array, string and boolean values`));
}
assertFail('<data> category', tvManifestEdited(USER_DEFAULTS_TYPE, `<data>${USER_DEFAULTS}</data>`), tvSyntax(9, '<data> values are not supported'));
// Dictionaries, arrays and booleans where a string or array is expected.
assertFail('non-string categories', {
  ...tvManifestEdited(USER_DEFAULTS_TYPE, `<array>${USER_DEFAULTS_TYPE}</array>`),
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy': manifest(APP_MANIFEST).replace(USER_DEFAULTS_TYPE, '<true/>').replace(`<string>${BOOT_TIME}</string>`, '<dict/>'),
}, [
  `${TV_ITEM} 1: NSPrivacyAccessedAPIType must be a <string>, found <array> of 1 item.`,
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): NSPrivacyAccessedAPITypes item 1: NSPrivacyAccessedAPIType must be a <string>, found <true/>.',
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): NSPrivacyAccessedAPITypes item 2: NSPrivacyAccessedAPIType must be a <string>, found <dict>.',
]);
assertFail('reasons as a string', tvManifestEdited(`<array>\n\t\t\t\t${CA92}\n\t\t\t</array>`, CA92),
  `${TV_MANIFEST_PATH} (TV): ${USER_DEFAULTS} NSPrivacyAccessedAPITypeReasons must be an <array> of <string> codes, found <string> "CA92.1".`);
assertFail('non-string reasons', {
  ...tvManifestEdited(CA92, `<array>${CA92}</array>`),
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy': manifest(APP_MANIFEST).replace(CA92, '<true/>').replace('<string>35F9.1</string>', '<dict><key>code</key><string>35F9.1</string></dict>'),
}, [
  `${TV_MANIFEST_PATH} (TV): ${USER_DEFAULTS} reasons must be <string> codes, found <array> of 1 item.`,
  `apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): ${USER_DEFAULTS} reasons must be <string> codes, found <true/>.`,
  `apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): ${BOOT_TIME} reasons must be <string> codes, found <dict>.`,
]);
assertFail('API type item not a dictionary', tvManifestEdited(API_TYPES_OPEN, `${API_TYPES_OPEN}\t\t${USER_DEFAULTS_TYPE}\n`),
  `${TV_ITEM} 1 must be a <dict>, found <string> "${USER_DEFAULTS}".`);
assertFail('API type item with an extra key', tvManifestEdited(`${CA92}\n\t\t\t</array>\n`, `${CA92}\n\t\t\t</array>\n\t\t\t<key>NSPrivacyAccessedAPITypeNote</key>\n\t\t\t<string>CA92.1</string>\n`),
  `${TV_ITEM} 1 has unsupported keys "NSPrivacyAccessedAPITypeNote"; it may hold only NSPrivacyAccessedAPIType and NSPrivacyAccessedAPITypeReasons.`);
assertFail('tracking and empty arrays of the wrong type', {
  ...tvManifestEdited(TRACKING_FALSE, '\t<key>NSPrivacyTracking</key>\n\t<string>false</string>\n'),
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy': manifest(APP_MANIFEST).replace(TRACKING_DOMAINS_EMPTY, '\t<key>NSPrivacyTrackingDomains</key>\n\t<dict/>\n').replace(COLLECTED_EMPTY, '\t<key>NSPrivacyCollectedDataTypes</key>\n\t<string></string>\n'),
  'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy': manifest(WATCH_MANIFEST).replace(/\t<key>NSPrivacyAccessedAPITypes<\/key>\n\t<array>\n[\s\S]*?\n\t<\/array>\n/, '\t<key>NSPrivacyAccessedAPITypes</key>\n\t<dict/>\n'),
}, [
  `${TV_MANIFEST_PATH} (TV): NSPrivacyTracking must be present and false (<false/>), found <string> "false"`,
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): NSPrivacyTrackingDomains must be present and an empty array (<array/>), found <dict>',
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): NSPrivacyCollectedDataTypes must be present and an empty array (<array/>), found <string> ""',
  'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy (Watch): NSPrivacyAccessedAPITypes must be an <array>, found <dict>.',
]);
// Apple's parser keeps the last of duplicate keys, so duplicates are rejected.
assertFail('duplicate top-level key', tvManifestEdited(TRACKING_FALSE, `${TRACKING_FALSE}\t<key>NSPrivacyTracking</key>\n\t<true/>\n`),
  tvSyntax(28, 'duplicate key "NSPrivacyTracking"'));
assertFail('duplicate key in an API type item', tvManifestEdited(`${USER_DEFAULTS_TYPE}\n`, `${USER_DEFAULTS_TYPE}\n\t\t\t<key>NSPrivacyAccessedAPIType</key>\n\t\t\t<string>${DISK_SPACE}</string>\n`),
  tvSyntax(10, 'duplicate key "NSPrivacyAccessedAPIType"'));
assertFail('key with no value', tvManifestEdited(TRACKING_DOMAINS_EMPTY, '\t<key>NSPrivacyTrackingDomains</key>\n'), tvSyntax(29, 'key "NSPrivacyTrackingDomains" has no value'));
// Empty and whitespace-padded strings and keys: Apple compares them exactly.
assertFail('empty strings and keys', {
  ...tvManifestEdited(CA92, '<string/>'),
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy': manifest(APP_MANIFEST).replace(USER_DEFAULTS_TYPE, '<string></string>').replace(TRACKING_FALSE, `${TRACKING_FALSE}\t<key/>\n\t<false/>\n`),
}, [
  `${TV_MANIFEST_PATH} (TV): "" is not an approved reason for ${USER_DEFAULTS} (approved: CA92.1, 1C8F.1, AC6B.1).`,
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): unknown NSPrivacyAccessedAPIType "".',
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): unsupported top-level keys ""',
]);
assertFail('whitespace-padded values and keys', {
  ...tvManifestEdited(CA92, '<string> CA92.1 </string>'),
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy': manifest(APP_MANIFEST).replace(`<string>${BOOT_TIME}</string>`, `<string>${BOOT_TIME}\n</string>`).replace('<key>NSPrivacyTracking</key>', '<key> NSPrivacyTracking</key>'),
  'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy': manifest(WATCH_MANIFEST).replace('<string>35F9.1</string>', '<string>&#32;35F9.1</string>'),
}, [
  `${TV_MANIFEST_PATH} (TV): " CA92.1 " is not an approved reason for ${USER_DEFAULTS} (whitespace around a code is significant)`,
  `apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): unknown NSPrivacyAccessedAPIType "${BOOT_TIME}\\n".`,
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): unsupported top-level keys " NSPrivacyTracking"',
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): NSPrivacyTracking must be present and false (<false/>), found nothing',
  `apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy (Watch): " 35F9.1" is not an approved reason for ${BOOT_TIME} (whitespace around a code is significant)`,
]);
// A `__proto__` key is an ordinary unsupported key, never an inherited value.
assertFail('__proto__ and Object.prototype names', {
  ...tvManifestEdited(TRACKING_FALSE, '\t<key>__proto__</key>\n\t<dict>\n\t\t<key>NSPrivacyTracking</key>\n\t\t<false/>\n\t</dict>\n'),
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy': manifest(APP_MANIFEST).replace(USER_DEFAULTS_TYPE, '<string>constructor</string>').replace(`<string>${BOOT_TIME}</string>`, '<string>__proto__</string>'),
}, [
  `${TV_MANIFEST_PATH} (TV): unsupported top-level keys "__proto__"`,
  `${TV_MANIFEST_PATH} (TV): NSPrivacyTracking must be present and false (<false/>), found nothing`,
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): unknown NSPrivacyAccessedAPIType "constructor".',
  'apps/apple/App/Resources/PrivacyInfo.xcprivacy (App): unknown NSPrivacyAccessedAPIType "__proto__".',
]);
assertFail('unsupported top-level key', tvManifestEdited(TRACKING_FALSE, `${TRACKING_FALSE}\t<key>NSPrivacyAccessedAPITypesNote</key>\n\t<string>none</string>\n`),
  `${TV_MANIFEST_PATH} (TV): unsupported top-level keys "NSPrivacyAccessedAPITypesNote"; a manifest may hold only NSPrivacyTracking, NSPrivacyTrackingDomains, NSPrivacyCollectedDataTypes, NSPrivacyAccessedAPITypes`);
// Forms Apple's parser reads the same way are accepted: comments between
// elements, a byte-order mark, no XML declaration, the older DOCTYPE,
// open-and-close empty elements and entity or character references.
assertPass('equivalent plist forms', {
  ...tvManifest(TV_WITH_PACKAGE),
  [TV_MANIFEST_PATH]: `\uFEFF<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- privacy manifest -->
<plist version="1.0">
<dict>
\t<!-- no tracking -->
\t<key>NSPrivacyTracking</key>
\t<false></false>
\t<key>NSPrivacyTrackingDomains</key>
\t<array></array>
\t<key>NSPrivacyCollectedDataTypes</key>
\t<array/>
\t<key>NSPrivacyAccessedAPITypes</key>
\t<array>
\t\t<dict>
\t\t\t<key>NSPrivacyAccessedAPIType</key>
\t\t\t<string>NSPrivacyAccessedAPICategory&#85;ser&#x44;efaults</string>
\t\t\t<key>NSPrivacyAccessedAPITypeReasons</key>
\t\t\t<array><string>CA92&#46;1</string></array>
\t\t</dict>
\t\t<dict>
\t\t\t<key>NSPrivacyAccessedAPIType</key>
\t\t\t<string>${FILE_TIMESTAMP}</string>
\t\t\t<key>NSPrivacyAccessedAPITypeReasons</key>
\t\t\t<array><string>C617.1</string></array>
\t\t</dict>
\t</array>
</dict>
</plist>
<!-- end -->
`,
}, ['TV: 3 Swift files; apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy; categories: FileTimestamp [C617.1], UserDefaults [CA92.1]']);
// Everything else Apple's parser accepts or skips is rejected.
for (const [name, from, to, line, text, ...more] of [
  ['unknown entity', CA92, '<string>&reason;</string>', 12, 'unsupported entity or character reference "&reason;" in <string>'],
  ['bare ampersand', CA92, '<string>CA92 & 1</string>', 12, 'unsupported entity or character reference "& 1" in <string>'],
  ['comment inside a string', CA92, '<string>CA92<!-- x -->.1</string>', 12, 'expected </string>, found "<!-- x -->.1</string>', '(comments, CDATA and markup are not supported inside <string>)'],
  ['CDATA', CA92, '<string><![CDATA[CA92.1]]></string>', 12, 'expected </string>, found "<![CDATA[CA92.1]]></stri"'],
  ['comment inside a key', '<key>NSPrivacyTracking</key>', '<key>NSPrivacy<!-- x -->Tracking</key>', 26, 'expected </key>'],
  ['processing instruction', TRACKING_FALSE, `<?generator xcode?>\n${TRACKING_FALSE}`, 26, 'expected <key> or </dict>, found "<?generator xcode?>'],
  ['attribute on a value', CA92, '<string xml:space="preserve">CA92.1</string>', 12, 'expected a value element without attributes'],
  ['DOCTYPE with an internal subset', '<!DOCTYPE plist PUBLIC', '<!DOCTYPE plist [ <!ENTITY reason "CA92.1"> ]>\n<!DOCTYPE plist PUBLIC', 2, 'only the standard Apple plist DOCTYPE is supported'],
  ['missing plist root', /<plist version="1\.0">\n|<\/plist>\n/g, '', 3, 'expected <plist version="1.0">, found "<dict>'],
  ['two root values', '</dict>\n</plist>', '</dict>\n<dict/>\n</plist>', 31, 'expected </plist> after one value'],
  ['content after </plist>', '</plist>\n', '</plist>\n<dict/>\n', 32, 'unexpected content after </plist>'],
  ['unknown element', TRACKING_FALSE, '\t<key>NSPrivacyTracking</key>\n\t<FALSE/>\n', 27, 'unsupported element <FALSE>'],
]) {
  assertFail(`plist ${name}`, { [TV_MANIFEST_PATH]: manifest(TV_WITH_PACKAGE).replace(from, to) }, [tvSyntax(line, text), ...more]);
}
assertFail('binary plist', { [TV_MANIFEST_PATH]: Buffer.concat([Buffer.from('bplist00'), Buffer.from('d10102', 'hex')]) },
  `${TV_MANIFEST_PATH}: invalid property list: binary property lists are not read (convert it with plutil -convert xml1)`);
assertFail('UTF-16 plist', { [TV_MANIFEST_PATH]: Buffer.from(`\uFEFF${manifest(TV_WITH_PACKAGE)}`, 'utf16le') },
  `${TV_MANIFEST_PATH}: invalid property list: not valid UTF-8`);
assertFail('JSON plist', { [TV_MANIFEST_PATH]: '{"NSPrivacyTracking": false}\n' },
  tvSyntax(1, 'expected <plist version="1.0">, found "{\\"NSPrivacyTracking\\"'));
assertFail('array root', { [TV_MANIFEST_PATH]: '<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0">\n<array/>\n</plist>\n' },
  `${TV_MANIFEST_PATH} (TV): top level must be a <dict>, found <array> of 0 items.`);

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
// Scan entry paths are checked with lstat too, including every directory
// between the repository root and them, outside the apps/apple walk.
const ENGINE_PATH = '    path: ../../packages/engine-swift\n';
assertFail('symlinked package directory', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace(ENGINE_PATH, '    path: ../../packages/linked-swift\n')),
  'packages/linked-swift': { symlink: 'engine-swift' },
}, 'packages/linked-swift is a symbolic link; the checker does not follow links');
assertFail('symlinked package Sources', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace(ENGINE_PATH, '    path: ../../packages/shim-swift\n')),
  'packages/shim-swift/Package.swift': PACKAGE_SWIFT,
  'packages/shim-swift/Sources': { symlink: '../engine-swift/Sources' },
}, 'packages/shim-swift/Sources is a symbolic link');
assertFail('symlinked sources path and parent directory', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n      - path: ../../shared-link\n      - path: ../../linked-parent/Settings.swift\n')),
  'shared-link': { symlink: 'apps/apple/Shared' },
  'linked-parent': { symlink: 'apps/apple/Shared' },
}, ['shared-link is a symbolic link', 'linked-parent is a symbolic link']);
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
// Folder references and buildPhase none entries compile nothing and never
// supply the manifest, but their paths are checked and their contents scanned
// for prebuilt code (including inside asset catalogues) and symbolic links.
const LESSONS_FOLDER = '      - path: ../../content/lessons\n        type: folder\n        buildPhase: resources\n';
const withReferences = (extra = '') => projectYml(PROJECT_YML.replace(LESSONS_FOLDER, `${LESSONS_FOLDER}      - path: ../../content/drafts\n        buildPhase: none\n      - path: ../../content/optional-media\n        type: folder\n        optional: true\n${extra}`));
const REFERENCE_DATA = {
  'content/lessons/m1/quiz.json': '{"questions": []}\n',
  'content/lessons/Media.xcassets/Contents.json': '{"info": {"version": 1}}\n',
  // Disk space is not declared by App, and a nested manifest is not App's manifest.
  'content/lessons/Notes.swift': 'let free = URLResourceKey.volumeAvailableCapacityKey\n',
  'content/lessons/PrivacyInfo.xcprivacy': manifest([[DISK_SPACE, ['E174.1']]]),
  'content/drafts/Draft.swift': 'let size = attributes[.systemFreeSize]\n',
  'content/drafts/PrivacyInfo.xcprivacy': manifest([[DISK_SPACE, ['E174.1']]]),
};
assertPass('folder reference with plain data', { ...tvManifest(TV_WITH_PACKAGE), ...withReferences(), ...REFERENCE_DATA }, [
  'App: 4 Swift files; apps/apple/App/Resources/PrivacyInfo.xcprivacy; categories: FileTimestamp [C617.1], SystemBootTime [35F9.1], UserDefaults [CA92.1]',
]);
assertFail('folder reference with prebuilt code', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...withReferences(),
  ...REFERENCE_DATA,
  'content/lessons/tools/helper': Buffer.from('cffaedfe0c000001', 'hex'),
  'content/lessons/Media.xcassets/blob.dataset/blob': Buffer.from('cafebabe00000002', 'hex'),
  'content/drafts/libVendor.dylib': 'not really a dylib\n',
}, [
  'App: content/lessons/tools/helper is prebuilt code',
  'App: content/lessons/Media.xcassets/blob.dataset/blob is prebuilt code',
  'App: content/drafts/libVendor.dylib is prebuilt code',
]);
assertFail('missing folder reference and buildPhase none paths', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...withReferences('      - path: ../../content/missing-drafts\n        buildPhase: none\n'),
  'content/lessons/m1/lesson.md': null,
}, [
  'App: sources path ../../content/lessons does not exist.',
  'App: sources path ../../content/drafts does not exist.',
  'App: sources path ../../content/missing-drafts does not exist.',
]);
assertFail('symbolic links in and as folder references', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...withReferences('      - path: ../../content/linked-lessons\n        type: folder\n'),
  ...REFERENCE_DATA,
  'content/lessons/latest': { symlink: 'm1' },
  'content/linked-lessons': { symlink: 'lessons' },
}, [
  'content/lessons/latest is a symbolic link; the checker does not follow links',
  'content/linked-lessons is a symbolic link; the checker does not follow links',
]);
// Every native-code format the checker models: by magic bytes for files with
// any name, and by name for code bundles, Swift modules and text-based stubs.
const NATIVE_MAGIC = {
  'macho-32': 'feedface00000007', 'macho-32-swapped': 'cefaedfe07000000',
  'macho-64': 'feedfacf01000007', 'macho-64-swapped': 'cffaedfe07000001',
  'universal-32': 'cafebabe00000002', 'universal-32-swapped': 'bebafeca02000000',
  'universal-64': 'cafebabf00000002', 'universal-64-swapped': 'bfbafeca02000000',
  archive: '213c617263683e0a', 'thin-archive': '213c7468696e3e0a',
  bitcode: '4243c0de35140000', 'bitcode-wrapper': 'dec0170b00000000',
  'swift-module': 'e29ca80e01000000',
};
assertFail('native code formats by magic', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...Object.fromEntries(Object.entries(NATIVE_MAGIC).map(([label, hex]) => [`apps/apple/Platforms/tvOS/Payloads/${label}`, Buffer.from(hex, 'hex')])),
}, Object.keys(NATIVE_MAGIC).map((label) => `TV: apps/apple/Platforms/tvOS/Payloads/${label} is prebuilt code`));
assertFail('native code by name', {
  ...tvManifest(TV_WITH_PACKAGE),
  'apps/apple/Platforms/tvOS/Embedded/Helper.app/Info.plist': '<plist/>\n',
  'apps/apple/Platforms/tvOS/Modules/Vendor.swiftmodule/x.swiftdoc': 'doc\n',
  'apps/apple/Platforms/tvOS/Modules/Legacy.swiftmodule': 'module\n',
  'apps/apple/Platforms/tvOS/Modules/Vendor.private.swiftinterface': '// swift-interface-format-version: 1.0\n',
  'apps/apple/Platforms/tvOS/Stubs/libVendor.tbd': '--- !tapi-tbd\n',
  'apps/apple/Platforms/tvOS/Shim/module.map': 'module Shim { header "shim.h" }\n',
  'apps/apple/Platforms/tvOS/Shim/Prefix.pch': '#include <sys/stat.h>\n',
  'apps/apple/Platforms/tvOS/Shim/uptime.ll': 'declare i64 @mach_absolute_time()\n',
}, [
  'TV: apps/apple/Platforms/tvOS/Embedded/Helper.app/Info.plist is prebuilt code',
  'TV: apps/apple/Platforms/tvOS/Modules/Vendor.swiftmodule/x.swiftdoc is prebuilt code',
  'TV: apps/apple/Platforms/tvOS/Modules/Legacy.swiftmodule is prebuilt code',
  'TV: apps/apple/Platforms/tvOS/Modules/Vendor.private.swiftinterface is prebuilt code',
  'TV: apps/apple/Platforms/tvOS/Stubs/libVendor.tbd is prebuilt code',
  'TV: apps/apple/Platforms/tvOS/Shim/module.map is not Swift',
  'TV: apps/apple/Platforms/tvOS/Shim/Prefix.pch is not Swift',
  'TV: apps/apple/Platforms/tvOS/Shim/uptime.ll is not Swift',
]);
// Resource catalogues are traversed in ordinary target and package walks, but
// their Swift files, headers and nested manifests are not sources or the
// bundle's manifest; nor are manifests in wrappers or .lproj folders. A real
// .DS_Store (Bud1 magic) is scanned and passes.
const TV_SUMMARY = 'TV: 3 Swift files; apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy; categories: FileTimestamp [C617.1], UserDefaults [CA92.1]';
assertPass('resource catalogues, bundles and nested manifests that pass', {
  ...tvManifest(TV_WITH_PACKAGE),
  'apps/apple/Platforms/tvOS/Media.xcassets/Contents.json': '{"info": {"version": 1}}\n',
  'apps/apple/Platforms/tvOS/Media.xcassets/Script.dataset/Probe.swift': 'let free = URLResourceKey.volumeAvailableCapacityKey\n',
  'apps/apple/Platforms/tvOS/Media.xcassets/Privacy.dataset/PrivacyInfo.xcprivacy': manifest([[DISK_SPACE, ['E174.1']]]),
  'apps/apple/Platforms/tvOS/Media.xcassets/Header.dataset/shim.h': '#include <sys/stat.h>\n',
  'apps/apple/Platforms/tvOS/Settings.bundle/Root.plist': '<plist/>\n',
  'apps/apple/Platforms/tvOS/Settings.bundle/PrivacyInfo.xcprivacy': manifest([[DISK_SPACE, ['E174.1']]]),
  'apps/apple/Platforms/tvOS/Resources/en.lproj/PrivacyInfo.xcprivacy': manifest([[DISK_SPACE, ['E174.1']]]),
  'apps/apple/Platforms/tvOS/Resources/.DS_Store': Buffer.from('0000000142756431', 'hex'),
  'packages/engine-swift/Sources/Engine/Media.xcassets/Data.dataset/Disk.swift': 'let free = URLResourceKey.volumeAvailableCapacityKey\n',
}, [TV_SUMMARY]);
assertFail('prebuilt code and links in resource catalogues and excluded paths', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n      - path: ../../vendor-docs\n        excludes:\n          - Drafts\n')),
  'apps/apple/App/Resources/Assets.xcassets/Helper.dataset/Helper': Buffer.from('cffaedfe0c000001', 'hex'),
  'packages/engine-swift/Sources/Engine/Media.xcassets/Tool.dataset/tool': Buffer.from('cafebabf00000002', 'hex'),
  'packages/engine-swift/Sources/Engine/Media.xcassets/Linked.dataset/data': { symlink: '../Tool.dataset/tool' },
  'vendor-docs/README.md': '# Vendor\n',
  'vendor-docs/Drafts/tool': Buffer.from('bfbafeca02000000', 'hex'),
  'vendor-docs/Drafts/latest': { symlink: 'tool' },
  'apps/apple/Platforms/watchOS/.DS_Store': Buffer.from('feedfacf01000007', 'hex'),
  'apps/apple/App/DebugOnly/probe': Buffer.from('cffaedfe0c000001', 'hex'),
}, [
  'App: apps/apple/App/Resources/Assets.xcassets/Helper.dataset/Helper is prebuilt code',
  'package EnginePkg: packages/engine-swift/Sources/Engine/Media.xcassets/Tool.dataset/tool is prebuilt code',
  'packages/engine-swift/Sources/Engine/Media.xcassets/Linked.dataset/data is a symbolic link',
  'TV: vendor-docs/Drafts/tool is prebuilt code',
  'vendor-docs/Drafts/latest is a symbolic link',
  'Watch: apps/apple/Platforms/watchOS/.DS_Store is prebuilt code',
  'App: apps/apple/App/DebugOnly/probe is prebuilt code',
]);
// Only a manifest copied flat into the bundle root is the target's manifest:
// not one excluded and re-added through a copyFiles phase, not one inside a
// directory added as a single file, and not one inside .lproj or a bundle.
assertFail('nested manifests are not the bundle manifest', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML
    .replace('          - "DebugOnly/**"\n', '          - "DebugOnly/**"\n          - Resources/PrivacyInfo.xcprivacy\n      - path: App/Resources/PrivacyInfo.xcprivacy\n        buildPhase:\n          copyFiles:\n            destination: plugins\n            subpath: Extras\n')
    .replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n        excludes:\n          - Resources\n      - path: Platforms/tvOS/Resources\n        type: file\n')),
  'apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy': null,
  'apps/apple/Platforms/watchOS/Resources/en.lproj/PrivacyInfo.xcprivacy': manifest(WATCH_MANIFEST),
  'apps/apple/Platforms/watchOS/Kit.bundle/PrivacyInfo.xcprivacy': manifest(WATCH_MANIFEST),
}, [
  'App: expected exactly one bundled PrivacyInfo.xcprivacy, found 0.',
  'TV: expected exactly one bundled PrivacyInfo.xcprivacy, found 0.',
  'Watch: expected exactly one bundled PrivacyInfo.xcprivacy, found 0.',
]);
// Exclude wildcards never match a leading dot (glob(3) without GLOB_PERIOD),
// so hidden Swift files under Generated/* and Cache/** are still compiled.
assertFail('hidden files are not matched by exclude wildcards', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n        excludes:\n          - "Generated/*"\n          - "Cache/**"\n')),
  'apps/apple/Platforms/tvOS/Generated/Visible.swift': 'let excludedUptime = ProcessInfo.processInfo.systemUptime\n',
  'apps/apple/Platforms/tvOS/Generated/.Hidden.swift': 'let hiddenUptime = ProcessInfo.processInfo.systemUptime\n',
  'apps/apple/Platforms/tvOS/Cache/.state/Snapshot.swift': 'let ticks = mach_absolute_time()\n',
}, [
  TV_BOOT_TIME,
  'apps/apple/Platforms/tvOS/Cache/.state/Snapshot.swift:1',
  'apps/apple/Platforms/tvOS/Generated/.Hidden.swift:1',
  // The visible file is excluded (so it is reported as compiled by no target).
  'apps/apple/Platforms/tvOS/Generated/Visible.swift is not compiled by any project.yml target',
]);
assertFail('unsupported exclude patterns', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n        excludes:\n          - "[Tt]ests"\n      - path: Shared\n        excludes:\n          - "**.swift"\n      - path: ../../content/lessons\n        excludes:\n          - "{A,B}"\n')),
}, [
  'TV: sources entry Platforms/tvOS: exclude pattern "[Tt]ests"',
  'TV: sources entry Shared: exclude pattern "**.swift"',
  'TV: sources entry ../../content/lessons: exclude pattern "{A,B}"',
]);
assertFail('unsupported source type and build phase', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n      - path: ../../content/synced\n        type: syncedFolder\n      - path: Shared/Settings.swift\n        buildPhase: frameworks\n')),
}, [
  'TV: sources entry ../../content/synced uses unsupported type "syncedFolder"',
  'TV: sources entry Shared/Settings.swift uses unsupported buildPhase "frameworks"',
]);
// A FIFO or other special file cannot be scanned (opening a FIFO blocks), so
// it fails whether it sits inside a walked directory or is an entry path.
assertFail('special files', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n      - path: ../../content/pipe\n        type: file\n        buildPhase: resources\n')),
  'apps/apple/Platforms/tvOS/Resources/pipe': { fifo: true },
  'content/pipe': { fifo: true },
}, [
  'apps/apple/Platforms/tvOS/Resources/pipe is not a regular file, directory or symbolic link',
  'content/pipe is not a regular file, directory or symbolic link',
]);
assertFail('package paths outside the package', {
  ...tvManifest(TV_WITH_PACKAGE),
  'packages/engine-swift/Package.swift': PACKAGE_SWIFT.replace('.target(name: "Engine")', '.target(name: "Engine", resources: [.copy("../Shared")])'),
}, 'packages/engine-swift/Package.swift uses paths outside the target directory (..)');
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
assertFail('split -D condition', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('targets:\n', SWIFT_FLAGS.replace('-DDEBUG_MENU', '-D DEBUG_MENU'))) },
  'project.yml settings: OTHER_SWIFT_FLAGS "-D DEBUG_MENU" splits the flag from its name; use the -DDEBUG_MENU form.');
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

// project.yml is read as a strict YAML subset: what the parser models must
// mean what Yams/XcodeGen read, and everything else fails.
const WATCH_PLATFORM = '    platform: watchOS\n';
const watchYml = (text) => ({ ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace(WATCH_PLATFORM, text)) });
const watchSettings = (lines) => watchYml(`${WATCH_PLATFORM}    settings:\n      base:\n${lines}`);
const YAML_SUBSET = 'the checker reads a strict YAML subset';
assertFail('escaped build-setting key', watchSettings('        "OTHER\\u005fLDFLAGS": -lvendor\n'),
  ['apps/apple/project.yml:39: double-quoted escape \\u is not supported (only \\\\ and \\" are decoded); write the character itself', YAML_SUBSET]);
assertFail('quoted build-setting keys', watchSettings('        \'OTHER_LDFLAGS\': -lvendor\n        "HEADER_SEARCH_PATHS[sdk=watchos*]": vendor\n'), [
  'Watch: build setting OTHER_LDFLAGS can compile, import or link code the checker does not scan',
  'Watch: build setting HEADER_SEARCH_PATHS[sdk=watchos*] can compile, import or link code the checker does not scan',
]);
// Mappings have no prototype: a target named __proto__ is still checked, and
// a package named toString is unknown rather than Object.prototype.toString.
assertFail('prototype keys', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('      - target: Watch\n', '      - target: Watch\n      - package: toString\n')
    .concat('  __proto__:\n    type: application\n    platform: tvOS\n    sources:\n      - Proto\n')),
  'apps/apple/Proto/Uptime.swift': 'let protoUptime = ProcessInfo.processInfo.systemUptime\n',
  'apps/apple/Proto/PrivacyInfo.xcprivacy': manifest([]),
}, [
  '__proto__: uses NSPrivacyAccessedAPICategorySystemBootTime',
  'App: depends on unknown package toString.',
]);
// Keys are matched as Yams reads them: a quoted key may hold ": ", and a key
// starting with "-" (no space) is a plain key, not a sequence item.
assertFail('quoted key with ": "', watchSettings('        "OTHER_LDFLAGS[sdk=a: b]": -lvendor\n'),
  'Watch: build setting OTHER_LDFLAGS[sdk=a: b] can compile, import or link code the checker does not scan');
assertPass('key starting with -', watchSettings('        SWIFT_VERSION: "6.0"\n        -OTHER_LDFLAGS: x\n'), ['Apple required-reason API check passed']);
assertFail('duplicate keys', watchYml(`${WATCH_PLATFORM}    settings:\n      base:\n        OTHER_LDFLAGS: -lvendor\n    settings: {}\n`),
  'apps/apple/project.yml:40: duplicate key "settings"');
for (const [name, text, expected] of [
  ['merge key', '    <<: *base\n', 'merge keys (<<) are not supported'],
  ['anchor', '    platform: &p watchOS\n', 'anchors, aliases and tags are not supported: &p watchOS'],
  ['tag', '    platform: !!str watchOS\n', 'anchors, aliases and tags are not supported: !!str watchOS'],
  ['": " in a plain key', '    platform: watchOS\n    settings:\n      OTHER_LDFLAGS[sdk=a: b]: x\n', '": " inside a plain scalar is not supported; quote it: b]: x'],
  ['complex key', '    ? OTHER_LDFLAGS\n    : -lvendor\n', 'complex keys ("? ") are not supported'],
  ['continuation line', '    platform: watch\n      OS\n', 'apps/apple/project.yml:37: a more-indented line after a scalar (a multi-line scalar or continuation line) is not supported'],
  ['multi-line double-quoted scalar', '    platform: "watch\n      OS"\n', 'unterminated double-quoted scalar; quoted scalars must close on the same line'],
  ['multi-line single-quoted scalar', "    platform: 'watch\n      OS'\n", 'unterminated single-quoted scalar; quoted scalars must close on the same line'],
  ['nested flow sequence', '    platform: watchOS\n    supportedDestinations: [[watchOS], iOS]\n', 'nested flow collections are not supported'],
  ['multi-line flow sequence', '    platform: watchOS\n    supportedDestinations: [watchOS,\n      iOS]\n', 'flow sequences must close on the same line'],
  ['flow sequence trailing comma', '    platform: watchOS\n    supportedDestinations: [watchOS, ]\n', 'empty flow sequence item (or trailing comma)'],
  ['flow mapping', '    platform: watchOS\n    info: {path: Info.plist}\n', 'flow mappings other than {} are not supported: {path: Info.plist}'],
  ['block scalar indentation indicator', '    platform: watchOS\n    postBuildScripts:\n      - script: |2\n            echo hi\n', 'block scalar header |2 is not supported (indentation indicators are not modelled)'],
  ['block scalar outside script', '    platform: |\n      watchOS\n', 'block scalars are only supported as a script value, not for platform'],
  ['block scalar dedent', '    platform: watchOS\n    postBuildScripts:\n      - script: |\n            echo one\n          echo two\n', 'a block scalar line is indented less than its first line but more than its key'],
  ['boolean key', '    platform: watchOS\n    settings:\n      NO: x\n', 'plain key "NO" is a boolean in YAML 1.1, not a string; quote it'],
  ['number key', '    platform: watchOS\n    settings:\n      0x1F: x\n', 'plain key "0x1F" is a number in YAML 1.1, not a string; quote it'],
  ['timestamp value', '    platform: 2024-01-02\n', '2024-01-02 is a YAML timestamp; quote it'],
  ['": " in a plain value', '    platform: watchOS\n    settings:\n      OTHER_SWIFT_FLAGS: a: b\n', '": " inside a plain scalar is not supported; quote it: a: b'],
  ['reserved indicator', '    platform: @watchOS\n', 'a plain scalar cannot start with "@"; quote it: @watchOS'],
  ['text after a quoted scalar', "    platform: 'watch'OS\n", "unexpected text after a quoted scalar: OS"],
  ['nested sequence on one line', '    platform: watchOS\n    sources:\n      - - Platforms/watchOS\n', 'nested sequences on one line ("- - item") are not supported'],
  ['complex key in a sequence', '    platform: watchOS\n    dependencies:\n      - ? target\n        : App\n', 'complex keys ("? ") are not supported'],
  ['flow sequence item with a colon', '    platform: watchOS\n    supportedDestinations: [watchOS:iOS]\n', 'flow sequence item watchOS:iOS holds [ ] { } # or :; quote it'],
  ['text after a flow sequence', '    platform: watchOS\n    supportedDestinations: [watchOS] iOS\n', 'unexpected text after a flow sequence: iOS'],
  ['block scalar leading blank line', '    platform: watchOS\n    postBuildScripts:\n      - script: |\n                \n            echo hi\n', 'a leading blank line of a block scalar is indented more than its first line'],
  ['inconsistent indentation', '    platform: watchOS\n    settings:\n      base:\n        A: b\n       C: d\n', 'apps/apple/project.yml:40: unexpected indentation'],
  ['comment before a colon', '    platform: watchOS\n    settings # note: here\n', 'expected "key: value", found: settings # note: here'],
  ['tab', '    platform:\twatchOS\n', 'apps/apple/project.yml:36: a tab is not supported'],
  ['lone carriage return', '    platform: watchOS\r    settings: {}\n', 'character U+000D is not supported'],
  ['line separator', '    platform: watchOS\u2028\n', 'character U+2028 is not supported'],
  ['byte order mark inside the file', '\uFEFF    platform: watchOS\n', 'character U+FEFF is not supported'],
  ['environment variable in a value', '    platform: watchOS\n    sources:\n      - ${HOME}/Sources\n', 'XcodeGen environment variables (${...}) are only supported in script values: ${HOME}/Sources'],
  ['environment variable in a key', '    platform: watchOS\n    settings:\n      ${SETTING}: x\n', 'XcodeGen environment variables (${...}) are not supported in keys: ${SETTING}'],
]) {
  assertFail(`unsupported YAML: ${name}`, watchYml(text), [expected, YAML_SUBSET]);
}
for (const [name, text, expected] of [
  ['document start marker', `---\n${PROJECT_YML}`, 'apps/apple/project.yml:1: document markers (--- and ...) are not supported'],
  ['document end marker', `${PROJECT_YML}...\n`, 'document markers (--- and ...) are not supported'],
  ['directive', `%YAML 1.1\n${PROJECT_YML}`, 'directives (%YAML, %TAG) are not supported'],
  ['tag directive', `%TAG !e! tag:example.com,2000:\n${PROJECT_YML}`, 'apps/apple/project.yml:1: directives (%YAML, %TAG) are not supported'],
  ['content after the document', `${PROJECT_YML}- stray\n`, 'unexpected content after document'],
]) {
  assertFail(`unsupported YAML: ${name}`, { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(text) }, [expected, YAML_SUBSET]);
}
assertFail('top level must be a mapping', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml('- name: Fixture\n') },
  'project.yml: the top level must be a mapping.');
assertFail('targets must be a mapping', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml('name: Fixture\ntargets: [App]\n') },
  'project.yml: packages and targets must be mappings.');
assertFail('top-level include', { ...tvManifest(TV_WITH_PACKAGE), ...projectYml(`include: [base.yml]\n${PROJECT_YML}`) },
  'project.yml uses top-level include');
// Plain scalars keep their YAML 1.1 types, and consumers that need a string
// or a real boolean fail closed on anything else.
const appSource = (lines) => ({ ...tvManifest(TV_WITH_PACKAGE), ...projectYml(PROJECT_YML.replace('      - path: Shared/Settings.swift\n', `      - path: Shared/Settings.swift\n${lines}`)) });
assertPass('optional: yes is a YAML boolean', appSource('      - path: Missing/Generated.swift\n        optional: yes\n'));
assertFail('quoted optional is a string', appSource('      - path: Missing/Generated.swift\n        optional: "true"\n'),
  'App: sources path Missing/Generated.swift does not exist.');
assertFail('YAML types where strings are needed', appSource('      - path: 2024\n      - path: Shared\n        type: ~\n      - path: Platforms\n        excludes: [~, yes]\n'), [
  'App: unsupported sources entry {"path":2024}',
  'App: sources entry Shared uses unsupported type null',
  'App: sources entry Platforms excludes must be a list of strings, found [null,true]',
]);
// YAML 1.1 numbers (sexagesimal 1:30 is 90, 017 is octal) are not strings.
assertFail('YAML 1.1 numbers', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace(WATCH_PLATFORM, '    platform: 1:30\n')
    .replace('      - path: Shared/Settings.swift\n', '      - path: Shared/Settings.swift\n      - path: Platforms\n        excludes: [017, 0o17, 0b11, -0x1F, 1_000, 6.0, .5]\n')),
}, [
  'Watch: platform must be one platform name, found 90',
  'App: sources entry Platforms excludes must be a list of strings, found [15,15,3,-31,1000,6,0.5]',
]);
assertFail('dependencies name exactly one kind as a string', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('      - sdk: AVFoundation.framework\n', '      - sdk: AVFoundation.framework\n      - package: yes\n      - package: EnginePkg\n        framework: Vendor/Analytics.framework\n      - target: Watch\n        bundle: Vendor/Helper.bundle\n')),
}, [
  'App: unsupported dependency {"package":true}',
  'App: unsupported dependency {"package":"EnginePkg","framework":"Vendor/Analytics.framework"}; a dependency must name exactly one target, package or sdk as a string',
  'App: unsupported dependency {"target":"Watch","bundle":"Vendor/Helper.bundle"}',
]);
assertFail('package path must be a string', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('    path: ../../packages/unlinked-swift\n', '    path: yes\n').replace('      - target: Watch\n', '      - package: UnlinkedPkg\n      - target: Watch\n')),
}, 'project.yml package UnlinkedPkg is not a local path package');
// XcodeGen variables and multi-platform targets change which files compile.
assertFail('XcodeGen variables and platform lists', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace(WATCH_PLATFORM, '    platform: [watchOS, tvOS]\n')
    .replace('      - path: Platforms/tvOS\n', '      - path: Platforms/$platform\n        optional: true\n      - path: Platforms/tvOS\n')
    .replace('    path: ../../packages/unlinked-swift\n', '    path: ../../packages/unlinked-swift\n    url: https://example.com/unlinked.git\n')
    .replace('      - package: EnginePkg\n      - target: Watch\n', '      - package: EnginePkg\n      - package: UnlinkedPkg\n      - target: Watch\n')),
}, [
  'Watch: platform must be one platform name, found ["watchOS","tvOS"]; multi-platform targets are not modelled',
  'TV: sources entry Platforms/$platform uses $ in a path or exclude',
  'project.yml package UnlinkedPkg uses keys the checker does not model (url)',
]);
// Modelled constructs: quoted flow items with commas, quotes and # inside
// quotes, '' and \\ \" decoding, comments after apostrophes, {}, script
// blocks with ${...}, a leading byte order mark and CRLF line ends.
const MODELLED_YAML = PROJECT_YML
  .replace('    platform: watchOS\n    sources:\n', '    platform: watchOS\n    sources: # the watch sources\n')
  .replace('          - "DebugOnly/**"\n', '          - "DebugOnly/**" # debug only\n')
  .replace('    supportedDestinations: [iOS, macOS]\n', '    supportedDestinations: [ iOS , "mac,OS" , \'x\'\'y\' ]\n')
  .replace('      - path: ../../content/lessons\n', '      - path: ../../content/Kid\'s notes # the lessons\' folder\n        type: folder\n      - path: ../../content/lessons\n')
  .replace('      - path: Platforms/tvOS\n', '      - path: Platforms/tvOS\n      - path: "Shared/a \\"q\\" #1 \\\\x.swift" # quoted\n      - path: \'Shared/It\'\'s.swift\'\n      - path: "Shared/End\\\\" # ends in a backslash\n')
  .replace('  TV:\n    type: application\n', '  TV:\n    type: application\n    settings: {} # none\n    postBuildScripts:\n      - name: Copy\n        script: |\n          cp "${SRCROOT}/a" "${TARGET_BUILD_DIR}/b"\n\n          # a comment line inside the script\n        basedOnDependencyAnalysis: false\n      - name: Run\n        script: bash "${SRCROOT}/run.sh"\n');
const MODELLED_FILES = {
  ...tvManifest(TV_WITH_PACKAGE),
  "content/Kid's notes/a.md": '# Notes\n',
  'apps/apple/Shared/a "q" #1 \\x.swift': 'let quotedName = "x"\n',
  "apps/apple/Shared/It's.swift": 'let apostrophe = "y"\n',
  'apps/apple/Shared/End\\/End.swift': 'let backslash = "z"\n',
};
const MODELLED_OUTPUT = ['App: 4 Swift files', 'TV: 6 Swift files', 'Apple required-reason API check passed'];
assertPass('modelled YAML', { ...MODELLED_FILES, ...projectYml(MODELLED_YAML) }, MODELLED_OUTPUT);
assertPass('modelled YAML with a byte order mark and CRLF', { ...MODELLED_FILES, ...projectYml(`\uFEFF${MODELLED_YAML.replace(/\n/g, '\r\n')}`) }, MODELLED_OUTPUT);
// Excludes with quoted commas are read as one glob each.
assertPass('quoted comma in a flow sequence', {
  ...tvManifest(TV_WITH_PACKAGE),
  ...projectYml(PROJECT_YML.replace('        excludes:\n          - "DebugOnly/**"\n', '        excludes: ["DebugOnly/**", "a,b/**"]\n').replace('      - path: App/DebugOnly\n', '      - path: App/DebugOnly\n      - path: "App/a,b"\n')),
  'apps/apple/App/a,b/Disk.swift': 'var info = statfs(); let status = statfs("/", &info)\n',
}, ['App: 4 Swift files']);

// Package.swift is read as a strict Swift subset; anything that could build,
// rename or hide targets fails.
const packageFail = (name, text, expected) => assertFail(`Package.swift: ${name}`, { ...tvManifest(TV_WITH_PACKAGE), 'packages/engine-swift/Package.swift': text },
  ['packages/engine-swift/Package.swift:', `uses Swift the checker does not model (${expected})`, 'extend scripts/check-apple-required-reasons.mjs before linking it']);
const ENGINE_TARGET = '.target(name: "Engine")';
packageFail('raw string', PACKAGE_SWIFT.replace(ENGINE_TARGET, '.target(name: #"Engine"#)'), 'a raw string or # directive');
packageFail('unicode escape', PACKAGE_SWIFT.replace(ENGINE_TARGET, '.target(name: "Engin\\u{65}")'), 'a string escape or interpolation');
packageFail('interpolation', PACKAGE_SWIFT.replace(ENGINE_TARGET, '.target(name: "\\(engine)")'), 'a string escape or interpolation');
packageFail('multi-line string', PACKAGE_SWIFT.replace(ENGINE_TARGET, '.target(name: """\n    Engine\n    """)'), 'a multi-line string literal');
packageFail('conditional compilation', PACKAGE_SWIFT.replace('    targets: [\n', '    targets: [\n#if os(macOS)\n        .target(name: "MacOnly"),\n#endif\n'), 'conditional compilation (#if)');
packageFail('target built by a variable', PACKAGE_SWIFT.replace('let package', 'let hidden = Target.target(name: "Hidden", path: "Elsewhere")\nlet package'), '"hidden" where package was expected');
packageFail('helper-built dependencies', PACKAGE_SWIFT.replace('let package', 'func deps() -> [Package.Dependency] { [] }\nlet package').replace('    name: "Engine",\n', '    name: "Engine",\n    dependencies: deps(),\n'), '"func" where let was expected');
packageFail('variable argument', PACKAGE_SWIFT.replace('    name: "Engine",\n', '    name: "Engine",\n    dependencies: deps,\n'), '"deps" where a string, array or .member value was expected');
packageFail('type-qualified member', PACKAGE_SWIFT.replace(ENGINE_TARGET, 'Target.target(name: "Engine")'), '"Target" where a string, array or .member value was expected');
packageFail('map', PACKAGE_SWIFT.replace('    targets: [\n', '    targets: ["Engine"].map { .target(name: $0) } + [\n'), '"." where ) was expected');
packageFail('operator', PACKAGE_SWIFT.replace('    ]\n)', '    ] + extraTargets\n)'), 'the character "+"');
packageFail('whitespace after a dot', PACKAGE_SWIFT.replace(ENGINE_TARGET, '. target(name: "Engine")'), 'whitespace after "."');
packageFail('extra import', PACKAGE_SWIFT.replace('import PackageDescription\n', 'import PackageDescription\nimport Foundation\n'), '"import" where let was expected');
packageFail('statement after the package', `${PACKAGE_SWIFT}package.targets.append(.target(name: "Hidden"))\n`, '"package" after the Package(...) declaration');
assertPass('Package.swift comments, backticks and trailing commas', {
  ...tvManifest(TV_WITH_PACKAGE),
  'packages/engine-swift/Package.swift': PACKAGE_SWIFT.replace(ENGINE_TARGET, '.`target`(\n            name: /* the module */ "Engine", // trailing comment\n            swiftSettings: [.swiftLanguageMode(.v6),],\n        )'),
});
assertFail('Package.swift version-specific manifest and other source directories', {
  ...tvManifest(TV_WITH_PACKAGE),
  'packages/engine-swift/Package@swift-6.0.swift': PACKAGE_SWIFT.replace(ENGINE_TARGET, '.target(name: "Engine", path: "Elsewhere")'),
  'packages/engine-swift/src/Hidden/Hidden.swift': 'let hiddenUptime = ProcessInfo.processInfo.systemUptime\n',
}, [
  'packages/engine-swift/Package@swift-6.0.swift is a version-specific manifest, which SwiftPM prefers over Package.swift',
  'packages/engine-swift/src is a SwiftPM source directory the checker does not scan (only Sources is)',
]);

if (failures !== 0) {
  console.error(`required-reasons-test: failed with ${failures} failure(s).`);
  process.exit(1);
}
console.log('required-reasons-test: passed self-test fixtures.');
