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
    } else if (/[ilI.,;:/'|]/.test(character)) {
      units += 0.42;
    } else if (/[A-Z0-9]/.test(character)) {
      units += 0.76;
    } else {
      units += 0.72;
    }
  }
  return units * fontSize;
}

function inheritedTextAnchorAt(source, position) {
  const stack = ["start"];
  const tagPattern = /<\/?\s*([A-Za-z][A-Za-z0-9:-]*)([^>]*)>/g;
  for (const match of source.slice(0, position).matchAll(tagPattern)) {
    const fullTag = match[0];
    const elementName = match[1].toLowerCase();
    if (elementName !== "g") {
      continue;
    }
    if (fullTag.startsWith("</")) {
      if (stack.length > 1) {
        stack.pop();
      }
      continue;
    }
    const attributes = parseAttributes(match[2]);
    const inherited = stack[stack.length - 1] ?? "start";
    if (!fullTag.endsWith("/>")) {
      stack.push(attributes.get("text-anchor") ?? inherited);
    }
  }
  return stack[stack.length - 1] ?? "start";
}

function estimatedTextBoxes(file, source, viewBox) {
  const boxes = [];
  const padding = 12;
  const textPattern = /<text\b([^>]*)>([\s\S]*?)<\/text>/gi;
  for (const match of source.matchAll(textPattern)) {
    const attributes = parseAttributes(match[1]);
    const fontSize = Number(attributes.get("font-size") ?? "16");
    const x = Number(attributes.get("x") ?? "0");
    const y = Number(attributes.get("y") ?? "0");
    const text = decodeEntities(match[2].replace(/<[^>]+>/g, "").trim());
    if (![fontSize, x, y].every(Number.isFinite) || fontSize <= 0) {
      fail(`${file}: <text> '${match[2].trim()}' must have numeric x, y, and font-size attributes`);
      continue;
    }

    const minimumFontSize = viewBox.width * 0.0367;
    if (fontSize < minimumFontSize) {
      fail(`${file}: <text> '${text}' font-size ${fontSize} is below the minimum ${minimumFontSize.toFixed(1)} for an 11pt label at 300pt display width`);
    }
    const anchor = attributes.get("text-anchor") ?? inheritedTextAnchorAt(source, match.index ?? 0);
    const textWidth = approximateTextWidth(text, fontSize);
    const left = anchor === "middle" ? x - textWidth / 2 : anchor === "end" ? x - textWidth : x;
    const right = anchor === "middle" ? x + textWidth / 2 : anchor === "end" ? x : x + textWidth;
    const top = y - fontSize;
    const bottom = y + fontSize * 0.25;
    if (left < viewBox.minX + padding || right > viewBox.minX + viewBox.width - padding || top < viewBox.minY + padding || bottom > viewBox.minY + viewBox.height - padding) {
      fail(`${file}: <text> '${text}' may extend beyond the viewBox padding (estimated bounds ${left.toFixed(1)},${top.toFixed(1)} to ${right.toFixed(1)},${bottom.toFixed(1)})`);
    }
    boxes.push({ text, left, right, top, bottom });
  }
  return boxes;
}

function checkTextBounds(file, source) {
  const viewBox = parseViewBox(source);
  if (viewBox === null) {
    fail(`${file}: root <svg> must include a valid viewBox so text bounds can be checked`);
    return;
  }

  const textBoxes = estimatedTextBoxes(file, source, viewBox);
  checkStrokeTextClearance(file, source, textBoxes);
}

function readNumber(tokens, index) {
  if (index >= tokens.length || /^[A-Za-z]$/.test(tokens[index])) {
    return null;
  }
  const value = Number(tokens[index]);
  return Number.isFinite(value) ? { value, next: index + 1 } : null;
}

function lineSamples(x1, y1, x2, y2, count = 24) {
  const samples = [];
  for (let step = 0; step <= count; step += 1) {
    const t = step / count;
    samples.push({ x: x1 + (x2 - x1) * t, y: y1 + (y2 - y1) * t });
  }
  return samples;
}

