#!/usr/bin/env node
import { createHash } from "node:crypto";
import { readdirSync, readFileSync, rmSync, mkdirSync, writeFileSync, existsSync, statSync } from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const figuresDir = path.join(repoRoot, "content", "figures");
const lessonsDir = path.join(repoRoot, "content", "lessons");
const appleCatalogDir = path.join(repoRoot, "apps", "apple", "CanadianHam", "Resources", "FigureAssets.xcassets");
const appleMetadataPath = path.join(repoRoot, "apps", "apple", "CanadianHam", "Generated", "LessonFigureMetadata.swift");

const fix = process.argv.includes("--fix");
const selfTest = process.argv.includes("--self-test");
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

function parseAttributes(tag) {
  const attributes = new Map();
  for (const match of tag.matchAll(/([A-Za-z_:][-A-Za-z0-9_:.]*)="([^"]*)"/g)) {
    attributes.set(match[1], match[2]);
  }
  return attributes;
}

function decodeEntities(value) {
  return value
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'");
}

function approximateTextWidth(text, fontSize) {
  const normalized = decodeEntities(text.replace(/<[^>]+>/g, "").trim());
  let units = 0;
  for (const character of normalized) {
    if (/\s/.test(character)) {
      units += 0.35;
    } else if (/[A-Z0-9]/.test(character)) {
      units += 0.68;
    } else if (/[ilI.,;:/'|]/.test(character)) {
      units += 0.35;
    } else {
      units += 0.62;
    }
  }
  return units * fontSize;
}

function checkTextBounds(file, source) {
  const viewBox = parseViewBox(source);
  if (viewBox === null) {
    fail(`${file}: root <svg> must include a valid viewBox so text bounds can be checked`);
    return;
  }

  const padding = 12;
  const defaultTextAnchor = /<g\b[^>]*\btext-anchor="([^"]+)"/i.exec(source)?.[1] ?? "start";
  const textPattern = /<text\b([^>]*)>([\s\S]*?)<\/text>/gi;
  for (const match of source.matchAll(textPattern)) {
    const attributes = parseAttributes(match[1]);
    const fontSize = Number(attributes.get("font-size") ?? "16");
    const x = Number(attributes.get("x") ?? "0");
    const y = Number(attributes.get("y") ?? "0");
    if (![fontSize, x, y].every(Number.isFinite) || fontSize <= 0) {
      fail(`${file}: <text> '${match[2].trim()}' must have numeric x, y, and font-size attributes`);
      continue;
    }

    const text = decodeEntities(match[2].replace(/<[^>]+>/g, "").trim());
    const anchor = attributes.get("text-anchor") ?? defaultTextAnchor;
    const textWidth = approximateTextWidth(text, fontSize);
    const left = anchor === "middle" ? x - textWidth / 2 : anchor === "end" ? x - textWidth : x;
    const right = anchor === "middle" ? x + textWidth / 2 : anchor === "end" ? x : x + textWidth;
    const top = y - fontSize;
    const bottom = y + fontSize * 0.25;
    if (left < viewBox.minX + padding || right > viewBox.minX + viewBox.width - padding || top < viewBox.minY + padding || bottom > viewBox.minY + viewBox.height - padding) {
      fail(`${file}: <text> '${text}' may extend beyond the viewBox padding (estimated bounds ${left.toFixed(1)},${top.toFixed(1)} to ${right.toFixed(1)},${bottom.toFixed(1)})`);
    }
  }
}

function parseViewBox(source) {
  const svgMatch = /<svg\b([^>]*)>/i.exec(source);
  const viewBox = svgMatch === null ? null : /\bviewBox="([^"]+)"/i.exec(svgMatch[1])?.[1];
  if (viewBox === undefined || viewBox === null) {
    return null;
  }
  const values = viewBox.trim().split(/[\s,]+/).map(Number);
  if (values.length !== 4 || !values.every(Number.isFinite) || values[2] <= 0 || values[3] <= 0) {
    return null;
  }
  return { minX: values[0], minY: values[1], width: values[2], height: values[3] };
}

