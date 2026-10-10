#!/usr/bin/env node
import { mkdtempSync, rmSync, mkdirSync, writeFileSync } from 'node:fs';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const root = process.env.ICLOUD_GATE_ROOT ?? process.cwd();
const projectYmlPath = join(root, 'apps/apple/project.yml');
const pbxprojPath = join(root, 'apps/apple/CanadianHam.xcodeproj/project.pbxproj');
const defaultMacEntitlementsPath = join(root, 'apps/apple/CanadianHam/Resources/CanadianHam.macOS.entitlements');
const cloudIOSEntitlementsPath = join(root, 'apps/apple/CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements');
const cloudMacEntitlementsPath = join(root, 'apps/apple/CanadianHam/Resources/CanadianHam.macOS.CloudKit.entitlements');

const projectYml = readFileSync(projectYmlPath, 'utf8');
const pbxproj = readFileSync(pbxprojPath, 'utf8');
const defaultMacEntitlements = readFileSync(defaultMacEntitlementsPath, 'utf8');
const cloudIOSEntitlements = readFileSync(cloudIOSEntitlementsPath, 'utf8');
const cloudMacEntitlements = readFileSync(cloudMacEntitlementsPath, 'utf8');

const errors = [];
const fail = (message) => errors.push(message);

const forbiddenDefaultPatterns = [
  /com\.apple\.developer\.icloud/,
  /aps-environment/,
  /UIBackgroundModes/,
  /remote-notification/,
  /\bICLOUD_SYNC\b/,
  /-DICLOUD_SYNC\b/,
  /SWIFT_ACTIVE_COMPILATION_CONDITIONS[\s\S]*ICLOUD_SYNC/,
  /CloudKit\.entitlements/,
  /CloudKit\.Info\.plist/,
  /INFOPLIST_FILE[\s\S]*CloudKit\.Info\.plist/,
];

for (const pattern of forbiddenDefaultPatterns.slice(0, 4)) {
  if (pattern.test(defaultMacEntitlements)) {
    fail(`Default macOS entitlements unexpectedly match ${pattern}.`);
  }
}

for (const token of [
  'DebugCloudKit: debug',
  '-DICLOUD_SYNC',
  'CanadianHam.iOS.CloudKit.entitlements',
  'CanadianHam.macOS.CloudKit.entitlements',
  'INFOPLIST_KEY_UIBackgroundModes: remote-notification',
]) {
  if (!projectYml.includes(token)) {
    fail(`project.yml is missing gated iCloud marker: ${token}`);
  }
}

for (const [label, text] of [
  ['iOS CloudKit entitlements', cloudIOSEntitlements],
  ['macOS CloudKit entitlements', cloudMacEntitlements],
]) {
  for (const token of ['com.apple.developer.icloud-container-identifiers', 'com.apple.developer.icloud-services', 'CloudKit', 'iCloud.org.davidjensenius.CanadianHam']) {
    if (!text.includes(token)) {
      fail(`${label} missing ${token}.`);
    }
  }
}
// Exact entitlement scope: only the approved keys, each with exactly the approved value.
function parseTopLevelEntitlements(text) {
  const entries = new Map();
  const pattern = /<key>([^<]+)<\/key>\s*(<string>([^<]*)<\/string>|<true\/>|<false\/>|<array>([\s\S]*?)<\/array>)/g;
  for (const match of text.matchAll(pattern)) {
    let value;
    if (match[3] !== undefined) value = match[3];
    else if (match[2] === '<true/>') value = true;
    else if (match[2] === '<false/>') value = false;
    else value = [...(match[4] ?? '').matchAll(/<string>([^<]*)<\/string>/g)].map((item) => item[1]);
    entries.set(match[1], value);
  }
  return entries;
}
const containerScope = ['iCloud.org.davidjensenius.CanadianHam'];
const serviceScope = ['CloudKit'];
for (const [label, text, required, optional] of [
  ['iOS CloudKit entitlements', cloudIOSEntitlements, {
    'aps-environment': 'development',
    'com.apple.developer.icloud-container-identifiers': containerScope,
    'com.apple.developer.icloud-services': serviceScope,
  }, {}],
  ['macOS CloudKit entitlements', cloudMacEntitlements, {
    'com.apple.developer.aps-environment': 'development',
    'com.apple.developer.icloud-container-identifiers': containerScope,
    'com.apple.developer.icloud-services': serviceScope,
  }, {
    'com.apple.security.app-sandbox': true,
    'com.apple.security.files.user-selected.read-write': true,
  }],
]) {
  const entries = parseTopLevelEntitlements(text);
  const allowed = { ...required, ...optional };
  for (const [key, value] of entries) {
    if (!(key in allowed)) {
      fail(`${label} has an entitlement outside the approved scope: ${key}`);
    } else if (JSON.stringify(value) !== JSON.stringify(allowed[key])) {
      fail(`${label} ${key} must be exactly ${JSON.stringify(allowed[key])}, found ${JSON.stringify(value)}`);
    }
  }
  for (const key of Object.keys(required)) {
    if (!entries.has(key)) {
      fail(`${label} missing ${key}.`);
    }
  }
}
if (!cloudIOSEntitlements.includes('<key>aps-environment</key>')) {
  fail('iOS CloudKit entitlements must use aps-environment.');
}
if (cloudIOSEntitlements.includes('<key>com.apple.developer.aps-environment</key>')) {
  fail('iOS CloudKit entitlements must not use the macOS com.apple.developer.aps-environment key.');
}
if (!cloudMacEntitlements.includes('<key>com.apple.developer.aps-environment</key>')) {
  fail('macOS CloudKit entitlements must use com.apple.developer.aps-environment.');
}
if (cloudMacEntitlements.includes('<key>aps-environment</key>')) {
  fail('macOS CloudKit entitlements must not use the iOS aps-environment key.');
}