function cubicPoint(p0, p1, p2, p3, t) {
  const mt = 1 - t;
  return mt * mt * mt * p0 + 3 * mt * mt * t * p1 + 3 * mt * t * t * p2 + t * t * t * p3;
}

function quadraticPoint(p0, p1, p2, t) {
  const mt = 1 - t;
  return mt * mt * p0 + 2 * mt * t * p1 + t * t * p2;
}

function pathSamples(d) {
  const tokens = d.match(/[A-Za-z]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?/g) ?? [];
  const samples = [];
  let index = 0;
  let command = "";
  let x = 0;
  let y = 0;
  let startX = 0;
  let startY = 0;
  const read = () => {
    const result = readNumber(tokens, index);
    if (result === null) {
      return null;
    }
    index = result.next;
    return result.value;
  };
  const hasNumber = () => index < tokens.length && !/^[A-Za-z]$/.test(tokens[index]);
  const absolute = (value, current, relative) => relative ? current + value : value;

  while (index < tokens.length) {
    if (/^[A-Za-z]$/.test(tokens[index])) {
      command = tokens[index++];
    }
    const relative = command === command.toLowerCase();
    switch (command.toUpperCase()) {
      case "M": {
        const nx = read();
        const ny = read();
        if (nx === null || ny === null) return samples;
        x = absolute(nx, x, relative);
        y = absolute(ny, y, relative);
        startX = x;
        startY = y;
        samples.push({ x, y });
        command = relative ? "l" : "L";
        break;
      }
      case "L": {
        while (hasNumber()) {
          const nx = read();
          const ny = read();
          if (nx === null || ny === null) return samples;
          const nextX = absolute(nx, x, relative);
          const nextY = absolute(ny, y, relative);
          samples.push(...lineSamples(x, y, nextX, nextY));
          x = nextX;
          y = nextY;
        }
        break;
      }
      case "H": {
        while (hasNumber()) {
          const nx = read();
          if (nx === null) return samples;
          const nextX = absolute(nx, x, relative);
          samples.push(...lineSamples(x, y, nextX, y));
          x = nextX;
        }
        break;
      }
      case "V": {
        while (hasNumber()) {
          const ny = read();
          if (ny === null) return samples;
          const nextY = absolute(ny, y, relative);
          samples.push(...lineSamples(x, y, x, nextY));
          y = nextY;
        }
        break;
      }
      case "C": {
        while (hasNumber()) {
          const x1 = read(); const y1 = read(); const x2 = read(); const y2 = read(); const x3 = read(); const y3 = read();
          if ([x1, y1, x2, y2, x3, y3].some((value) => value === null)) return samples;
          const cx1 = absolute(x1, x, relative);
          const cy1 = absolute(y1, y, relative);
          const cx2 = absolute(x2, x, relative);
          const cy2 = absolute(y2, y, relative);
          const nextX = absolute(x3, x, relative);
          const nextY = absolute(y3, y, relative);
          for (let step = 0; step <= 40; step += 1) {
            const t = step / 40;
            samples.push({ x: cubicPoint(x, cx1, cx2, nextX, t), y: cubicPoint(y, cy1, cy2, nextY, t) });
          }
          x = nextX;
          y = nextY;
        }
        break;
      }
      case "Q": {
        while (hasNumber()) {
          const x1 = read(); const y1 = read(); const x2 = read(); const y2 = read();
          if ([x1, y1, x2, y2].some((value) => value === null)) return samples;
          const cx1 = absolute(x1, x, relative);
          const cy1 = absolute(y1, y, relative);
          const nextX = absolute(x2, x, relative);
          const nextY = absolute(y2, y, relative);
          for (let step = 0; step <= 32; step += 1) {
            const t = step / 32;
            samples.push({ x: quadraticPoint(x, cx1, nextX, t), y: quadraticPoint(y, cy1, nextY, t) });
          }
          x = nextX;
          y = nextY;
        }
        break;
      }
      case "Z": {
        samples.push(...lineSamples(x, y, startX, startY));
        x = startX;
        y = startY;
        command = "";
        break;
      }
      default:
        return samples;
    }
  }
  return samples;
}

