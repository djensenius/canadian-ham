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

function mergeTextStyle(parent, attributes) {
  const next = { ...parent };
  const fontSize = presentationValue(attributes, "font-size");
  const fontWeight = presentationValue(attributes, "font-weight");
  const textAnchor = presentationValue(attributes, "text-anchor");
  if (fontSize !== undefined) {
    next.fontSize = fontSize;
  }
  if (fontWeight !== undefined) {
    next.fontWeight = fontWeight;
  }
  if (textAnchor !== undefined) {
    next.textAnchor = textAnchor;
  }
  return next;
}

function mergeStrokeStyle(parent, attributes) {
  const next = { ...parent };
  const stroke = presentationValue(attributes, "stroke");
  const strokeWidth = presentationValue(attributes, "stroke-width");
  if (stroke !== undefined) {
    next.stroke = stroke;
  }
  if (strokeWidth !== undefined) {
    next.strokeWidth = strokeWidth;
  }
  return next;
}

function approximateTextWidth(text, fontSize, fontWeight = "400") {
  const normalized = decodeEntities(text.replace(/<[^>]+>/g, "").trim());
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
    } else if (/[A-Z]/.test(character)) {
      units += 0.7;
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
  return units * fontSize * uppercaseFactor * weightFactor;
}

function textRunBounds(text, x, y, style) {
  const fontSize = parseLength(style.fontSize, 16);
  if (![fontSize, x, y].every(Number.isFinite) || fontSize <= 0) {
    return null;
  }
  const width = approximateTextWidth(text, fontSize, style.fontWeight);
  const anchor = ["start", "middle", "end"].includes(style.textAnchor) ? style.textAnchor : "start";
  const left = anchor === "middle" ? x - width / 2 : anchor === "end" ? x - width : x;
  const right = anchor === "middle" ? x + width / 2 : anchor === "end" ? x : x + width;
  const hasDescender = /[gjpqy]/.test(text);
  const bounds = {
    left,
    right,
    top: y - fontSize * 0.78,
    bottom: y + fontSize * (hasDescender ? 0.25 : 0.2),
    fontSize,
    width
  };
  const horizontalBearing = Math.min(width * 0.18, fontSize * 0.12);
  bounds.strokeBounds = {
    left: Math.min(left + horizontalBearing, (left + right) / 2),
    right: Math.max(right - horizontalBearing, (left + right) / 2),
    top: y - fontSize * 0.7,
    bottom: y + fontSize * (hasDescender ? 0.18 : 0.12)
  };
  return bounds;
}

function unionBounds(bounds) {
  return {
    left: Math.min(...bounds.map((bound) => bound.left)),
    right: Math.max(...bounds.map((bound) => bound.right)),
    top: Math.min(...bounds.map((bound) => bound.top)),
    bottom: Math.max(...bounds.map((bound) => bound.bottom))
  };
}

