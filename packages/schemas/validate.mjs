#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { parseFrontMatter as parseCanonicalLessonFrontMatter } from "../content-tools/src/check-lesson-coverage.ts";

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
const supportedSchemaKeywords = new Set([
  "$schema",
  "$id",
  "title",
  "$defs",
  "$ref",
  "type",
  "const",
  "enum",
  "oneOf",
  "allOf",
  "properties",
  "required",
  "additionalProperties",
  "items",
  "prefixItems",
  "minItems",
  "maxItems",
  "uniqueItems",
  "minimum",
  "maximum",
  "minLength",
  "maxLength",
  "pattern",
  "canonicalUtcTimestamp",
]);

const canonicalUtcTimestampPattern = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/u;

let validationCount = 0;
const failures = [];

for (const file of schemaFiles) {
  loadSchema(file);
}

for (const bankId of ["basic-2025-07-15", "advanced-2025-02-04"]) {
  validateJsonFile(`content/generated/${bankId}/manifest.json`, "generated-bank-manifest.schema.json");
  validateJsonFile(`content/generated/${bankId}/categories.json`, "generated-bank-categories.schema.json");
  validateJsonFile(`content/generated/${bankId}/questions.json`, "generated-bank-questions.schema.json");
  validateJsonFile(`content/generated/${bankId}/subsections.json`, "generated-bank-subsections.schema.json");
}
validateJsonFile("content/subsection-titles.json", "subsection-titles.schema.json");