function parsePoints(points) {
  const values = points.trim().split(/[\s,]+/).map(Number);
  const result = [];
  for (let index = 0; index + 1 < values.length; index += 2) {
    if (Number.isFinite(values[index]) && Number.isFinite(values[index + 1])) {
      result.push({ x: values[index], y: values[index + 1] });
    }
  }
  return result;
}

function collectStrokeSamples(source) {
  const samples = [];
  const stack = [{ stroke: null, strokeWidth: 1 }];
  const tagPattern = /<\/?\s*([A-Za-z][A-Za-z0-9:-]*)([^>]*)>/g;
  for (const match of source.matchAll(tagPattern)) {
    const fullTag = match[0];
    const elementName = match[1].toLowerCase();
    if (fullTag.startsWith("</")) {
      if (elementName === "g" && stack.length > 1) {
        stack.pop();
      }
      continue;
    }
    const attributes = parseAttributes(match[2]);
    const parent = stack[stack.length - 1] ?? { stroke: null, strokeWidth: 1 };
    const state = {
      stroke: attributes.get("stroke") ?? parent.stroke,
      strokeWidth: Number(attributes.get("stroke-width") ?? parent.strokeWidth)
    };
    if (!Number.isFinite(state.strokeWidth) || state.strokeWidth <= 0) {
      state.strokeWidth = parent.strokeWidth;
    }
    if (elementName === "g") {
      if (!fullTag.endsWith("/>")) {
        stack.push(state);
      }
      continue;
    }
    if (state.stroke === null || state.stroke === "none") {
      continue;
    }

    let elementSamples = [];
    if (elementName === "path") {
      elementSamples = pathSamples(attributes.get("d") ?? "");
    } else if (elementName === "circle") {
      const cx = Number(attributes.get("cx") ?? 0);
      const cy = Number(attributes.get("cy") ?? 0);
      const r = Number(attributes.get("r") ?? 0);
      if ([cx, cy, r].every(Number.isFinite) && r > 0) {
        for (let step = 0; step < 192; step += 1) {
          const angle = (Math.PI * 2 * step) / 192;
          elementSamples.push({ x: cx + Math.cos(angle) * r, y: cy + Math.sin(angle) * r });
        }
      }
    } else if (elementName === "line") {
      elementSamples = lineSamples(Number(attributes.get("x1") ?? 0), Number(attributes.get("y1") ?? 0), Number(attributes.get("x2") ?? 0), Number(attributes.get("y2") ?? 0));
    } else if (elementName === "polyline" || elementName === "polygon") {
      const points = parsePoints(attributes.get("points") ?? "");
      for (let index = 0; index + 1 < points.length; index += 1) {
        elementSamples.push(...lineSamples(points[index].x, points[index].y, points[index + 1].x, points[index + 1].y));
      }
      if (elementName === "polygon" && points.length > 2) {
        elementSamples.push(...lineSamples(points.at(-1).x, points.at(-1).y, points[0].x, points[0].y));
      }
    } else if (elementName === "rect") {
      const x = Number(attributes.get("x") ?? 0);
      const y = Number(attributes.get("y") ?? 0);
      const width = Number(attributes.get("width") ?? 0);
      const height = Number(attributes.get("height") ?? 0);
      if ([x, y, width, height].every(Number.isFinite) && width > 0 && height > 0) {
        elementSamples.push(...lineSamples(x, y, x + width, y));
        elementSamples.push(...lineSamples(x + width, y, x + width, y + height));
        elementSamples.push(...lineSamples(x + width, y + height, x, y + height));
        elementSamples.push(...lineSamples(x, y + height, x, y));
      }
    } else if (elementName === "ellipse") {
      const cx = Number(attributes.get("cx") ?? 0);
      const cy = Number(attributes.get("cy") ?? 0);
      const rx = Number(attributes.get("rx") ?? 0);
      const ry = Number(attributes.get("ry") ?? 0);
      if ([cx, cy, rx, ry].every(Number.isFinite) && rx > 0 && ry > 0) {
        for (let step = 0; step < 192; step += 1) {
          const angle = (Math.PI * 2 * step) / 192;
          elementSamples.push({ x: cx + Math.cos(angle) * rx, y: cy + Math.sin(angle) * ry });
        }
      }
    }
    for (const sample of elementSamples) {
      samples.push({ ...sample, strokeWidth: state.strokeWidth });
    }
  }
  return samples;
}

