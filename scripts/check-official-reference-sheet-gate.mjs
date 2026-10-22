#!/usr/bin/env node
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { resolve, join } from "node:path";
import { spawnSync } from "node:child_process";

const root = resolve(import.meta.dirname, "..");
const temporary = mkdtempSync(join(tmpdir(), "official-reference-gate-"));
try {
  const project = readFileSync(join(root, "apps/apple/project.yml"), "utf8");
  const settings = project.slice(project.indexOf("settings:"), project.indexOf("targets:"));
  assert.doesNotMatch(settings.slice(0, settings.indexOf("  configs:")), /OFFICIAL_REFERENCE_SHEET/, "base settings must not enable public Release content");
  assert.match(settings, /Debug:\n\s+OTHER_SWIFT_FLAGS: \$\(inherited\) -DOFFICIAL_REFERENCE_SHEET/);
  assert.doesNotMatch(settings, /Release:\n\s+[^\n]*OFFICIAL_REFERENCE_SHEET/);
  assert.equal((project.match(/name: Copy gated official exam reference sheet/g) ?? []).length, 2);
  assert.doesNotMatch(project, /path: .*content\/reference\/official-basic-exam/, "official assets must not be unconditional resource members");
  const generatedProject = readFileSync(join(root, "apps/apple/CanadianHam.xcodeproj/project.pbxproj"), "utf8");
  assert.match(generatedProject, /copy-official-reference-sheet\.sh/);
  assert.doesNotMatch(generatedProject, /page-[1-5]\.png/, "generated project must not add unconditional official images");
  const resources = join(temporary, "resources");
  const destination = join(resources, "official-basic-exam");
  const copy = (conditions, flags) => {
    const result = spawnSync("bash", [join(root, "scripts/copy-official-reference-sheet.sh")], {
      encoding: "utf8",
      env: { ...process.env, SRCROOT: join(root, "apps/apple"), TARGET_BUILD_DIR: temporary,
        UNLOCALIZED_RESOURCES_FOLDER_PATH: "resources", SWIFT_ACTIVE_COMPILATION_CONDITIONS: conditions, OTHER_SWIFT_FLAGS: flags },
    });
    assert.equal(result.status, 0, result.stderr);
  };
  copy("DEBUG", "-DOFFICIAL_REFERENCE_SHEET");
  assert.equal(readdirSync(destination).length, 6, "Debug opt-in copies only five pages and the text equivalent");
  copy("", "");
  assert.equal(existsSync(destination), false, "default Release removes previously opted-in content");
  copy("OFFICIAL_REFERENCE_SHEET", "");
  assert.equal(readdirSync(destination).length, 6, "internal beta may explicitly opt in");
  copy("NOT_OFFICIAL_REFERENCE_SHEET", "");
  assert.equal(existsSync(destination), false, "similar condition names must not opt in");
  console.log("Official reference sheet gate: Debug/internal opt-in, default Release exclusion and stale-resource removal passed.");
} finally {
  rmSync(temporary, { recursive: true, force: true });
}
