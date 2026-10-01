#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const schemasDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(schemasDir, "../..");
const schemaCache = new Map();
const schemaFiles = [
  "common.schema.json",
  "generated-bank-manifest.schema.json",
  "generated-bank-categories.schema.json",
  "generated-bank-questions.schema.json",
  "generated-bank-subsections.schema.json",
  "subsection-titles.schema.json",
  "lesson-module-front-matter.schema.json",
  "lesson-front-matter.schema.json",
  "explanation.schema.json",
  "progress-export-v1.schema.json",
  "engine-fixture.schema.json",
];

let validationCount = 0;
const failures = [];

for (const file of schemaFiles) {
  loadSchema(file);
}

validateJsonFile("content/generated/basic-2025-07-15/manifest.json", "generated-bank-manifest.schema.json");
validateJsonFile("content/generated/basic-2025-07-15/categories.json", "generated-bank-categories.schema.json");
validateJsonFile("content/generated/basic-2025-07-15/questions.json", "generated-bank-questions.schema.json");
validateJsonFile("content/generated/basic-2025-07-15/subsections.json", "generated-bank-subsections.schema.json");
validateJsonFile("content/subsection-titles.json", "subsection-titles.schema.json");

for (const file of walk(path.join(projectRoot, "content/lessons"), ".md")) {
  const relative = path.relative(projectRoot, file);
  const frontMatter = parseFrontMatter(fs.readFileSync(file, "utf8"), relative);
  if (frontMatter === null) {
    continue;
  }
  if (frontMatter.type === "module") {
    validateData(relative, frontMatter, "lesson-module-front-matter.schema.json");
  } else if (frontMatter.type === "lesson") {
    validateData(relative, frontMatter, "lesson-front-matter.schema.json");
  } else {
    failures.push(`${relative}: unsupported front matter type ${JSON.stringify(frontMatter.type)}`);
  }
}

for (const file of walk(path.join(projectRoot, "content/explanations"), ".json")) {
  validateJsonFile(path.relative(projectRoot, file), "explanation.schema.json");
}

for (const file of walk(path.join(projectRoot, "fixtures/engine"), ".json")) {
  validateJsonFile(path.relative(projectRoot, file), "engine-fixture.schema.json");
}

for (const sample of progressExportSamples()) {
  validateData(sample.name, sample.data, "progress-export-v1.schema.json");
}

if (failures.length > 0) {
  console.error(`Schema validation failed: ${failures.length} error(s) across ${validationCount} validation target(s).`);
  for (const failure of failures.slice(0, 100)) {
    console.error(`- ${failure}`);
  }
  if (failures.length > 100) {
    console.error(`... ${failures.length - 100} more error(s) omitted.`);
  }
  process.exit(1);
}

console.log(`Schema validation passed: ${validationCount} validation target(s).`);
console.log("Validated generated bank JSON, subsection titles, lesson front matter, explanations, engine fixtures, and progress export samples.");

function validateJsonFile(relativePath, schemaFile) {
  const absolutePath = path.join(projectRoot, relativePath);
  const data = JSON.parse(fs.readFileSync(absolutePath, "utf8"));
  validateData(relativePath, data, schemaFile);
}

function validateData(label, data, schemaFile) {
  validationCount += 1;
  const schema = loadSchema(schemaFile);
  const errors = validateAgainstSchema(schema, data, { documentId: schemaFile, path: "$" });
  for (const error of errors) {
    failures.push(`${label}: ${error}`);
  }
}

function loadSchema(schemaFile) {
  const normalized = path.basename(schemaFile);
  if (schemaCache.has(normalized)) {
    return schemaCache.get(normalized);
  }
  const schema = JSON.parse(fs.readFileSync(path.join(schemasDir, normalized), "utf8"));
  schemaCache.set(normalized, schema);
  return schema;
}

