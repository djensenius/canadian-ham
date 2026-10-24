#!/usr/bin/env node
import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { resolve, join } from "node:path";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";

const root = resolve(import.meta.dirname, "..");
const officialDirectory = join(root, "content/reference/official-basic-exam");
const officialAssetHashes = readOfficialAssetHashes();
const officialAssetsByHash = new Map([...officialAssetHashes].map(([name, hash]) => [hash, name]));

function sha256(content) {
  return createHash("sha256").update(content).digest("hex");
}

function readOfficialAssetHashes() {
  const readme = readFileSync(join(officialDirectory, "README.md"), "utf8");
  const section = readme.split("## SHA-256 of app assets\n")[1]?.split(/^## /m)[0];
  assert.ok(section, "official reference README must list app asset SHA-256 values");
  const assets = new Map([...section.matchAll(/^([a-f0-9]{64}) {2}(page-\d+\.png|text-equivalent\.md)$/gm)]
    .map(([, hash, name]) => [name, hash]));
  assert.equal([...assets.keys()].filter((name) => /^page-\d+\.png$/.test(name)).length, 5,
    "official reference README must list all five page hashes");
  assert.ok(assets.has("text-equivalent.md"), "official reference README must list the transcript hash");
  return assets;
}

function checkProjectYml(project) {
  // Inspect every base/Release mapping, including target-level and multiline settings.
  const lines = project.split("\n");
  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(/^(\s*)(["']?)(base|Release)\2:(?:\s|$)/);
    if (!match) continue;
    let end = index + 1;
    while (end < lines.length) {
      const line = lines[end];
      if (line.trim() && !line.trimStart().startsWith("#") && line.search(/\S/) <= match[1].length) break;
      end += 1;
    }
    assert.doesNotMatch(lines.slice(index, end).join("\n"), /OFFICIAL_REFERENCE_SHEET/,
      `project.yml ${match[3]} settings at line ${index + 1} must not enable public Release content`);
  }
}

function checkGeneratedProject(project) {
  const configurations = [...project.matchAll(/^\s*[A-F0-9]+ \/\*[^\n]*\*\/ = \{\n\s*isa = XCBuildConfiguration;([\s\S]*?)^\t\t\};/gm)];
  const releases = configurations.filter(([, body]) => /\bname = "?Release"?;/.test(body));
  assert.ok(releases.length > 0, "generated project must contain Release build configurations");
  assert.equal(releases.length, (project.match(/\bname = "?Release"?;/g) ?? []).length,
    "every generated Release configuration must be inspected");
  for (const [block] of releases) {
    assert.match(block, /buildSettings = \{/);
    assert.doesNotMatch(block, /OFFICIAL_REFERENCE_SHEET/, "generated Release buildSettings must not enable the official sheet");
  }
}

function checkWebDist(directory) {
  assert.ok(existsSync(directory), `web build output must exist: ${directory}`);
  const transcript = readFileSync(join(officialDirectory, "text-equivalent.md"), "utf8");
  const transcriptMarkers = [transcript.trim(), "Diagram descriptions (project accessibility text, not ISED labels)", "The diagrams on pages 2–5 have no written labels."];
  for (const entry of readdirSync(directory, { recursive: true, withFileTypes: true })) {
    if (!entry.isFile()) continue;
    const path = join(entry.parentPath, entry.name);
    assert.doesNotMatch(entry.name, /^page-\d+(?:-[^.]+)?\.png$/i, `default web build contains an official page: ${path}`);
    assert.doesNotMatch(entry.name, /^text-equivalent(?:-[^.]+)?\.(?:md|txt)$/i, `default web build contains the transcript: ${path}`);
    const bytes = readFileSync(path);
    const officialAsset = officialAssetsByHash.get(sha256(bytes));
    assert.ok(!officialAsset, `default web build contains official asset by SHA-256 (${officialAsset}): ${path}`);
    const content = bytes.toString("utf8");
    for (const marker of transcriptMarkers) {
      assert.ok(!content.includes(marker), `default web build contains official transcript text: ${path}`);
    }
    // Scan every extension: bundlers can inline images in JS, CSS, HTML or other assets.
    for (const [, base64] of content.matchAll(/data:image\/[a-z0-9.+-]+(?:;[^,\s"'()<>]*)?;base64,([a-z0-9+/]+={0,2})/gi)) {
      const inlineAsset = officialAssetsByHash.get(sha256(Buffer.from(base64, "base64")));
      assert.ok(!inlineAsset, `default web build contains inline official asset by SHA-256 (${inlineAsset}): ${path}`);
    }
  }
}

function selfTest(temporary, project, generatedProject) {
  const releaseMapping = "settings:\n  base:\n    PRODUCT_NAME: App\n  configs:\n    Release:\n      PRODUCT_NAME: App\n      OTHER_SWIFT_FLAGS: |\n        $(inherited) -DOFFICIAL_REFERENCE_SHEET\n";
  assert.throws(() => checkProjectYml(releaseMapping), /must not enable/);
  assert.throws(() => checkProjectYml(`targets:\n  App:\n    ${releaseMapping.replaceAll("\n", "\n    ")}`), /must not enable/);
  assert.throws(() => checkProjectYml("targets:\n  Tests:\n    settings:\n      configs:\n        Release: { OTHER_SWIFT_FLAGS: -DOFFICIAL_REFERENCE_SHEET }\n"), /must not enable/);
  assert.throws(() => checkProjectYml("targets:\n  App:\n    settings:\n      base:\n        SWIFT_ACTIVE_COMPILATION_CONDITIONS: OFFICIAL_REFERENCE_SHEET\n"), /must not enable/);
  assert.throws(() => checkProjectYml(releaseMapping.replace("Release:", '"Release":')), /must not enable/);
  assert.throws(() => checkProjectYml("settings:\n  'base': { OTHER_SWIFT_FLAGS: -DOFFICIAL_REFERENCE_SHEET }\n"), /must not enable/);
  checkProjectYml(project);
  checkProjectYml(releaseMapping.replace("-DOFFICIAL_REFERENCE_SHEET", ""));
  const releases = [...generatedProject.matchAll(/^\s*[A-F0-9]+ \/\*[^\n]*\*\/ = \{\n\s*isa = XCBuildConfiguration;([\s\S]*?)^\t\t\};/gm)]
    .filter(([, body]) => /\bname = "?Release"?;/.test(body));
  for (const match of releases) {
    const block = match[0].replace("buildSettings = {", "buildSettings = {\n\t\t\tOTHER_SWIFT_FLAGS = \"-DOFFICIAL_REFERENCE_SHEET\";");
    const mutated = generatedProject.slice(0, match.index) + block + generatedProject.slice(match.index + match[0].length);
    assert.throws(() => checkGeneratedProject(mutated), /must not enable/, "must reject opt-in in every project/target Release buildSettings");
  }
  assert.throws(() => checkGeneratedProject("name = Release;"), /must contain/);
  const dist = join(temporary, "dist", "assets");
  mkdirSync(dist, { recursive: true });
  writeFileSync(join(dist, "app.js"), "export default null;");
  const studySheet = readFileSync(join(root, "content/reference-sheet/basic.md"), "utf8");
  writeFileSync(join(dist, "study-sheet.txt"), studySheet);
  writeFileSync(join(dist, "study-sheet.js"), `export default ${JSON.stringify(studySheet)};`);
  writeFileSync(join(dist, "unrelated.css"), 'body { background: url("data:image/png;base64,aW1hZ2U="); }');
  checkWebDist(join(temporary, "dist"));
  for (const [name, hash] of officialAssetHashes) {
    const bytes = readFileSync(join(officialDirectory, name));
    assert.equal(sha256(bytes), hash, `official asset must match its README SHA-256: ${name}`);
    for (const renamed of ["renamed.png", "asset-D6h8k2.webp", "download.bin", "extensionless"]) {
      writeFileSync(join(dist, renamed), bytes);
      assert.throws(() => checkWebDist(join(temporary, "dist")), /official asset by SHA-256/,
        `must reject ${name} renamed to ${renamed}`);
      rmSync(join(dist, renamed));
    }
    if (!name.endsWith(".png")) continue;
    for (const [inlinedName, content] of [
      ["inline.js", `export default "data:image/png;base64,${bytes.toString("base64")}";`],
      ["inline.css", `body { background: url('data:image/png;base64,${bytes.toString("base64")}'); }`],
      ["inline.bin", `<img src="DATA:IMAGE/PNG;charset=utf-8;BASE64,${bytes.toString("base64")}">`],
    ]) {
      writeFileSync(join(dist, inlinedName), content);
      assert.throws(() => checkWebDist(join(temporary, "dist")), /inline official asset by SHA-256/,
        `must reject ${name} inlined in ${inlinedName}`);
      rmSync(join(dist, inlinedName));
    }
  }
  for (const [name, content] of [
    ["page-1.png", "image"], ["page-5-hashed.png", "image"],
    ["text-equivalent-hashed.md", "transcript"],
    ["official.js", "Diagram descriptions (project accessibility text, not ISED labels)"],
    ["official.css", "/* The diagrams on pages 2–5 have no written labels. */"],
    ["transcript.bin", JSON.stringify(readFileSync(join(officialDirectory, "text-equivalent.md"), "utf8"))],
  ]) {
    writeFileSync(join(dist, name), content);
    assert.throws(() => checkWebDist(join(temporary, "dist")), /default web build contains/);
    rmSync(join(dist, name));
  }
  checkWebDist(join(temporary, "dist"));
  console.log(`Official reference sheet gate self-test: YAML scopes, all ${releases.length} generated Release configurations, renamed assets (all extensions), inline JS/CSS image data URLs, transcript content and clean study-sheet fixtures passed.`);
}

const temporary = mkdtempSync(join(tmpdir(), "official-reference-gate-"));
try {
  const project = readFileSync(join(root, "apps/apple/project.yml"), "utf8");
  checkProjectYml(project);
  assert.match(project, /Debug:\n\s+OTHER_SWIFT_FLAGS: \$\(inherited\) -DOFFICIAL_REFERENCE_SHEET/);
  assert.equal((project.match(/name: Copy gated official exam reference sheet/g) ?? []).length, 2);
  assert.doesNotMatch(project, /path: .*content\/reference\/official-basic-exam/, "official assets must not be unconditional resource members");
  const generatedProject = readFileSync(join(root, "apps/apple/CanadianHam.xcodeproj/project.pbxproj"), "utf8");
  checkGeneratedProject(generatedProject);
  assert.match(generatedProject, /copy-official-reference-sheet\.sh/);
  assert.doesNotMatch(generatedProject, /page-[1-5]\.png/, "generated project must not add unconditional official images");
  selfTest(temporary, project, generatedProject);
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
  if (process.argv.includes("--web-dist")) {
    if (process.env.OFFICIAL_REFERENCE_SHEET === "YES") {
      console.log("Web output exclusion check not applicable: explicitly opted-in internal build.");
    } else {
      checkWebDist(join(root, "apps/web/dist"));
      console.log("Default web output contains no official asset hashes (standalone or inline) or transcript text.");
    }
  }
} finally {
  rmSync(temporary, { recursive: true, force: true });
}
