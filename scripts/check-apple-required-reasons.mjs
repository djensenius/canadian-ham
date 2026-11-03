#!/usr/bin/env node
// Checks that every shipped Apple app target declares, in its own bundled
// PrivacyInfo.xcprivacy, exactly the required-reason API categories its Swift
// sources (and the local Swift packages it links) use, with approved reasons.
// Each manifest must also keep NSPrivacyTracking = false and empty
// NSPrivacyTrackingDomains / NSPrivacyCollectedDataTypes, and shipped targets
// and linked packages may contain only Swift sources.
//
// Categories, listed APIs and reason codes follow Apple's current
// documentation, quoted in docs/release/privacy-label-evidence.md:
// https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
// https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
//
// Target membership comes from apps/apple/project.yml (the XcodeGen spec), so
// new source folders are mapped automatically. Every Swift file under
// apps/apple must belong to some project.yml target; XcodeGen constructs this
// script does not understand fail the check rather than being skipped.
//
// Limitation: `#if` conditions are not evaluated, so an API compiled out on a
// platform still counts for every target that compiles the file, and string
// literals are scanned too. Both err towards declaring a category; binary
// inspection of the built bundles is the cross-check.
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { basename, join, normalize, relative, resolve, sep } from 'node:path';

const root = resolve(process.env.REQUIRED_REASONS_ROOT ?? process.cwd());
const verbose = process.argv.includes('--verbose');
const appleDir = join(root, 'apps/apple');
const projectYmlPath = join(appleDir, 'project.yml');
const MANIFEST_NAME = 'PrivacyInfo.xcprivacy';

