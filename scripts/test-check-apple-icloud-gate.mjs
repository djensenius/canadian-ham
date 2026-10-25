#!/usr/bin/env node
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { spawnSync } from 'node:child_process';

const scriptPath = join(process.cwd(), 'scripts/check-apple-icloud-gate.mjs');
let failures = 0;

function fail(message) {
  console.error(`icloud-gate-test: FAIL: ${message}`);
  failures += 1;
}

function basePbxproj({ projectDebug = '', appDebug = '', tvDebug = '', tvCloudKit = '', macEntitlement = 'CanadianHam/Resources/CanadianHam.macOS.CloudKit.entitlements', resourceLeak = '', watchCloudKit } = {}) {
  return `// !$*UTF8*$!
/* Begin PBXBuildFile section */
${resourceLeak}/* End PBXBuildFile section */
/* Begin XCBuildConfiguration section */
	AAAA0001 /* Debug */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
			PRODUCT_NAME = "$(TARGET_NAME)";
${projectDebug}		};
		name = Debug;
	};
	AAAA0002 /* Release */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
			PRODUCT_NAME = "$(TARGET_NAME)";
		};
		name = Release;
	};
	AAAA0003 /* DebugCloudKit */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
			OTHER_SWIFT_FLAGS = "$(inherited) -DICLOUD_SYNC";
			PRODUCT_NAME = "$(TARGET_NAME)";
		};
		name = DebugCloudKit;
	};
	BBBB0001 /* Debug */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
			"CODE_SIGN_ENTITLEMENTS[sdk=iphone*]" = "";
			"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = CanadianHam/Resources/CanadianHam.macOS.entitlements;
${appDebug}			PRODUCT_BUNDLE_IDENTIFIER = org.davidjensenius.CanadianHam;
			PRODUCT_NAME = CanadianHam;
		};
		name = Debug;
	};
	BBBB0002 /* Release */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
			"CODE_SIGN_ENTITLEMENTS[sdk=iphone*]" = "";
			"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = CanadianHam/Resources/CanadianHam.macOS.entitlements;
			PRODUCT_BUNDLE_IDENTIFIER = org.davidjensenius.CanadianHam;
			PRODUCT_NAME = CanadianHam;
		};
		name = Release;
	};
	BBBB0003 /* DebugCloudKit */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
			"CODE_SIGN_ENTITLEMENTS[sdk=iphone*]" = CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements;
			"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = ${macEntitlement};
			"INFOPLIST_KEY_UIBackgroundModes[sdk=iphone*]" = "remote-notification";
			PRODUCT_BUNDLE_IDENTIFIER = org.davidjensenius.CanadianHam;
			PRODUCT_NAME = CanadianHam;
		};
		name = DebugCloudKit;
	};
	CCCC0001 /* Debug */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
${tvDebug}			PRODUCT_BUNDLE_IDENTIFIER = org.davidjensenius.CanadianHam;
			PRODUCT_NAME = CanadianHamTV;
		};
		name = Debug;
	};
${tvCloudKit ? `	CCCC0003 /* DebugCloudKit */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
${tvCloudKit}			PRODUCT_BUNDLE_IDENTIFIER = org.davidjensenius.CanadianHam;
			PRODUCT_NAME = CanadianHamTV;
		};
		name = DebugCloudKit;
	};
` : ''}${watchCloudKit !== undefined ? `	DDDD0003 /* DebugCloudKit */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
${watchCloudKit}			PRODUCT_BUNDLE_IDENTIFIER = org.davidjensenius.CanadianHam.watchkitapp;
			PRODUCT_NAME = CanadianHamWatch;
		};
		name = DebugCloudKit;
	};
` : ''}/* End XCBuildConfiguration section */
`;
}