function resolveRef(ref, currentDocumentId) {
  const [rawDocument, pointer = ""] = ref.split("#");
  const documentId = rawDocument === "" ? currentDocumentId : path.basename(rawDocument);
  let target = loadSchema(documentId);
  if (pointer === "" || pointer === "/") {
    return { schema: target, documentId };
  }
  const tokens = pointer.replace(/^\//, "").split("/").map((token) => token.replace(/~1/g, "/").replace(/~0/g, "~"));
  for (const token of tokens) {
    if (!isObject(target) || !(token in target)) {
      throw new Error(`Unresolvable $ref ${ref} from ${currentDocumentId}`);
    }
    target = target[token];
  }
  return { schema: target, documentId };
}

function validateAgainstSchema(schema, data, context) {
  if (typeof schema === "boolean") {
    return schema ? [] : [`${context.path}: boolean schema false rejected value`];
  }
  if (!isObject(schema)) {
    return [];
  }

  if (typeof schema.$ref === "string") {
    const resolved = resolveRef(schema.$ref, context.documentId);
    return validateAgainstSchema(resolved.schema, data, { documentId: resolved.documentId, path: context.path });
  }

  const errors = [];

  if (Array.isArray(schema.oneOf)) {
    const branchResults = schema.oneOf.map((branch) => validateAgainstSchema(branch, data, context));
    const passing = branchResults.filter((branchErrors) => branchErrors.length === 0).length;
    if (passing !== 1) {
      const firstReason = branchResults.find((branchErrors) => branchErrors.length > 0)?.[0];
      errors.push(`${context.path}: expected exactly one oneOf branch to match, got ${passing}${firstReason ? `; first mismatch: ${firstReason}` : ""}`);
    }
  }

  if (schema.const !== undefined && !deepEqual(data, schema.const)) {
    errors.push(`${context.path}: expected const ${JSON.stringify(schema.const)}, got ${JSON.stringify(data)}`);
  }

  if (Array.isArray(schema.enum) && !schema.enum.some((value) => deepEqual(value, data))) {
    errors.push(`${context.path}: expected one of ${JSON.stringify(schema.enum)}, got ${JSON.stringify(data)}`);
  }

  if (schema.type !== undefined && !matchesType(data, schema.type)) {
    errors.push(`${context.path}: expected type ${JSON.stringify(schema.type)}, got ${jsonType(data)}`);
    return errors;
  }

  if (typeof data === "string") {
    if (typeof schema.minLength === "number" && data.length < schema.minLength) {
      errors.push(`${context.path}: expected string length >= ${schema.minLength}`);
    }
    if (typeof schema.maxLength === "number" && data.length > schema.maxLength) {
      errors.push(`${context.path}: expected string length <= ${schema.maxLength}`);
    }
    if (typeof schema.pattern === "string" && !(new RegExp(schema.pattern, "u").test(data))) {
      errors.push(`${context.path}: expected string to match /${schema.pattern}/, got ${JSON.stringify(data)}`);
    }
  }

  if (typeof data === "number") {
    if (typeof schema.minimum === "number" && data < schema.minimum) {
      errors.push(`${context.path}: expected number >= ${schema.minimum}, got ${data}`);
    }
    if (typeof schema.maximum === "number" && data > schema.maximum) {
      errors.push(`${context.path}: expected number <= ${schema.maximum}, got ${data}`);
    }
  }

  if (Array.isArray(data)) {
    if (typeof schema.minItems === "number" && data.length < schema.minItems) {
      errors.push(`${context.path}: expected at least ${schema.minItems} item(s), got ${data.length}`);
    }
    if (typeof schema.maxItems === "number" && data.length > schema.maxItems) {
      errors.push(`${context.path}: expected at most ${schema.maxItems} item(s), got ${data.length}`);
    }
    if (schema.uniqueItems === true) {
      const seen = new Set();
      for (const item of data) {
        const serialized = JSON.stringify(item);
        if (seen.has(serialized)) {
          errors.push(`${context.path}: expected uniqueItems`);
          break;
        }
        seen.add(serialized);
      }
    }
    if (schema.items !== undefined) {
      data.forEach((item, index) => {
        errors.push(...validateAgainstSchema(schema.items, item, { documentId: context.documentId, path: `${context.path}[${index}]` }));
      });
    }
  }

  if (isObject(data)) {
    const properties = isObject(schema.properties) ? schema.properties : {};
    if (Array.isArray(schema.required)) {
      for (const key of schema.required) {
        if (!(key in data)) {
          errors.push(`${context.path}: missing required property ${key}`);
        }
      }
    }
    for (const [key, propertySchema] of Object.entries(properties)) {
      if (key in data) {
        errors.push(...validateAgainstSchema(propertySchema, data[key], { documentId: context.documentId, path: `${context.path}.${key}` }));
      }
    }
    if (schema.additionalProperties === false) {
      for (const key of Object.keys(data)) {
        if (!(key in properties)) {
          errors.push(`${context.path}: unexpected property ${key}`);
        }
      }
    } else if (isObject(schema.additionalProperties)) {
      for (const [key, value] of Object.entries(data)) {
        if (!(key in properties)) {
          errors.push(...validateAgainstSchema(schema.additionalProperties, value, { documentId: context.documentId, path: `${context.path}.${key}` }));
        }
      }
    }
  }

  return errors;
}

function matchesType(value, expected) {
  const expectedTypes = Array.isArray(expected) ? expected : [expected];
  return expectedTypes.some((type) => {
    switch (type) {
      case "array": return Array.isArray(value);
      case "boolean": return typeof value === "boolean";
      case "integer": return typeof value === "number" && Number.isInteger(value);
      case "null": return value === null;
      case "number": return typeof value === "number" && Number.isFinite(value);
      case "object": return isObject(value);
      case "string": return typeof value === "string";
      default: throw new Error(`Unsupported schema type ${type}`);
    }
  });
}

function jsonType(value) {
  if (Array.isArray(value)) return "array";
  if (value === null) return "null";
  if (Number.isInteger(value)) return "integer";
  return typeof value;
}

function isObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function deepEqual(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

function walk(directory, extension) {
  const results = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      results.push(...walk(absolute, extension));
    } else if (entry.isFile() && entry.name.endsWith(extension)) {
      results.push(absolute);
    }
  }
  return results.sort((a, b) => a.localeCompare(b));
}