// Each category's approved app reasons and the source spellings that use it.
// SDK-only reasons are valid codes but may not be declared by an app.
const CATEGORIES = {
  NSPrivacyAccessedAPICategoryFileTimestamp: {
    label: 'File timestamp',
    appReasons: ['DDA9.1', 'C617.1', '3B52.1'],
    sdkOnlyReasons: ['0A2A.1'],
    patterns: [
      [/\.creationDate\b/, 'creationDate'],
      [/\.modificationDate\b/, 'modificationDate'],
      [/\bfileModificationDate\b/, 'fileModificationDate'],
      [/\bcontentModificationDate(?:Key)?\b/, 'contentModificationDateKey'],
      [/\bcreationDateKey\b/, 'creationDateKey'],
      [/\bNSFile(?:Creation|Modification)Date\b/, 'NSFileCreationDate/NSFileModificationDate'],
      [/\bNSURL(?:Creation|ContentModification)DateKey\b/, 'NSURLCreationDateKey/NSURLContentModificationDateKey'],
      [/\bf?getattrlist(?:bulk|at)?\s*\(/, 'getattrlist family'],
      [/\b(?:f|l)?stat\s*\(/, 'stat/fstat/lstat'],
      [/\bfstatat\s*\(/, 'fstatat'],
    ],
  },
  NSPrivacyAccessedAPICategorySystemBootTime: {
    label: 'System boot time',
    appReasons: ['35F9.1', '8FFB.1', '3D61.1'],
    sdkOnlyReasons: [],
    patterns: [
      [/\bsystemUptime\b/, 'systemUptime'],
      [/\bmach_absolute_time\b/, 'mach_absolute_time'],
      // Not on Apple's list, but a direct boot-time read; flagged conservatively.
      [/\bkern\.boottime\b|\bKERN_BOOTTIME\b/, 'sysctl kern.boottime'],
    ],
  },
  NSPrivacyAccessedAPICategoryDiskSpace: {
    label: 'Disk space',
    appReasons: ['85F4.1', 'E174.1', '7D9E.1', 'B728.1'],
    sdkOnlyReasons: [],
    patterns: [
      [/\bvolumeAvailableCapacity(?:ForImportantUsage|ForOpportunisticUsage)?(?:Key)?\b/, 'volumeAvailableCapacity*'],
      [/\bvolumeTotalCapacity(?:Key)?\b/, 'volumeTotalCapacityKey'],
      [/\.systemFreeSize\b|\bNSFileSystemFreeSize\b/, 'systemFreeSize'],
      [/\.systemSize\b|\bNSFileSystemSize\b/, 'systemSize'],
      [/\bf?statv?fs\s*\(/, 'statfs/statvfs/fstatfs/fstatvfs'],
      [/\bf?getattrlist(?:at)?\s*\(/, 'getattrlist family'],
    ],
  },
  NSPrivacyAccessedAPICategoryActiveKeyboards: {
    label: 'Active keyboards',
    appReasons: ['3EC4.1', '54BD.1'],
    sdkOnlyReasons: [],
    patterns: [[/\bactiveInputModes\b/, 'activeInputModes']],
  },
  NSPrivacyAccessedAPICategoryUserDefaults: {
    label: 'User defaults',
    appReasons: ['CA92.1', '1C8F.1', 'AC6B.1'],
    sdkOnlyReasons: ['C56D.1'],
    patterns: [
      [/\bUserDefaults\b/, 'UserDefaults'],
      [/\bNSUserDefaults\b|\bstandardUserDefaults\b/, 'NSUserDefaults'],
      // SwiftUI and Core Foundation front-ends to the same defaults store.
      [/@AppStorage\b/, '@AppStorage'],
      [/\bCFPreferences[A-Za-z]*\b/, 'CFPreferences'],
    ],
  },
};

// Only Swift is scanned. C-family sources could call required-reason APIs
// (stat, mach_absolute_time, NSUserDefaults, ...) with other spellings, so any
// such file in a shipped target or linked package fails the check.
const NON_SWIFT_SOURCE = /\.(?:c|m|mm|cpp|cc|cxx|h|hpp)$/;
const NON_SWIFT_MESSAGE = 'only Swift sources are scanned; extend scripts/check-apple-required-reasons.mjs to scan C/Objective-C/C++ before shipping it';

const SHIPPED_TARGET_TYPE = /^(?:application(?:\..+)?|app-extension(?:\..+)?|.*-extension)$/;
const TEST_TARGET_TYPES = new Set(['bundle.unit-test', 'bundle.ui-testing']);
const KNOWN_SOURCE_KEYS = new Set([
  'path', 'excludes', 'buildPhase', 'type', 'createIntermediateGroups', 'destinationFilters',
  'inferDestinationFiltersByPath', 'group', 'name', 'optional', 'compilerFlags', 'attributes',
  'resourceTags', 'headerVisibility',
]);

const errors = [];
const fail = (message) => errors.push(message);
const display = (absolutePath) => relative(root, absolutePath).split(sep).join('/');

// ---------------------------------------------------------------------------
// Minimal YAML subset parser for the XcodeGen spec: block mappings, block
// sequences, flow sequences, quoted/plain scalars, comments and block scalars.
// Anything else (anchors, flow mappings, tabs) is an error, not a silent skip.

function parseYamlSubset(text, label) {
  const lines = text.split(/\r?\n/);
  let index = 0;
  const syntaxError = (lineIndex, message) => {
    throw new Error(`${label}:${lineIndex + 1}: ${message}`);
  };

  const significant = (lineIndex) => {
    const line = lines[lineIndex];
    return line.trim() !== '' && !/^\s*#/.test(line);
  };
  const peek = () => {
    while (index < lines.length && !significant(index)) index += 1;
    if (index >= lines.length) return null;
    const line = lines[index];
    if (/^\s*\t/.test(line)) syntaxError(index, 'tab indentation is not supported');
    const indent = line.length - line.trimStart().length;
    return { indent, text: stripYamlComment(line.slice(indent)), lineIndex: index };
  };

  function stripYamlComment(value) {
    let single = false;
    let double = false;
    for (let i = 0; i < value.length; i += 1) {
      const c = value[i];
      if (c === "'" && !double) single = !single;
      else if (c === '"' && !single && value[i - 1] !== '\\') double = !double;
      else if (c === '#' && !single && !double && (i === 0 || /\s/.test(value[i - 1]))) {
        return value.slice(0, i).trimEnd();
      }
    }
    return value.trimEnd();
  }

  function scalar(raw, lineIndex) {
    const value = raw.trim();
    if (/^[&*!]/.test(value)) syntaxError(lineIndex, `anchors, aliases and tags are not supported: ${value}`);
    if (value.startsWith('{')) {
      if (value === '{}') return {};
      syntaxError(lineIndex, `flow mappings are not supported: ${value}`);
    }
    if (value.startsWith('[')) {
      if (!value.endsWith(']')) syntaxError(lineIndex, `unterminated flow sequence: ${value}`);
      const inner = value.slice(1, -1).trim();
      return inner === '' ? [] : inner.split(',').map((item) => scalar(item, lineIndex));
    }
    if (/^".*"$/.test(value)) return value.slice(1, -1).replace(/\\"/g, '"').replace(/\\\\/g, '\\');
    if (/^'.*'$/.test(value)) return value.slice(1, -1).replace(/''/g, "'");
    return value;
  }

  const KEY_PATTERN = /^("[^"]*"|'[^']*'|[^\s'"\-?:][^:]*?|-[^\s:][^:]*?):(?:\s+(.*))?$/;

  function blockScalar(parentIndent) {
    const collected = [];
    while (index < lines.length) {
      const line = lines[index];
      const indent = line.length - line.trimStart().length;
      if (line.trim() !== '' && indent <= parentIndent) break;
      collected.push(line);
      index += 1;
    }
    return collected.join('\n');
  }

  function valueAfterKey(rest, keyIndent, lineIndex) {
    if (rest === undefined || rest === '') {
      const next = peek();
      if (next && next.indent > keyIndent) return node(next.indent);
      if (next && next.indent === keyIndent && /^-(\s|$)/.test(next.text)) return sequence(keyIndent);
      return null;
    }
    if (/^[|>][-+]?\d*$/.test(rest)) return blockScalar(keyIndent);
    return scalar(rest, lineIndex);
  }

  function mapping(indent) {
    const result = {};
    for (let next = peek(); next && next.indent === indent && !/^-(\s|$)/.test(next.text); next = peek()) {
      const match = next.text.match(KEY_PATTERN);
      if (!match) syntaxError(next.lineIndex, `expected "key: value", found: ${next.text}`);
      index += 1;
      const key = scalar(match[1], next.lineIndex);
      result[key] = valueAfterKey(match[2], indent, next.lineIndex);
    }
    const after = peek();
    if (after && after.indent > indent) syntaxError(after.lineIndex, 'unexpected indentation');
    return result;
  }

  function sequence(indent) {
    const result = [];
    for (let next = peek(); next && next.indent === indent && /^-(\s|$)/.test(next.text); next = peek()) {
      const content = next.text.replace(/^-\s*/, '');
      if (content === '') {
        index += 1;
        const child = peek();
        result.push(child && child.indent > indent ? node(child.indent) : null);
      } else if (KEY_PATTERN.test(content)) {
        // "- key: value" starts a mapping whose keys align with "key".
        const childIndent = indent + (next.text.length - content.length);
        lines[next.lineIndex] = ' '.repeat(childIndent) + content;
        result.push(mapping(childIndent));
      } else {
        index += 1;
        result.push(scalar(content, next.lineIndex));
      }
    }
    return result;
  }

  function node(indent) {
    const next = peek();
    if (!next) return null;
    return /^-(\s|$)/.test(next.text) ? sequence(indent) : mapping(indent);
  }

  const first = peek();
  const document = first ? node(first.indent) : {};
  const trailing = peek();
  if (trailing) syntaxError(trailing.lineIndex, 'unexpected content after document');
  return document;
}

// ---------------------------------------------------------------------------
// Minimal XML property list parser (dict, array, string, key, booleans, numbers).

function parsePlist(xml, label) {
  const tokenPattern = /<!--[\s\S]*?-->|<\?[\s\S]*?\?>|<!DOCTYPE[^>]*>|<(\/?)([A-Za-z]+)(?:\s[^>]*?)?(\/?)>|([^<]+)/g;
  const tokens = [];
  for (const match of xml.matchAll(tokenPattern)) {
    if (match[2]) {
      tokens.push({ kind: match[1] ? 'close' : match[3] ? 'empty' : 'open', name: match[2] });
    } else if (match[4] !== undefined && match[4].trim() !== '') {
      tokens.push({ kind: 'text', value: match[4] });
    }
  }
  let position = 0;
  const syntaxError = (message) => {
    throw new Error(`${label}: invalid property list: ${message}`);
  };
  const next = () => tokens[position++] ?? syntaxError('unexpected end of document');
  const decode = (value) => value
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&');
  const textUntilClose = (name) => {
    let token = next();
    let value = '';
    if (token.kind === 'text') {
      value = decode(token.value);
      token = next();
    }
    if (token.kind !== 'close' || token.name !== name) syntaxError(`expected </${name}>`);
    return value;
  };

  function value(token = next()) {
    if (token.kind === 'empty') {
      if (token.name === 'dict') return {};
      if (token.name === 'array') return [];
      if (token.name === 'string') return '';
      if (token.name === 'true') return true;
      if (token.name === 'false') return false;
      syntaxError(`unsupported empty element <${token.name}/>`);
    }
    if (token.kind !== 'open') syntaxError(`unexpected ${token.kind} ${token.name ?? token.value}`);
    switch (token.name) {
      case 'dict': {
        const result = {};
        for (let item = next(); !(item.kind === 'close' && item.name === 'dict'); item = next()) {
          if (item.kind !== 'open' || item.name !== 'key') syntaxError('expected <key> in <dict>');
          const key = textUntilClose('key');
          if (Object.hasOwn(result, key)) syntaxError(`duplicate key ${key}`);
          result[key] = value();
        }
        return result;
      }
      case 'array': {
        const result = [];
        for (let item = next(); !(item.kind === 'close' && item.name === 'array'); item = next()) {
          result.push(value(item));
        }
        return result;
      }
      case 'string':
      case 'date':
      case 'data':
        return textUntilClose(token.name);
      case 'integer':
      case 'real':
        return Number(textUntilClose(token.name));
      default:
        return syntaxError(`unsupported element <${token.name}>`);
    }
  }

  const open = next();
  if (open.kind !== 'open' || open.name !== 'plist') syntaxError('expected <plist>');
  const result = value();
  const close = next();
  if (close.kind !== 'close' || close.name !== 'plist') syntaxError('expected </plist>');
  if (position !== tokens.length) syntaxError('unexpected content after </plist>');
  return result;
}

// ---------------------------------------------------------------------------
// Swift source scanning: blank out comments (keeping strings and line numbers).

function stripSwiftComments(source) {
  const out = [];
  let i = 0;
  const n = source.length;

  const blank = (end) => {
    for (; i < end && i < n; i += 1) out.push(source[i] === '\n' ? '\n' : ' ');
  };
  const rawStringAhead = () => {
    let j = i;
    while (source[j] === '#') j += 1;
    return j > i && source[j] === '"';
  };

  function lineComment() {
    const end = source.indexOf('\n', i);
    blank(end === -1 ? n : end);
  }

  function blockComment() {
    let depth = 0;
    while (i < n) {
      if (source.startsWith('/*', i)) {
        depth += 1;
        blank(i + 2);
      } else if (source.startsWith('*/', i)) {
        depth -= 1;
        blank(i + 2);
        if (depth === 0) return;
      } else {
        blank(i + 1);
      }
    }
  }

  function stringLiteral() {
    let hashes = 0;
    while (source[i] === '#') {
      out.push('#');
      hashes += 1;
      i += 1;
    }
    const quote = source.startsWith('"""', i) ? '"""' : '"';
    out.push(quote);
    i += quote.length;
    const terminator = quote + '#'.repeat(hashes);
    const escape = '\\' + '#'.repeat(hashes);
    while (i < n) {
      if (source.startsWith(terminator, i)) {
        out.push(terminator);
        i += terminator.length;
        return;
      }
      if (source.startsWith(escape, i)) {
        out.push(escape);
        i += escape.length;
        if (source[i] === '(') {
          out.push('(');
          i += 1;
          code(true);
        } else if (i < n) {
          out.push(source[i]);
          i += 1;
        }
        continue;
      }
      if (quote === '"' && source[i] === '\n') return;
      out.push(source[i]);
      i += 1;
    }
  }

  function code(inInterpolation) {
    let depth = 0;
    while (i < n) {
      const c = source[i];
      if (source.startsWith('//', i)) {
        lineComment();
      } else if (source.startsWith('/*', i)) {
        blockComment();
      } else if (c === '"' || (c === '#' && rawStringAhead())) {
        stringLiteral();
      } else {
        if (inInterpolation && c === '(') depth += 1;
        if (inInterpolation && c === ')') {
          if (depth === 0) {
            out.push(c);
            i += 1;
            return;
          }
          depth -= 1;
        }
        out.push(c);
        i += 1;
      }
    }
  }

  code(false);
  return out.join('');
}

const usageCache = new Map();
function apiUsage(file) {
  if (usageCache.has(file)) return usageCache.get(file);
  const lines = stripSwiftComments(readFileSync(file, 'utf8')).split('\n');
  const usages = [];
  lines.forEach((line, lineIndex) => {
    for (const [category, { patterns }] of Object.entries(CATEGORIES)) {
      for (const [pattern, spelling] of patterns) {
        if (pattern.test(line)) usages.push({ category, spelling, file, line: lineIndex + 1 });
      }
    }
  });
  usageCache.set(file, usages);
  return usages;
}

// ---------------------------------------------------------------------------
// project.yml target resolution.

function globToRegExp(glob) {
  let pattern = '';
  for (let i = 0; i < glob.length; i += 1) {
    const c = glob[i];
    if (c === '*' && glob[i + 1] === '*') {
      pattern += glob[i + 2] === '/' ? '(?:.*/)?' : '.*';
      i += glob[i + 2] === '/' ? 2 : 1;
    } else if (c === '*') {
      pattern += '[^/]*';
    } else if (c === '?') {
      pattern += '[^/]';
    } else {
      pattern += c.replace(/[.+^${}()|[\]\\]/g, '\\$&');
    }
  }
  return new RegExp(`^${pattern.replace(/\/$/, '')}$`);
}

function walk(directory, excludes, base, visit) {
  for (const entry of readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    if (entry.name.startsWith('.')) continue;
    const absolutePath = join(directory, entry.name);
    const relativePath = relative(base, absolutePath).split(sep).join('/');
    if (excludes.some((pattern) => pattern.test(relativePath))) continue;
    if (entry.isDirectory() && !/\.(?:xcassets|icon|xcstrings)$/.test(entry.name)) {
      walk(absolutePath, excludes, base, visit);
    } else if (entry.isFile()) {
      visit(absolutePath);
    }
  }
}

function resolveTarget(name, target, packages) {
  const swiftFiles = new Set();
  const nonSwiftFiles = new Set();
  const manifests = new Set();
  const packageNames = [];
  const sources = target.sources ?? [];
  if (!Array.isArray(sources)) {
    fail(`${name}: sources must be a list in project.yml.`);
    return { swiftFiles, nonSwiftFiles, manifests, packageNames };
  }
  for (const rawEntry of sources) {
    const entry = typeof rawEntry === 'string' ? { path: rawEntry } : rawEntry;
    if (!entry || typeof entry !== 'object' || typeof entry.path !== 'string') {
      fail(`${name}: unsupported sources entry ${JSON.stringify(rawEntry)}; extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    const unknownKeys = Object.keys(entry).filter((key) => !KNOWN_SOURCE_KEYS.has(key));
    if (unknownKeys.length > 0) {
      fail(`${name}: sources entry ${entry.path} uses unsupported XcodeGen keys (${unknownKeys.join(', ')}); extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    const buildPhase = entry.buildPhase ?? 'default';
    if (buildPhase === 'none' || entry.type === 'folder') continue; // folder references keep their subpath
    const compiles = buildPhase === 'default' || buildPhase === 'sources';
    const absolutePath = normalize(join(appleDir, entry.path));
    if (!existsSync(absolutePath)) {
      // A missing source path would hide compiled Swift; missing resource files cannot.
      if (compiles && entry.optional !== 'true' && entry.optional !== true) {
        fail(`${name}: sources path ${entry.path} does not exist.`);
      }
      continue;
    }
    const record = (file) => {
      if (file.endsWith('.swift') && compiles) swiftFiles.add(file);
      if (NON_SWIFT_SOURCE.test(file) && buildPhase !== 'resources') nonSwiftFiles.add(file);
      if (basename(file) === MANIFEST_NAME && buildPhase !== 'sources') manifests.add(file);
    };
    if (statSync(absolutePath).isDirectory()) {
      const excludes = (entry.excludes ?? []).map((glob) => globToRegExp(glob));
      walk(absolutePath, excludes, absolutePath, record);
    } else {
      record(absolutePath);
    }
  }

  for (const dependency of target.dependencies ?? []) {
    if (dependency.package) {
      if (!packages[dependency.package]) {
        fail(`${name}: depends on unknown package ${dependency.package}.`);
      } else {
        packageNames.push(dependency.package);
      }
    } else if (dependency.target) {
      // Embedded app targets are separate bundles, checked with their own manifest.
      continue;
    } else if (dependency.sdk) {
      continue; // System frameworks: Apple's own use is not declared by the app.
    } else {
      fail(`${name}: unsupported dependency ${JSON.stringify(dependency)}; binary or third-party code needs its own required-reason review.`);
    }
  }
  return { swiftFiles, nonSwiftFiles, manifests, packageNames };
}

function resolvePackage(name, spec) {
  const files = new Set();
  const packagePath = typeof spec === 'string' ? spec : spec?.path;
  if (!packagePath) {
    fail(`project.yml package ${name} is not a local path package; remote packages are not allowed.`);
    return files;
  }
  const packageDir = normalize(join(appleDir, packagePath));
  const manifestPath = join(packageDir, 'Package.swift');
  if (!existsSync(manifestPath)) {
    fail(`project.yml package ${name}: ${display(manifestPath)} does not exist.`);
    return files;
  }
  const manifest = stripSwiftComments(readFileSync(manifestPath, 'utf8'));
  for (const [pattern, reason] of [
    [/\bpath\s*:/, 'custom target paths'],
    [/\bsources\s*:/, 'custom source lists'],
    [/\.package\s*\(/, 'package dependencies'],
    [/\.binaryTarget\s*\(/, 'binary targets'],
    [/\.dynamic\b/, 'dynamic library products (which need their own bundled manifest)'],
  ]) {
    if (pattern.test(manifest)) {
      fail(`${display(manifestPath)} uses ${reason}; extend scripts/check-apple-required-reasons.mjs before linking it.`);
    }
  }
  const sourcesDir = join(packageDir, 'Sources');
  if (existsSync(sourcesDir)) {
    walk(sourcesDir, [], sourcesDir, (file) => {
      if (file.endsWith('.swift')) files.add(file);
      if (NON_SWIFT_SOURCE.test(file)) fail(`package ${name}: ${display(file)} is not Swift; ${NON_SWIFT_MESSAGE}.`);
    });
  }
  return files;
}

// ---------------------------------------------------------------------------
// Manifest validation.

function declaredCategories(manifestPath, targetName) {
  const label = display(manifestPath);
  let plist;
  try {
    plist = parsePlist(readFileSync(manifestPath, 'utf8'), label);
  } catch (error) {
    fail(error.message);
    return null;
  }
  if (!plist || typeof plist !== 'object' || Array.isArray(plist)) {
    fail(`${label}: top level must be a dictionary.`);
    return null;
  }
  // The Apple app does no tracking and collects no data (AGENTS.md, docs/privacy.md).
  if (plist.NSPrivacyTracking !== false) {
    fail(`${label} (${targetName}): NSPrivacyTracking must be present and false; the Apple app does no tracking.`);
  }
  for (const key of ['NSPrivacyTrackingDomains', 'NSPrivacyCollectedDataTypes']) {
    if (!Array.isArray(plist[key]) || plist[key].length !== 0) {
      fail(`${label} (${targetName}): ${key} must be present and an empty array; the Apple app does no tracking and collects no data.`);
    }
  }
  const entries = plist.NSPrivacyAccessedAPITypes ?? [];
  if (!Array.isArray(entries)) {
    fail(`${label}: NSPrivacyAccessedAPITypes must be an array.`);
    return null;
  }
  const declared = new Map();
  for (const entry of entries) {
    const category = entry?.NSPrivacyAccessedAPIType;
    const reasons = entry?.NSPrivacyAccessedAPITypeReasons;
    if (typeof category !== 'string' || !CATEGORIES[category]) {
      fail(`${label} (${targetName}): unknown NSPrivacyAccessedAPIType ${JSON.stringify(category)}.`);
      continue;
    }
    if (declared.has(category)) {
      fail(`${label} (${targetName}): ${category} is declared more than once.`);
      continue;
    }
    if (!Array.isArray(reasons) || reasons.length === 0) {
      fail(`${label} (${targetName}): ${category} must list at least one NSPrivacyAccessedAPITypeReasons code.`);
      continue;
    }
    const { appReasons, sdkOnlyReasons } = CATEGORIES[category];
    for (const reason of reasons) {
      if (sdkOnlyReasons.includes(reason)) {
        fail(`${label} (${targetName}): ${reason} may only be declared by third-party SDKs, not by an app, for ${category}.`);
      } else if (!appReasons.includes(reason)) {
        fail(`${label} (${targetName}): ${JSON.stringify(reason)} is not an approved reason for ${category} (approved: ${appReasons.join(', ')}).`);
      }
    }
    if (new Set(reasons).size !== reasons.length) {
      fail(`${label} (${targetName}): ${category} lists a reason more than once.`);
    }
    declared.set(category, reasons);
  }
  return declared;
}

// ---------------------------------------------------------------------------

function main() {
  let project;
  try {
    project = parseYamlSubset(readFileSync(projectYmlPath, 'utf8'), display(projectYmlPath));
  } catch (error) {
    fail(error.message);
    return;
  }
  for (const unsupported of ['include', 'targetTemplates']) {
    if (project[unsupported] !== undefined) {
      fail(`project.yml uses top-level ${unsupported}; extend scripts/check-apple-required-reasons.mjs.`);
    }
  }
  const packages = project.packages ?? {};
  const targets = project.targets ?? {};
  if (Object.keys(targets).length === 0) fail('project.yml defines no targets.');

  const packageFiles = new Map();
  const claimed = new Set();
  const results = [];
  for (const [name, target] of Object.entries(targets)) {
    if (target?.templates !== undefined) {
      fail(`${name}: target templates are not supported; extend scripts/check-apple-required-reasons.mjs.`);
    }
    const type = String(target?.type ?? '');
    const shipped = SHIPPED_TARGET_TYPE.test(type);
    if (!shipped && !TEST_TARGET_TYPES.has(type)) {
      fail(`${name}: target type ${JSON.stringify(type)} is not supported; extend scripts/check-apple-required-reasons.mjs.`);
      continue;
    }
    const resolved = resolveTarget(name, target, packages);
    for (const file of resolved.swiftFiles) claimed.add(file);
    if (!shipped) continue;
    for (const file of resolved.nonSwiftFiles) fail(`${name}: ${display(file)} is not Swift; ${NON_SWIFT_MESSAGE}.`);

    const files = [...resolved.swiftFiles];
    for (const packageName of resolved.packageNames) {
      if (!packageFiles.has(packageName)) packageFiles.set(packageName, resolvePackage(packageName, packages[packageName]));
      files.push(...packageFiles.get(packageName));
    }
    if (resolved.swiftFiles.size === 0) fail(`${name}: no Swift sources resolved from project.yml.`);

    const manifests = [...resolved.manifests];
    if (manifests.length !== 1) {
      fail(`${name}: expected exactly one bundled ${MANIFEST_NAME}, found ${manifests.length}${manifests.length ? ` (${manifests.map(display).join(', ')})` : ''}.`);
    }
    const usages = files.flatMap((file) => apiUsage(file));
    const used = new Map();
    for (const usage of usages) {
      if (!used.has(usage.category)) used.set(usage.category, []);
      used.get(usage.category).push(usage);
    }
    const declared = manifests.length === 1 ? declaredCategories(manifests[0], name) : null;
    if (declared) {
      const manifestLabel = display(manifests[0]);
      for (const [category, categoryUsages] of used) {
        if (!declared.has(category)) {
          const examples = categoryUsages.slice(0, 3).map((usage) => `${display(usage.file)}:${usage.line} ${usage.spelling}`).join('; ');
          fail(`${name}: uses ${category} (${CATEGORIES[category].label}) but ${manifestLabel} does not declare it. Evidence: ${examples}${categoryUsages.length > 3 ? '; ...' : ''}`);
        }
      }
      for (const category of declared.keys()) {
        if (!used.has(category)) {
          fail(`${name}: ${manifestLabel} declares ${category} (${CATEGORIES[category].label}) but no Swift source compiled into ${name} or its linked local packages uses it.`);
        }
      }
    }
    results.push({ name, manifest: manifests[0], declared, used, fileCount: files.length });
  }

  const allSwift = [];
  if (existsSync(appleDir)) {
    walk(appleDir, [/\.xcodeproj$/, /(?:^|\/)DerivedData$/, /(?:^|\/)build$/], appleDir, (file) => {
      if (file.endsWith('.swift')) allSwift.push(file);
    });
  }
  for (const file of allSwift) {
    if (!claimed.has(file)) {
      fail(`${display(file)} is not compiled by any project.yml target; add it to a target (or extend scripts/check-apple-required-reasons.mjs) so its required-reason API use is attributed.`);
    }
  }

  for (const { name, manifest, declared, used, fileCount } of results) {
    const summary = [...(declared ?? used).keys()].sort()
      .map((category) => `${category.replace('NSPrivacyAccessedAPICategory', '')}${declared?.has(category) ? ` [${declared.get(category).join(', ')}]` : ''}`)
      .join(', ') || 'none';
    console.log(`${name}: ${fileCount} Swift files; ${manifest ? display(manifest) : 'no manifest'}; categories: ${summary}`);
    if (verbose) {
      for (const [category, categoryUsages] of used) {
        for (const usage of categoryUsages) {
          console.log(`  ${category.replace('NSPrivacyAccessedAPICategory', '')}: ${display(usage.file)}:${usage.line} ${usage.spelling}`);
        }
      }
    }
  }
}

main();

if (errors.length > 0) {
  console.error('Apple required-reason API check failed:');
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}
console.log('Apple required-reason API check passed: every shipped target declares exactly the required-reason API categories its sources and linked local packages use, with approved app reasons, no tracking and no collected data.');