function writeFixture(options = {}) {
  const root = mkdtempSync(join(tmpdir(), 'icloud-gate-test.'));
  const resources = join(root, 'apps/apple/CanadianHam/Resources');
  mkdirSync(resources, { recursive: true });
  mkdirSync(join(root, 'apps/apple/CanadianHam.xcodeproj'), { recursive: true });
  writeFileSync(join(root, 'apps/apple/project.yml'), options.projectYml ?? `configs:
  Debug: debug
  DebugCloudKit: debug
  Release: release
settings:
  configs:
    DebugCloudKit:
      OTHER_SWIFT_FLAGS: $(inherited) -DICLOUD_SYNC
targets:
  CanadianHam:
    settings:
      configs:
        DebugCloudKit:
          CODE_SIGN_ENTITLEMENTS[sdk=macosx*]: CanadianHam/Resources/CanadianHam.macOS.CloudKit.entitlements
          CODE_SIGN_ENTITLEMENTS[sdk=iphone*]: CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements
          INFOPLIST_KEY_UIBackgroundModes: remote-notification
`);
  writeFileSync(join(resources, 'CanadianHam.macOS.entitlements'), options.defaultMacEntitlements ?? '<plist><dict><key>com.apple.security.app-sandbox</key><true/></dict></plist>');
  writeFileSync(join(resources, 'CanadianHam.iOS.CloudKit.entitlements'), options.iosEntitlements ?? '<plist><dict><key>aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.org.davidjensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>');
  writeFileSync(join(resources, 'CanadianHam.macOS.CloudKit.entitlements'), options.macEntitlements ?? '<plist><dict><key>com.apple.developer.aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.org.davidjensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>');
  writeFileSync(join(resources, 'CanadianHam.iOS.CloudKit.Info.plist'), options.cloudInfoPlist ?? '<plist><dict><key>UIBackgroundModes</key><array><string>remote-notification</string></array></dict></plist>');
  writeFileSync(join(root, 'apps/apple/CanadianHam.xcodeproj/project.pbxproj'), options.pbxproj ?? basePbxproj(options));
  return root;
}

function runCheck(root) {
  return spawnSync(process.execPath, [scriptPath], {
    cwd: process.cwd(),
    env: { ...process.env, ICLOUD_GATE_ROOT: root },
    encoding: 'utf8',
  });
}

