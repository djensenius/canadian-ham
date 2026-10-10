#!/usr/bin/env node
import { createHash } from "node:crypto";
import { readdirSync, readFileSync, rmSync, mkdirSync, writeFileSync, existsSync, statSync } from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const figuresDir = path.join(repoRoot, "content", "figures");
const lessonsDir = path.join(repoRoot, "content", "lessons");
const appleCatalogDir = path.join(repoRoot, "apps", "apple", "CanadianHam", "Resources", "FigureAssets.xcassets");

const fix = process.argv.includes("--fix");
const errors = [];

function fail(message) {
  errors.push(message);
}

function listFiles(dir, predicate) {
  const results = [];
  function walk(current) {
    for (const entry of readdirSync(current, { withFileTypes: true })) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (predicate(full)) {
        results.push(full);
      }
    }
  }
  walk(dir);
  return results.sort((a, b) => a.localeCompare(b));
}

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

function readFigures() {
  if (!existsSync(figuresDir)) {
    fail("content/figures does not exist");
    return new Map();
  }
  const figures = new Map();
  for (const file of readdirSync(figuresDir).filter((name) => name.endsWith(".svg")).sort()) {
    const id = file.replace(/\.svg$/, "");
    if (!/^[a-z0-9][a-z0-9-]*$/.test(id)) {
      fail(`${file}: figure filenames must be lower-case stable ids with hyphens only`);
    }
    const source = readFileSync(path.join(figuresDir, file), "utf8");
    const rootId = /<svg\b[^>]*\bid="([^"]+)"/i.exec(source)?.[1];
    if (rootId !== id) {
      fail(`${file}: root <svg id> must equal filename id '${id}'`);
    }
    if (/#[0-9a-f]{3,8}\b/i.test(source)) {
      fail(`${file}: hard-coded hex colours are not allowed; use currentColor/design tokens`);
    }
    if (!/<title>[^<]+<\/title>/i.test(source) || !/<desc>[^<]+<\/desc>/i.test(source)) {
      fail(`${file}: SVG source must include <title> and <desc> for authoring context`);
    }
    figures.set(id, { id, file, source });
  }
  if (figures.size === 0) {
    fail("content/figures contains no SVG sources");
  }
  return figures;
}

function parseFigureReferences(markdown, relativePath) {
  const lines = markdown.replace(/\r\n/g, "\n").split("\n");
  const references = [];
  for (let index = 0; index < lines.length; index += 1) {
    const match = /^::figure\s+([a-z0-9][a-z0-9-]*)\s*$/.exec(lines[index]?.trim() ?? "");
    if (match === null) {
      continue;
    }
    const id = match[1];
    let altText = "";
    let closed = false;
    index += 1;
    for (; index < lines.length; index += 1) {
      const line = lines[index] ?? "";
      if (line.trim() === "::") {
        closed = true;
        break;
      }
      const altMatch = /^Alt text:\s*(.+)\s*$/i.exec(line.trim());
      if (altMatch !== null) {
        altText = altMatch[1].trim();
      }
    }
    if (!closed) {
      fail(`${relativePath}: figure '${id}' directive is missing its closing '::'`);
    }
    if (altText.length === 0) {
      fail(`${relativePath}: figure '${id}' is missing non-empty Alt text`);
    }
    references.push({ id, altText, relativePath });
  }
  return references;
}

function checkReferences(figures) {
  const references = [];
  for (const file of listFiles(lessonsDir, (name) => name.endsWith(".md"))) {
    const markdown = readFileSync(file, "utf8");
    references.push(...parseFigureReferences(markdown, path.relative(repoRoot, file)));
  }
  for (const reference of references) {
    if (!figures.has(reference.id)) {
      fail(`${reference.relativePath}: figure '${reference.id}' does not resolve to content/figures/${reference.id}.svg`);
    }
  }
  return references;
}

function assetContentsJSON(filename) {
  return `${JSON.stringify({
    images: [{ filename, idiom: "universal" }],
    info: { author: "xcode", version: 1 },
    properties: {
      "preserves-vector-representation": true,
      "template-rendering-intent": "template"
    }
  }, null, 2)}\n`;
}

function expectedAssets(figures) {
  const assets = new Map();
  for (const figure of figures.values()) {
    const assetName = `lesson-figure-${figure.id}`;
    const svgFilename = `${assetName}.svg`;
    assets.set(assetName, {
      assetName,
      svgFilename,
      source: figure.source,
      contents: assetContentsJSON(svgFilename)
    });
  }
  return assets;
}

function writeAssets(figures) {
  rmSync(appleCatalogDir, { recursive: true, force: true });
  mkdirSync(appleCatalogDir, { recursive: true });
  writeFileSync(path.join(appleCatalogDir, "Contents.json"), `${JSON.stringify({ info: { author: "xcode", version: 1 } }, null, 2)}\n`);
  for (const asset of expectedAssets(figures).values()) {
    const imageset = path.join(appleCatalogDir, `${asset.assetName}.imageset`);
    mkdirSync(imageset, { recursive: true });
    writeFileSync(path.join(imageset, asset.svgFilename), asset.source);
    writeFileSync(path.join(imageset, "Contents.json"), asset.contents);
  }
}

function checkAssets(figures) {
  if (!existsSync(appleCatalogDir)) {
    fail("Apple figure asset catalog is missing; run pnpm check:figures:fix");
    return;
  }
  const rootContents = path.join(appleCatalogDir, "Contents.json");
  if (!existsSync(rootContents)) {
    fail("Apple figure asset catalog is missing Contents.json");
  }
  const expected = expectedAssets(figures);
  for (const asset of expected.values()) {
    const imageset = path.join(appleCatalogDir, `${asset.assetName}.imageset`);
    if (!existsSync(imageset) || !statSync(imageset).isDirectory()) {
      fail(`Apple figure asset '${asset.assetName}' is missing`);
      continue;
    }
    const svgPath = path.join(imageset, asset.svgFilename);
    const contentsPath = path.join(imageset, "Contents.json");
    if (!existsSync(svgPath)) {
      fail(`Apple figure asset '${asset.assetName}' is missing ${asset.svgFilename}`);
    } else if (sha256(readFileSync(svgPath, "utf8")) !== sha256(asset.source)) {
      fail(`Apple figure asset '${asset.assetName}' SVG is out of sync with content/figures`);
    }
    if (!existsSync(contentsPath)) {
      fail(`Apple figure asset '${asset.assetName}' is missing Contents.json`);
    } else if (readFileSync(contentsPath, "utf8") !== asset.contents) {
      fail(`Apple figure asset '${asset.assetName}' Contents.json is out of sync`);
    }
  }
  const actualImagesets = new Set(readdirSync(appleCatalogDir).filter((name) => name.endsWith(".imageset")).map((name) => name.replace(/\.imageset$/, "")));
  for (const assetName of actualImagesets) {
    if (!expected.has(assetName)) {
      fail(`Apple figure asset '${assetName}' has no matching content/figures SVG`);
    }
  }
}

const figures = readFigures();
const references = checkReferences(figures);
if (fix) {
  writeAssets(figures);
}
checkAssets(figures);

if (errors.length > 0) {
  for (const error of errors) {
    console.error(`figure check: ${error}`);
  }
  process.exit(1);
}
console.log(`Figure check passed: ${figures.size} SVG source(s), ${references.length} lesson reference(s), Apple assets ${fix ? "generated and " : ""}in sync.`);