function checkStrokeTextClearance(file, source, textBoxes) {
  const strokeSamples = collectStrokeSamples(source);
  for (const box of textBoxes) {
    for (const sample of strokeSamples) {
      const expansion = sample.strokeWidth / 2 + 2;
      if (sample.x >= box.left - expansion && sample.x <= box.right + expansion && sample.y >= box.top - expansion && sample.y <= box.bottom + expansion) {
        fail(`${file}: stroke may touch <text> '${box.text}' (sample ${sample.x.toFixed(1)},${sample.y.toFixed(1)} intersects estimated text bounds expanded by stroke width)`);
        break;
      }
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
  if (/<!\s*(?:DOCTYPE|ENTITY)\b/i.test(source) || /<!\[CDATA\[/i.test(source)) {
    fail(`${file}: DOCTYPE, ENTITY, and CDATA declarations are not allowed in lesson SVGs`);
  }
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
    const leftoverAttributes = match[2]
      .replace(/([A-Za-z_:][-A-Za-z0-9_:.]*)="([^"]*)"/g, "")
      .replace(/\//g, "")
      .trim();
    if (leftoverAttributes.length > 0) {
      fail(`${file}: SVG tag <${element}> contains unsupported or non-double-quoted attribute syntax '${leftoverAttributes}'`);
    }
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
    ["single-quoted-attribute.svg", `<svg id="bad" viewBox="0 0 10 10"><path fill='red' d="M0 0"/></svg>`],
    ["unquoted-attribute.svg", `<svg id="bad" viewBox="0 0 10 10"><path fill=red d="M0 0"/></svg>`],
    ["doctype.svg", `<!DOCTYPE svg><svg id="bad" viewBox="0 0 10 10"></svg>`],
    ["entity.svg", `<!ENTITY x "bad"><svg id="bad" viewBox="0 0 10 10"></svg>`],
    ["cdata.svg", `<svg id="bad" viewBox="0 0 10 10"><![CDATA[bad]]></svg>`],
    ["external.svg", `<svg id="bad" viewBox="0 0 10 10"><use href="https://example.com/x.svg#x"/></svg>`]
  ]) {
    expectNewError(`unsafe SVG fixture ${name}`, () => validateSvgSafety(name, svg));
  }
  expectNewError("minimum text size", () => checkTextBounds("small-text.svg", `<svg id="bad" viewBox="0 0 100 100"><text x="50" y="50" font-size="2">tiny</text></svg>`));
  expectNewError("text bounds", () => checkTextBounds("out-of-bounds-text.svg", `<svg id="bad" viewBox="0 0 100 100"><text x="2" y="10" font-size="20">Wide</text></svg>`));
  expectNewError("stroke/text clearance", () => checkTextBounds("stroke-text.svg", `<svg id="bad" viewBox="0 0 100 100"><g stroke="currentColor" fill="none"><line x1="0" y1="50" x2="100" y2="50" stroke-width="10"/></g><text x="40" y="55" font-size="20">Hit</text></svg>`));
  expectNewError("duplicate figure directive", () => parseFigureReferences("::figure safe\nAlt text: Safe\n::\n\n::figure safe\nAlt text: Safe again\n::", "duplicate.md"));
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