function parseFrontMatter(raw, label) {
  const normalized = raw.replace(/^\uFEFF/, "").replace(/\r\n/g, "\n");
  const match = /^---\n([\s\S]*?)\n---\n?/.exec(normalized);
  if (match === null) {
    return null;
  }
  const source = match[1];
  const lines = source.split("\n");
  const result = {};
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.trim() === "") {
      continue;
    }
    const scalarMatch = /^([A-Za-z][A-Za-z0-9]*):(?:\s*(.*))?$/.exec(line);
    if (scalarMatch === null) {
      throw new Error(`${label}: unsupported front matter line ${JSON.stringify(line)}`);
    }
    const key = scalarMatch[1];
    const rest = scalarMatch[2] ?? "";
    if (rest.trim() !== "") {
      result[key] = parseScalar(rest);
      continue;
    }

    const block = [];
    while (index + 1 < lines.length && /^  /.test(lines[index + 1])) {
      block.push(lines[index + 1].slice(2));
      index += 1;
    }
    result[key] = parseBlock(block, label, key);
  }
  return result;
}

function parseBlock(block, label, key) {
  const significant = block.filter((line) => line.trim() !== "");
  if (significant.length === 0) {
    return [];
  }
  if (significant.length === 1 && significant[0].trim() === "[]") {
    return [];
  }
  if (significant.every((line) => line.trimStart().startsWith("- "))) {
    return significant.map((line) => parseScalar(line.trimStart().slice(2)));
  }
  const object = {};
  for (const line of significant) {
    const match = /^([A-Za-z][A-Za-z0-9]*):\s*(.*)$/.exec(line);
    if (match === null) {
      throw new Error(`${label}: unsupported front matter block line for ${key}: ${JSON.stringify(line)}`);
    }
    object[match[1]] = parseScalar(match[2]);
  }
  return object;
}

function parseScalar(raw) {
  const trimmed = raw.trim();
  if (trimmed === "null") return null;
  if (trimmed === "[]") return [];
  if (/^-?\d+$/.test(trimmed)) return Number(trimmed);
  const quoted = /^"([\s\S]*)"$/.exec(trimmed);
  return quoted === null ? trimmed : quoted[1].replace(/\\"/g, "\"");
}

function progressExportSamples() {
  const questionProgress = {
    questionId: "B-001-001-001",
    bankId: "basic-2025-07-15",
    attempts: 1,
    correctAttempts: 1,
    lastAttemptedAt: "2026-01-02T03:04:05.000Z",
    lastResult: "correct",
    recentResults: [true],
    leitner: { box: 1, dueAt: "2026-01-03T03:04:05.000Z" },
    notes: null,
  };
  const examAttempt = {
    id: "attempt-1",
    bankId: "basic-2025-07-15",
    mode: "mock-exam",
    seed: "seed-1",
    startedAt: "2026-01-02T02:00:00.000Z",
    submittedAt: "2026-01-02T03:00:00.000Z",
    timer: { enabled: false, secondsAllowed: null, secondsElapsed: 0 },
    items: [{
      position: 1,
      questionId: "B-001-001-001",
      subsectionId: "B-001-001",
      categoryId: "B-001",
      choicePermutation: [0, 1, 2, 3],
      selectedSourceIndex: 0,
      isCorrect: true,
      flagged: false,
    }],
    score: {
      correct: 1,
      total: 1,
      percent: 100,
      passed: true,
      honours: true,
      categoryBreakdown: [{ categoryId: "B-001", correct: 1, total: 1, percent: 100 }],
      weakSubsectionIds: [],
    },
  };
  return [
    {
      name: "progress-export-v1 full web/apple export sample",
      data: {
        schema: "canadian-ham.progress-export",
        version: 1,
        exportedAt: "2026-01-02T04:00:00.000Z",
        bankId: "basic-2025-07-15",
        questionProgress: [questionProgress],
        examAttempts: [examAttempt],
        lessonProgress: [{ lessonId: "L-005-01", readAt: "2026-01-02T03:30:00.000Z", readCount: 2 }],
        lessonQuizAttempts: [{
          id: "lesson-quiz-1",
          quizId: "QZ-L-005-01-A",
          lessonId: "L-005-01",
          submittedAt: "2026-01-02T03:45:00.000Z",
          correct: 9,
          total: 11,
          percent: 81.81818181818183,
          officialQuestionIds: ["B-005-001-001"],
          incorrectOfficialQuestionIds: [],
          incorrectConceptCheckIds: ["QZ-L-005-01-A-C1"],
        }],
        preferences: { practiceMode: "review-later", examTimerEnabled: true, theme: "dark" },
      },
    },
    {
      name: "progress-export-v1 compatible minimal import sample",
      data: {
        schema: "canadian-ham.progress-export",
        version: 1,
        exportedAt: "2026-01-02T04:00:00.000Z",
        bankId: "basic-2025-07-15",
        questionProgress: [questionProgress],
        examAttempts: [examAttempt],
        preferences: { practiceMode: "immediate", examTimerEnabled: false },
      },
    },
  ];
}