function validateSvgSafety(file, source) {
  const allowedElements = new Set(["svg", "title", "desc", "g", "path", "circle", "ellipse", "line", "polyline", "polygon", "rect", "text", "tspan"]);
  const allowedAttributes = new Set([
    "id", "xmlns", "viewBox", "role", "fill", "stroke", "stroke-linecap", "stroke-linejoin", "stroke-width", "opacity",
    "d", "cx", "cy", "r", "rx", "ry", "x", "y", "x1", "y1", "x2", "y2", "width", "height", "points",
    "font-family", "font-size", "font-weight", "text-anchor"
  ]);
  for (const match of source.matchAll(/<\/?\s*([A-Za-z][A-Za-z0-9:-]*)([^>]*)>/g)) {
    const element = match[1];
    const elementName = element.toLowerCase();
    if (!allowedElements.has(elementName)) {
      fail(`${file}: SVG element <${element}> is not allowed`);
    }
    if (match[0].startsWith("</")) {
      continue;
    }
    const attributes = parseAttributes(match[2]);
    if (elementName === "tspan" && attributes.size > 0) {
      fail(`${file}: <tspan> attributes are not allowed because the checker cannot model positioned tspan text`);
    }
    for (const [name, value] of attributes) {
      const lowerName = name.toLowerCase();
      if (lowerName.startsWith("on")) {
        fail(`${file}: event handler attribute '${name}' is not allowed`);
      }
      if (!allowedAttributes.has(name)) {
        fail(`${file}: SVG attribute '${name}' is not allowed`);
      }
      if (lowerName === "href" || lowerName === "xlink:href") {
        fail(`${file}: SVG references via '${name}' are not allowed`);
      }
      if ((name === "fill" || name === "stroke") && value !== "currentColor" && value !== "none") {
        fail(`${file}: ${name} must be currentColor or none, got '${value}'`);
      }
      if (value.includes("url(") || (name !== "xmlns" && /^https?:/i.test(value))) {
        fail(`${file}: external references are not allowed in '${name}'`);
      }
    }
  }
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
    validateSvgSafety(file, source);
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
    checkTextBounds(file, source);
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
  const idsOnPage = new Set();
  let inFence = false;
  for (let index = 0; index < lines.length; index += 1) {
    const trimmedLine = lines[index]?.trim() ?? "";
    if (/^```/.test(trimmedLine)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) {
      continue;
    }
    const match = /^::figure\s+([a-z0-9][a-z0-9-]*)\s*$/.exec(trimmedLine);
    if (match === null) {
      continue;
    }
    const id = match[1];
    if (idsOnPage.has(id)) {
      fail(`${relativePath}: figure '${id}' is referenced more than once, which would duplicate inline SVG ids`);
    }
    idsOnPage.add(id);
    let altText = "";
    let closed = false;
    index += 1;
    for (; index < lines.length; index += 1) {
      const line = lines[index] ?? "";
      const trimmed = line.trim();
      if (trimmed === "::") {
        closed = true;
        break;
      }
      if (trimmed === "" || /^(#{1,6})(?:\s|$)/.test(line)) {
        index -= 1;
        break;
      }
      const altMatch = /^Alt text:\s*(.+)\s*$/i.exec(trimmed);
      if (altMatch !== null) {
        altText = altMatch[1].trim();
      }
    }
    if (!closed) {
      fail(`${relativePath}: figure '${id}' directive is missing its closing '::' before the next blank line or heading`);
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

function appleMetadataSource(figures) {
  const entries = [...figures.values()].map((figure) => {
    const viewBox = parseViewBox(figure.source);
    if (viewBox === null) {
      return null;
    }
    return `        \"${figure.id}\": CGSize(width: ${viewBox.width}, height: ${viewBox.height})`;
  }).filter((entry) => entry !== null).join(",\n");
  return `// Generated by scripts/check-figures.mjs. Do not edit by hand.\nimport CoreGraphics\n\nenum LessonFigureMetadata {\n    static let sizes: [String: CGSize] = [\n${entries}\n    ]\n\n    static func aspectRatio(for id: String) -> CGFloat {\n        guard let size = sizes[id], size.width > 0, size.height > 0 else {\n            return 4.0 / 3.0\n        }\n        return size.width / size.height\n    }\n}\n`;
}

function writeAppleMetadata(figures) {
  mkdirSync(path.dirname(appleMetadataPath), { recursive: true });
  writeFileSync(appleMetadataPath, appleMetadataSource(figures));
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
  writeAppleMetadata(figures);
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
  if (!existsSync(appleMetadataPath)) {
    fail("Apple figure metadata is missing; run pnpm check:figures:fix");
  } else if (readFileSync(appleMetadataPath, "utf8") !== appleMetadataSource(figures)) {
    fail("Apple figure metadata is out of sync with content/figures viewBox sizes");
  }
}

function runSelfTest() {
  const previousErrorCount = errors.length;
  const safeSvg = `<svg id="safe" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><title>Safe</title><desc>Safe</desc><g fill="currentColor" stroke="none" text-anchor="middle"><text x="50" y="55" font-size="20">OK</text></g></svg>`;
  validateSvgSafety("safe.svg", safeSvg);
  checkTextBounds("safe.svg", safeSvg);
  const refs = parseFigureReferences("```\n::figure ignored\nAlt text: Nope\n::\n```\n\n::figure safe\nalt text: Safe alt\n::", "fixture.md");
  if (refs.length !== 1 || refs[0].id !== "safe" || refs[0].altText !== "Safe alt") {
    fail("self-test: figure reference parser did not skip fences or parse case-insensitive alt text");
  }
  function expectNewError(label, action) {
    const before = errors.length;
    action();
    if (errors.length === before) {
      fail(`self-test: ${label} was not rejected`);
      return;
    }
    errors.splice(before);
  }
  for (const [name, svg] of [
    ["script.svg", `<svg id="bad" viewBox="0 0 10 10"><script>alert(1)</script></svg>`],
    ["handler.svg", `<svg id="bad" viewBox="0 0 10 10"><path onclick="x" d="M0 0"/></svg>`],
    ["style.svg", `<svg id="bad" viewBox="0 0 10 10"><path style="fill:black" d="M0 0"/></svg>`],
    ["colour.svg", `<svg id="bad" viewBox="0 0 10 10"><path fill="black" d="M0 0"/></svg>`],
    ["external.svg", `<svg id="bad" viewBox="0 0 10 10"><use href="https://example.com/x.svg#x"/></svg>`]
  ]) {
    expectNewError(`unsafe SVG fixture ${name}`, () => validateSvgSafety(name, svg));
  }
  expectNewError("unclosed figure directive", () => parseFigureReferences("::figure safe\nAlt text: Safe\n\nNext paragraph", "unclosed.md"));
  if (errors.length > previousErrorCount) {
    throw new Error(errors.slice(previousErrorCount).join("\n"));
  }
}

if (selfTest) {
  try {
    runSelfTest();
    console.log("Figure checker self-test passed.");
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
  process.exit(0);
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
