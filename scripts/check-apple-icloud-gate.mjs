#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const root = process.cwd();
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

const forbiddenDefaultTokens = [
  'com.apple.developer.icloud',
  'aps-environment',
  'UIBackgroundModes',
  'remote-notification',
  'ICLOUD_SYNC',
  'CanadianHam.iOS.CloudKit.entitlements',
  'CanadianHam.macOS.CloudKit.entitlements',
];

for (const token of forbiddenDefaultTokens.slice(0, 4)) {
  if (defaultMacEntitlements.includes(token)) {
    fail(`Default macOS entitlements unexpectedly contain ${token}.`);
  }
}

for (const token of ['DebugCloudKit: debug', '-DICLOUD_SYNC', 'CanadianHam.iOS.CloudKit.entitlements', 'CanadianHam.macOS.CloudKit.entitlements', 'INFOPLIST_KEY_UIBackgroundModes[sdk=iphone*]: remote-notification']) {
  if (!projectYml.includes(token)) {
    fail(`project.yml is missing gated iCloud marker: ${token}`);
  }
}

for (const [label, text] of [
  ['iOS CloudKit entitlements', cloudIOSEntitlements],
  ['macOS CloudKit entitlements', cloudMacEntitlements],
]) {
  for (const token of ['com.apple.developer.icloud-container-identifiers', 'com.apple.developer.icloud-services', 'CloudKit', 'aps-environment', 'iCloud.com.djensenius.CanadianHam']) {
    if (!text.includes(token)) {
      fail(`${label} missing ${token}.`);
    }
  }
}

const buildConfigPattern = /[A-F0-9]+ \/\* (Debug|Release|DebugCloudKit) \*\/ = \{[\s\S]*?isa = XCBuildConfiguration;[\s\S]*?name = \1;[\s\S]*?\n\t\t\};/g;
const defaultAppBlocks = [];
const cloudKitAppBlocks = [];
let match;
while ((match = buildConfigPattern.exec(pbxproj)) !== null) {
  const [block, configName] = match;
  const buildSettings = block.match(/buildSettings = \{([\s\S]*?)\n\t\t\t\};/)?.[1] ?? '';
  if (!buildSettings.includes('PRODUCT_BUNDLE_IDENTIFIER = com.djensenius.CanadianHam;')) {
    continue;
  }
  if (configName === 'DebugCloudKit') {
    cloudKitAppBlocks.push(buildSettings);
  } else {
    defaultAppBlocks.push({ configName, buildSettings });
  }
}

if (defaultAppBlocks.length < 2) {
  fail('Could not find both default Debug and Release app build settings in the generated project.');
}

for (const { configName, buildSettings } of defaultAppBlocks) {
  for (const token of forbiddenDefaultTokens) {
    if (buildSettings.includes(token)) {
      fail(`${configName} app build settings unexpectedly contain gated iCloud token: ${token}`);
    }
  }
}

if (cloudKitAppBlocks.length === 0) {
  fail('Could not find the DebugCloudKit app build settings in the generated project.');
} else {
  const cloudKitBuildSettings = cloudKitAppBlocks.join('\n');
  for (const token of ['CanadianHam.iOS.CloudKit.entitlements', 'CanadianHam.macOS.CloudKit.entitlements', 'INFOPLIST_KEY_UIBackgroundModes']) {
    if (!cloudKitBuildSettings.includes(token)) {
      fail(`DebugCloudKit app build settings missing ${token}.`);
    }
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

console.log('iCloud gate check passed: default Debug/Release app settings stay free of iCloud, Push, and remote-notification capabilities; DebugCloudKit carries the gated capability settings.');
