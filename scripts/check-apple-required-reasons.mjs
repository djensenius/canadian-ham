#!/usr/bin/env node
// Checks that every shipped Apple app target declares, in its own bundled
// PrivacyInfo.xcprivacy, exactly the required-reason API categories its Swift
// sources (and the local Swift packages it links) use, with approved reasons.
// Each manifest must also keep NSPrivacyTracking = false and empty
// NSPrivacyTrackingDomains / NSPrivacyCollectedDataTypes, and shipped targets
// and linked packages may contain only Swift sources.
//
// Categories, listed APIs and reason codes follow Apple's current
// documentation, quoted in docs/release/privacy-label-evidence.md:
// https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
// https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
//
// Target membership comes from apps/apple/project.yml (the XcodeGen spec), so
// new source folders are mapped automatically. Every Swift file under
// apps/apple must belong to some project.yml target; XcodeGen constructs this
// script does not understand fail the check rather than being skipped, as do
// symbolic links and special files, prebuilt code (Mach-O, universal, archive,
// bitcode and Swift module formats, also inside resource catalogues, excluded
// paths, folder references and buildPhase none entries, which are otherwise
// not compiled), build scripts that run before compiling,
// header/search-path/linker settings, non -D Swift flags, unmodelled source
// types, build phases and exclude globs, and SwiftPM plugins, macros, system
// libraries, unsafe flags and paths outside the package.
// Manifests are read with a strict XML plist parser that keeps value types
// and rejects anything Apple's parser could read differently. project.yml is
// read with a strict YAML subset parser (see parseYamlSubset) and each linked
// Package.swift with a strict Swift subset grammar (see checkPackageSyntax);
// constructs either could read differently from XcodeGen or SwiftPM fail.
//
// Limitation: `#if` conditions are not evaluated, so an API compiled out on a
// platform still counts for every target that compiles the file, and string
// and regex literals are scanned too. Both err towards declaring a category;
// binary inspection of the built bundles is the cross-check. API names built
// at run time (computed KVC keys, dlsym, NSSelectorFromString with a computed
// string) and wholesale attribute reads that never name a listed key are not
// detected; docs/release/privacy-label-evidence.md lists every such class.
import { closeSync, existsSync, lstatSync, openSync, readdirSync, readFileSync, readSync, statSync } from 'node:fs';
import { basename, dirname, extname, join, normalize, relative, resolve, sep } from 'node:path';

const root = resolve(process.env.REQUIRED_REASONS_ROOT ?? process.cwd());
const verbose = process.argv.includes('--verbose');
const appleDir = join(root, 'apps/apple');
const projectYmlPath = join(appleDir, 'project.yml');
const MANIFEST_NAME = 'PrivacyInfo.xcprivacy';