function collectTextBox(file, textAttributes, inheritedStyle, body, failFn) {
  const textStyle = mergeTextStyle(inheritedStyle, textAttributes);
  const rootX = parseFirstLength(textAttributes.get("x"));
  const rootY = parseFirstLength(textAttributes.get("y"));
  let currentX = rootX;
  let currentY = rootY;
  const runs = [];
  const addRun = (rawText, rawX, rawY, style, context) => {
    const text = stripMarkup(rawText);
    if (text.length === 0) {
      return;
    }
    const x = parseFirstLength(rawX);
    const y = parseFirstLength(rawY);
    const bounds = textRunBounds(text, x, y, style);
    if (bounds === null) {
      failFn(`${file}: <text> '${text}' must have numeric x, y, and font-size attributes${context === undefined ? "" : ` (${context})`}`);
      return;
    }
    runs.push({ text, x, y, style, bounds });
  };

  let cursor = 0;
  const tspanPattern = /<tspan\b([^>]*)>([\s\S]*?)<\/tspan>/gi;
  for (const match of body.matchAll(tspanPattern)) {
    addRun(body.slice(cursor, match.index), currentX, currentY, textStyle);
    const tspanAttributes = parseAttributes(match[1]);
    const tspanStyle = mergeTextStyle(textStyle, tspanAttributes);
    const nextX = tspanAttributes.has("x") ? parseFirstLength(tspanAttributes.get("x")) : currentX;
    const nextY = tspanAttributes.has("y") ? parseFirstLength(tspanAttributes.get("y")) : currentY;
    const dx = parseFirstLength(tspanAttributes.get("dx"), 0);
    const dy = parseFirstLength(tspanAttributes.get("dy"), 0);
    currentX = nextX + dx;
    currentY = nextY + dy;
    addRun(match[2], currentX, currentY, tspanStyle, "tspan");
    if (runs.length > 0) {
      const last = runs[runs.length - 1];
      currentX = last.x + (last.style.textAnchor === "start" ? last.bounds.width : 0);
      currentY = last.y;
    }
    cursor = match.index + match[0].length;
  }
  addRun(body.slice(cursor), currentX, currentY, textStyle);

  if (runs.length === 0) {
    return null;
  }
  const bounds = unionBounds(runs.map((run) => run.bounds));
  const strokeBounds = unionBounds(runs.map((run) => run.bounds.strokeBounds));
  const text = runs.map((run) => run.text).join(" ").replace(/\s+/g, " ").trim();
  return {
    text,
    bounds,
    strokeBounds,
    fontSize: Math.max(...runs.map((run) => run.bounds.fontSize)),
    runs
  };
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

function parsePathData(d) {
  const tokens = [...String(d ?? "").matchAll(/[AaCcHhLlMmQqVvZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?/g)].map((match) => match[0]);
  const points = [];
  let index = 0;
  let command = null;
  let current = { x: 0, y: 0 };
  let subpathStart = { x: 0, y: 0 };
  const isCommand = (token) => /^[AaCcHhLlMmQqVvZz]$/.test(token);
  const hasNumber = () => index < tokens.length && !isCommand(tokens[index]);
  const readNumber = () => Number(tokens[index++]);
  const lineTo = (point) => {
    current = point;
    points.push(current);
  };
  while (index < tokens.length) {
    if (isCommand(tokens[index])) {
      command = tokens[index++];
    }
    if (command === null) {
      break;
    }
    const relative = command === command.toLowerCase();
    switch (command.toUpperCase()) {
      case "M": {
        if (!hasNumber()) break;
        const x = readNumber();
        const y = readNumber();
        current = { x: relative ? current.x + x : x, y: relative ? current.y + y : y };
        subpathStart = current;
        if (points.length > 0) {
          points.push(null);
        }
        points.push(current);
        command = relative ? "l" : "L";
        break;
      }
      case "L": {
        if (!hasNumber()) break;
        const x = readNumber();
        const y = readNumber();
        lineTo({ x: relative ? current.x + x : x, y: relative ? current.y + y : y });
        break;
      }
      case "H": {
        if (!hasNumber()) break;
        const x = readNumber();
        lineTo({ x: relative ? current.x + x : x, y: current.y });
        break;
      }
      case "V": {
        if (!hasNumber()) break;
        const y = readNumber();
        lineTo({ x: current.x, y: relative ? current.y + y : y });
        break;
      }
      case "C": {
        if (!hasNumber()) break;
        const p1 = { x: readNumber(), y: readNumber() };
        const p2 = { x: readNumber(), y: readNumber() };
        const p3 = { x: readNumber(), y: readNumber() };
        const control1 = relative ? { x: current.x + p1.x, y: current.y + p1.y } : p1;
        const control2 = relative ? { x: current.x + p2.x, y: current.y + p2.y } : p2;
        const end = relative ? { x: current.x + p3.x, y: current.y + p3.y } : p3;
        for (let sample = 1; sample <= 64; sample += 1) {
          points.push(cubicPoint(current, control1, control2, end, sample / 64));
        }
        current = end;
        break;
      }
      case "Q": {
        if (!hasNumber()) break;
        const p1 = { x: readNumber(), y: readNumber() };
        const p2 = { x: readNumber(), y: readNumber() };
        const control = relative ? { x: current.x + p1.x, y: current.y + p1.y } : p1;
        const end = relative ? { x: current.x + p2.x, y: current.y + p2.y } : p2;
        for (let sample = 1; sample <= 64; sample += 1) {
          points.push(quadraticPoint(current, control, end, sample / 64));
        }
        current = end;
        break;
      }
      case "A": {
        if (!hasNumber()) break;
        const rx = readNumber();
        const ry = readNumber();
        const rotation = readNumber();
        const largeArc = readNumber() !== 0;
        const sweep = readNumber() !== 0;
        const x = readNumber();
        const y = readNumber();
        const end = { x: relative ? current.x + x : x, y: relative ? current.y + y : y };
        points.push(...sampleArc(current, rx, ry, rotation, largeArc, sweep, end));
        current = end;
        break;
      }
      case "Z": {
        lineTo(subpathStart);
        command = null;
        break;
      }
      default:
        command = null;
        break;
    }
  }
  return points;
}

function collectStrokeSegments(file, tag, attributes, strokeStyle, failFn) {
  if (String(strokeStyle.stroke ?? "none").trim().toLowerCase() === "none") {
    return null;
  }
  const strokeWidth = parseLength(strokeStyle.strokeWidth, 1);
  if (!Number.isFinite(strokeWidth) || strokeWidth <= 0) {
    return null;
  }
  const invalid = () => {
    failFn(`${file}: <${tag}> stroke must use numeric geometry attributes so label intersections can be checked`);
    return null;
  };
  let segments = [];
  if (tag === "line") {
    const x1 = parseLength(attributes.get("x1"), 0);
    const y1 = parseLength(attributes.get("y1"), 0);
    const x2 = parseLength(attributes.get("x2"), 0);
    const y2 = parseLength(attributes.get("y2"), 0);
    if (![x1, y1, x2, y2].every(Number.isFinite)) return invalid();
    segments = [[{ x: x1, y: y1 }, { x: x2, y: y2 }]];
  } else if (tag === "polyline" || tag === "polygon") {
    const points = parsePointList(attributes.get("points"));
    if (points.length < 2) return invalid();
    segments = lineSegmentsFromPoints(points, tag === "polygon");
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
  } else if (tag === "ellipse") {
    const cx = parseLength(attributes.get("cx"), 0);
    const cy = parseLength(attributes.get("cy"), 0);
    const rx = parseLength(attributes.get("rx"));
    const ry = parseLength(attributes.get("ry"));
    if (![cx, cy, rx, ry].every(Number.isFinite) || rx < 0 || ry < 0) return invalid();
    segments = lineSegmentsFromPoints(sampleEllipse(cx, cy, rx, ry), true);
  } else if (tag === "path") {
    const points = parsePathData(attributes.get("d"));
    segments = lineSegmentsFromPathPoints(points);
    if (segments.length === 0) return invalid();
  }
  return segments.length === 0 ? null : { description: `<${tag}>`, strokeWidth, segments };
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

function collectFigureGeometry(file, source, failFn) {
  const viewBox = parseViewBox(file, source, failFn);
  if (viewBox === null) {
    return { viewBox, texts: [], strokes: [] };
  }
  const texts = [];
  const strokes = [];
  const defaultTextStyle = { fontSize: "16", fontWeight: "400", textAnchor: "start" };
  const defaultStrokeStyle = { stroke: "none", strokeWidth: "1" };
  const stack = [{ name: "#document", textStyle: defaultTextStyle, strokeStyle: defaultStrokeStyle }];
  const supportedStrokeTags = new Set(["line", "polyline", "rect", "circle", "ellipse", "path", "polygon"]);
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
    const textStyle = mergeTextStyle(parent.textStyle, attributes);
    const strokeStyle = mergeStrokeStyle(parent.strokeStyle, attributes);

    if (name === "text") {
      const closePattern = /<\/text\s*>/ig;
      closePattern.lastIndex = tagPattern.lastIndex;
      const close = closePattern.exec(source);
      if (close === null) {
        failFn(`${file}: <text> is missing a closing </text>`);
        continue;
      }
      const body = source.slice(tagPattern.lastIndex, close.index);
      const textBox = collectTextBox(file, attributes, parent.textStyle, body, failFn);
      if (textBox !== null) {
        texts.push(textBox);
      }
      tagPattern.lastIndex = close.index + close[0].length;
      continue;
    }

    if (supportedStrokeTags.has(name)) {
      const stroke = collectStrokeSegments(file, name, attributes, strokeStyle, failFn);
      if (stroke !== null) {
        strokes.push(stroke);
      }
    }

    if (!isSelfClosingTag(token)) {
      stack.push({ name, textStyle, strokeStyle });
    }
  }
  return { viewBox, texts, strokes };
}

function checkTextEdges(file, viewBox, texts, failFn) {
  const edgeMargin = 2;
  for (const text of texts) {
    const { bounds } = text;
    if (bounds.left < viewBox.minX + edgeMargin || bounds.right > viewBox.maxX - edgeMargin || bounds.top < viewBox.minY + edgeMargin || bounds.bottom > viewBox.maxY - edgeMargin) {
      failFn(`${file}: <text> '${text.text}' estimated bounds are too close to or beyond the viewBox edge (bounds ${bounds.left.toFixed(1)},${bounds.top.toFixed(1)} to ${bounds.right.toFixed(1)},${bounds.bottom.toFixed(1)}; required inside ${viewBox.minX + edgeMargin},${viewBox.minY + edgeMargin} to ${viewBox.maxX - edgeMargin},${viewBox.maxY - edgeMargin})`);
    }
  }
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
      const requiredGap = Math.min(first.fontSize, second.fontSize) * 0.25;
      if (gap < requiredGap) {
        failFn(`${file}: <text> '${first.text}' and <text> '${second.text}' are only ${gap.toFixed(1)} units apart; required at least ${requiredGap.toFixed(1)} units (short by ${(requiredGap - gap).toFixed(1)})`);
      }
    }
  }
}

function checkTextStrokeIntersections(file, texts, strokes, failFn) {
  for (const text of texts) {
    for (const stroke of strokes) {
      const requiredClearance = stroke.strokeWidth / 2;
      for (const [start, end] of stroke.segments) {
        const clearance = segmentRectDistance(start, end, text.strokeBounds);
        if (clearance <= requiredClearance) {
          failFn(`${file}: <text> '${text.text}' estimated ink bounds intersect ${stroke.description} stroke (clearance ${clearance.toFixed(1)}; stroke padding ${requiredClearance.toFixed(1)})`);
          break;
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
  checkTextStrokeIntersections(file, geometry.texts, geometry.strokes, failFn);
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
      name: "viewBox edge fails",
      source: fixture(`<text x="1" y="18" font-size="20" fill="currentColor">Edge</text>`),
      expect: [/Edge.*viewBox edge/]
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
      name: "tspan anchor and bold width pass",
      source: fixture(`<g fill="currentColor" text-anchor="middle"><text x="100" y="45" font-size="18" font-weight="700"><tspan x="100" y="45">Top</tspan><tspan x="100" y="82">Bottom</tspan></text></g>`),
      expect: []
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