if (/CloudKit\.Info\.plist in Resources/.test(pbxproj)) {
  fail('CloudKit Info.plist must not be copied in any resources build phase.');
}

const buildConfigPattern = /[A-F0-9]+ \/\* (Debug|Release|DebugCloudKit) \*\/ = \{[\s\S]*?isa = XCBuildConfiguration;[\s\S]*?name = \1;[\s\S]*?\n\t+\};/g;
const defaultBlocks = [];
const cloudKitBlocks = [];
let match;
while ((match = buildConfigPattern.exec(pbxproj)) !== null) {
  const [block, configName] = match;
  const buildSettings = block.match(/buildSettings = \{([\s\S]*?)\n\t+\};/)?.[1] ?? '';
  const entry = { configName, buildSettings };
  if (configName === 'DebugCloudKit') {
    cloudKitBlocks.push(entry);
  } else {
    defaultBlocks.push(entry);
  }
}

if (defaultBlocks.length === 0) {
  fail('Could not find generated Debug/Release build settings.');
}
for (const { configName, buildSettings } of defaultBlocks) {
  for (const pattern of forbiddenDefaultPatterns) {
    if (pattern.test(buildSettings)) {
      fail(`${configName} build settings unexpectedly match gated iCloud token: ${pattern}`);
    }
  }
}

const isPrimaryCanadianHamAppBlock = (buildSettings) =>
  buildSettings.includes('PRODUCT_BUNDLE_IDENTIFIER = org.davidjensenius.CanadianHam;')
  && buildSettings.includes('PRODUCT_NAME = CanadianHam;');
const appCloudKitBlocks = cloudKitBlocks.filter(({ buildSettings }) => isPrimaryCanadianHamAppBlock(buildSettings));
if (appCloudKitBlocks.length === 0) {
  fail('Could not find the DebugCloudKit app build settings in the generated project.');
} else {
  const cloudKitBuildSettings = appCloudKitBlocks.map(({ buildSettings }) => buildSettings).join('\n');
  for (const token of ['CanadianHam.iOS.CloudKit.entitlements', 'CanadianHam.macOS.CloudKit.entitlements', 'INFOPLIST_KEY_UIBackgroundModes']) {
    if (!cloudKitBuildSettings.includes(token)) {
      fail(`DebugCloudKit app build settings missing ${token}.`);
    }
  }
}
for (const { buildSettings } of cloudKitBlocks) {
  const hasCloudKitEntitlement = /CloudKit\.entitlements/.test(buildSettings);
  if (hasCloudKitEntitlement && !isPrimaryCanadianHamAppBlock(buildSettings)) {
    fail('Only the CanadianHam app target may carry CloudKit entitlements in DebugCloudKit.');
  }
}

if (!pbxproj.includes('DebugCloudKit')) {
  fail('Generated project is missing the DebugCloudKit configuration.');
}
if (!pbxproj.includes('OTHER_SWIFT_FLAGS = "$(inherited) -DICLOUD_SYNC";') && !pbxproj.includes('OTHER_SWIFT_FLAGS = "$(inherited) -DICLOUD_SYNC')) {
  fail('Generated project is missing the ICLOUD_SYNC compilation condition for the gated configuration.');
}

if (errors.length > 0) {
  console.error('iCloud gate check failed:');
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log('iCloud gate check passed: default Debug/Release settings across project and targets stay free of iCloud, Push, remote-notification, and ICLOUD_SYNC; DebugCloudKit carries the gated app capability settings.');
