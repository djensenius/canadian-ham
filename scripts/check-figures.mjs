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

function stripMarkup(value) {
  return decodeEntities(value.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim());
}

function parseStyleAttribute(value) {
  const declarations = new Map();
  for (const declaration of (value ?? "").split(";")) {
    const separator = declaration.indexOf(":");
    if (separator === -1) {
      continue;
    }
    const property = declaration.slice(0, separator).trim();
    const propertyValue = declaration.slice(separator + 1).trim();
    if (property.length > 0 && propertyValue.length > 0) {
      declarations.set(property, propertyValue);
    }
  }
  return declarations;
}

function presentationValue(attributes, name) {
  const style = parseStyleAttribute(attributes.get("style"));
  return style.get(name) ?? attributes.get(name);
}

function parseLength(value, fallback = Number.NaN) {
  if (value === undefined || value === null || value === "") {
    return fallback;
  }
  const match = /^[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?/.exec(String(value).trim());
  return match === null ? fallback : Number(match[0]);
}

function parseFirstLength(value, fallback = Number.NaN) {
  if (value === undefined || value === null) {
    return fallback;
  }
  return parseLength(String(value).trim().split(/[\s,]+/)[0], fallback);
}

function parsePointList(value) {
  const numbers = [...String(value ?? "").matchAll(/[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?/g)].map((match) => Number(match[0]));
  const points = [];
  for (let index = 0; index + 1 < numbers.length; index += 2) {
    points.push({ x: numbers[index], y: numbers[index + 1] });
  }
  return points;
}

function isBoldWeight(fontWeight) {
  const normalized = String(fontWeight ?? "").trim().toLowerCase();
  return normalized === "bold" || normalized === "bolder" || Number(normalized) >= 600;
}

function normalizedFontWeight(fontWeight) {
  return isBoldWeight(fontWeight) ? "bold" : "normal";
}

function mergeTextStyle(parent, attributes) {
  const next = { ...parent };
  const fontSize = presentationValue(attributes, "font-size");
  const fontWeight = presentationValue(attributes, "font-weight");
  const textAnchor = presentationValue(attributes, "text-anchor");
  const fontFamily = presentationValue(attributes, "font-family");
  if (fontSize !== undefined) {
    next.fontSize = fontSize;
  }
  if (fontWeight !== undefined) {
    next.fontWeight = fontWeight;
  }
  if (textAnchor !== undefined) {
    next.textAnchor = textAnchor;
  }
  if (fontFamily !== undefined) {
    next.fontFamily = fontFamily;
  }
  return next;
}

function mergeStrokeStyle(parent, attributes) {
  const next = { ...parent };
  const stroke = presentationValue(attributes, "stroke");
  const strokeWidth = presentationValue(attributes, "stroke-width");
  const fill = presentationValue(attributes, "fill");
  if (stroke !== undefined) {
    next.stroke = stroke;
  }
  if (strokeWidth !== undefined) {
    next.strokeWidth = strokeWidth;
  }
  if (fill !== undefined) {
    next.fill = fill;
  }
  return next;
}

function lengthTokens(value) {
  return String(value ?? "").trim().split(/[\s,]+/).filter((token) => token.length > 0);
}

function isUnitlessNumber(value) {
  return /^[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?$/.test(String(value ?? "").trim());
}

function parseSingleUnitlessLength(value, fallback, failFn, context) {
  if (value === undefined || value === null || value === "") {
    return fallback;
  }
  const tokens = lengthTokens(value);
  if (tokens.length !== 1) {
    failFn(`${context} must use a single unitless value; per-glyph lists are not supported`);
    return Number.NaN;
  }
  if (!isUnitlessNumber(tokens[0])) {
    failFn(`${context} must be unitless; '${value}' is not supported`);
    return Number.NaN;
  }
  return Number(tokens[0]);
}

function rawTextSegment(value) {
  const decoded = decodeEntities(value.replace(/<[^>]+>/g, ""));
  if (/^\s*$/.test(decoded)) {
    return "";
  }
  return decoded.replace(/\s+/g, " ");
}

function approximateTextWidth(text, fontSize, fontWeight = "400") {
  const normalized = decodeEntities(text.replace(/<[^>]+>/g, ""));
  let units = 0;
  let upperOrDigitCount = 0;
  let nonSpaceCount = 0;
  for (const character of normalized) {
    if (/\s/.test(character)) {
      units += 0.35;
    } else if (/[MW@#%&]/.test(character)) {
      units += 0.9;
      upperOrDigitCount += 1;
      nonSpaceCount += 1;
    } else if (/[A-ZÀ-ÖØ-ÞΩ]/.test(character)) {
      units += 0.74;
      upperOrDigitCount += 1;
      nonSpaceCount += 1;
    } else if (/[0-9]/.test(character)) {
      units += 0.64;
      upperOrDigitCount += 1;
      nonSpaceCount += 1;
    } else if (/[ilI.,;:/'|!]/.test(character)) {
      units += 0.38;
      nonSpaceCount += 1;
    } else if (/[-+=/()\[\]{}x×√²]/.test(character)) {
      units += 0.55;
      nonSpaceCount += 1;
    } else {
      units += 0.62;
      nonSpaceCount += 1;
    }
  }
  const uppercaseFactor = nonSpaceCount > 0 && upperOrDigitCount / nonSpaceCount >= 0.5 ? 1.05 : 1;
  const weightFactor = isBoldWeight(fontWeight) ? 1.08 : 1;
  const proportionalWidth = units * fontSize * uppercaseFactor * weightFactor;
  const monospaceFloor = [...normalized].length * fontSize * 0.6;
  return Math.max(proportionalWidth, monospaceFloor);
}

function runMetrics(text, fontSize, fontWeight) {
  const width = approximateTextWidth(text, fontSize, fontWeight);
  const hasDescender = /[gjpqy]/.test(text);
  const bounds = {
    top: -fontSize * 0.8,
    bottom: fontSize * (hasDescender ? 0.25 : 0.2),
    fontSize,
    width
  };
  const horizontalBearing = Math.min(width * 0.18, fontSize * 0.12);
  bounds.strokeInsetLeft = horizontalBearing;
  bounds.strokeInsetRight = horizontalBearing;
  bounds.strokeTop = -fontSize * 0.72;
  bounds.strokeBottom = fontSize * (hasDescender ? 0.18 : 0.12);
  return bounds;
}

function anchoredLineBounds(line, file, failFn) {
  const runMetricsList = [];
  let totalWidth = 0;
  for (const run of line.runs) {
    const fontSize = parseSingleUnitlessLength(run.style.fontSize, 16, failFn, `${file}: <text> '${run.text.trim()}' font-size`);
    if (!Number.isFinite(fontSize) || fontSize <= 0) {
      failFn(`${file}: <text> '${run.text.trim()}' must have a positive unitless font-size`);
      return null;
    }
    const metrics = runMetrics(run.text, fontSize, run.style.fontWeight);
    runMetricsList.push({ run, metrics, fontSize });
    totalWidth += metrics.width;
  }
  const anchor = ["start", "middle", "end"].includes(line.textAnchor) ? line.textAnchor : "start";
  const left = anchor === "middle" ? line.x - totalWidth / 2 : anchor === "end" ? line.x - totalWidth : line.x;
  const right = left + totalWidth;
  let cursor = left;
  const runBounds = [];
  for (const item of runMetricsList) {
    const { metrics } = item;
    const runLeft = cursor;
    const runRight = cursor + metrics.width;
    runBounds.push({
      left: runLeft,
      right: runRight,
      top: line.y + metrics.top,
      bottom: line.y + metrics.bottom,
      strokeBounds: {
        left: Math.min(runLeft + metrics.strokeInsetLeft, (runLeft + runRight) / 2),
        right: Math.max(runRight - metrics.strokeInsetRight, (runLeft + runRight) / 2),
        top: line.y + metrics.strokeTop,
        bottom: line.y + metrics.strokeBottom
      },
      fillBounds: {
        left: Math.min(runLeft + metrics.strokeInsetLeft, (runLeft + runRight) / 2),
        right: Math.max(runRight - metrics.strokeInsetRight, (runLeft + runRight) / 2),
        top: line.y - metrics.fontSize * 0.7,
        bottom: line.y + metrics.fontSize * 0.12
      }
    });
    cursor = runRight;
  }
  const bounds = unionBounds(runBounds);
  const strokeBounds = unionBounds(runBounds.map((bound) => bound.strokeBounds));
  const fillBounds = unionBounds(runBounds.map((bound) => bound.fillBounds));
  const text = line.runs.map((run) => run.text).join("").replace(/\s+/g, " ").trim();
  return {
    text,
    bounds,
    strokeBounds,
    fillBounds,
    fontSize: Math.max(...runMetricsList.map((item) => item.fontSize)),
    fontWeight: normalizedFontWeight(line.runs[0]?.style.fontWeight),
    textAnchor: anchor,
    anchorX: line.x,
    baselineY: line.y,
    runs: line.runs
  };
}

function unionBounds(bounds) {
  return {
    left: Math.min(...bounds.map((bound) => bound.left)),
    right: Math.max(...bounds.map((bound) => bound.right)),
    top: Math.min(...bounds.map((bound) => bound.top)),
    bottom: Math.max(...bounds.map((bound) => bound.bottom))
  };
}

function validateTextPositionAttribute(file, tag, attributes, name, failFn) {
  if (!attributes.has(name)) {
    return;
  }
  parseSingleUnitlessLength(attributes.get(name), Number.NaN, failFn, `${file}: <${tag}> ${name}`);
}

function collectTextBoxes(file, textAttributes, inheritedStyle, body, failFn) {
  const textStyle = mergeTextStyle(inheritedStyle, textAttributes);
  const rootX = parseSingleUnitlessLength(textAttributes.get("x"), Number.NaN, failFn, `${file}: <text> x`);
  const rootY = parseSingleUnitlessLength(textAttributes.get("y"), Number.NaN, failFn, `${file}: <text> y`);
  const rootDx = parseSingleUnitlessLength(textAttributes.get("dx"), 0, failFn, `${file}: <text> dx`);
  const rootDy = parseSingleUnitlessLength(textAttributes.get("dy"), 0, failFn, `${file}: <text> dy`);
  if (![rootX, rootY, rootDx, rootDy].every(Number.isFinite)) {
    return [];
  }
  let currentLine = {
    x: rootX + rootDx,
    y: rootY + rootDy,
    textAnchor: textStyle.textAnchor,
    runs: []
  };
  const lines = [currentLine];
  const addRun = (rawText, style) => {
    const text = rawTextSegment(rawText);
    if (text.length === 0) {
      return;
    }
    currentLine.runs.push({ text, style });
  };
  const startLine = (x, y, style) => {
    if (currentLine.runs.length === 0) {
      currentLine.x = x;
      currentLine.y = y;
      currentLine.textAnchor = style.textAnchor;
      return;
    }
    currentLine = { x, y, textAnchor: style.textAnchor, runs: [] };
    lines.push(currentLine);
  };

  let cursor = 0;
  const tspanPattern = /<tspan\b([^>]*)>([\s\S]*?)<\/tspan>/gi;
  for (const match of body.matchAll(tspanPattern)) {
    addRun(body.slice(cursor, match.index), textStyle);
    const tspanAttributes = parseAttributes(match[1]);
    validateUnsupportedAttributes(file, "tspan", tspanAttributes, failFn);
    const tspanStyle = mergeTextStyle(textStyle, tspanAttributes);
    const hasPosition = tspanAttributes.has("x") || tspanAttributes.has("y") || tspanAttributes.has("dy");
    const nextX = tspanAttributes.has("x") ? parseSingleUnitlessLength(tspanAttributes.get("x"), Number.NaN, failFn, `${file}: <tspan> x`) : currentLine.x;
    const nextY = tspanAttributes.has("y") ? parseSingleUnitlessLength(tspanAttributes.get("y"), Number.NaN, failFn, `${file}: <tspan> y`) : currentLine.y;
    const dx = parseSingleUnitlessLength(tspanAttributes.get("dx"), 0, failFn, `${file}: <tspan> dx`);
    const dy = parseSingleUnitlessLength(tspanAttributes.get("dy"), 0, failFn, `${file}: <tspan> dy`);
    if (![nextX, nextY, dx, dy].every(Number.isFinite)) {
      cursor = match.index + match[0].length;
      continue;
    }
    if (hasPosition) {
      startLine(nextX + dx, nextY + dy, tspanStyle);
    }
    addRun(match[2], tspanStyle);
    cursor = match.index + match[0].length;
  }
  addRun(body.slice(cursor), textStyle);

  const boxes = [];
  for (const line of lines.filter((candidate) => candidate.runs.length > 0)) {
    const box = anchoredLineBounds(line, file, failFn);
    if (box !== null && box.text.length > 0) {
      boxes.push(box);
    }
  }
  return boxes;
}

function tagName(tag) {
  return /^<\s*\/?\s*([A-Za-z][A-Za-z0-9:_-]*)/.exec(tag)?.[1]?.toLowerCase() ?? "";
}

function isClosingTag(tag) {
  return /^<\s*\//.test(tag);
}

function isSelfClosingTag(tag) {
  return /\/\s*>$/.test(tag) || /^<\s*!(?:doctype)?/i.test(tag) || /^<\?/.test(tag);
}

function parseViewBox(file, source, failFn) {
  const svgMatch = /<svg\b([^>]*)>/i.exec(source);
  const viewBox = svgMatch === null ? null : /\bviewBox="([^\"]+)"/i.exec(svgMatch[1])?.[1];
  if (viewBox === undefined || viewBox === null) {
    failFn(`${file}: root <svg> must include a viewBox so text bounds can be checked`);
    return null;
  }
  const [minX, minY, width, height] = viewBox.trim().split(/[\s,]+/).map(Number);
  if (![minX, minY, width, height].every(Number.isFinite) || width <= 0 || height <= 0) {
    failFn(`${file}: root <svg> has an invalid viewBox`);
    return null;
  }
  return { minX, minY, width, height, maxX: minX + width, maxY: minY + height };
}

function lineSegmentsFromPoints(points, closed = false) {
  const segments = [];
  for (let index = 1; index < points.length; index += 1) {
    segments.push([points[index - 1], points[index]]);
  }
  if (closed && points.length > 1) {
    segments.push([points[points.length - 1], points[0]]);
  }
  return segments;
}

function lineSegmentsFromPathPoints(points) {
  const segments = [];
  let previous = null;
  for (const point of points) {
    if (point === null) {
      previous = null;
      continue;
    }
    if (previous !== null) {
      segments.push([previous, point]);
    }
    previous = point;
  }
  return segments;
}

function sampleEllipse(cx, cy, rx, ry, count = 128) {
  const points = [];
  for (let index = 0; index < count; index += 1) {
    const angle = (Math.PI * 2 * index) / count;
    points.push({ x: cx + Math.cos(angle) * rx, y: cy + Math.sin(angle) * ry });
  }
  return points;
}

function cubicPoint(p0, p1, p2, p3, t) {
  const oneMinusT = 1 - t;
  return {
    x: oneMinusT ** 3 * p0.x + 3 * oneMinusT ** 2 * t * p1.x + 3 * oneMinusT * t ** 2 * p2.x + t ** 3 * p3.x,
    y: oneMinusT ** 3 * p0.y + 3 * oneMinusT ** 2 * t * p1.y + 3 * oneMinusT * t ** 2 * p2.y + t ** 3 * p3.y
  };
}

function quadraticPoint(p0, p1, p2, t) {
  const oneMinusT = 1 - t;
  return {
    x: oneMinusT ** 2 * p0.x + 2 * oneMinusT * t * p1.x + t ** 2 * p2.x,
    y: oneMinusT ** 2 * p0.y + 2 * oneMinusT * t * p1.y + t ** 2 * p2.y
  };
}

function vectorAngle(from, to) {
  const dot = from.x * to.x + from.y * to.y;
  const determinant = from.x * to.y - from.y * to.x;
  return Math.atan2(determinant, dot);
}

function sampleArc(p0, rxInput, ryInput, xAxisRotation, largeArcFlag, sweepFlag, p1, samples = 64) {
  let rx = Math.abs(rxInput);
  let ry = Math.abs(ryInput);
  if (rx === 0 || ry === 0 || (p0.x === p1.x && p0.y === p1.y)) {
    return [p1];
  }
  const phi = (xAxisRotation * Math.PI) / 180;
  const cosPhi = Math.cos(phi);
  const sinPhi = Math.sin(phi);
  const dx = (p0.x - p1.x) / 2;
  const dy = (p0.y - p1.y) / 2;
  const x1Prime = cosPhi * dx + sinPhi * dy;
  const y1Prime = -sinPhi * dx + cosPhi * dy;
  const radiusScale = (x1Prime ** 2) / (rx ** 2) + (y1Prime ** 2) / (ry ** 2);
  if (radiusScale > 1) {
    const scale = Math.sqrt(radiusScale);
    rx *= scale;
    ry *= scale;
  }
  const numerator = rx ** 2 * ry ** 2 - rx ** 2 * y1Prime ** 2 - ry ** 2 * x1Prime ** 2;
  const denominator = rx ** 2 * y1Prime ** 2 + ry ** 2 * x1Prime ** 2;
  const sign = largeArcFlag === sweepFlag ? -1 : 1;
  const coefficient = sign * Math.sqrt(Math.max(0, numerator / denominator));
  const cxPrime = coefficient * ((rx * y1Prime) / ry);
  const cyPrime = coefficient * (-(ry * x1Prime) / rx);
  const cx = cosPhi * cxPrime - sinPhi * cyPrime + (p0.x + p1.x) / 2;
  const cy = sinPhi * cxPrime + cosPhi * cyPrime + (p0.y + p1.y) / 2;
  const startVector = { x: (x1Prime - cxPrime) / rx, y: (y1Prime - cyPrime) / ry };
  const endVector = { x: (-x1Prime - cxPrime) / rx, y: (-y1Prime - cyPrime) / ry };
  let startAngle = vectorAngle({ x: 1, y: 0 }, startVector);
  let deltaAngle = vectorAngle(startVector, endVector);
  if (!sweepFlag && deltaAngle > 0) {
    deltaAngle -= Math.PI * 2;
  } else if (sweepFlag && deltaAngle < 0) {
    deltaAngle += Math.PI * 2;
  }
  const points = [];
  for (let index = 1; index <= samples; index += 1) {
    const angle = startAngle + (deltaAngle * index) / samples;
    points.push({
      x: cx + cosPhi * rx * Math.cos(angle) - sinPhi * ry * Math.sin(angle),
      y: cy + sinPhi * rx * Math.cos(angle) + cosPhi * ry * Math.sin(angle)
    });
  }
  return points;
}

function tokenizePathData(file, d, failFn) {
  const tokens = [];
  const source = String(d ?? "");
  let index = 0;
  const numberPattern = /^[-+]?(?:(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?)/;
  while (index < source.length) {
    const character = source[index];
    if (/[\s,]/.test(character)) {
      index += 1;
      continue;
    }
    if (/[A-Za-z]/.test(character)) {
      tokens.push(character);
      index += 1;
      continue;
    }
    const match = numberPattern.exec(source.slice(index));
    if (match !== null) {
      tokens.push(match[0]);
      index += match[0].length;
      continue;
    }
    failFn(`${file}: <path> has unsupported path data near '${source.slice(index, index + 12)}'`);
    return [];
  }
  return tokens;
}

function parsePathData(file, d, failFn) {
  const tokens = tokenizePathData(file, d, failFn);
  const points = [];
  let index = 0;
  let command = null;
  let current = { x: 0, y: 0 };
  let subpathStart = { x: 0, y: 0 };
  let lastCubicControl = null;
  let lastQuadraticControl = null;
  const supportedCommands = /^[AaCcHhLlMmQqSsTtVvZz]$/;
  const isCommand = (token) => /^[A-Za-z]$/.test(token);
  const hasNumber = () => index < tokens.length && !isCommand(tokens[index]);
  const failPath = (message) => {
    failFn(`${file}: <path> ${message}`);
  };
  const readNumber = (label) => {
    if (!hasNumber()) {
      failPath(`is missing a numeric ${label} for command ${command}`);
      return Number.NaN;
    }
    const value = Number(tokens[index]);
    index += 1;
    if (!Number.isFinite(value)) {
      failPath(`has a non-finite ${label} for command ${command}`);
      return Number.NaN;
    }
    return value;
  };
  const readFlag = (label) => {
    if (!hasNumber()) {
      failPath(`is missing arc ${label} flag`);
      return Number.NaN;
    }
    const token = String(tokens[index]);
    if (!/^[01]/.test(token)) {
      failPath(`arc ${label} flag must be 0 or 1`);
      return Number.NaN;
    }
    const flag = Number(token[0]);
    const rest = token.slice(1);
    if (rest.length > 0) {
      tokens[index] = rest;
    } else {
      index += 1;
    }
    return flag;
  };
  const finitePoint = (point) => Number.isFinite(point.x) && Number.isFinite(point.y);
  const addPoint = (point) => {
    if (!finitePoint(point)) {
      failPath(`produced a non-finite coordinate for command ${command}`);
      return false;
    }
    current = point;
    points.push(current);
    return true;
  };
  const resetControls = () => {
    lastCubicControl = null;
    lastQuadraticControl = null;
  };
  while (index < tokens.length) {
    if (isCommand(tokens[index])) {
      command = tokens[index++];
      if (!supportedCommands.test(command)) {
        failPath(`uses unsupported command '${command}'`);
        return points;
      }
    }
    if (command === null) {
      failPath("must start with a path command");
      return points;
    }
    const relative = command === command.toLowerCase();
    switch (command.toUpperCase()) {
      case "M": {
        if (!hasNumber()) return points;
        const x = readNumber("x");
        const y = readNumber("y");
        const point = { x: relative ? current.x + x : x, y: relative ? current.y + y : y };
        if (!finitePoint(point)) return points;
        current = point;
        subpathStart = current;
        if (points.length > 0) {
          points.push(null);
        }
        points.push(current);
        resetControls();
        command = relative ? "l" : "L";
        break;
      }
      case "L": {
        if (!hasNumber()) return points;
        const x = readNumber("x");
        const y = readNumber("y");
        if (!addPoint({ x: relative ? current.x + x : x, y: relative ? current.y + y : y })) return points;
        resetControls();
        break;
      }
      case "H": {
        if (!hasNumber()) return points;
        const x = readNumber("x");
        if (!addPoint({ x: relative ? current.x + x : x, y: current.y })) return points;
        resetControls();
        break;
      }
      case "V": {
        if (!hasNumber()) return points;
        const y = readNumber("y");
        if (!addPoint({ x: current.x, y: relative ? current.y + y : y })) return points;
        resetControls();
        break;
      }
      case "C": {
        if (!hasNumber()) return points;
        const p1 = { x: readNumber("x1"), y: readNumber("y1") };
        const p2 = { x: readNumber("x2"), y: readNumber("y2") };
        const p3 = { x: readNumber("x"), y: readNumber("y") };
        const control1 = relative ? { x: current.x + p1.x, y: current.y + p1.y } : p1;
        const control2 = relative ? { x: current.x + p2.x, y: current.y + p2.y } : p2;
        const end = relative ? { x: current.x + p3.x, y: current.y + p3.y } : p3;
        if (![control1, control2, end].every(finitePoint)) return points;
        for (let sample = 1; sample <= 64; sample += 1) {
          points.push(cubicPoint(current, control1, control2, end, sample / 64));
        }
        current = end;
        lastCubicControl = control2;
        lastQuadraticControl = null;
        break;
      }
      case "S": {
        if (!hasNumber()) return points;
        const reflected = lastCubicControl === null ? current : { x: current.x * 2 - lastCubicControl.x, y: current.y * 2 - lastCubicControl.y };
        const p2 = { x: readNumber("x2"), y: readNumber("y2") };
        const p3 = { x: readNumber("x"), y: readNumber("y") };
        const control2 = relative ? { x: current.x + p2.x, y: current.y + p2.y } : p2;
        const end = relative ? { x: current.x + p3.x, y: current.y + p3.y } : p3;
        if (![reflected, control2, end].every(finitePoint)) return points;
        for (let sample = 1; sample <= 64; sample += 1) {
          points.push(cubicPoint(current, reflected, control2, end, sample / 64));
        }
        current = end;
        lastCubicControl = control2;
        lastQuadraticControl = null;
        break;
      }
      case "Q": {
        if (!hasNumber()) return points;
        const p1 = { x: readNumber("x1"), y: readNumber("y1") };
        const p2 = { x: readNumber("x"), y: readNumber("y") };
        const control = relative ? { x: current.x + p1.x, y: current.y + p1.y } : p1;
        const end = relative ? { x: current.x + p2.x, y: current.y + p2.y } : p2;
        if (![control, end].every(finitePoint)) return points;
        for (let sample = 1; sample <= 64; sample += 1) {
          points.push(quadraticPoint(current, control, end, sample / 64));
        }
        current = end;
        lastQuadraticControl = control;
        lastCubicControl = null;
        break;
      }
      case "T": {
        if (!hasNumber()) return points;
        const reflected = lastQuadraticControl === null ? current : { x: current.x * 2 - lastQuadraticControl.x, y: current.y * 2 - lastQuadraticControl.y };
        const p2 = { x: readNumber("x"), y: readNumber("y") };
        const end = relative ? { x: current.x + p2.x, y: current.y + p2.y } : p2;
        if (![reflected, end].every(finitePoint)) return points;
        for (let sample = 1; sample <= 64; sample += 1) {
          points.push(quadraticPoint(current, reflected, end, sample / 64));
        }
        current = end;
        lastQuadraticControl = reflected;
        lastCubicControl = null;
        break;
      }
      case "A": {
        if (!hasNumber()) return points;
        const rx = readNumber("rx");
        const ry = readNumber("ry");
        const rotation = readNumber("rotation");
        const largeArc = readFlag("large-arc") === 1;
        const sweep = readFlag("sweep") === 1;
        const x = readNumber("x");
        const y = readNumber("y");
        const end = { x: relative ? current.x + x : x, y: relative ? current.y + y : y };
        if (![rx, ry, rotation, x, y].every(Number.isFinite) || !finitePoint(end)) return points;
        points.push(...sampleArc(current, rx, ry, rotation, largeArc, sweep, end));
        current = end;
        resetControls();
        break;
      }
      case "Z": {
        if (!addPoint(subpathStart)) return points;
        command = null;
        resetControls();
        break;
      }
      default:
        failPath(`uses unsupported command '${command}'`);
        return points;
    }
  }
  return points;
}

function shapeDescription(tag, attributes) {
  const id = attributes.get("id");
  return id === undefined ? `<${tag}>` : `<${tag} id="${id}">`;
}

function collectShapeObstacles(file, tag, attributes, shapeStyle, failFn) {
  const description = shapeDescription(tag, attributes);
  const invalid = () => {
    failFn(`${file}: ${description} must use numeric geometry attributes so label intersections can be checked`);
    return [];
  };
  let segments = [];
  let fillShape = null;
  if (tag === "line") {
    const x1 = parseLength(attributes.get("x1"), 0);
    const y1 = parseLength(attributes.get("y1"), 0);
    const x2 = parseLength(attributes.get("x2"), 0);
    const y2 = parseLength(attributes.get("y2"), 0);
    if (![x1, y1, x2, y2].every(Number.isFinite)) return invalid();
    segments = [[{ x: x1, y: y1 }, { x: x2, y: y2 }]];
  } else if (tag === "polyline" || tag === "polygon") {
    const points = parsePointList(attributes.get("points"));
    if (points.length < 2 || !points.every((point) => Number.isFinite(point.x) && Number.isFinite(point.y))) return invalid();
    segments = lineSegmentsFromPoints(points, tag === "polygon");
    if (tag === "polygon") {
      fillShape = { kind: "polygon-fill", description, points };
    }
  } else if (tag === "rect") {
    const x = parseLength(attributes.get("x"), 0);
    const y = parseLength(attributes.get("y"), 0);
    const width = parseLength(attributes.get("width"));
    const height = parseLength(attributes.get("height"));
    if (![x, y, width, height].every(Number.isFinite) || width < 0 || height < 0) return invalid();
    segments = lineSegmentsFromPoints([{ x, y }, { x: x + width, y }, { x: x + width, y: y + height }, { x, y: y + height }], true);
  } else if (tag === "circle") {
    const cx = parseLength(attributes.get("cx"), 0);
    const cy = parseLength(attributes.get("cy"), 0);
    const r = parseLength(attributes.get("r"));
    if (![cx, cy, r].every(Number.isFinite) || r < 0) return invalid();
    segments = lineSegmentsFromPoints(sampleEllipse(cx, cy, r, r), true);
    fillShape = { kind: "circle-fill", description, cx, cy, r };
  } else if (tag === "ellipse") {
    const cx = parseLength(attributes.get("cx"), 0);
    const cy = parseLength(attributes.get("cy"), 0);
    const rx = parseLength(attributes.get("rx"));
    const ry = parseLength(attributes.get("ry"));
    if (![cx, cy, rx, ry].every(Number.isFinite) || rx < 0 || ry < 0) return invalid();
    segments = lineSegmentsFromPoints(sampleEllipse(cx, cy, rx, ry), true);
  } else if (tag === "path") {
    const points = parsePathData(file, attributes.get("d"), failFn);
    segments = lineSegmentsFromPathPoints(points);
    if (segments.length === 0) return invalid();
  }

  const obstacles = [];
  const strokeWidth = parseLength(shapeStyle.strokeWidth, 1);
  const hasStroke = String(shapeStyle.stroke ?? "none").trim().toLowerCase() !== "none";
  if (hasStroke && Number.isFinite(strokeWidth) && strokeWidth > 0 && segments.length > 0) {
    obstacles.push({ kind: "stroke", description, strokeWidth, segments });
  }
  const hasFill = String(shapeStyle.fill ?? "black").trim().toLowerCase() !== "none";
  if (hasFill && fillShape !== null) {
    obstacles.push(fillShape);
  }
  return obstacles;
}

function pointInRect(point, rect) {
  return point.x >= rect.left && point.x <= rect.right && point.y >= rect.top && point.y <= rect.bottom;
}

function orientation(a, b, c) {
  const value = (b.y - a.y) * (c.x - b.x) - (b.x - a.x) * (c.y - b.y);
  if (Math.abs(value) < 1e-9) return 0;
  return value > 0 ? 1 : 2;
}

function onSegment(a, b, c) {
  return b.x <= Math.max(a.x, c.x) && b.x >= Math.min(a.x, c.x) && b.y <= Math.max(a.y, c.y) && b.y >= Math.min(a.y, c.y);
}

function segmentsIntersect(p1, q1, p2, q2) {
  const o1 = orientation(p1, q1, p2);
  const o2 = orientation(p1, q1, q2);
  const o3 = orientation(p2, q2, p1);
  const o4 = orientation(p2, q2, q1);
  if (o1 !== o2 && o3 !== o4) return true;
  if (o1 === 0 && onSegment(p1, p2, q1)) return true;
  if (o2 === 0 && onSegment(p1, q2, q1)) return true;
  if (o3 === 0 && onSegment(p2, p1, q2)) return true;
  return o4 === 0 && onSegment(p2, q1, q2);
}

function pointRectDistance(point, rect) {
  const dx = Math.max(rect.left - point.x, 0, point.x - rect.right);
  const dy = Math.max(rect.top - point.y, 0, point.y - rect.bottom);
  return Math.hypot(dx, dy);
}

function pointSegmentDistance(point, a, b) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  if (dx === 0 && dy === 0) {
    return Math.hypot(point.x - a.x, point.y - a.y);
  }
  const t = Math.max(0, Math.min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / (dx * dx + dy * dy)));
  return Math.hypot(point.x - (a.x + t * dx), point.y - (a.y + t * dy));
}

function segmentRectDistance(a, b, rect) {
  if (pointInRect(a, rect) || pointInRect(b, rect)) {
    return 0;
  }
  const corners = [
    { x: rect.left, y: rect.top },
    { x: rect.right, y: rect.top },
    { x: rect.right, y: rect.bottom },
    { x: rect.left, y: rect.bottom }
  ];
  const edges = lineSegmentsFromPoints(corners, true);
  if (edges.some(([edgeStart, edgeEnd]) => segmentsIntersect(a, b, edgeStart, edgeEnd))) {
    return 0;
  }
  return Math.min(pointRectDistance(a, rect), pointRectDistance(b, rect), ...corners.map((corner) => pointSegmentDistance(corner, a, b)));
}

function rectCorners(rect) {
  return [
    { x: rect.left, y: rect.top },
    { x: rect.right, y: rect.top },
    { x: rect.right, y: rect.bottom },
    { x: rect.left, y: rect.bottom }
  ];
}

function pointInPolygon(point, polygon) {
  let inside = false;
  for (let index = 0, previous = polygon.length - 1; index < polygon.length; previous = index, index += 1) {
    const current = polygon[index];
    const before = polygon[previous];
    const intersects = current.y > point.y !== before.y > point.y && point.x < ((before.x - current.x) * (point.y - current.y)) / (before.y - current.y) + current.x;
    if (intersects) inside = !inside;
  }
  return inside;
}

function polygonIntersectsRect(points, rect) {
  if (points.some((point) => pointInRect(point, rect))) {
    return true;
  }
  if (rectCorners(rect).some((corner) => pointInPolygon(corner, points))) {
    return true;
  }
  const rectEdges = lineSegmentsFromPoints(rectCorners(rect), true);
  const polygonEdges = lineSegmentsFromPoints(points, true);
  return polygonEdges.some(([polygonStart, polygonEnd]) => rectEdges.some(([rectStart, rectEnd]) => segmentsIntersect(polygonStart, polygonEnd, rectStart, rectEnd)));
}

function circleIntersectsRect(circle, rect) {
  return pointRectDistance({ x: circle.cx, y: circle.cy }, rect) <= circle.r;
}

function validateUnsupportedAttributes(file, tag, attributes, failFn) {
  if (attributes.has("style") || attributes.has("class")) {
    failFn(`${file}: <${tag}> uses style/class styling, which the figure checker does not support; use presentation attributes instead`);
  }
  if (attributes.has("transform")) {
    failFn(`${file}: <${tag}> uses transform, which the figure checker does not support`);
  }
  if ((tag === "text" || tag === "tspan") && attributes.has("text-anchor")) {
    const anchor = attributes.get("text-anchor");
    if (!["start", "middle", "end"].includes(anchor)) {
      failFn(`${file}: <${tag}> text-anchor '${anchor}' is not supported`);
    }
  }
  const unsupportedTextAttributes = ["dominant-baseline", "alignment-baseline", "baseline-shift", "letter-spacing", "textLength", "lengthAdjust", "rotate"];
  if (tag === "text" || tag === "tspan") {
    for (const attribute of unsupportedTextAttributes) {
      if (attributes.has(attribute)) {
        failFn(`${file}: <${tag}> uses ${attribute}, which the figure checker does not support`);
      }
    }
    for (const attribute of ["x", "y", "dx", "dy"]) {
      validateTextPositionAttribute(file, tag, attributes, attribute, failFn);
    }
  }
}

function collectFigureGeometry(file, source, failFn) {
  const viewBox = parseViewBox(file, source, failFn);
  if (viewBox === null) {
    return { viewBox, texts: [], obstacles: [] };
  }
  const texts = [];
  const obstacles = [];
  const defaultTextStyle = { fontSize: "16", fontWeight: "400", textAnchor: "start", fontFamily: "" };
  const defaultShapeStyle = { stroke: "none", strokeWidth: "1", fill: "black" };
  const stack = [{ name: "#document", textStyle: defaultTextStyle, strokeStyle: defaultShapeStyle, skip: false }];
  const supportedShapeTags = new Set(["line", "polyline", "rect", "circle", "ellipse", "path", "polygon"]);
  const skipContentTags = new Set(["defs", "marker", "clippath", "mask", "pattern"]);
  const unsupportedElements = new Set(["use", "symbol", "textpath", "foreignobject", "style"]);
  const tagPattern = /<[^>]+>/g;
  let match;
  while ((match = tagPattern.exec(source)) !== null) {
    const token = match[0];
    if (/^<!--/.test(token) || /^<!\[CDATA/i.test(token)) {
      continue;
    }
    const name = tagName(token);
    if (name.length === 0) {
      continue;
    }
    if (isClosingTag(token)) {
      for (let index = stack.length - 1; index > 0; index -= 1) {
        const frame = stack.pop();
        if (frame.name === name) {
          break;
        }
      }
      continue;
    }

    const attributes = parseAttributes(token);
    const parent = stack[stack.length - 1];
    if (parent.skip) {
      if (!isSelfClosingTag(token)) {
        stack.push({ name, textStyle: parent.textStyle, strokeStyle: parent.strokeStyle, skip: true });
      }
      continue;
    }

    validateUnsupportedAttributes(file, name, attributes, failFn);
    if (unsupportedElements.has(name)) {
      failFn(`${file}: <${name}> is not supported by the figure checker`);
    }
    if (name === "svg" && stack.some((frame) => frame.name === "svg")) {
      failFn(`${file}: nested <svg> elements are not supported by the figure checker`);
    }

    const textStyle = mergeTextStyle(parent.textStyle, attributes);
    const strokeStyle = mergeStrokeStyle(parent.strokeStyle, attributes);

    if (skipContentTags.has(name)) {
      if (!isSelfClosingTag(token)) {
        stack.push({ name, textStyle, strokeStyle, skip: true });
      }
      continue;
    }

    if (name === "text") {
      if (isSelfClosingTag(token)) {
        failFn(`${file}: self-closing <text/> elements are not supported`);
        continue;
      }
      const closePattern = /<\/text\s*>/ig;
      closePattern.lastIndex = tagPattern.lastIndex;
      const close = closePattern.exec(source);
      if (close === null) {
        failFn(`${file}: <text> is missing a closing </text>`);
        continue;
      }
      const body = source.slice(tagPattern.lastIndex, close.index);
      if (/<(?:textPath|textpath)\b/i.test(body)) {
        failFn(`${file}: <textPath> is not supported by the figure checker`);
      }
      texts.push(...collectTextBoxes(file, attributes, parent.textStyle, body, failFn));
      tagPattern.lastIndex = close.index + close[0].length;
      continue;
    }

    if (supportedShapeTags.has(name)) {
      obstacles.push(...collectShapeObstacles(file, name, attributes, strokeStyle, failFn));
    }

    if (!isSelfClosingTag(token)) {
      stack.push({ name, textStyle, strokeStyle, skip: false });
    }
  }
  return { viewBox, texts, obstacles };
}

function checkTextEdges(file, viewBox, texts, failFn) {
  for (const text of texts) {
    const { bounds } = text;
    const edgeMargin = text.fontSize * 0.25;
    if (bounds.left < viewBox.minX + edgeMargin || bounds.right > viewBox.maxX - edgeMargin || bounds.top < viewBox.minY + edgeMargin || bounds.bottom > viewBox.maxY - edgeMargin) {
      failFn(`${file}: <text> '${text.text}' estimated bounds are too close to or beyond the viewBox edge (bounds ${bounds.left.toFixed(1)},${bounds.top.toFixed(1)} to ${bounds.right.toFixed(1)},${bounds.bottom.toFixed(1)}; required inside ${viewBox.minX + edgeMargin},${viewBox.minY + edgeMargin} to ${viewBox.maxX - edgeMargin},${viewBox.maxY - edgeMargin})`);
    }
  }
}

function horizontalCenter(bounds) {
  return (bounds.left + bounds.right) / 2;
}

function boundsWidth(bounds) {
  return bounds.right - bounds.left;
}

function isAlignedVerticalStack(first, second, horizontalOverlap, verticalOverlap) {
  if (horizontalOverlap <= 0 || verticalOverlap > 0) {
    return false;
  }
  if (first.textAnchor !== second.textAnchor || Math.abs(first.anchorX - second.anchorX) > 1) {
    return false;
  }
  const narrowerWidth = Math.min(boundsWidth(first.bounds), boundsWidth(second.bounds));
  if (narrowerWidth <= 0) {
    return false;
  }
  const centerOffset = Math.abs(horizontalCenter(first.bounds) - horizontalCenter(second.bounds));
  const substantialOverlap = horizontalOverlap >= narrowerWidth * 0.5;
  return substantialOverlap && centerOffset <= narrowerWidth / 2;
}

function checkTextProximity(file, texts, failFn) {
  for (let leftIndex = 0; leftIndex < texts.length; leftIndex += 1) {
    for (let rightIndex = leftIndex + 1; rightIndex < texts.length; rightIndex += 1) {
      const first = texts[leftIndex];
      const second = texts[rightIndex];
      const horizontalOverlap = Math.min(first.bounds.right, second.bounds.right) - Math.max(first.bounds.left, second.bounds.left);
      const verticalOverlap = Math.min(first.bounds.bottom, second.bounds.bottom) - Math.max(first.bounds.top, second.bounds.top);
      if (horizontalOverlap > 0 && verticalOverlap > 0) {
        failFn(`${file}: <text> '${first.text}' overlaps <text> '${second.text}' by ${horizontalOverlap.toFixed(1)} × ${verticalOverlap.toFixed(1)} units`);
        continue;
      }
      const horizontalGap = Math.max(second.bounds.left - first.bounds.right, first.bounds.left - second.bounds.right, 0);
      const verticalGap = Math.max(second.bounds.top - first.bounds.bottom, first.bounds.top - second.bounds.bottom, 0);
      const gap = Math.hypot(horizontalGap, verticalGap);
      const smallerFontSize = Math.min(first.fontSize, second.fontSize);
      const usesStackClearance = isAlignedVerticalStack(first, second, horizontalOverlap, verticalOverlap);
      const requiredGap = smallerFontSize * (usesStackClearance ? 0.08 : 0.25);
      if (gap < requiredGap) {
        const spacingKind = usesStackClearance ? "stacked-label" : "neighbour";
        failFn(`${file}: <text> '${first.text}' and <text> '${second.text}' are only ${gap.toFixed(1)} units apart; required at least ${requiredGap.toFixed(1)} units for ${spacingKind} spacing (short by ${(requiredGap - gap).toFixed(1)})`);
      }
    }
  }
}

function checkTextShapeIntersections(file, texts, obstacles, failFn) {
  for (const text of texts) {
    for (const obstacle of obstacles) {
      if (obstacle.kind === "stroke") {
        const requiredClearance = obstacle.strokeWidth / 2;
        for (const [start, end] of obstacle.segments) {
          const clearance = segmentRectDistance(start, end, text.strokeBounds);
          if (clearance <= requiredClearance) {
            failFn(`${file}: <text> '${text.text}' estimated ink bounds intersect ${obstacle.description} stroke from (${start.x.toFixed(1)},${start.y.toFixed(1)}) to (${end.x.toFixed(1)},${end.y.toFixed(1)}) (clearance ${clearance.toFixed(1)}; stroke padding ${requiredClearance.toFixed(1)})`);
            break;
          }
        }
      } else if (obstacle.kind === "polygon-fill") {
        if (polygonIntersectsRect(obstacle.points, text.fillBounds)) {
          failFn(`${file}: <text> '${text.text}' estimated ink bounds intersect ${obstacle.description} fill`);
        }
      } else if (obstacle.kind === "circle-fill") {
        if (circleIntersectsRect(obstacle, text.fillBounds)) {
          failFn(`${file}: <text> '${text.text}' estimated ink bounds intersect ${obstacle.description} fill`);
        }
      }
    }
  }
}

function checkTextBounds(file, source, failFn = fail) {
  const geometry = collectFigureGeometry(file, source, failFn);
  if (geometry.viewBox === null) {
    return;
  }
  checkTextEdges(file, geometry.viewBox, geometry.texts, failFn);
  checkTextProximity(file, geometry.texts, failFn);
  checkTextShapeIntersections(file, geometry.texts, geometry.obstacles, failFn);
}

function validateFigureSource(file, source) {
  const localErrors = [];
  checkTextBounds(file, source, (message) => localErrors.push(message));
  return localErrors;
}

function runSelfTest() {
  const fixture = (body, viewBox = "0 0 200 120") => `<svg id="fixture" xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}"><title>Fixture</title><desc>Fixture</desc>${body}</svg>`;
  const cases = [
    {
      name: "spaced text inside viewBox passes",
      source: fixture(`<g fill="currentColor" text-anchor="middle"><text x="45" y="60" font-size="20">A</text><text x="150" y="60" font-size="20" font-weight="700">B</text></g><line x1="20" y1="105" x2="180" y2="105" stroke="currentColor" stroke-width="4"/>`),
      expect: []
    },
    {
      name: "text overlap fails",
      source: fixture(`<g fill="currentColor"><text x="40" y="60" font-size="20">Label</text><text x="55" y="62" font-size="20">Other</text></g>`),
      expect: [/Label.*overlaps.*Other.*by/]
    },
    {
      name: "text gap under threshold fails",
      source: fixture(`<g fill="currentColor"><text x="20" y="60" font-size="20">A</text><text x="39" y="60" font-size="20">B</text></g>`),
      expect: [/A.*B.*required at least/]
    },
    {
      name: "tight aligned vertical stack uses reduced gap threshold",
      source: fixture(`<g fill="currentColor" text-anchor="middle"><text x="100" y="40" font-size="20">1st</text><text x="100" y="62" font-size="20">digit</text></g>`),
      expect: []
    },
    {
      name: "aligned vertical stack below reduced threshold fails",
      source: fixture(`<g fill="currentColor" text-anchor="middle"><text x="100" y="40" font-size="20">Top</text><text x="100" y="61" font-size="20">Bot</text></g>`),
      expect: [/Top.*Bot.*required at least.*stacked-label/]
    },
    {
      name: "offset vertical neighbours keep normal gap threshold",
      source: fixture(`<g fill="currentColor" text-anchor="middle"><text x="90" y="40" font-size="20">Top</text><text x="112" y="62" font-size="20">Bot</text></g>`),
      expect: [/Top.*Bot.*required at least.*neighbour/]
    },
    {
      name: "left viewBox edge fails",
      source: fixture(`<text x="1" y="40" font-size="20" fill="currentColor">Edge</text>`),
      expect: [/Edge.*viewBox edge/]
    },
    {
      name: "right viewBox edge fails",
      source: fixture(`<text x="170" y="60" font-size="20" fill="currentColor">Right</text>`),
      expect: [/Right.*viewBox edge/]
    },
    {
      name: "top viewBox edge fails",
      source: fixture(`<text x="60" y="15" font-size="20" fill="currentColor">Top</text>`),
      expect: [/Top.*viewBox edge/]
    },
    {
      name: "bottom viewBox edge fails",
      source: fixture(`<text x="60" y="118" font-size="20" fill="currentColor">Bottom</text>`),
      expect: [/Bottom.*viewBox edge/]
    },
    {
      name: "end-anchored edge fails",
      source: fixture(`<text x="199" y="60" font-size="20" text-anchor="end" fill="currentColor">End</text>`),
      expect: [/End.*viewBox edge/]
    },
    {
      name: "line stroke intersection fails",
      source: fixture(`<line x1="10" y1="60" x2="190" y2="60" stroke="currentColor" stroke-width="6"/><text x="70" y="60" font-size="20" fill="currentColor">Line</text>`),
      expect: [/Line.*<line> stroke/]
    },
    {
      name: "polyline stroke intersection fails",
      source: fixture(`<polyline points="10,20 90,60 180,20" stroke="currentColor" stroke-width="6" fill="none"/><text x="70" y="60" font-size="20" fill="currentColor">Poly</text>`),
      expect: [/Poly.*<polyline> stroke/]
    },
    {
      name: "rect stroke intersection fails",
      source: fixture(`<rect x="40" y="35" width="100" height="40" stroke="currentColor" stroke-width="6" fill="none"/><text x="50" y="49" font-size="18" fill="currentColor">Rect</text>`),
      expect: [/Rect.*<rect> stroke/]
    },
    {
      name: "circle stroke intersection fails",
      source: fixture(`<circle cx="100" cy="60" r="40" stroke="currentColor" stroke-width="6" fill="none"/><text x="95" y="24" font-size="18" fill="currentColor">Circle</text>`),
      expect: [/Circle.*<circle> stroke/]
    },
    {
      name: "ellipse stroke intersection fails",
      source: fixture(`<ellipse cx="100" cy="60" rx="70" ry="25" stroke="currentColor" stroke-width="6" fill="none"/><text x="95" y="39" font-size="18" fill="currentColor">Ellipse</text>`),
      expect: [/Ellipse.*<ellipse> stroke/]
    },
    {
      name: "path curve and arc stroke intersections fail",
      source: fixture(`<path d="M20 100 C60 20 100 20 140 100 Q155 70 170 100 A20 20 0 0 1 190 80" stroke="currentColor" stroke-width="6" fill="none"/><text x="78" y="42" font-size="18" fill="currentColor">Curve</text><text x="162" y="91" font-size="14" fill="currentColor">Arc</text>`),
      expect: [/Curve.*<path> stroke/, /Arc.*<path> stroke/]
    },
    {
      name: "relative path commands fail on intersection",
      source: fixture(`<path d="m20 60 l50 0 h30 v0 c20 -30 40 -30 60 0 q10 15 20 0 a5 5 0 0 1 10 0 z" stroke="currentColor" stroke-width="6" fill="none"/><text x="70" y="60" font-size="18" fill="currentColor">relative</text>`),
      expect: [/relative.*<path> stroke/]
    },
    {
      name: "absolute H V Z path commands fail on intersection",
      source: fixture(`<path d="M20 60 H180 V90 Z" stroke="currentColor" stroke-width="6" fill="none"/><text x="70" y="60" font-size="18" fill="currentColor">absolute</text>`),
      expect: [/absolute.*<path> stroke/]
    },
    {
      name: "arc-only path fixture fails on arc intersection",
      source: fixture(`<path d="M50 80 A40 40 0 0 1 130 80" stroke="currentColor" stroke-width="6" fill="none"/><text x="82" y="48" font-size="18" fill="currentColor">arc</text>`, "0 0 200 160"),
      expect: [/arc.*<path> stroke/]
    },
    {
      name: "smooth S and T path commands are sampled",
      source: fixture(`<path d="M20 80 C50 20 70 20 100 80 S150 140 180 80 M30 30 Q70 90 110 30 T190 30" stroke="currentColor" stroke-width="6" fill="none"/><text x="92" y="80" font-size="18" fill="currentColor">smooth</text>`),
      expect: [/smooth.*<path> stroke/]
    },
    {
      name: "shape pass fixtures stay clear",
      source: fixture(`<line x1="20" y1="135" x2="180" y2="135" stroke="currentColor" stroke-width="4"/><polyline points="20,145 60,130 100,145" stroke="currentColor" stroke-width="4" fill="none"/><rect x="18" y="28" width="64" height="48" stroke="currentColor" stroke-width="4" fill="none"/><circle cx="128" cy="52" r="28" stroke="currentColor" stroke-width="4" fill="none"/><ellipse cx="122" cy="106" rx="36" ry="12" stroke="currentColor" stroke-width="4" fill="none"/><path d="M20 112 C45 96 70 96 95 112" stroke="currentColor" stroke-width="4" fill="none"/><polygon points="164,88 190,104 164,120" stroke="currentColor" stroke-width="4" fill="none"/><text x="50" y="58" font-size="16" text-anchor="middle" fill="currentColor">box</text>`),
      expect: []
    },
    {
      name: "line pass fixture stays clear",
      source: fixture(`<line x1="20" y1="100" x2="180" y2="100" stroke="currentColor" stroke-width="4"/><text x="60" y="50" font-size="18" fill="currentColor">line ok</text>`),
      expect: []
    },
    {
      name: "polyline pass fixture stays clear",
      source: fixture(`<polyline points="20,110 90,95 180,110" stroke="currentColor" stroke-width="4" fill="none"/><text x="60" y="50" font-size="18" fill="currentColor">poly ok</text>`),
      expect: []
    },
    {
      name: "circle pass fixture stays clear",
      source: fixture(`<circle cx="100" cy="68" r="42" stroke="currentColor" stroke-width="4" fill="none"/><text x="72" y="74" font-size="18" fill="currentColor">inside</text>`),
      expect: []
    },
    {
      name: "ellipse pass fixture stays clear",
      source: fixture(`<ellipse cx="100" cy="68" rx="72" ry="32" stroke="currentColor" stroke-width="4" fill="none"/><text x="70" y="74" font-size="18" fill="currentColor">inside</text>`),
      expect: []
    },
    {
      name: "path pass fixture stays clear",
      source: fixture(`<path d="M20 105 C70 88 130 88 180 105" stroke="currentColor" stroke-width="4" fill="none"/><text x="64" y="50" font-size="18" fill="currentColor">path ok</text>`),
      expect: []
    },
    {
      name: "polygon pass fixture stays clear",
      source: fixture(`<polygon points="120,82 178,108 126,112" stroke="currentColor" stroke-width="4" fill="none"/><text x="42" y="50" font-size="18" fill="currentColor">poly ok</text>`),
      expect: []
    },
    {
      name: "filled polygon and circle intersections fail",
      source: fixture(`<polygon points="80,46 120,46 100,78" fill="currentColor"/><circle cx="150" cy="55" r="10" fill="currentColor"/><text x="84" y="60" font-size="18" fill="currentColor">poly</text><text x="145" y="60" font-size="18" fill="currentColor">dot</text>`),
      expect: [/poly.*<polygon> fill/, /dot.*<circle> fill/]
    },
    {
      name: "tspan anchor and bold width pass",
      source: fixture(`<g fill="currentColor" text-anchor="middle"><text x="100" y="45" font-size="18" font-weight="700"><tspan x="100" y="45">Top</tspan><tspan x="100" y="82">Bottom</tspan></text></g>`),
      expect: []
    },
    {
      name: "tspan lines are checked against each other",
      source: fixture(`<g fill="currentColor" text-anchor="middle"><text x="100" y="45" font-size="18"><tspan x="100" y="45">Top</tspan><tspan x="100" y="57">Bottom</tspan></text></g>`),
      expect: [/Top.*overlaps.*Bottom/]
    },
    {
      name: "inline tspan line anchors as one string",
      source: fixture(`<g fill="currentColor" text-anchor="middle"><text x="100" y="60" font-size="18">Hello <tspan font-weight="700">World</tspan></text></g>`),
      expect: []
    },
    {
      name: "unsupported features fail loudly",
      source: fixture(`<g transform="translate(1 1)"><path d="M20 60 R40 60" stroke="currentColor"/><text x="20 30" y="50" font-size="20" class="label" dominant-baseline="middle">Bad</text><text x="70" y="50" font-size="1.2em">Unit</text><use href="#x"/></g>`),
      expect: [/transform/, /unsupported command 'R'/, /per-glyph lists/, /font-size.*unitless/, /style\/class/, /dominant-baseline/, /<use>/]
    }
  ];
  const failures = [];
  for (const testCase of cases) {
    const actualErrors = validateFigureSource(`self-test:${testCase.name}`, testCase.source);
    for (const expected of testCase.expect) {
      if (!actualErrors.some((error) => expected.test(error))) {
        failures.push(`${testCase.name}: expected error ${expected} but saw ${JSON.stringify(actualErrors)}`);
      }
    }
    if (testCase.expect.length === 0 && actualErrors.length > 0) {
      failures.push(`${testCase.name}: expected pass but saw ${JSON.stringify(actualErrors)}`);
    }
  }
  if (failures.length > 0) {
    for (const failure of failures) {
      console.error(`figure self-test: ${failure}`);
    }
    process.exit(1);
  }
  console.log(`Figure self-test passed: ${cases.length} inline fixture(s).`);
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

if (selfTest) {
  runSelfTest();
} else {
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
}