// Each category's approved app reasons and the source spellings that use it.
// SDK-only reasons are valid codes but may not be declared by an app.
const CATEGORIES = {
  NSPrivacyAccessedAPICategoryFileTimestamp: {
    label: 'File timestamp',
    appReasons: ['DDA9.1', 'C617.1', '3B52.1'],
    sdkOnlyReasons: ['0A2A.1'],
    patterns: [
      [/\.creationDate\b/, 'creationDate'],
      [/\.modificationDate\b/, 'modificationDate'],
      [/\bfileModificationDate\b/, 'fileModificationDate'],
      [/\bcontentModificationDate(?:Key)?\b/, 'contentModificationDateKey'],
      [/\bcreationDateKey\b/, 'creationDateKey'],
      [/\bNSFile(?:Creation|Modification)Date\b/, 'NSFileCreationDate/NSFileModificationDate'],
      [/\bNSURL(?:Creation|ContentModification)DateKey\b/, 'NSURLCreationDateKey/NSURLContentModificationDateKey'],
      // C functions are matched as identifiers, not only calls, so references
      // such as `let read = Darwin.fstat` count. Bare `stat` is also a common
      // Swift name, so it counts only as a call, a C-module-qualified name or the
      // whole right-hand side of an assignment. Patterns run over the whole
      // file, so `\s*` also spans line breaks (Swift allows one before `.`, not
      // after it), and lookbehinds keep the reported line on `stat` itself.
      [/\bf?getattrlist(?:bulk|at)?\b/, 'getattrlist family'],
      [/\b[fl]stat\b|\bfstatat\b/, 'fstat/lstat/fstatat'],
      [/\bstat\s*\(|(?<=\b(?:Darwin|Glibc|SwiftGlibc|Musl|Foundation|ucrt)\s*\.)stat\b|(?<==\s*)stat(?=\s*(?:;|$))/, 'stat'],
      // String literals are scanned, so other API names count inside them
      // (key-value coding, selectors, `@_silgen_name`). These names are only
      // matched after a `.` above, so a literal holding exactly one counts too.
      [/"(?:creationDate|modificationDate|stat)"/, 'API name string literal'],
    ],
  },
  NSPrivacyAccessedAPICategorySystemBootTime: {
    label: 'System boot time',
    appReasons: ['35F9.1', '8FFB.1', '3D61.1'],
    sdkOnlyReasons: [],
    patterns: [
      [/\bsystemUptime\b/, 'systemUptime'],
      [/\bmach_absolute_time\b/, 'mach_absolute_time'],
      // Not on Apple's list, but a direct boot-time read; flagged conservatively.
      [/\bkern\.boottime\b|\bKERN_BOOTTIME\b/, 'sysctl kern.boottime'],
    ],
  },
  NSPrivacyAccessedAPICategoryDiskSpace: {
    label: 'Disk space',
    appReasons: ['85F4.1', 'E174.1', '7D9E.1', 'B728.1'],
    sdkOnlyReasons: [],
    patterns: [
      [/\bvolumeAvailableCapacity(?:ForImportantUsage|ForOpportunisticUsage)?(?:Key)?\b/, 'volumeAvailableCapacity*'],
      [/\bvolumeTotalCapacity(?:Key)?\b/, 'volumeTotalCapacityKey'],
      // Raw values for URLResourceKey(rawValue:).
      [/\bNSURLVolume(?:AvailableCapacity(?:ForImportantUsage|ForOpportunisticUsage)?|TotalCapacity)Key\b/, 'NSURLVolume*CapacityKey'],
      [/\.systemFreeSize\b|\bNSFileSystemFreeSize\b/, 'systemFreeSize'],
      [/\.systemSize\b|\bNSFileSystemSize\b/, 'systemSize'],
      [/"(?:systemFreeSize|systemSize)"/, 'API name string literal'],
      [/\bf?statv?fs\b/, 'statfs/statvfs/fstatfs/fstatvfs'],
      [/\bf?getattrlist(?:at)?\b/, 'getattrlist family'],
    ],
  },
  NSPrivacyAccessedAPICategoryActiveKeyboards: {
    label: 'Active keyboards',
    appReasons: ['3EC4.1', '54BD.1'],
    sdkOnlyReasons: [],
    patterns: [[/\bactiveInputModes\b/, 'activeInputModes']],
  },
  NSPrivacyAccessedAPICategoryUserDefaults: {
    label: 'User defaults',
    appReasons: ['CA92.1', '1C8F.1', 'AC6B.1'],
    sdkOnlyReasons: ['C56D.1'],
    patterns: [
      [/\bUserDefaults\b/, 'UserDefaults'],
      [/\bNSUserDefaults\b|\bstandardUserDefaults\b/, 'NSUserDefaults'],
      // SwiftUI and Core Foundation front-ends to the same defaults store.
      // `AppStorage` is matched as a name, so `@SwiftUI.AppStorage`, a
      // qualifier on the line before, and `AppStorage(wrappedValue:_:)` count.
      [/\bAppStorage\b/, 'AppStorage'],
      [/\bCFPreferences[A-Za-z]*\b/, 'CFPreferences'],
    ],
  },
};

// Only Swift is scanned. Xcode and SwiftPM compile files, or generate code
// from them, by type: C-family, assembly, LLVM IR, lex, yacc, MIG and Metal
// sources, module maps, API notes and prefix headers, Core Data and Core ML
// models, Intents definitions, Reality Composer projects and more. So file
// types are an allowlist rather than a list of known source types: a file in
// a shipped target (outside folder references, buildPhase none entries,
// excluded paths and resource catalogues, in any build phase) must be Swift
// or one of the inert data types below, which are exactly the types the real
// targets hold there, and a linked package's Sources may hold only Swift.
// Anything else fails, including files with no extension and extensions in
// another letter case. .DS_Store is exempt: XcodeGen leaves it out and Finder
// writes it. When a real target gains a data type, the check fails; confirm
// the type is inert (Xcode neither compiles it nor generates code from it),
// then add it here and to the evidence doc.
const SOURCE_DATA_EXTENSIONS = new Set([
  '.json', // copied as data (course and subsection data)
  '.strings', // localized string tables, copied as data
  '.xcstrings', // string catalogues, compiled to string tables
  '.entitlements', // signing entitlements, never copied or compiled
  '.xcprivacy', // privacy manifests, copied as data and checked below
]);
const sourceTypeAllowed = (file, dataAllowed) => basename(file) === '.DS_Store'
  || extname(file) === '.swift'
  || (dataAllowed && SOURCE_DATA_EXTENSIONS.has(extname(file)));
const NON_SWIFT_MESSAGE = 'only Swift sources are scanned; extend scripts/check-apple-required-reasons.mjs to scan C/Objective-C/C++/assembly, module maps and API notes, or other types Xcode compiles or generates code from, before shipping it (for an inert data type, add its extension to SOURCE_DATA_EXTENSIONS)';
// Prebuilt code in a shipped target's sources is linked, embedded or loadable
// without any Swift spelling to scan. Code bundles and prebuilt Swift modules
// match by directory name; libraries, objects, text-based stubs and module
// interfaces by extension (the linker and XcodeGen find them by extension);
// any other file by its magic bytes. Resource bundles (.bundle, Settings.bundle)
// are data unless they hold an executable, which its Mach-O magic catches.
// docs/release/privacy-label-evidence.md lists the formats left out and why.
const BINARY_CODE = /\.(?:app|appex|framework|xcframework|xpc|swiftmodule)\/|\.(?:a|dylib|so|o|tbd|swiftmodule|swiftinterface)$/;
const BINARY_MAGIC = [
  'feedface', 'cefaedfe', 'feedfacf', 'cffaedfe', // Mach-O, 32- and 64-bit, both byte orders
  'cafebabe', 'bebafeca', 'cafebabf', 'bfbafeca', // universal (fat), 32- and 64-bit, both byte orders
  '213c617263683e0a', '213c7468696e3e0a', // ar "!<arch>\n" and thin "!<thin>\n" archives
  '4243c0de', 'dec0170b', // LLVM bitcode ("BC\xC0\xDE") and its wrapper (0x0B17C0DE, little-endian)
  'e29ca80e', // binary .swiftmodule
];
function isBinaryCode(file) {
  if (BINARY_CODE.test(display(file))) return true;
  const header = Buffer.alloc(8);
  const fd = openSync(file, 'r');
  try {
    const length = readSync(fd, header, 0, 8, 0);
    const hex = header.subarray(0, length).toString('hex');
    return BINARY_MAGIC.some((magic) => hex.startsWith(magic));
  } finally {
    closeSync(fd);
  }
}

// Target types are exactly those the real project.yml uses. Other types
// (frameworks, libraries, app extensions, watch app containers, App Clips,
// XPC services, ...) build or embed products the checker does not model, so
// they fail.
const SHIPPED_TARGET_TYPES = new Set(['application']);
const TEST_TARGET_TYPES = new Set(['bundle.unit-test', 'bundle.ui-testing']);
// project.yml paths (sources entries and package paths) are relative to
// apps/apple: any leading ../ components, then one or more non-empty names
// that are not . or .., hold no control characters and (for the first) do
// not start with ~. XcodeGen (PathKit) uses an absolute path as is (joining
// it to apps/apple would name another file), and it pops a leading .. off the
// base path lexically but leaves a later .. to be resolved through symbolic
// links, which could reach a different directory from the checker's; ~ and
// empty, trailing-slash or . components are not modelled either, so all of
// these fail. $ is rejected separately (XcodeGen variables).
const SPEC_PATH = /^(?:\.\.\/)*(?!~)(?!\.\.?(?:\/|$))[^/\x00-\x1f\x7f]+(?:\/(?!\.\.?(?:\/|$))[^/\x00-\x1f\x7f]+)*$/;
const specPathMessage = (what) => `${what} is not a relative path the checker models (leading ../ components, then non-empty names other than . and ..); absolute, ~, empty, trailing-slash, . and later .. components are not modelled, so extend scripts/check-apple-required-reasons.mjs.`;
// XcodeGen sources keys the checker models. Per-file compilerFlags are left
// out because they could pass import or include flags.
const KNOWN_SOURCE_KEYS = new Set([
  'path', 'excludes', 'buildPhase', 'type', 'createIntermediateGroups', 'destinationFilters',
  'inferDestinationFiltersByPath', 'group', 'name', 'optional', 'attributes',
  'resourceTags', 'headerVisibility',
]);
// XcodeGen source types and build phases the checker models (a copyFiles
// phase is a mapping); anything else, such as syncedFolder, fails.
const SOURCE_TYPES = new Set(['file', 'group', 'folder']);
const SOURCE_BUILD_PHASES = new Set(['sources', 'resources', 'headers', 'none']);
// XcodeGen dependency kinds; a dependency names exactly one.
const DEPENDENCY_KINDS = ['target', 'framework', 'carthage', 'sdk', 'package', 'bundle'];
// project.yml allowlist: every key the checker accepts, with the shape its
// value may take. ANY means the value is inert for code and link inputs, or
// is modelled where the checker reads it; 'string' must be a string; { keys }
// is a mapping whose keys must be listed; { values } is a mapping with any
// keys whose values have the given shape; { items } is a list. The keys are
// exactly those apps/apple/project.yml uses, plus the sdk dependency, which
// is modelled as a bare SDK framework or stub name. Any other key fails with
// its file:line, because XcodeGen keys such as include, projectReferences,
// options.preGenCommand, targetTemplates and templates, aggregateTargets,
// fileGroups, localPackages, configFiles, settingGroups and settings groups,
// preBuildScripts, postCompileScripts, buildRules, buildToolPlugins, a
// target scheme and scheme pre- and post-actions can add code, link inputs
// or bundled files the checker does not scan. When the real project.yml
// gains a key, the check fails; confirm the key is inert (or model it) and
// add it here.
const ANY = 'any';
const SETTINGS_SHAPE = {
  keys: {
    base: { values: ANY }, // build settings, checked by checkBuildSettings
    configs: { values: { values: ANY } }, // per-configuration build settings, also checked
  },
};
const TARGET_SHAPE = {
  keys: {
    type: ANY, // must be a shipped or test target type (main)
    platform: ANY, // must be one platform name (main)
    supportedDestinations: ANY, // the destinations that build the same sources
    deploymentTarget: ANY, // the minimum OS version
    sources: ANY, // each entry is modelled by resolveTarget
    dependencies: {
      items: {
        keys: {
          target: ANY, // modelled by resolveTarget
          package: ANY, // modelled by resolveTarget and resolvePackage
          sdk: ANY, // modelled by resolveTarget
          product: ANY, // picks a library product of a package whose Sources are all scanned
          embed: ANY, // copies a target's product, which is checked as its own target
          destinationFilters: ANY, // narrows the platforms that link the dependency
        },
      },
    },
    settings: SETTINGS_SHAPE,
    // Post-build scripts run after the compile, link and copy phases but
    // before code signing, so they could still replace the executable or copy
    // a dylib into the app; their inline text is reviewed by hand, with binary
    // inspection as the cross-check (see the evidence doc's limitations).
    postBuildScripts: {
      items: {
        keys: { name: ANY, script: 'string', basedOnDependencyAnalysis: ANY, inputFiles: ANY, outputFiles: ANY },
      },
    },
  },
};
const PROJECT_SHAPE = {
  keys: {
    name: ANY, // the project name
    options: {
      keys: {
        bundleIdPrefix: ANY, // bundle identifier prefix
        deploymentTarget: ANY, // minimum OS versions
        developmentLanguage: ANY, // the development region
        knownRegions: ANY, // localisations
        createIntermediateGroups: ANY, // navigator groups only
      },
    },
    configs: { values: ANY }, // configuration names and their debug or release presets
    packages: ANY, // each linked package is modelled by resolvePackage
    settings: SETTINGS_SHAPE,
    targets: { values: TARGET_SHAPE },
    // Which targets each scheme builds and tests, test coverage and test
    // plans; build products come from the targets themselves.
    schemes: {
      values: {
        keys: {
          build: { keys: { targets: { values: ANY } } },
          test: {
            keys: {
              gatherCoverageData: ANY,
              testPlans: { items: { keys: { path: ANY, defaultPlan: ANY } } },
              targets: { items: 'string' },
            },
          },
        },
      },
    },
  },
};
// Build-setting allowlist. The project's settings and each shipped target's
// settings (base and every configuration) may use only these exact setting
// names, each with a rule for its value. A conditional variant NAME[sdk=...]
// or NAME[arch=...] (one or more conditions) is matched on NAME and gets the
// same value rule; any other key spelling or condition fails. The names are
// exactly those apps/apple/project.yml sets at those levels, with no prefix
// families, so linker, compiler, search-path, header, tool-path and plugin
// settings (OTHER_LDFLAGS, WARNING_LDFLAGS, PRELINK_LIBS, LD, SWIFT_EXEC,
// SWIFT_INCLUDE_PATHS, SWIFT_PLUGIN_SERVER_PATH, HEADER_SEARCH_PATHS,
// OTHER_CFLAGS, GCC_PREPROCESSOR_DEFINITIONS, ...) and every other setting
// fail with their file:line. Values may not refer to other settings ($(...)
// or ${...}) except $(inherited) where a rule allows it. When the real
// project.yml gains a setting, the check fails; confirm the setting is inert
// for code and link inputs (or model its value), then add it here with a
// value rule and to the evidence doc. Test-target settings are not checked,
// because test bundles never ship; BUNDLE_LOADER and TEST_HOST appear only on
// CanadianHamTests.
const settingRule = (description, test, extra = {}) => ({ description, test, ...extra });
const settingWords = (value) => (typeof value === 'string' ? value.split(' ').filter(Boolean) : null);
const SETTING_IDENTIFIER = /^[A-Za-z_][A-Za-z0-9_]*$/;
const SETTING_BUNDLE_ID = /^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/;
const YES_NO = settingRule('YES, NO or a YAML boolean', (value) => typeof value === 'boolean' || value === 'YES' || value === 'NO');
const VERSION = settingRule('a version number such as 27.0',
  (value) => (typeof value === 'number' && Number.isFinite(value) && value >= 0) || (typeof value === 'string' && /^[0-9]+(?:\.[0-9]+){0,2}$/.test(value)));
const settingMatch = (description, pattern) => settingRule(description, (value) => typeof value === 'string' && pattern.test(value));
const settingOneOf = (...choices) => settingRule(`one of ${choices.join(', ')}`, (value) => choices.includes(value));
const BUNDLE_ID = settingMatch('a bundle identifier', SETTING_BUNDLE_ID);
const ASSET_NAME = settingMatch('an asset name of letters, digits, spaces and &._-', /^[A-Za-z0-9][A-Za-z0-9 &._-]*$/);
const ORIENTATIONS = new Set(['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight']);
const ORIENTATION_LIST = settingRule('space-separated UIInterfaceOrientation names',
  (value) => settingWords(value)?.length > 0 && settingWords(value).every((word) => ORIENTATIONS.has(word)));
// A path relative to apps/apple (SRCROOT) to an existing regular file of the
// expected type: names of letters, digits and _.+- that do not start with a
// dot, no .., $, ~ or leading /, no symbolic link on the way and the exact
// letter case on disk.
const SETTING_PATH = /^[A-Za-z0-9_][A-Za-z0-9_.+-]*(?:\/[A-Za-z0-9_][A-Za-z0-9_.+-]*)*$/;
const settingPath = (extension, emptyAllowed) => settingRule(
  `${emptyAllowed ? '"" or ' : ''}a path relative to apps/apple to a ${extension} file (no .., $, ~, hidden or absolute paths)`,
  (value) => typeof value === 'string' && ((emptyAllowed && value === '') || (SETTING_PATH.test(value) && value.endsWith(extension))),
  { file: true },
);
// Compilation conditions only select #if branches, and every branch is scanned.
const CONDITIONS = settingRule('$(inherited) and condition names, as a string or list of strings',
  (value) => [value].flat().every((item) => typeof item === 'string' && settingWords(item).every((word) => word === '$(inherited)' || SETTING_IDENTIFIER.test(word))));
// OTHER_SWIFT_FLAGS may hold only $(inherited) and -DNAME conditions (checkSwiftFlags).
const SWIFT_FLAGS = settingRule('$(inherited) and -DNAME conditions, as a string or list of strings',
  (value) => [value].flat().every((item) => typeof item === 'string'), { swiftFlags: true });
const BUILD_SETTINGS = new Map(Object.entries({
  // Version, identity and signing metadata written to Info.plist or used to sign.
  CURRENT_PROJECT_VERSION: VERSION, // build number
  MARKETING_VERSION: VERSION, // version string
  DEVELOPMENT_TEAM: settingMatch('a 10-character team ID', /^[A-Z0-9]{10}$/), // signing team
  CODE_SIGN_STYLE: settingOneOf('Automatic', 'Manual'), // automatic or manual signing
  CODE_SIGN_ENTITLEMENTS: settingPath('.entitlements', true), // capabilities, not code; the iCloud gate checks their content
  PRODUCT_BUNDLE_IDENTIFIER: BUNDLE_ID, // bundle ID
  PRODUCT_NAME: settingMatch('a product name of letters, digits, _ and -', /^[A-Za-z0-9_-]+$/), // product, executable and module name
  // Language mode and platforms.
  SWIFT_VERSION: VERSION, // Swift language mode
  SWIFT_STRICT_CONCURRENCY: settingOneOf('minimal', 'targeted', 'complete'), // concurrency diagnostics
  IPHONEOS_DEPLOYMENT_TARGET: VERSION, // minimum OS versions
  MACOSX_DEPLOYMENT_TARGET: VERSION,
  TVOS_DEPLOYMENT_TARGET: VERSION,
  XROS_DEPLOYMENT_TARGET: VERSION,
  TARGETED_DEVICE_FAMILY: settingRule('device family numbers 1 to 7, comma-separated', // device families
    (value) => (Number.isInteger(value) && value >= 1 && value <= 7) || (typeof value === 'string' && /^[1-7](?:,[1-7])*$/.test(value))),
  SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: YES_NO, // whether the iOS build runs on Mac or Vision as is
  SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD: YES_NO,
  // Conditions: names for #if, never flags.
  SWIFT_ACTIVE_COMPILATION_CONDITIONS: CONDITIONS,
  OTHER_SWIFT_FLAGS: SWIFT_FLAGS,
  // Build-process switches that add no inputs.
  ENABLE_USER_SCRIPT_SANDBOXING: YES_NO, // sandboxes script phases, whose text is reviewed by hand
  SWIFT_EMIT_LOC_STRINGS: YES_NO, // extracts localizable strings at compile time
  LOCALIZATION_PREFERS_STRING_CATALOGS: YES_NO, // string catalogue export format
  // Asset catalogue compiler: which icon and colour to use.
  ASSETCATALOG_COMPILER_APPICON_NAME: ASSET_NAME,
  ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: ASSET_NAME,
  ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS: YES_NO,
  // Info.plist: generated from these keys or read from a plist file, data only.
  GENERATE_INFOPLIST_FILE: YES_NO,
  INFOPLIST_FILE: settingPath('.plist', false),
  INFOPLIST_KEY_CFBundleDisplayName: settingMatch('a display name of letters, digits, spaces and &._-', /^[A-Za-z0-9][A-Za-z0-9 &._-]*$/),
  INFOPLIST_KEY_CFBundleIconName: ASSET_NAME,
  INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: YES_NO,
  INFOPLIST_KEY_LSApplicationCategoryType: settingMatch('a public.app-category type', /^public\.app-category\.[a-z]+(?:-[a-z]+)*$/),
  INFOPLIST_KEY_UIBackgroundModes: settingRule('space-separated background mode names', // the iCloud gate checks which modes
    (value) => settingWords(value)?.length > 0 && settingWords(value).every((word) => /^[a-z]+(?:-[a-z]+)*$/.test(word))),
  INFOPLIST_KEY_UILaunchScreen_Generation: YES_NO,
  INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: ORIENTATION_LIST,
  INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: ORIENTATION_LIST,
  INFOPLIST_KEY_WKApplication: YES_NO,
  INFOPLIST_KEY_WKCompanionAppBundleIdentifier: BUNDLE_ID,
  INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp: YES_NO,
}));
// NAME, then any number of [sdk=...] or [arch=...] conditions.
const SETTING_KEY = /^([A-Za-z_][A-Za-z0-9_]*)((?:\[(?:sdk|arch)=[A-Za-z0-9_.*-]+\])*)$/;

const errors = [];
const fail = (message) => {
  if (!errors.includes(message)) errors.push(message);
};
const display = (absolutePath) => relative(root, absolutePath).split(sep).join('/');

// ---------------------------------------------------------------------------
// Strict YAML subset parser for the XcodeGen spec. XcodeGen loads the spec
// with Yams (libyaml, YAML 1.1 implicit types) and then replaces ${NAME} with
// environment variables in keys and string values. This parser models exactly
// the subset the spec needs: one document of block mappings and sequences
// indented with spaces, comments, plain, single-quoted and double-quoted
// scalars on one line, one-line flow sequences of scalars, the empty flow
// mapping `{}`, CRLF line ends, a leading byte order mark, and literal or
// folded block scalars as a `script` value (whose text the checker never
// reads). Anything it could read differently from Yams fails instead: tabs,
// non-ASCII and control characters (libyaml reads NEL, LS, PS and lone CR as
// line breaks and skips a byte order mark at the start of any line), document
// markers, directives, anchors, aliases, tags, merge and complex keys,
// multi-line scalars, nested or multi-line flow collections, non-empty flow
// mappings, block scalar indentation indicators, double-quoted escapes other
// than \\ and \", plain keys that YAML 1.1 reads as null, booleans, numbers or
// timestamps, timestamp values, duplicate keys and ${...} outside a `script`
// value. Mappings are null-prototype objects, so `__proto__`, `constructor`
// and `prototype` are ordinary keys. Plain values keep their YAML 1.1 type
// (null, true/false, or a number whose value the checker never reads), so a
// consumer that needs a string fails closed on them.

const YAML_NULL = /^(?:~|null|Null|NULL|)$/;
const YAML_TRUE = /^(?:yes|Yes|YES|true|True|TRUE|on|On|ON)$/;
const YAML_FALSE = /^(?:no|No|NO|false|False|FALSE|off|Off|OFF)$/;
const YAML_INT = /^(?:[-+]?0b[0-1_]+|[-+]?0o?[0-7_]+|[-+]?(?:0|[1-9][0-9_]*)|[-+]?0x[0-9a-fA-F_]+|[-+]?[1-9][0-9_]*(?::[0-5]?[0-9])+)$/;
const YAML_FLOAT = /^(?:[-+]?(?:[0-9][0-9_]*)(?:\.[0-9_]*)?(?:[eE][-+]?[0-9]+)?|\.[0-9_]+(?:[eE][-+][0-9]+)?|[-+]?[0-9][0-9_]*(?::[0-5]?[0-9])+\.[0-9_]*|[-+]?\.(?:inf|Inf|INF)|\.(?:nan|NaN|NAN))$/;
const YAML_TIMESTAMP = /^(?:[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]|[0-9][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?(?:[Tt]|[ \t]+)[0-9][0-9]?:[0-9][0-9]:[0-9][0-9](?:\.[0-9]*)?(?:[ \t]*(?:Z|[-+][0-9][0-9]?(?::[0-9][0-9])?))?)$/;

// The value of a YAML 1.1 int or float (binary, octal with 0 or 0o, hex,
// sexagesimal, underscores, .inf and .nan). Only error messages show it.
function yamlNumber(text) {
  const clean = text.replace(/_/g, '');
  const sign = clean.startsWith('-') ? -1 : 1;
  const body = clean.replace(/^[-+]/, '');
  if (/^\.(?:inf|Inf|INF)$/.test(body)) return sign * Infinity;
  if (/^\.(?:nan|NaN|NAN)$/.test(body)) return NaN;
  if (body.includes(':')) return sign * body.split(':').reduce((total, part) => total * 60 + Number(part), 0);
  if (body.startsWith('0b')) return sign * parseInt(body.slice(2), 2);
  if (body.startsWith('0x')) return sign * parseInt(body.slice(2), 16);
  if (body.startsWith('0o')) return sign * parseInt(body.slice(2), 8);
  if (/^0[0-7]+$/.test(body)) return sign * parseInt(body.slice(1), 8);
  return sign * Number(body);
}

// The line of each key in every parsed mapping, so project.yml messages can
// name file:line.
const yamlKeyLines = new WeakMap();
const keyLine = (mapping, key, fallback = 0) => yamlKeyLines.get(mapping)?.get(key) ?? fallback;
const specAt = (line) => `${display(projectYmlPath)}:${line}`;

function parseYamlSubset(text, label) {
  const syntaxError = (lineIndex, message) => {
    throw new Error(`${label}:${lineIndex + 1}: ${message}`);
  };
  const lines = (text.startsWith('\uFEFF') ? text.slice(1) : text).split(/\r\n|\n/);
  for (const [lineIndex, line] of lines.entries()) {
    const bad = line.search(/[^\x20-\x7E]/);
    if (bad !== -1) {
      const code = line.codePointAt(bad);
      const what = code === 9 ? 'a tab' : `character U+${code.toString(16).toUpperCase().padStart(4, '0')}`;
      syntaxError(lineIndex, `${what} is not supported; the spec must be printable ASCII indented with spaces, because libyaml reads tabs, line breaks other than LF and CRLF, and byte order marks differently`);
    }
  }
  let index = 0;
  const isItem = (content) => /^-(?: |$)/.test(content);
  const significant = (lineIndex) => !/^ *(?:#.*)?$/.test(lines[lineIndex]);
  const peek = () => {
    while (index < lines.length && !significant(index)) index += 1;
    if (index >= lines.length) return null;
    const line = lines[index];
    const indent = line.length - line.trimStart().length;
    const content = line.slice(indent);
    if (indent === 0 && /^(?:---|\.\.\.)(?: |$)/.test(content)) syntaxError(index, 'document markers (--- and ...) are not supported; the spec must be one document');
    if (indent === 0 && content.startsWith('%')) syntaxError(index, 'directives (%YAML, %TAG) are not supported');
    return { indent, content, lineIndex: index };
  };
  // After a complete token, only spaces and a comment may follow on the line.
  const lineEnd = (rest, lineIndex, what) => {
    if (!/^(?: *| +#.*)$/.test(rest)) syntaxError(lineIndex, `unexpected text after ${what}: ${rest.trim()}`);
  };
  const noContinuation = (indent) => {
    const next = peek();
    if (next && next.indent > indent) syntaxError(next.lineIndex, 'a more-indented line after a scalar (a multi-line scalar or continuation line) is not supported');
  };
  const checkEnv = (value, key, lineIndex) => {
    if (key === 'script') return;
    for (const item of [value].flat()) {
      if (typeof item === 'string' && item.includes('${')) {
        syntaxError(lineIndex, `XcodeGen environment variables (\${...}) are only supported in script values: ${item}`);
      }
    }
  };

  // Reads a quoted scalar starting at text[start]; it must close on the same
  // line. Single quotes decode only ''; double quotes decode only \\ and \".
  function quoted(text, start, lineIndex) {
    const quote = text[start];
    let value = '';
    for (let i = start + 1; i < text.length; i += 1) {
      const c = text[i];
      if (quote === "'" && c === "'") {
        if (text[i + 1] !== "'") return { value, end: i + 1 };
        i += 1;
      } else if (quote === '"' && c === '"') {
        return { value, end: i + 1 };
      } else if (quote === '"' && c === '\\') {
        const next = text[i + 1];
        if (next !== '\\' && next !== '"') {
          syntaxError(lineIndex, `double-quoted escape ${next === undefined ? '\\ at the end of a line' : `\\${next}`} is not supported (only \\\\ and \\" are decoded); write the character itself`);
        }
        i += 1;
        value += next;
        continue;
      }
      value += c;
    }
    syntaxError(lineIndex, `unterminated ${quote === '"' ? 'double' : 'single'}-quoted scalar; quoted scalars must close on the same line`);
  }

  // Resolves a plain scalar as YAML 1.1 (Yams) does. Keys must be strings.
  function plain(raw, lineIndex, isKey) {
    const value = raw.trim();
    if (/^[&*!]/.test(value)) syntaxError(lineIndex, `anchors, aliases and tags are not supported: ${value}`);
    if (/^(?:[,[\]{}#|>'"%@`?:]|-(?: |$))/.test(value)) syntaxError(lineIndex, `a plain scalar cannot start with ${JSON.stringify(value[0])}; quote it: ${value}`);
    if (/: |:$/.test(value)) syntaxError(lineIndex, `": " inside a plain scalar is not supported; quote it: ${value}`);
    if (value === '<<') syntaxError(lineIndex, 'merge keys (<<) are not supported');
    if (value === '=') syntaxError(lineIndex, 'value keys (=) are not supported');
    if (YAML_TIMESTAMP.test(value)) syntaxError(lineIndex, `${value} is a YAML timestamp; quote it`);
    let type;
    let resolved;
    if (YAML_NULL.test(value)) [type, resolved] = ['null', null];
    else if (YAML_TRUE.test(value)) [type, resolved] = ['a boolean', true];
    else if (YAML_FALSE.test(value)) [type, resolved] = ['a boolean', false];
    else if (YAML_INT.test(value) || YAML_FLOAT.test(value)) [type, resolved] = ['a number', yamlNumber(value)];
    else return value;
    if (isKey) syntaxError(lineIndex, `plain key ${JSON.stringify(value)} is ${type} in YAML 1.1, not a string; quote it`);
    return resolved;
  }

  function flowSequence(text, lineIndex) {
    const items = [];
    let i = 1;
    const spaces = () => {
      while (text[i] === ' ') i += 1;
    };
    spaces();
    if (text[i] === ']') {
      i += 1;
    } else {
      for (;;) {
        spaces();
        if (i >= text.length) syntaxError(lineIndex, `unterminated or unsupported flow sequence; flow sequences must close on the same line: ${text}`);
        if (text[i] === '"' || text[i] === "'") {
          const item = quoted(text, i, lineIndex);
          items.push(item.value);
          i = item.end;
        } else {
          const start = i;
          while (i < text.length && text[i] !== ',' && text[i] !== ']') i += 1;
          const item = text.slice(start, i).trim();
          if (item === '') syntaxError(lineIndex, `empty flow sequence item (or trailing comma): ${text}`);
          if (/^[[{]/.test(item)) syntaxError(lineIndex, `nested flow collections are not supported: ${text}`);
          if (/[[\]{}#:]/.test(item)) syntaxError(lineIndex, `flow sequence item ${item} holds [ ] { } # or :; quote it`);
          items.push(plain(item, lineIndex, false));
        }
        spaces();
        if (text[i] === ',') {
          i += 1;
          continue;
        }
        if (text[i] === ']') {
          i += 1;
          break;
        }
        syntaxError(lineIndex, `unterminated or unsupported flow sequence; flow sequences must close on the same line: ${text}`);
      }
    }
    lineEnd(text.slice(i), lineIndex, 'a flow sequence');
    return items;
  }

  // Splits "key: rest" (the key plain or quoted); returns null for a scalar.
  function entry(content, lineIndex) {
    if (/^\?(?: |$)/.test(content)) syntaxError(lineIndex, 'complex keys ("? ") are not supported');
    let key;
    let rest;
    if (content[0] === '"' || content[0] === "'") {
      const { value, end } = quoted(content, 0, lineIndex);
      const colon = content.slice(end).match(/^ *:(?= |$)/);
      if (!colon) return null;
      key = value;
      rest = content.slice(end + colon[0].length);
    } else {
      let end = -1;
      for (let i = 0; i < content.length && end === -1; i += 1) {
        if (content[i] === '#' && content[i - 1] === ' ') break;
        if (content[i] === ':' && (i + 1 === content.length || content[i + 1] === ' ')) end = i;
      }
      if (end === -1) return null;
      key = plain(content.slice(0, end), lineIndex, true);
      rest = content.slice(end + 1);
    }
    if (key.includes('${')) syntaxError(lineIndex, `XcodeGen environment variables (\${...}) are not supported in keys: ${key}`);
    return { key, rest };
  }

  // The value after "key:" or "- ": { empty } when it follows on later lines,
  // { block } for a block scalar header, or { value }.
  function inlineValue(rest, lineIndex, key) {
    const text = rest.replace(/^ +/, '');
    if (text === '' || text.startsWith('#')) return { empty: true };
    if (/^[|>]/.test(text)) {
      if (!/^[|>][-+]?(?: +#.*)?$/.test(text)) syntaxError(lineIndex, `block scalar header ${text} is not supported (indentation indicators are not modelled)`);
      if (key !== 'script') syntaxError(lineIndex, `block scalars are only supported as a script value, not for ${key === null ? 'a sequence item' : key}`);
      return { block: true };
    }
    let value;
    if (text[0] === '[') {
      value = flowSequence(text, lineIndex);
    } else if (text[0] === '{') {
      if (!/^\{\}(?: +#.*)?$/.test(text)) syntaxError(lineIndex, `flow mappings other than {} are not supported: ${text}`);
      return { value: Object.create(null) };
    } else if (text[0] === '"' || text[0] === "'") {
      const scalar = quoted(text, 0, lineIndex);
      lineEnd(text.slice(scalar.end), lineIndex, 'a quoted scalar');
      value = scalar.value;
    } else {
      const comment = text.indexOf(' #');
      value = plain(comment === -1 ? text : text.slice(0, comment), lineIndex, false);
    }
    checkEnv(value, key, lineIndex);
    return { value };
  }

  // Literal or folded block scalar. Like libyaml, the first non-blank line
  // sets the content indentation; the block ends at the first non-blank line
  // indented less. Its text is kept only roughly: no consumer reads it.
  function blockScalar(parentIndent) {
    const collected = [];
    let contentIndent = null;
    let longestBlank = 0;
    for (; index < lines.length; index += 1) {
      const line = lines[index];
      const indent = line.length - line.trimStart().length;
      if (line.trim() === '') {
        if (contentIndent === null) longestBlank = Math.max(longestBlank, line.length);
        collected.push('');
        continue;
      }
      if (contentIndent === null) {
        if (indent <= parentIndent) break;
        if (longestBlank > indent) syntaxError(index, 'a leading blank line of a block scalar is indented more than its first line');
        contentIndent = indent;
      }
      if (indent < contentIndent) {
        if (indent > parentIndent && !/^ *#/.test(line)) syntaxError(index, 'a block scalar line is indented less than its first line but more than its key');
        break;
      }
      collected.push(line.slice(contentIndent));
    }
    return collected.join('\n');
  }

  function mapping(indent) {
    const result = Object.create(null);
    const keyLines = new Map();
    yamlKeyLines.set(result, keyLines);
    for (let next = peek(); next && next.indent === indent && !isItem(next.content); next = peek()) {
      const parsed = entry(next.content, next.lineIndex);
      if (!parsed) syntaxError(next.lineIndex, `expected "key: value", found: ${next.content}`);
      if (Object.hasOwn(result, parsed.key)) syntaxError(next.lineIndex, `duplicate key ${JSON.stringify(parsed.key)}`);
      keyLines.set(parsed.key, next.lineIndex + 1);
      index += 1;
      const value = inlineValue(parsed.rest, next.lineIndex, parsed.key);
      if (value.block) {
        result[parsed.key] = blockScalar(indent);
      } else if (value.empty) {
        const child = peek();
        if (child && child.indent > indent) result[parsed.key] = node(child.indent);
        else if (child && child.indent === indent && isItem(child.content)) result[parsed.key] = sequence(indent);
        else result[parsed.key] = null;
      } else {
        noContinuation(indent);
        result[parsed.key] = value.value;
      }
    }
    const after = peek();
    if (after && after.indent > indent) syntaxError(after.lineIndex, 'unexpected indentation');
    return result;
  }

  function sequence(indent) {
    const result = [];
    for (let next = peek(); next && next.indent === indent && isItem(next.content); next = peek()) {
      const content = next.content.slice(1).replace(/^ +/, '');
      if (content === '' || content.startsWith('#')) {
        index += 1;
        const child = peek();
        result.push(child && child.indent > indent ? node(child.indent) : null);
        continue;
      }
      if (isItem(content)) syntaxError(next.lineIndex, 'nested sequences on one line ("- - item") are not supported');
      if (entry(content, next.lineIndex)) {
        // "- key: value" starts a mapping whose keys align with "key".
        const childIndent = indent + next.content.length - content.length;
        lines[next.lineIndex] = ' '.repeat(childIndent) + content;
        result.push(mapping(childIndent));
        continue;
      }
      index += 1;
      const item = inlineValue(content, next.lineIndex, null);
      noContinuation(indent);
      result.push(item.value);
    }
    return result;
  }

  function node(indent) {
    const next = peek();
    if (!next) return null;
    return isItem(next.content) ? sequence(indent) : mapping(indent);
  }

  const first = peek();
  const document = first ? node(first.indent) : Object.create(null);
  const trailing = peek();
  if (trailing) syntaxError(trailing.lineIndex, 'unexpected content after document');
  return document;
}

// ---------------------------------------------------------------------------
// Strict XML property list parser for privacy manifests. Values keep their
// plist types: <dict> becomes a null-prototype object (so a `__proto__` key is
// an ordinary key), <array> an array, <string> a string and <true/>/<false/>
// a boolean. Privacy manifests use no other value types, so <integer>, <real>,
// <date> and <data> are rejected rather than read as strings. Entity and
// character references are decoded as Apple's parser decodes them, and string
// and key text keeps its whitespace. Everything else Apple's parser would
// accept or skip (binary, JSON or OpenStep plists, CDATA, comments inside a
// key or string, processing instructions, attributes, other DOCTYPEs, a
// missing <plist> root, duplicate keys and trailing content) is rejected, so
// the checker never reads a value differently from Apple.

const XML_DECLARATION = /<\?xml\s+version\s*=\s*(["'])1\.0\1(?:\s+encoding\s*=\s*(["'])(?:UTF-8|utf-8)\2)?\s*\?>/y;
const PLIST_DOCTYPE = /<!DOCTYPE\s+plist\s+PUBLIC\s+"-\/\/Apple(?: Computer)?\/\/DTD PLIST 1\.0\/\/EN"\s+"http:\/\/www\.apple\.com\/DTDs\/PropertyList-1\.0\.dtd"\s*>/y;
const PREDEFINED_ENTITIES = new Map([['lt', '<'], ['gt', '>'], ['amp', '&'], ['quot', '"'], ['apos', "'"]]);

function parsePlist(bytes, label) {
  const syntaxError = (message, offset) => {
    const line = offset === undefined ? '' : ` at line ${text.slice(0, offset).split('\n').length}`;
    throw new Error(`${label}: invalid property list${line}: ${message}; the checker reads only the XML plist subset Xcode writes, so rewrite the manifest or extend scripts/check-apple-required-reasons.mjs.`);
  };
  let text = '';
  if (bytes.subarray(0, 6).toString('latin1') === 'bplist') {
    syntaxError('binary property lists are not read (convert it with plutil -convert xml1)');
  }
  try {
    text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
  } catch {
    syntaxError('not valid UTF-8');
  }
  let i = text.startsWith('\uFEFF') ? 1 : 0;
  const at = (pattern) => {
    pattern.lastIndex = i;
    const match = pattern.exec(text);
    if (match) i = pattern.lastIndex;
    return match;
  };
  const found = () => (i >= text.length ? 'end of file' : JSON.stringify(text.slice(i, i + 24)));
  // Whitespace and comments may separate elements, as in Apple's parser.
  const skipMisc = () => {
    while (at(/\s+/y) || at(/<!--[\s\S]*?-->/y));
  };

  function decode(raw, name, start) {
    return raw.replace(/&[^;]*;?/g, (reference) => {
      const body = reference.slice(1, -1);
      if (reference.endsWith(';') && PREDEFINED_ENTITIES.has(body)) return PREDEFINED_ENTITIES.get(body);
      const numeric = reference.match(/^&#(?:([0-9]+)|x([0-9A-Fa-f]+));$/);
      const codePoint = numeric ? Number.parseInt(numeric[1] ?? numeric[2], numeric[1] ? 10 : 16) : Number.NaN;
      if (!(codePoint >= 1 && codePoint <= 0x10ffff) || (codePoint >= 0xd800 && codePoint <= 0xdfff)) {
        syntaxError(`unsupported entity or character reference ${JSON.stringify(reference)} in <${name}>`, start);
      }
      return String.fromCodePoint(codePoint);
    });
  }

  // Key and string text: character data only, then the closing tag.
  function textUntilClose(name) {
    const start = i;
    const raw = at(/[^<]*/y)[0];
    if (!at(new RegExp(`</${name}\\s*>`, 'y'))) {
      syntaxError(`expected </${name}>, found ${found()} (comments, CDATA and markup are not supported inside <${name}>)`, i);
    }
    return decode(raw, name, start);
  }

  function value() {
    const start = i;
    const tag = at(/<([A-Za-z]+)\s*(\/?)>/y);
    if (!tag) syntaxError(`expected a value element without attributes, found ${found()}`, start);
    const [, name, empty] = tag;
    switch (name) {
      case 'dict': {
        const result = Object.create(null);
        if (empty) return result;
        for (;;) {
          skipMisc();
          if (at(/<\/dict\s*>/y)) return result;
          const keyStart = i;
          const keyTag = at(/<key\s*(\/?)>/y);
          if (!keyTag) syntaxError(`expected <key> or </dict>, found ${found()}`, keyStart);
          const key = keyTag[1] ? '' : textUntilClose('key');
          // Apple's parser keeps the last value, so a duplicate could hide one.
          if (Object.hasOwn(result, key)) syntaxError(`duplicate key ${JSON.stringify(key)}`, keyStart);
          skipMisc();
          if (text.startsWith('</dict', i)) syntaxError(`key ${JSON.stringify(key)} has no value`, i);
          result[key] = value();
        }
      }
      case 'array': {
        const result = [];
        if (empty) return result;
        for (;;) {
          skipMisc();
          if (at(/<\/array\s*>/y)) return result;
          result.push(value());
        }
      }
      case 'string':
        return empty ? '' : textUntilClose('string');
      case 'true':
      case 'false':
        if (!empty && !at(new RegExp(`</${name}\\s*>`, 'y'))) syntaxError(`expected </${name}>, found ${found()}`, i);
        return name === 'true';
      case 'integer':
      case 'real':
      case 'date':
      case 'data':
        return syntaxError(`<${name}> values are not supported; privacy manifests use only dict, array, string and boolean values`, start);
      default:
        return syntaxError(`unsupported element <${name}>`, start);
    }
  }

  at(XML_DECLARATION);
  skipMisc();
  if (text.startsWith('<!DOCTYPE', i) && !at(PLIST_DOCTYPE)) syntaxError('only the standard Apple plist DOCTYPE is supported', i);
  skipMisc();
  if (!at(/<plist(?:\s+version\s*=\s*(["'])1\.0\1)?\s*>/y)) syntaxError(`expected <plist version="1.0">, found ${found()}`, i);
  skipMisc();
  const result = value();
  skipMisc();
  if (!at(/<\/plist\s*>/y)) syntaxError(`expected </plist> after one value, found ${found()}`, i);
  skipMisc();
  if (i !== text.length) syntaxError(`unexpected content after </plist>: ${found()}`, i);
  return result;
}

// ---------------------------------------------------------------------------
// Swift source scanning: blank out comments (keeping strings, regex literals
// and line numbers). Regex literals follow the Swift 6 lexer: extended
// `#/.../#` literals end at the matching `/#`; a bare `/.../` literal starts
// where an expression can start (not straight after an identifier, literal,
// `)`, `]` or postfix operator), cannot start with whitespace, and ends at the
// first unescaped `/` on the line, unless that `/` starts a comment or follows
// whitespace. Anything that could hide code fails closed instead: a comment
// marker straight after `\` (an undelimited regex) or an unterminated block
// comment or extended regex. A backtick-escaped identifier (`name`, also a
// Swift 6 raw identifier) is one token, so comment and string markers inside
// it are not lexed; once lexing is done, each escaped plain identifier is
// rewritten as the bare name followed by two spaces, keeping offsets and line
// numbers, so ``FileAttributeKey.`creationDate` `` matches like the plain
// spelling. String and regex contents are never rewritten.

const SWIFT_OPERATOR_CHARS = '=-+!*%<>&|^~?.';
const EXPRESSION_KEYWORDS = new Set([
  'return', 'throw', 'case', 'in', 'where', 'if', 'guard', 'while', 'try', 'await', 'switch',
  'yield', 'else', 'do', 'repeat', 'catch', 'is', 'as', 'some', 'any', 'then', 'consume', 'copy',
]);

function stripSwiftComments(source, label) {
  const out = [];
  const escapedNames = [];
  let i = 0;
  const n = source.length;
  const problem = (index, message) => {
    fail(`${label}:${source.slice(0, index).split('\n').length}: ${message}; rewrite it or extend scripts/check-apple-required-reasons.mjs.`);
  };

  const blank = (end) => {
    for (; i < end && i < n; i += 1) out.push(source[i] === '\n' ? '\n' : ' ');
  };
  const hashesThen = (char) => {
    let j = i;
    while (source[j] === '#') j += 1;
    return j > i && source[j] === char;
  };
  const lookback = (count) => {
    let text = '';
    for (let k = out.length - 1; k >= 0 && text.length < count; k -= 1) text = out[k] + text;
    return text;
  };

  function lineComment() {
    const end = source.indexOf('\n', i);
    blank(end === -1 ? n : end);
  }

  function blockComment() {
    const start = i;
    let depth = 0;
    while (i < n) {
      if (source.startsWith('/*', i)) {
        depth += 1;
        blank(i + 2);
      } else if (source.startsWith('*/', i)) {
        depth -= 1;
        blank(i + 2);
        if (depth === 0) return;
      } else {
        blank(i + 1);
      }
    }
    problem(start, 'unterminated block comment (possibly a misread regex literal) would hide the rest of the file');
  }

  // Swift's left-bound rule: a `/` straight after an expression is division.
  function slashIsLeftBound() {
    const before = lookback(64);
    let k = before.length - 1;
    while (k >= 0 && SWIFT_OPERATOR_CHARS.includes(before[k])) k -= 1;
    if (k < 0 || /[\s([{,;:]/.test(before[k])) return false;
    const word = /[A-Za-z_][A-Za-z0-9_]*$/.exec(before.slice(0, k + 1))?.[0];
    if (word && EXPRESSION_KEYWORDS.has(word) && before[k - word.length] !== '.') return false;
    return true;
  }

  // Returns the end index of a bare regex literal starting at i, or -1.
  function bareRegexEnd() {
    if (i + 1 >= n || /\s/.test(source[i + 1]) || slashIsLeftBound()) return -1;
    for (let j = i + 1; j < n && source[j] !== '\n'; j += 1) {
      if (source[j] === '\\') {
        if (source[j + 1] === '\n') return -1;
        j += 1;
      } else if (source[j] === '/') {
        if (source[j + 1] === '/' || source[j + 1] === '*' || /[ \t]/.test(source[j - 1])) return -1;
        return j + 1;
      }
    }
    return -1;
  }

  // Returns the end index of a backtick-escaped identifier starting at i, or -1.
  function escapedIdentifierEnd() {
    for (let j = i + 1; j < n && source[j] !== '\n'; j += 1) {
      if (source[j] === '`') return j + 1;
    }
    return -1;
  }

  function extendedRegexLiteral() {
    const start = i;
    let hashes = 0;
    while (source[i] === '#') {
      hashes += 1;
      i += 1;
    }
    i += 1; // opening '/'
    const terminator = '/' + '#'.repeat(hashes);
    while (i < n) {
      if (source[i] === '\\') {
        i += 2;
      } else if (source.startsWith(terminator, i)) {
        i += terminator.length;
        out.push(source.slice(start, i));
        return;
      } else {
        i += 1;
      }
    }
    i = n;
    out.push(source.slice(start));
    problem(start, 'unterminated extended regex literal');
  }

  function stringLiteral() {
    let hashes = 0;
    while (source[i] === '#') {
      out.push('#');
      hashes += 1;
      i += 1;
    }
    const quote = source.startsWith('"""', i) ? '"""' : '"';
    out.push(quote);
    i += quote.length;
    const terminator = quote + '#'.repeat(hashes);
    const escape = '\\' + '#'.repeat(hashes);
    while (i < n) {
      if (source.startsWith(terminator, i)) {
        out.push(terminator);
        i += terminator.length;
        return;
      }
      if (source.startsWith(escape, i)) {
        out.push(escape);
        i += escape.length;
        if (source[i] === '(') {
          out.push('(');
          i += 1;
          code(true);
        } else if (i < n) {
          out.push(source[i]);
          i += 1;
        }
        continue;
      }
      if (quote === '"' && source[i] === '\n') return;
      out.push(source[i]);
      i += 1;
    }
  }

  function code(inInterpolation) {
    let depth = 0;
    while (i < n) {
      const c = source[i];
      let regexEnd = -1;
      let escapedEnd = -1;
      if (source.startsWith('//', i) || source.startsWith('/*', i)) {
        if (source[i - 1] === '\\') {
          problem(i, `comment marker ${source.slice(i, i + 2)} straight after "\\" looks like an escaped slash in a regex literal the checker could not delimit`);
        }
        if (source[i + 1] === '/') lineComment();
        else blockComment();
      } else if (c === '"' || (c === '#' && hashesThen('"'))) {
        stringLiteral();
      } else if (c === '#' && hashesThen('/')) {
        extendedRegexLiteral();
      } else if (c === '/' && (regexEnd = bareRegexEnd()) !== -1) {
        out.push(source.slice(i, regexEnd));
        i = regexEnd;
      } else if (c === '`' && (escapedEnd = escapedIdentifierEnd()) !== -1) {
        if (/^[A-Za-z_][A-Za-z0-9_]*$/.test(source.slice(i + 1, escapedEnd - 1))) escapedNames.push(i);
        out.push(source.slice(i, escapedEnd));
        i = escapedEnd;
      } else {
        if (inInterpolation && c === '(') depth += 1;
        if (inInterpolation && c === ')') {
          if (depth === 0) {
            out.push(c);
            i += 1;
            return;
          }
          depth -= 1;
        }
        out.push(c);
        i += 1;
      }
    }
  }

  code(false);
  const stripped = out.join('');
  if (stripped.length !== n) {
    fail(`${label}: internal error: comment stripping changed the file length; fix scripts/check-apple-required-reasons.mjs.`);
  }
  if (escapedNames.length === 0) return stripped;
  const parts = [];
  let cursor = 0;
  for (const start of escapedNames) {
    const end = stripped.indexOf('`', start + 1);
    parts.push(stripped.slice(cursor, start), stripped.slice(start + 1, end), '  ');
    cursor = end + 1;
  }
  parts.push(stripped.slice(cursor));
  return parts.join('');
}

// Patterns run over the whole comment-stripped file, not line by line, so API
// spellings split across lines still count. Each usage is reported on the line
// where its match starts, once per pattern and line, in line order.
const MATCHERS = Object.entries(CATEGORIES).flatMap(([category, { patterns }]) =>
  patterns.map(([pattern, spelling]) => ({ category, spelling, regex: new RegExp(pattern.source, `${pattern.flags.replace(/[gm]/g, '')}gm`) })));

const usageCache = new Map();
function apiUsage(file) {
  if (usageCache.has(file)) return usageCache.get(file);
  const code = stripSwiftComments(readFileSync(file, 'utf8'), display(file));
  const lineStarts = [0];
  for (let k = 0; k < code.length; k += 1) if (code[k] === '\n') lineStarts.push(k + 1);
  const lineOf = (offset) => {
    let low = 0;
    let high = lineStarts.length - 1;
    while (low < high) {
      const middle = Math.ceil((low + high) / 2);
      if (lineStarts[middle] <= offset) low = middle;
      else high = middle - 1;
    }
    return low + 1;
  };
  const found = [];
  MATCHERS.forEach(({ category, spelling, regex }, order) => {
    const lines = new Set();
    for (const match of code.matchAll(regex)) {
      const line = lineOf(match.index);
      if (lines.has(line)) continue;
      lines.add(line);
      found.push({ category, spelling, file, line, order });
    }
  });
  const usages = found
    .sort((a, b) => a.line - b.line || a.order - b.order)
    .map(({ category, spelling, line }) => ({ category, spelling, file, line }));
  usageCache.set(file, usages);
  return usages;
}

// ---------------------------------------------------------------------------
// project.yml target resolution.

// XcodeGen expands excludes with glob(3) plus globstar, whose wildcards never
// match a leading dot, so neither do these: a hidden file stays compiled (and
// counted) unless an exclude names it literally. `**` is supported only as a
// whole path component; character classes, braces and escapes fail, so an
// exclude can never hide more than XcodeGen's would.
function globToRegExp(glob) {
  if (/[[{\\]/.test(glob) || /[^/]\*\*|\*\*[^/]/.test(glob)) {
    throw new Error(`exclude pattern ${JSON.stringify(glob)} uses glob syntax the checker does not model (character classes, braces, escapes or ** inside a name)`);
  }
  let pattern = '';
  for (let i = 0; i < glob.length; i += 1) {
    const c = glob[i];
    const componentStart = i === 0 || glob[i - 1] === '/';
    if (c === '*' && glob[i + 1] === '*') {
      // Zero or more non-hidden path components.
      pattern += glob[i + 2] === '/' ? '(?:(?!\\.)[^/]+/)*' : '(?:(?!\\.)[^/]+(?:/(?!\\.)[^/]+)*)?';
      i += glob[i + 2] === '/' ? 2 : 1;
    } else if (c === '*') {
      pattern += componentStart ? '(?!\\.)[^/]*' : '[^/]*';
    } else if (c === '?') {
      pattern += componentStart ? '(?!\\.)[^/]' : '[^/]';
    } else {
      pattern += c.replace(/[.+^${}()|[\]\\]/g, '\\$&');
    }
  }
  return new RegExp(`^${pattern.replace(/\/$/, '')}$`);
}

// XcodeGen compiles hidden files and follows symbolic links (SwiftPM skips
// hidden files), so hidden entries are scanned and a symbolic link fails the
// check instead of being silently skipped.
const symlinkMessage = (absolutePath) => `${display(absolutePath)} is a symbolic link; the checker does not follow links, so replace it with the real file or directory (or extend scripts/check-apple-required-reasons.mjs).`;
const specialFileMessage = (absolutePath) => `${display(absolutePath)} is not a regular file, directory or symbolic link; the checker cannot scan it, so remove it (or extend scripts/check-apple-required-reasons.mjs).`;

// Scan entry paths (project.yml sources, package directories and their
// Sources) would be followed by statSync/readdirSync, so the path itself and
// every directory between the repository root and it are checked with lstat.
// Returns true after failing when one is a symbolic link; a missing component
// is left to the caller's existence check.
function symlinkOnPath(absolutePath) {
  const fromRoot = relative(root, absolutePath);
  const outsideRoot = fromRoot === '..' || fromRoot.startsWith(`..${sep}`);
  const parts = outsideRoot ? [] : fromRoot.split(sep).filter(Boolean);
  const candidates = parts.length > 0
    ? parts.map((_, index) => join(root, ...parts.slice(0, index + 1)))
    : [absolutePath];
  for (const candidate of candidates) {
    const stats = lstatSync(candidate, { throwIfNoEntry: false });
    if (!stats) return false;
    if (stats.isSymbolicLink()) {
      fail(symlinkMessage(candidate));
      return true;
    }
  }
  return false;
}

// macOS volumes usually ignore letter case and Linux CI's do not, so a spec
// path whose case differs from the disk would resolve in Xcode but be missing
// on CI (and silently skipped there when optional), or the reverse. Each
// component below the repository root is compared exactly with its
// directory's listing, and a component that matches only when case is
// ignored is returned, so both systems fail the same way. The fold is broad
// (Unicode upper then lower case), so it errs towards failing.
const foldCase = (name) => name.toUpperCase().toLowerCase();
function caseMismatch(absolutePath) {
  const fromRoot = relative(root, absolutePath);
  if (fromRoot === '..' || fromRoot.startsWith(`..${sep}`)) return null;
  let directory = root;
  for (const part of fromRoot.split(sep).filter(Boolean)) {
    let names;
    try {
      names = readdirSync(directory);
    } catch {
      return null; // a missing or non-directory parent is left to the caller's checks
    }
    if (!names.includes(part)) {
      const actual = names.find((name) => foldCase(name) === foldCase(part));
      return actual === undefined ? null : join(directory, actual);
    }
    directory = join(directory, part);
  }
  return null;
}
const caseMessage = (what, actual) => `${what} differs only in letter case from ${display(actual)} on disk; macOS volumes usually ignore case and Linux CI does not, so Xcode and the checker could read different files. Use the exact case.`;

// Asset, icon and string catalogues are compiled by actool or the string
// catalogue compiler (SwiftPM processes them as resources), never as Swift
// sources and never copied as the bundle's manifest, so their contents count
// only for the prebuilt-code and symbolic-link checks.
const RESOURCE_CONTAINER = /\.(?:xcassets|icon|xcstrings)$/;

// Walks every entry below `directory` with no silent skips: hidden files,
// .DS_Store, resource catalogues and excluded paths are all visited, so
// prebuilt code, symbolic links and special files are always seen. visit(file,
// { excluded, container }) learns whether an XcodeGen exclude matched the file
// or a directory above it (excluded files are neither compiled nor copied, so
// they count only for the prebuilt-code check; scanning them too means a glob
// mismatch cannot hide prebuilt code) and whether it is inside a resource
// catalogue. Only `prune` patterns skip a subtree: the unmapped-Swift walk uses
// them for the generated project and build output, and no target walk does.
function walk(directory, visit, { base = directory, excludes = [], prune = [] } = {}, state = { excluded: false, container: RESOURCE_CONTAINER.test(directory) }) {
  for (const entry of readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const absolutePath = join(directory, entry.name);
    const relativePath = relative(base, absolutePath).split(sep).join('/');
    if (prune.some((pattern) => pattern.test(relativePath))) continue;
    const excluded = state.excluded || excludes.some((pattern) => pattern.test(relativePath));
    if (entry.isSymbolicLink()) {
      fail(symlinkMessage(absolutePath));
    } else if (entry.isDirectory()) {
      walk(absolutePath, visit, { base, excludes, prune }, { excluded, container: state.container || RESOURCE_CONTAINER.test(entry.name) });
    } else if (entry.isFile()) {
      visit(absolutePath, { excluded, container: state.container });
    } else {
      fail(specialFileMessage(absolutePath));
    }
  }
}

// Xcode copies files from groups flat into the bundle root, but keeps a
// directory with an extension (a bundle, .lproj or other wrapper) as its own
// folder, so a manifest below one is not the bundle's manifest.
function inWrapperDirectory(entryPath, file) {
  return relative(dirname(entryPath), file).split(sep).slice(0, -1).some((part) => part.lastIndexOf('.') > 0);
}

function resolveTarget(name, target, packages, targets, shipped) {
  const swiftFiles = new Set();
  const nonSwiftFiles = new Set();
  const binaryFiles = new Set();
  const manifests = new Set();
  const packageNames = [];
  const sources = target.sources ?? [];
  if (!Array.isArray(sources)) {
    fail(`${name}: sources must be a list in project.yml.`);
    return { swiftFiles, nonSwiftFiles, binaryFiles, manifests, packageNames };
  }
  for (const rawEntry of sources) {
    const entry = typeof rawEntry === 'string' ? { path: rawEntry } : rawEntry;
    if (!entry || typeof entry !== 'object' || typeof entry.path !== 'string') {
      fail(`${name}: unsupported sources entry ${JSON.stringify(rawEntry)}; extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    const unknownKeys = Object.keys(entry).filter((key) => !KNOWN_SOURCE_KEYS.has(key));
    if (unknownKeys.length > 0) {
      fail(`${name}: sources entry ${entry.path} uses unsupported XcodeGen keys (${unknownKeys.join(', ')}); extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    const buildPhase = entry.buildPhase ?? 'default';
    const copyFilesPhase = isDict(buildPhase) && Object.keys(buildPhase).join() === 'copyFiles';
    if (!(buildPhase === 'default' || SOURCE_BUILD_PHASES.has(buildPhase) || copyFilesPhase)) {
      fail(`${name}: sources entry ${entry.path} uses unsupported buildPhase ${JSON.stringify(buildPhase)}; extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    if (entry.type !== undefined && !SOURCE_TYPES.has(entry.type)) {
      fail(`${name}: sources entry ${entry.path} uses unsupported type ${JSON.stringify(entry.type)}; extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    const globs = entry.excludes ?? [];
    if (!Array.isArray(globs) || globs.some((glob) => typeof glob !== 'string')) {
      fail(`${name}: sources entry ${entry.path} excludes must be a list of strings, found ${JSON.stringify(globs)}; quote YAML null, boolean and number values.`);
      continue;
    }
    // XcodeGen replaces $platform, ${platform}, $target_name and similar
    // variables in target specs, so such a path names files the checker
    // cannot resolve.
    if ([entry.path, ...globs].some((path) => path.includes('$'))) {
      fail(`${name}: sources entry ${entry.path} uses $ in a path or exclude; XcodeGen variables such as $platform are not modelled, so extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    if (!SPEC_PATH.test(entry.path)) {
      fail(specPathMessage(`${name}: sources path ${JSON.stringify(entry.path)}`));
      continue;
    }
    let excludes = [];
    try {
      excludes = globs.map((glob) => globToRegExp(glob));
    } catch (error) {
      fail(`${name}: sources entry ${entry.path}: ${error.message}; extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    // Folder references (copied into the bundle as a whole, ignoring
    // excludes) and buildPhase none entries (in the project but in no build
    // phase) compile nothing and never supply the target's manifest, even when
    // they hold Swift files or a nested PrivacyInfo.xcprivacy. Their paths are
    // still checked like other entries, and everything in them is scanned for
    // prebuilt code and symbolic links.
    const reference = entry.type === 'folder' || buildPhase === 'none';
    const compiles = !reference && (buildPhase === 'default' || buildPhase === 'sources');
    // Only the resources phase copies to the bundle root; headers and
    // copyFiles phases (other destinations or subpaths) never supply it.
    const copiesToRoot = !reference && (buildPhase === 'default' || buildPhase === 'resources');
    const absolutePath = normalize(join(appleDir, entry.path));
    if (symlinkOnPath(absolutePath)) continue;
    const differentCase = caseMismatch(absolutePath);
    if (differentCase) {
      fail(caseMessage(`${name}: sources path ${entry.path}`, differentCase));
      continue;
    }
    if (!existsSync(absolutePath)) {
      // XcodeGen rejects a missing path unless it is optional, in any build
      // phase, so a missing resources path fails here too: it could hold
      // prebuilt code on the machine that builds the release. XcodeGen reads
      // optional as a YAML boolean (true, yes, on, ...); a quoted "true" is
      // a string, not optional.
      if (entry.optional !== true) {
        fail(`${name}: sources path ${entry.path} does not exist.`);
      }
      continue;
    }
    const stats = statSync(absolutePath);
    if (!stats.isFile() && !stats.isDirectory()) {
      fail(specialFileMessage(absolutePath));
      continue;
    }
    // A directory added as `type: file` is copied as one folder, like a wrapper.
    const copiedAsFolder = stats.isDirectory() && entry.type === 'file';
    const record = (file, { excluded, container }) => {
      const binary = isBinaryCode(file);
      if (binary) binaryFiles.add(file);
      if (reference || excluded || container) return;
      if (file.endsWith('.swift') && compiles) swiftFiles.add(file);
      if (!binary && !sourceTypeAllowed(file, true)) nonSwiftFiles.add(file);
      if (basename(file) === MANIFEST_NAME && copiesToRoot && !copiedAsFolder && !inWrapperDirectory(absolutePath, file)) manifests.add(file);
    };
    if (stats.isDirectory()) {
      walk(absolutePath, record, { excludes: reference ? [] : excludes });
    } else {
      record(absolutePath, { excluded: false, container: false });
    }
  }

  const dependencies = target.dependencies ?? [];
  if (!Array.isArray(dependencies)) {
    fail(`${name}: dependencies must be a list in project.yml.`);
    return { swiftFiles, nonSwiftFiles, binaryFiles, manifests, packageNames };
  }
  for (const dependency of dependencies) {
    // XcodeGen tries one kind key after another, so a dependency must name
    // exactly one kind, as a string: with two, or a non-string value XcodeGen
    // passes over, it could link something the checker never sees.
    const kinds = isDict(dependency) ? DEPENDENCY_KINDS.filter((kind) => Object.hasOwn(dependency, kind)) : [];
    const kind = kinds.length === 1 && typeof dependency[kinds[0]] === 'string' ? kinds[0] : null;
    if (kind === 'package') {
      if (!Object.hasOwn(packages, dependency.package)) {
        fail(`${name}: depends on unknown package ${dependency.package}.`);
      } else {
        packageNames.push(dependency.package);
      }
    } else if (kind === 'target') {
      // Embedded app targets are separate bundles, checked with their own
      // manifest. XcodeGen reads Project/Target as a target of another
      // project, which the checker cannot see, and a shipped target that
      // embeds or links a test bundle would ship code that is never checked.
      const dependsOn = dependency.target;
      if (!Object.hasOwn(targets, dependsOn)) {
        fail(`${specAt(keyLine(dependency, 'target'))}: ${name} depends on target ${dependsOn}, which project.yml does not define; cross-project (Project/Target) dependencies are not modelled, so extend scripts/check-apple-required-reasons.mjs.`);
      } else if (shipped && !SHIPPED_TARGET_TYPES.has(String(targets[dependsOn]?.type ?? ''))) {
        fail(`${specAt(keyLine(dependency, 'target'))}: ${name} depends on ${dependsOn}, which is not a shipped target, so its code would ship unchecked; extend scripts/check-apple-required-reasons.mjs.`);
      }
    } else if (kind === 'sdk') {
      // System frameworks: Apple's own use is not declared by the app.
      // XcodeGen looks up a bare .framework or .tbd name in the SDK; a name
      // with a slash is a path from the SDK root that could leave it.
      if (!/^[A-Za-z0-9][A-Za-z0-9_+.-]*\.(?:framework|tbd)$/.test(dependency.sdk)) {
        fail(`${specAt(keyLine(dependency, 'sdk'))}: ${name} sdk dependency ${dependency.sdk} must be a bare .framework or .tbd name from the SDK; paths and other files are not modelled, so extend scripts/check-apple-required-reasons.mjs.`);
      }
    } else {
      fail(`${name}: unsupported dependency ${JSON.stringify(dependency)}; a dependency must name exactly one target, package or sdk as a string, and binary or third-party code needs its own required-reason review.`);
    }
  }
  return { swiftFiles, nonSwiftFiles, binaryFiles, manifests, packageNames };
}

// Package.swift is read as a strict subset of Swift, so every construct the
// checks below look for is spelled out where they can see it. After comments
// are removed (backtick-escaped names become plain names), the manifest must
// be `import PackageDescription` and one `let package = Package(...)` whose
// arguments use only `label:`, simple string literals (no escapes,
// interpolation, raw or multi-line strings), array literals and implicit
// member expressions `.name` or `.name(...)`. Variables, helper functions,
// type-qualified or referenced members (Target.target, .map), operators,
// closures, dictionaries, `#if` and every other construct throw.
//
// Within that grammar, labels, members and strings are an allowlist: the
// labels and members are exactly those the real packages/*-swift manifests
// use, and strings may only be target and product names. Everything else,
// such as path:, sources:, resources:, exclude:, type:, plugins:, cSettings:
// and linkerSettings:, or .package, .binaryTarget, .executableTarget,
// .plugin, .macro, .systemLibrary, .unsafeFlags, .define, .linkedLibrary and
// .dynamic, is returned with its line, because SwiftPM could then compile,
// generate or link code from places the checker does not scan. When a real
// manifest gains a label or member, the check fails; confirm it is inert (or
// model it), then add it here and to the evidence doc.
const PACKAGE_LABELS = new Set(['name', 'platforms', 'products', 'targets', 'dependencies', 'swiftSettings', 'swiftLanguageModes']);
const PACKAGE_MEMBERS = new Set(['iOS', 'macOS', 'tvOS', 'visionOS', 'watchOS', 'v27', 'library', 'target', 'testTarget', 'swiftLanguageMode', 'v6']);
const PACKAGE_STRING = /^[A-Za-z_][A-Za-z0-9_-]*$/;
function checkPackageSyntax(source, label) {
  const lineAt = (offset) => source.slice(0, offset).split('\n').length;
  const problem = (offset, what) => {
    throw new Error(`${label}:${lineAt(offset)}: uses Swift the checker does not model (${what}); Package.swift may hold only import PackageDescription and one let package = Package(...) built from labels, simple string literals, arrays and .member(...) values`);
  };
  const unmodelled = [];
  const notAllowed = (offset, what) => unmodelled.push({ line: lineAt(offset), what });
  // Tokens are scanned on demand, so the first problem in source order is
  // the one reported.
  const tokens = [];
  let scan = 0;
  const scanToken = () => {
    while (scan < source.length) {
      const c = source[scan];
      const word = /[A-Za-z_][A-Za-z0-9_]*/y;
      word.lastIndex = scan;
      const name = word.exec(source);
      if (' \t\r\n'.includes(c)) {
        scan += 1;
      } else if (name) {
        tokens.push({ type: 'name', text: name[0], offset: scan });
        scan += name[0].length;
        return;
      } else if (c === '"') {
        if (source.startsWith('"""', scan)) problem(scan, 'a multi-line string literal');
        let end = scan + 1;
        while (end < source.length && !'"\\\r\n'.includes(source[end])) end += 1;
        if (source[end] === '\\') problem(end, 'a string escape or interpolation');
        if (source[end] !== '"') problem(scan, 'an unterminated string literal');
        tokens.push({ type: 'string', text: source.slice(scan + 1, end), offset: scan });
        scan = end + 1;
        return;
      } else if ('()[],:.='.includes(c)) {
        tokens.push({ type: c, text: c, offset: scan });
        scan += 1;
        return;
      } else if (c === '#') {
        problem(scan, source.startsWith('#if', scan) ? 'conditional compilation (#if)' : 'a raw string or # directive');
      } else {
        problem(scan, `the character ${JSON.stringify(c)}`);
      }
    }
  };
  const at = (index) => {
    while (tokens.length <= index && scan < source.length) scanToken();
    return tokens[index];
  };
  let position = 0;
  const describe = (token) => (token ? JSON.stringify(token.text) : 'the end of the file');
  const expect = (type, text) => {
    const token = at(position);
    if (!token || token.type !== type || (text !== undefined && token.text !== text)) {
      problem(token ? token.offset : source.length, `${describe(token)} where ${text ?? type} was expected`);
    }
    position += 1;
    return token;
  };
  const list = (close, item) => {
    while (at(position)?.type !== close) {
      item();
      if (at(position)?.type !== ',') break;
      position += 1;
    }
    expect(close);
  };
  function value() {
    const token = at(position);
    if (token?.type === 'string') {
      if (!PACKAGE_STRING.test(token.text)) notAllowed(token.offset, `the string ${JSON.stringify(token.text)}`);
      position += 1;
    } else if (token?.type === '[') {
      position += 1;
      list(']', value);
    } else if (token?.type === '.') {
      position += 1;
      const member = expect('name');
      if (member.offset !== token.offset + 1) problem(token.offset, 'whitespace after "."');
      if (!PACKAGE_MEMBERS.has(member.text)) notAllowed(token.offset, `the member .${member.text}`);
      if (at(position)?.type === '(') {
        position += 1;
        list(')', argument);
      }
    } else {
      problem(token ? token.offset : source.length, `${describe(token)} where a string, array or .member value was expected`);
    }
  }
  function argument() {
    const token = at(position);
    if (token?.type === 'name' && at(position + 1)?.type === ':') {
      if (!PACKAGE_LABELS.has(token.text)) notAllowed(token.offset, `the label ${token.text}:`);
      position += 2;
    }
    value();
  }
  for (const text of ['import', 'PackageDescription', 'let', 'package']) expect('name', text);
  expect('=');
  expect('name', 'Package');
  expect('(');
  list(')', argument);
  const extra = at(position);
  if (extra) problem(extra.offset, `${describe(extra)} after the Package(...) declaration`);
  return unmodelled;
}

// SwiftPM also finds target sources in Source, src and srcs (and, on a
// case-insensitive file system, any spelling of Sources), and prefers a
// version-specific Package@swift-*.swift manifest; the checker reads only
// Package.swift and Sources, so these fail.
const OTHER_SOURCE_ROOT = /^(?:sources|source|src|srcs)$/i;
const VERSIONED_MANIFEST = /^Package@swift-.*\.swift$/;
// XcodeGen local package keys; url, from, branch and the like are remote.
const PACKAGE_SPEC_KEYS = new Set(['path', 'group', 'excludeFromProject']);

function resolvePackage(name, spec) {
  const files = new Set();
  const packagePath = typeof spec === 'string' ? spec : spec?.path;
  if (typeof packagePath !== 'string' || packagePath === '') {
    fail(`project.yml package ${name} is not a local path package; remote packages are not allowed.`);
    return files;
  }
  const packageKeys = isDict(spec) ? Object.keys(spec).filter((key) => !PACKAGE_SPEC_KEYS.has(key)) : [];
  if (packageKeys.length > 0 || packagePath.includes('$')) {
    fail(`project.yml package ${name} uses ${packageKeys.length > 0 ? `keys the checker does not model (${packageKeys.join(', ')})` : '$ in its path'}; extend scripts/check-apple-required-reasons.mjs.`);
    return files;
  }
  if (!SPEC_PATH.test(packagePath)) {
    fail(specPathMessage(`project.yml package ${name} path ${JSON.stringify(packagePath)}`));
    return files;
  }
  const packageDir = normalize(join(appleDir, packagePath));
  const sourcesDir = join(packageDir, 'Sources');
  if (symlinkOnPath(sourcesDir)) return files;
  const manifestPath = join(packageDir, 'Package.swift');
  const packageCase = caseMismatch(manifestPath);
  if (packageCase) {
    fail(caseMessage(`project.yml package ${name} path ${packagePath}`, packageCase));
    return files;
  }
  if (!existsSync(manifestPath)) {
    fail(`project.yml package ${name}: ${display(manifestPath)} does not exist.`);
    return files;
  }
  for (const entry of readdirSync(packageDir)) {
    if (VERSIONED_MANIFEST.test(entry)) {
      fail(`${display(join(packageDir, entry))} is a version-specific manifest, which SwiftPM prefers over Package.swift; the checker reads only Package.swift, so remove it or extend scripts/check-apple-required-reasons.mjs.`);
    } else if (OTHER_SOURCE_ROOT.test(entry) && entry !== 'Sources') {
      fail(`${display(join(packageDir, entry))} is a SwiftPM source directory the checker does not scan (only Sources is); move its targets to Sources or extend scripts/check-apple-required-reasons.mjs.`);
    }
  }
  const manifest = stripSwiftComments(readFileSync(manifestPath, 'utf8'), display(manifestPath));
  try {
    for (const { line, what } of checkPackageSyntax(manifest, display(manifestPath))) {
      fail(`${display(manifestPath)}:${line}: uses ${what}, which is not in the checker's Package.swift allowlist; labels, members and strings outside it (custom paths, sources, resources and excludes, package dependencies, binary, executable, plugin, macro and system library targets, C, linker and unsafe settings, dynamic products and others) can add code or link inputs the checker does not scan. Confirm it is inert or model it, then add it to the allowlist in scripts/check-apple-required-reasons.mjs before linking the package.`);
    }
  } catch (error) {
    fail(`${error.message}; rewrite it or extend scripts/check-apple-required-reasons.mjs before linking it.`);
  }
  if (existsSync(sourcesDir)) {
    // Package exclude and resources rules only narrow what SwiftPM compiles,
    // and the allowlist above rejects them anyway, so all of Sources is
    // scanned. Resource catalogues are bundled as resources, so they count
    // only for prebuilt code and links; every other file must be Swift.
    walk(sourcesDir, (file, { container }) => {
      const binary = isBinaryCode(file);
      if (binary) fail(`package ${name}: ${display(file)} is prebuilt code; binary or third-party code needs its own required-reason review.`);
      if (container) return;
      if (file.endsWith('.swift')) files.add(file);
      if (!binary && !sourceTypeAllowed(file, false)) fail(`package ${name}: ${display(file)} is not Swift; ${NON_SWIFT_MESSAGE}.`);
    });
  }
  return files;
}

// ---------------------------------------------------------------------------
// Manifest validation.

// Privacy manifest keys the checker models; any other key fails until it does.
const MANIFEST_KEYS = ['NSPrivacyTracking', 'NSPrivacyTrackingDomains', 'NSPrivacyCollectedDataTypes', 'NSPrivacyAccessedAPITypes'];
const API_TYPE_KEYS = ['NSPrivacyAccessedAPIType', 'NSPrivacyAccessedAPITypeReasons'];
const isDict = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);
const plistType = (value) => {
  if (value === undefined) return 'nothing';
  if (Array.isArray(value)) return `<array> of ${value.length} item${value.length === 1 ? '' : 's'}`;
  if (isDict(value)) return '<dict>';
  if (typeof value === 'boolean') return `<${value}/>`;
  return `<string> ${JSON.stringify(value)}`;
};
const keyList = (keys) => keys.map((key) => JSON.stringify(key)).join(', ');

function declaredCategories(manifestPath, targetName) {
  const label = display(manifestPath);
  const where = `${label} (${targetName})`;
  let plist;
  try {
    plist = parsePlist(readFileSync(manifestPath), label);
  } catch (error) {
    fail(error.message);
    return null;
  }
  if (!isDict(plist)) {
    fail(`${where}: top level must be a <dict>, found ${plistType(plist)}.`);
    return null;
  }
  const unknownKeys = Object.keys(plist).filter((key) => !MANIFEST_KEYS.includes(key));
  if (unknownKeys.length > 0) {
    fail(`${where}: unsupported top-level keys ${keyList(unknownKeys)}; a manifest may hold only ${MANIFEST_KEYS.join(', ')}, so remove them or extend scripts/check-apple-required-reasons.mjs.`);
  }
  // The Apple app does no tracking and collects no data (AGENTS.md, docs/privacy.md).
  if (plist.NSPrivacyTracking !== false) {
    fail(`${where}: NSPrivacyTracking must be present and false (<false/>), found ${plistType(plist.NSPrivacyTracking)}; the Apple app does no tracking.`);
  }
  for (const key of ['NSPrivacyTrackingDomains', 'NSPrivacyCollectedDataTypes']) {
    if (!Array.isArray(plist[key]) || plist[key].length !== 0) {
      fail(`${where}: ${key} must be present and an empty array (<array/>), found ${plistType(plist[key])}; the Apple app does no tracking and collects no data.`);
    }
  }
  const entries = plist.NSPrivacyAccessedAPITypes ?? [];
  if (!Array.isArray(entries)) {
    fail(`${where}: NSPrivacyAccessedAPITypes must be an <array>, found ${plistType(entries)}.`);
    return null;
  }
  const declared = new Map();
  for (const [index, entry] of entries.entries()) {
    const item = `${where}: NSPrivacyAccessedAPITypes item ${index + 1}`;
    if (!isDict(entry)) {
      fail(`${item} must be a <dict>, found ${plistType(entry)}.`);
      continue;
    }
    const unknownEntryKeys = Object.keys(entry).filter((key) => !API_TYPE_KEYS.includes(key));
    if (unknownEntryKeys.length > 0) {
      fail(`${item} has unsupported keys ${keyList(unknownEntryKeys)}; it may hold only ${API_TYPE_KEYS.join(' and ')}.`);
    }
    const category = entry.NSPrivacyAccessedAPIType;
    const reasons = entry.NSPrivacyAccessedAPITypeReasons;
    if (typeof category !== 'string') {
      fail(`${item}: NSPrivacyAccessedAPIType must be a <string>, found ${plistType(category)}.`);
      continue;
    }
    if (!Object.hasOwn(CATEGORIES, category)) {
      fail(`${where}: unknown NSPrivacyAccessedAPIType ${JSON.stringify(category)}.`);
      continue;
    }
    if (declared.has(category)) {
      fail(`${where}: ${category} is declared more than once.`);
      continue;
    }
    if (reasons === undefined || (Array.isArray(reasons) && reasons.length === 0)) {
      fail(`${where}: ${category} must list at least one NSPrivacyAccessedAPITypeReasons code.`);
      continue;
    }
    if (!Array.isArray(reasons)) {
      fail(`${where}: ${category} NSPrivacyAccessedAPITypeReasons must be an <array> of <string> codes, found ${plistType(reasons)}.`);
      continue;
    }
    const { appReasons, sdkOnlyReasons } = CATEGORIES[category];
    const codes = [];
    for (const reason of reasons) {
      if (typeof reason !== 'string') {
        fail(`${where}: ${category} reasons must be <string> codes, found ${plistType(reason)}.`);
        continue;
      }
      codes.push(reason);
      if (sdkOnlyReasons.includes(reason)) {
        fail(`${where}: ${reason} may only be declared by third-party SDKs, not by an app, for ${category}.`);
      } else if (!appReasons.includes(reason)) {
        // Apple compares codes exactly, so surrounding whitespace makes a code unknown.
        const padded = reason.trim() !== reason && appReasons.includes(reason.trim()) ? ' (whitespace around a code is significant)' : '';
        fail(`${where}: ${JSON.stringify(reason)} is not an approved reason for ${category}${padded} (approved: ${appReasons.join(', ')}).`);
      }
    }
    if (new Set(codes).size !== codes.length) {
      fail(`${where}: ${category} lists a reason more than once.`);
    }
    declared.set(category, codes);
  }
  return declared;
}

// ---------------------------------------------------------------------------

// Build settings apply to every target, so the project's and each shipped
// target's settings may not add bridging or prefix headers, search paths,
// linker flags or Swift flags other than -D conditions. Settings maps (base,
// configs, Debug, ...) are walked recursively; `KEY[sdk=...]` counts as KEY.
// OTHER_SWIFT_FLAGS may hold only $(inherited) and single-token -DNAME conditions.
function checkSwiftFlags(where, key, value) {
  const flags = [value].flat().join(' ').split(/\s+/).filter(Boolean);
  const unsupported = [];
  for (let index = 0; index < flags.length; index += 1) {
    const flag = flags[index];
    if (flag === '-D' && SETTING_IDENTIFIER.test(flags[index + 1] ?? '')) {
      // Still rejected (only single-token conditions are modelled), with a fix.
      fail(`${where}: ${key} "-D ${flags[index + 1]}" splits the flag from its name; use the -D${flags[index + 1]} form.`);
      index += 1;
    } else if (flag !== '$(inherited)' && !/^-D[A-Za-z_][A-Za-z0-9_]*$/.test(flag)) {
      unsupported.push(flag);
    }
  }
  if (unsupported.length > 0) {
    fail(`${where}: ${key} ${unsupported.join(' ')} is not a -D condition; compiler flags can import or link code the checker does not scan, so extend scripts/check-apple-required-reasons.mjs.`);
  }
}

// A path setting must name an existing regular file under apps/apple, reached
// without symbolic links and with the exact letter case on disk.
function checkSettingFile(where, key, value) {
  if (value === '') return;
  const absolutePath = join(appleDir, value);
  if (symlinkOnPath(absolutePath)) return;
  const differentCase = caseMismatch(absolutePath);
  if (differentCase) {
    fail(caseMessage(`${where}: build setting ${key} path ${value}`, differentCase));
    return;
  }
  const stats = lstatSync(absolutePath, { throwIfNoEntry: false });
  if (!stats?.isFile()) {
    fail(`${where}: build setting ${key} path ${value} ${stats ? 'is not a regular file' : 'does not exist'} under apps/apple.`);
  }
}

// Checks the project's or a shipped target's settings against BUILD_SETTINGS:
// settings.base and every settings.configs.<name> mapping (checkShape reports
// any other shape).
function checkBuildSettings(label, settings) {
  if (!isDict(settings)) return;
  const groups = [];
  if (isDict(settings.base)) groups.push(settings.base);
  if (isDict(settings.configs)) groups.push(...Object.values(settings.configs).filter(isDict));
  for (const group of groups) {
    for (const [key, value] of Object.entries(group)) {
      const where = `${specAt(keyLine(group, key))}: ${label}`;
      const match = SETTING_KEY.exec(key);
      if (!match) {
        fail(`${where}: build setting key ${JSON.stringify(key)} is not NAME or NAME followed by [sdk=...] or [arch=...] conditions; other conditions and spellings are not modelled, so extend scripts/check-apple-required-reasons.mjs.`);
        continue;
      }
      const rule = BUILD_SETTINGS.get(match[1]);
      if (!rule) {
        fail(`${where}: build setting ${key} is not in the checker's build-setting allowlist; settings outside it (linker, compiler, search-path, header, tool-path and plugin settings and others) can compile, import or link code it does not scan. Confirm the setting is inert or model its value, then add it to BUILD_SETTINGS in scripts/check-apple-required-reasons.mjs.`);
        continue;
      }
      if (!rule.test(value)) {
        fail(`${where}: build setting ${key} must be ${rule.description}, found ${JSON.stringify(value)}; extend scripts/check-apple-required-reasons.mjs if the new value is inert.`);
        continue;
      }
      if (rule.swiftFlags) checkSwiftFlags(where, key, value);
      if (rule.file) checkSettingFile(where, key, value);
    }
  }
}

// Checks a parsed project.yml value against the allowlist shapes above.
function checkShape(value, shape, path, line) {
  if (shape === ANY) return;
  const where = path || 'the top level';
  if (shape === 'string') {
    if (typeof value !== 'string') fail(`${specAt(line)}: ${where} must be a string, found ${JSON.stringify(value)}.`);
    return;
  }
  if (shape.items) {
    if (!Array.isArray(value)) {
      fail(`${specAt(line)}: ${where} must be a list.`);
      return;
    }
    value.forEach((item, index) => checkShape(item, shape.items, `${path}[${index}]`, line));
    return;
  }
  if (!isDict(value)) {
    fail(`${specAt(line)}: ${where} must be a mapping.`);
    return;
  }
  for (const [key, child] of Object.entries(value)) {
    const childPath = path ? `${path}.${key}` : key;
    const childLine = keyLine(value, key, line);
    const childShape = shape.values ?? (Object.hasOwn(shape.keys, key) ? shape.keys[key] : undefined);
    if (childShape === undefined) {
      fail(`${specAt(childLine)}: key ${childPath} is not in the checker's project.yml allowlist; XcodeGen keys outside it (scripts, templates, xcconfig files, plugins, scheme actions, setting groups, project references and others) can add code, link inputs or bundled files it does not scan. Confirm the key is inert or model it, then add it to the allowlist in scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    checkShape(child, childShape, childPath, childLine);
  }
}

function main() {
  let project;
  try {
    project = parseYamlSubset(readFileSync(projectYmlPath, 'utf8'), display(projectYmlPath));
  } catch (error) {
    fail(`${error.message} (the checker reads a strict YAML subset; rewrite project.yml or extend scripts/check-apple-required-reasons.mjs).`);
    return;
  }
  if (!isDict(project)) {
    fail('project.yml: the top level must be a mapping.');
    return;
  }
  checkShape(project, PROJECT_SHAPE, '', 1);
  checkBuildSettings('project.yml settings', project.settings);
  // Parsed mappings have no prototype, so names such as toString or
  // __proto__ are only ever the spec's own keys.
  const packages = project.packages ?? Object.create(null);
  const targets = project.targets ?? Object.create(null);
  if (!isDict(packages) || !isDict(targets)) {
    fail('project.yml: packages and targets must be mappings.');
    return;
  }
  if (Object.keys(targets).length === 0) fail('project.yml defines no targets.');

  const packageFiles = new Map();
  const claimed = new Set();
  const results = [];
  for (const [name, target] of Object.entries(targets)) {
    const type = String(target?.type ?? '');
    const shipped = SHIPPED_TARGET_TYPES.has(type);
    if (!shipped && !TEST_TARGET_TYPES.has(type)) {
      fail(`${name}: target type ${JSON.stringify(type)} is not supported; extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    // A platform list makes XcodeGen generate one target per platform
    // (App_iOS, App_tvOS, ...) with $platform replaced in its sources.
    if (typeof target.platform !== 'string') {
      fail(`${name}: platform must be one platform name, found ${JSON.stringify(target.platform ?? null)}; multi-platform targets are not modelled, so extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    const resolved = resolveTarget(name, target, packages, targets, shipped);
    for (const file of resolved.swiftFiles) claimed.add(file);
    if (!shipped) continue;
    checkBuildSettings(name, target.settings);
    for (const file of resolved.nonSwiftFiles) fail(`${name}: ${display(file)} is not Swift; ${NON_SWIFT_MESSAGE}.`);
    for (const file of resolved.binaryFiles) fail(`${name}: ${display(file)} is prebuilt code; binary or third-party code needs its own required-reason review.`);

    const files = [...resolved.swiftFiles];
    for (const packageName of resolved.packageNames) {
      if (!packageFiles.has(packageName)) packageFiles.set(packageName, resolvePackage(packageName, packages[packageName]));
      files.push(...packageFiles.get(packageName));
    }
    if (resolved.swiftFiles.size === 0) fail(`${name}: no Swift sources resolved from project.yml.`);

    const manifests = [...resolved.manifests];
    if (manifests.length !== 1) {
      fail(`${name}: expected exactly one bundled ${MANIFEST_NAME}, found ${manifests.length}${manifests.length ? ` (${manifests.map(display).join(', ')})` : ''}.`);
    }
    const usages = files.flatMap((file) => apiUsage(file));
    const used = new Map();
    for (const usage of usages) {
      if (!used.has(usage.category)) used.set(usage.category, []);
      used.get(usage.category).push(usage);
    }
    const declared = manifests.length === 1 ? declaredCategories(manifests[0], name) : null;
    if (declared) {
      const manifestLabel = display(manifests[0]);
      for (const [category, categoryUsages] of used) {
        if (!declared.has(category)) {
          const examples = categoryUsages.slice(0, 3).map((usage) => `${display(usage.file)}:${usage.line} ${usage.spelling}`).join('; ');
          fail(`${name}: uses ${category} (${CATEGORIES[category].label}) but ${manifestLabel} does not declare it. Evidence: ${examples}${categoryUsages.length > 3 ? '; ...' : ''}`);
        }
      }
      for (const category of declared.keys()) {
        if (!used.has(category)) {
          fail(`${name}: ${manifestLabel} declares ${category} (${CATEGORIES[category].label}) but no Swift source compiled into ${name} or its linked local packages uses it.`);
        }
      }
    }
    results.push({ name, manifest: manifests[0], declared, used, fileCount: files.length });
  }

  const allSwift = [];
  if (existsSync(appleDir)) {
    // Only Swift attribution happens here; the generated project and build
    // output are pruned because no target compiles them, and Swift inside a
    // resource catalogue is never compiled.
    walk(appleDir, (file, { container }) => {
      if (!container && file.endsWith('.swift')) allSwift.push(file);
    }, { prune: [/\.xcodeproj$/, /(?:^|\/)DerivedData$/, /(?:^|\/)build$/] });
  }
  for (const file of allSwift) {
    if (!claimed.has(file)) {
      fail(`${display(file)} is not compiled by any project.yml target; add it to a target (or extend scripts/check-apple-required-reasons.mjs) so its required-reason API use is attributed.`);
    }
  }

  for (const { name, manifest, declared, used, fileCount } of results) {
    const summary = [...(declared ?? used).keys()].sort()
      .map((category) => `${category.replace('NSPrivacyAccessedAPICategory', '')}${declared?.has(category) ? ` [${declared.get(category).join(', ')}]` : ''}`)
      .join(', ') || 'none';
    console.log(`${name}: ${fileCount} Swift files; ${manifest ? display(manifest) : 'no manifest'}; categories: ${summary}`);
    if (verbose) {
      for (const [category, categoryUsages] of used) {
        for (const usage of categoryUsages) {
          console.log(`  ${category.replace('NSPrivacyAccessedAPICategory', '')}: ${display(usage.file)}:${usage.line} ${usage.spelling}`);
        }
      }
    }
  }
}

main();

if (errors.length > 0) {
  console.error('Apple required-reason API check failed:');
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}
console.log('Apple required-reason API check passed: every shipped target declares exactly the required-reason API categories its sources and linked local packages use, with approved app reasons, no tracking and no collected data.');