function assertPass(name, options) {
  const root = writeFixture(options);
  try {
    const result = runCheck(root);
    if (result.status !== 0) {
      fail(`${name} expected pass but failed:\n${result.stderr}${result.stdout}`);
    }
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

function assertFail(name, options, expected) {
  const root = writeFixture(options);
  try {
    const result = runCheck(root);
    const output = `${result.stderr}${result.stdout}`;
    if (result.status === 0) {
      fail(`${name} expected failure but passed`);
    } else if (!output.includes(expected)) {
      fail(`${name} missed expected output ${JSON.stringify(expected)}:\n${output}`);
    }
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

assertPass('clean fixture');
const cleanWatchCloudKit = '\t\t\tCODE_SIGN_ENTITLEMENTS = "";\n\t\t\tOTHER_SWIFT_FLAGS = "";\n';
assertPass('watch excludes project CloudKit gate', { watchCloudKit: cleanWatchCloudKit });
assertFail('watch inherits project CloudKit flags', { watchCloudKit: '\t\t\tCODE_SIGN_ENTITLEMENTS = "";\n' }, 'Watch DebugCloudKit must override inherited OTHER_SWIFT_FLAGS');
assertFail('watch enables cloud compilation', { watchCloudKit: cleanWatchCloudKit.replace('OTHER_SWIFT_FLAGS = ""', 'OTHER_SWIFT_FLAGS = "$(inherited) -DICLOUD_SYNC"') }, 'Watch DebugCloudKit build settings unexpectedly match');
assertFail('watch enables push background mode', { watchCloudKit: cleanWatchCloudKit + '\t\t\tINFOPLIST_KEY_UIBackgroundModes = "remote-notification";\n' }, 'Watch DebugCloudKit build settings unexpectedly match');
assertFail('watch non-empty entitlement path', { watchCloudKit: cleanWatchCloudKit.replace('CODE_SIGN_ENTITLEMENTS = ""', 'CODE_SIGN_ENTITLEMENTS = watch.entitlements') }, 'Watch DebugCloudKit must have empty CODE_SIGN_ENTITLEMENTS');

assertFail('project Debug ICLOUD_SYNC leak', { projectDebug: '\t\t\tOTHER_SWIFT_FLAGS = "$(inherited) -DICLOUD_SYNC";\n' }, 'Debug build settings unexpectedly match gated iCloud token');
assertFail('app Debug CloudKit entitlements leak', { appDebug: '\t\t\t"CODE_SIGN_ENTITLEMENTS[sdk=iphone*]" = CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements;\n' }, 'Debug build settings unexpectedly match gated iCloud token');
assertFail('app Debug CloudKit Info plist leak', { appDebug: '\t\t\tINFOPLIST_FILE = CanadianHam/Resources/CanadianHam.iOS.CloudKit.Info.plist;\n' }, 'Debug build settings unexpectedly match gated iCloud token');
assertFail('CloudKit Info plist resource leak', { resourceLeak: '\tDDDD0001 /* CanadianHam.iOS.CloudKit.Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = DDDD0002 /* CanadianHam.iOS.CloudKit.Info.plist */; };\n' }, 'CloudKit Info.plist must not be copied in any resources build phase');
assertFail('other target Debug CloudKit entitlements leak', { tvDebug: '\t\t\tCODE_SIGN_ENTITLEMENTS = CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements;\n' }, 'Debug build settings unexpectedly match gated iCloud token');
assertFail('shared-bundle-ID tvOS DebugCloudKit entitlements leak', { tvCloudKit: '\t\t\tCODE_SIGN_ENTITLEMENTS = CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements;\n' }, 'Only the CanadianHam app target may carry CloudKit entitlements in DebugCloudKit.');
assertFail('default mac entitlements iCloud leak', { defaultMacEntitlements: '<plist><dict><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>' }, 'Default macOS entitlements unexpectedly match');
assertFail('macOS wrong push key', { macEntitlements: '<plist><dict><key>aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.org.davidjensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>' }, 'macOS CloudKit entitlements must use com.apple.developer.aps-environment');
assertFail('iOS wrong push key', { iosEntitlements: '<plist><dict><key>com.apple.developer.aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.org.davidjensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>' }, 'iOS CloudKit entitlements must use aps-environment');

const extraContainer = '<plist><dict><key>aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.org.davidjensenius.CanadianHam</string><string>iCloud.com.example.Other</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>';
assertFail('iOS extra iCloud container', { iosEntitlements: extraContainer }, 'com.apple.developer.icloud-container-identifiers must be exactly');
assertFail('macOS extra iCloud service', { macEntitlements: '<plist><dict><key>com.apple.developer.aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.org.davidjensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string><string>CloudDocuments</string></array></dict></plist>' }, 'com.apple.developer.icloud-services must be exactly');
assertFail('iOS extra entitlement key', { iosEntitlements: extraContainer.replace('</dict>', '<key>com.apple.developer.ubiquity-kvstore-identifier</key><string>x</string></dict>') }, 'outside the approved scope');
assertFail('iOS extra integer entitlement key', { iosEntitlements: extraContainer.replace('</dict>', '<key>com.apple.developer.extra-integer</key><integer>1</integer></dict>') }, 'outside the approved scope');
assertFail('iOS extra real entitlement key', { iosEntitlements: extraContainer.replace('</dict>', '<key>com.apple.developer.extra-real</key><real>1.5</real></dict>') }, 'outside the approved scope');
assertFail('iOS extra self-closing array entitlement key', { iosEntitlements: extraContainer.replace('</dict>', '<key>com.apple.developer.extra-array</key><array/></dict>') }, 'outside the approved scope');
assertFail('macOS extra dict entitlement key', { macEntitlements: '<plist><dict><key>com.apple.developer.aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.org.davidjensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array><key>com.apple.developer.extra-dict</key><dict><key>nested</key><string>x</string></dict></dict></plist>' }, 'outside the approved scope');
assertFail('CloudKit Info plist extra background mode', { cloudInfoPlist: '<plist><dict><key>UIBackgroundModes</key><array><string>remote-notification</string><string>fetch</string></array></dict></plist>' }, 'UIBackgroundModes must be exactly');
assertFail('CloudKit Info plist duplicate background mode key', { cloudInfoPlist: '<plist><dict><key>UIBackgroundModes</key><array><string>remote-notification</string></array><key>UIBackgroundModes</key><array><string>remote-notification</string></array></dict></plist>' }, 'exactly one UIBackgroundModes key');
assertFail('CloudKit Info plist missing background mode', { cloudInfoPlist: '<plist><dict></dict></plist>' }, 'exactly one UIBackgroundModes key');

if (failures !== 0) {
  console.error(`icloud-gate-test: failed with ${failures} failure(s).`);
  process.exit(1);
}
console.log('icloud-gate-test: passed self-test fixtures.');