for (const file of walk(path.join(projectRoot, "content/lessons"), ".md")) {
  const relative = path.relative(projectRoot, file);
  let frontMatter;
  try {
    frontMatter = parseLessonFrontMatter(fs.readFileSync(file, "utf8"), relative);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (path.basename(relative) === "README.md" && message.includes("missing opening front matter delimiter")) {
      continue;
    }
    failures.push(`${relative}: ${message}`);
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
  for (const error of validateDataAgainstSchema(data, schemaFile)) {
    failures.push(`${label}: ${error}`);
  }
}

export function validateDataAgainstSchema(data, schemaFile) {
  const [rawDocument, pointer = ""] = schemaFile.split("#");
  const documentId = path.basename(rawDocument);
  let schema = loadSchema(documentId);
  if (pointer !== "" && pointer !== "/") {
    const resolved = resolveRef(`#${pointer}`, documentId);
    schema = resolved.schema;
  } else if (documentId === "generated-bank-categories.schema.json") {
    schema = selectGeneratedBankCategoriesSchema(data, documentId) ?? schema;
  }
  return validateAgainstSchema(schema, data, { documentId, path: "$" });
}

function selectGeneratedBankCategoriesSchema(data, documentId) {
  if (!Array.isArray(data) || data.length === 0) {
    return null;
  }
  const bankIds = new Set();
  for (const item of data) {
    if (!isObject(item) || typeof item.bankId !== "string") {
      return null;
    }
    bankIds.add(item.bankId);
  }
  if (bankIds.size !== 1) {
    return null;
  }
  const [bankId] = bankIds;
  if (bankId === "basic-2025-07-15") {
    return resolveRef("#/$defs/basicCategories", documentId).schema;
  }
  if (bankId === "advanced-2025-02-04") {
    return resolveRef("#/$defs/advancedCategories", documentId).schema;
  }
  return null;
}

function loadSchema(schemaFile) {
  const normalized = path.basename(schemaFile);
  if (schemaCache.has(normalized)) {
    return schemaCache.get(normalized);
  }
  const schema = JSON.parse(fs.readFileSync(path.join(schemasDir, normalized), "utf8"));
  validateSchemaKeywords(schema, normalized, "$");
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
    if (!isObject(target) || !Object.hasOwn(target, token)) {
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

  if (Array.isArray(schema.allOf)) {
    for (const branch of schema.allOf) {
      errors.push(...validateAgainstSchema(branch, data, context));
    }
  }

  if (Array.isArray(schema.oneOf)) {
    const selectedBranch = selectOneOfBranchByConstDiscriminator(schema.oneOf, data);
    if (selectedBranch !== null) {
      // Report the selected branch's own errors (clearer than a generic oneOf message), but keep
      // oneOf's "exactly one" rule: no other branch may also validate.
      const selectedErrors = validateAgainstSchema(selectedBranch, data, context);
      errors.push(...selectedErrors);
      const otherPassing = schema.oneOf
        .filter((branch) => branch !== selectedBranch)
        .filter((branch) => validateAgainstSchema(branch, data, context).length === 0).length;
      if (otherPassing > 0) {
        const passing = otherPassing + (selectedErrors.length === 0 ? 1 : 0);
        errors.push(`${context.path}: expected exactly one oneOf branch to match, got ${passing}`);
      }
    } else {
      const branchResults = schema.oneOf.map((branch) => validateAgainstSchema(branch, data, context));
      const passing = branchResults.filter((branchErrors) => branchErrors.length === 0).length;
      if (passing !== 1) {
        const firstReason = branchResults.find((branchErrors) => branchErrors.length > 0)?.[0];
        errors.push(`${context.path}: expected exactly one oneOf branch to match, got ${passing}${firstReason ? `; first mismatch: ${firstReason}` : ""}`);
      }
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
    if (schema.canonicalUtcTimestamp === true && !isCanonicalUtcTimestamp(data)) {
      errors.push(`${context.path}: expected canonical UTC timestamp YYYY-MM-DDTHH:MM:SS.sssZ, got ${JSON.stringify(data)}`);
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
    const prefixItemCount = Array.isArray(schema.prefixItems) ? schema.prefixItems.length : 0;
    if (Array.isArray(schema.prefixItems)) {
      schema.prefixItems.forEach((itemSchema, index) => {
        if (index < data.length) {
          errors.push(...validateAgainstSchema(itemSchema, data[index], { documentId: context.documentId, path: `${context.path}[${index}]` }));
        }
      });
    }
    if (schema.items !== undefined) {
      data.forEach((item, index) => {
        if (prefixItemCount === 0 || index >= prefixItemCount) {
          errors.push(...validateAgainstSchema(schema.items, item, { documentId: context.documentId, path: `${context.path}[${index}]` }));
        }
      });
    }
  }

  if (isObject(data)) {
    const properties = isObject(schema.properties) ? schema.properties : {};
    if (Array.isArray(schema.required)) {
      for (const key of schema.required) {
        if (!Object.hasOwn(data, key)) {
          errors.push(`${context.path}: missing required property ${key}`);
        }
      }
    }
    for (const [key, propertySchema] of Object.entries(properties)) {
      if (Object.hasOwn(data, key)) {
        errors.push(...validateAgainstSchema(propertySchema, data[key], { documentId: context.documentId, path: `${context.path}.${key}` }));
      }
    }
    if (schema.additionalProperties === false) {
      for (const key of Object.keys(data)) {
        if (!Object.hasOwn(properties, key)) {
          errors.push(`${context.path}: unexpected property ${key}`);
        }
      }
    } else if (isObject(schema.additionalProperties)) {
      for (const [key, value] of Object.entries(data)) {
        if (!Object.hasOwn(properties, key)) {
          errors.push(...validateAgainstSchema(schema.additionalProperties, value, { documentId: context.documentId, path: `${context.path}.${key}` }));
        }
      }
    }
  }

  return errors;
}

// Returns the single branch selected by a true discriminator: a property that every branch
// requires and pins with `const`. Anything looser falls back to plain oneOf evaluation.
export function selectOneOfBranchByConstDiscriminator(branches, data) {
  if (!isObject(data) || branches.length === 0 || !branches.every((branch) => isObject(branch) && isObject(branch.properties))) {
    return null;
  }
  const discriminatorKeys = Object.keys(branches[0].properties).filter((key) => branches.every((branch) => (
    Array.isArray(branch.required)
    && branch.required.includes(key)
    && isObject(branch.properties[key])
    && Object.hasOwn(branch.properties[key], "const")
  )));
  for (const key of discriminatorKeys) {
    if (!Object.hasOwn(data, key)) {
      continue;
    }
    const matchingBranches = branches.filter((branch) => deepEqual(data[key], branch.properties[key].const));
    if (matchingBranches.length === 1) {
      return matchingBranches[0];
    }
  }
  return null;
}

function validateSchemaKeywords(schema, schemaFile, schemaPath) {
  if (typeof schema === "boolean") {
    return;
  }
  if (!isObject(schema)) {
    throw new Error(`${schemaFile}: schema at ${schemaPath} must be an object or boolean`);
  }

  for (const keyword of Object.keys(schema)) {
    if (!supportedSchemaKeywords.has(keyword)) {
      throw new Error(`${schemaFile}: unsupported schema keyword ${JSON.stringify(keyword)} at ${schemaPath}`);
    }
  }

  if (Object.hasOwn(schema, "canonicalUtcTimestamp") && schema.canonicalUtcTimestamp !== true) {
    throw new Error(`${schemaFile}: schema keyword "canonicalUtcTimestamp" at ${schemaPath} must be true`);
  }

  if (Object.hasOwn(schema, "$ref")) {
    for (const keyword of Object.keys(schema)) {
      if (keyword !== "$ref") {
        throw new Error(`${schemaFile}: unsupported $ref sibling keyword ${JSON.stringify(keyword)} at ${schemaPath}`);
      }
    }
    return;
  }

  if (Object.hasOwn(schema, "$defs")) {
    if (!isObject(schema.$defs)) {
      throw new Error(`${schemaFile}: schema keyword "$defs" at ${schemaPath} must be an object`);
    }
    for (const [name, childSchema] of Object.entries(schema.$defs)) {
      validateSchemaKeywords(childSchema, schemaFile, `${schemaPath}.$defs.${escapeSchemaPathSegment(name)}`);
    }
  }

  if (Object.hasOwn(schema, "properties")) {
    if (!isObject(schema.properties)) {
      throw new Error(`${schemaFile}: schema keyword "properties" at ${schemaPath} must be an object`);
    }
    for (const [name, propertySchema] of Object.entries(schema.properties)) {
      validateSchemaKeywords(propertySchema, schemaFile, `${schemaPath}.properties.${escapeSchemaPathSegment(name)}`);
    }
  }

  if (Object.hasOwn(schema, "oneOf")) {
    if (!Array.isArray(schema.oneOf)) {
      throw new Error(`${schemaFile}: schema keyword "oneOf" at ${schemaPath} must be an array`);
    }
    schema.oneOf.forEach((branch, index) => {
      validateSchemaKeywords(branch, schemaFile, `${schemaPath}.oneOf[${index}]`);
    });
  }

  if (Object.hasOwn(schema, "allOf")) {
    if (!Array.isArray(schema.allOf)) {
      throw new Error(`${schemaFile}: schema keyword "allOf" at ${schemaPath} must be an array`);
    }
    schema.allOf.forEach((branch, index) => {
      validateSchemaKeywords(branch, schemaFile, `${schemaPath}.allOf[${index}]`);
    });
  }

  if (Object.hasOwn(schema, "prefixItems")) {
    if (!Array.isArray(schema.prefixItems)) {
      throw new Error(`${schemaFile}: schema keyword "prefixItems" at ${schemaPath} must be an array`);
    }
    schema.prefixItems.forEach((itemSchema, index) => {
      validateSchemaKeywords(itemSchema, schemaFile, `${schemaPath}.prefixItems[${index}]`);
    });
  }

  if (Object.hasOwn(schema, "items")) {
    validateSchemaKeywords(schema.items, schemaFile, `${schemaPath}.items`);
  }

  if (isObject(schema.additionalProperties)) {
    validateSchemaKeywords(schema.additionalProperties, schemaFile, `${schemaPath}.additionalProperties`);
  }
}

function escapeSchemaPathSegment(segment) {
  return /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(segment) ? segment : JSON.stringify(segment);
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

// Mirrors the engine/importer timestamp contract: the literal canonical UTC
// millisecond shape must also round-trip through the calendar/time parser.
function isCanonicalUtcTimestamp(value) {
  if (!canonicalUtcTimestampPattern.test(value)) {
    return false;
  }
  const epochMilliseconds = Date.parse(value);
  return !Number.isNaN(epochMilliseconds) && new Date(epochMilliseconds).toISOString() === value;
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

export function parseLessonFrontMatter(raw, label) {
  return parseCanonicalLessonFrontMatter(raw, label);
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
  const fractionalTimerExamAttempt = {
    ...examAttempt,
    id: "attempt-fractional-timer",
    submittedAt: "2026-01-02T03:15:00.000Z",
    timer: { enabled: true, secondsAllowed: 3600.5, secondsElapsed: 12.5 },
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
        examAttempts: [fractionalTimerExamAttempt],
        preferences: { practiceMode: "immediate", examTimerEnabled: false },
      },
    },
  ];
}
