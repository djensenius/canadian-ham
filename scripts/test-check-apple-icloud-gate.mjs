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

function basePbxproj({ projectDebug = '', appDebug = '', tvDebug = '', macEntitlement = 'CanadianHam/Resources/CanadianHam.macOS.CloudKit.entitlements' } = {}) {
  return `// !$*UTF8*$!
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
${appDebug}			PRODUCT_BUNDLE_IDENTIFIER = com.djensenius.CanadianHam;
		};
		name = Debug;
	};
	BBBB0002 /* Release */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
			"CODE_SIGN_ENTITLEMENTS[sdk=iphone*]" = "";
			"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = CanadianHam/Resources/CanadianHam.macOS.entitlements;
			PRODUCT_BUNDLE_IDENTIFIER = com.djensenius.CanadianHam;
		};
		name = Release;
	};
	BBBB0003 /* DebugCloudKit */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
			"CODE_SIGN_ENTITLEMENTS[sdk=iphone*]" = CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements;
			"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = ${macEntitlement};
			"INFOPLIST_KEY_UIBackgroundModes[sdk=iphone*]" = "remote-notification";
			PRODUCT_BUNDLE_IDENTIFIER = com.djensenius.CanadianHam;
		};
		name = DebugCloudKit;
	};
	CCCC0001 /* Debug */ = {
		isa = XCBuildConfiguration;
		buildSettings = {
${tvDebug}			PRODUCT_BUNDLE_IDENTIFIER = com.djensenius.CanadianHam.TV;
		};
		name = Debug;
	};
/* End XCBuildConfiguration section */
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
  writeFileSync(join(resources, 'CanadianHam.iOS.CloudKit.entitlements'), options.iosEntitlements ?? '<plist><dict><key>aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.com.djensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>');
  writeFileSync(join(resources, 'CanadianHam.macOS.CloudKit.entitlements'), options.macEntitlements ?? '<plist><dict><key>com.apple.developer.aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.com.djensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>');
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
assertFail('project Debug ICLOUD_SYNC leak', { projectDebug: '\t\t\tOTHER_SWIFT_FLAGS = "$(inherited) -DICLOUD_SYNC";\n' }, 'Debug build settings unexpectedly match gated iCloud token');
assertFail('app Debug CloudKit entitlements leak', { appDebug: '\t\t\t"CODE_SIGN_ENTITLEMENTS[sdk=iphone*]" = CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements;\n' }, 'Debug build settings unexpectedly match gated iCloud token');
assertFail('other target Debug CloudKit entitlements leak', { tvDebug: '\t\t\tCODE_SIGN_ENTITLEMENTS = CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements;\n' }, 'Debug build settings unexpectedly match gated iCloud token');
assertFail('default mac entitlements iCloud leak', { defaultMacEntitlements: '<plist><dict><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>' }, 'Default macOS entitlements unexpectedly match');
assertFail('macOS wrong push key', { macEntitlements: '<plist><dict><key>aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.com.djensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>' }, 'macOS CloudKit entitlements must use com.apple.developer.aps-environment');
assertFail('iOS wrong push key', { iosEntitlements: '<plist><dict><key>com.apple.developer.aps-environment</key><string>development</string><key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.com.djensenius.CanadianHam</string></array><key>com.apple.developer.icloud-services</key><array><string>CloudKit</string></array></dict></plist>' }, 'iOS CloudKit entitlements must use aps-environment');

if (failures !== 0) {
  console.error(`icloud-gate-test: failed with ${failures} failure(s).`);
  process.exit(1);
}
console.log('icloud-gate-test: passed self-test fixtures.');
