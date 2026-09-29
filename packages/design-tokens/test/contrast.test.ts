import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { contrastRatio, contrastRows, type TokenSet } from "../src/token-utils.ts";

const tokens = JSON.parse(await readFile(new URL("../tokens.json", import.meta.url), "utf8")) as TokenSet & {
  readonly typography: { readonly scale: Record<string, unknown> };
};
const schema = JSON.parse(await readFile(new URL("../tokens.schema.json", import.meta.url), "utf8")) as JsonSchema;

type JsonSchema = {
  readonly $ref?: string;
  readonly type?: "object" | "array" | "string" | "number" | "boolean" | "null";
  readonly enum?: readonly unknown[];
  readonly required?: readonly string[];
  readonly properties?: Record<string, JsonSchema>;
  readonly additionalProperties?: boolean | JsonSchema;
  readonly items?: JsonSchema;
  readonly pattern?: string;
  readonly minItems?: number;
  readonly minProperties?: number;
  readonly minimum?: number;
  readonly exclusiveMinimum?: number;
  readonly $defs?: Record<string, JsonSchema>;
};

function resolveRef(ref: string, root: JsonSchema): JsonSchema {
  const prefix = "#/$defs/";
  if (!ref.startsWith(prefix)) {
    throw new Error(`Unsupported schema $ref: ${ref}`);
  }
  const name = ref.slice(prefix.length);
  const resolved = root.$defs?.[name];
  if (resolved === undefined) {
    throw new Error(`Unresolved schema $ref: ${ref}`);
  }
  return resolved;
}

function valueType(value: unknown): JsonSchema["type"] {
  if (Array.isArray(value)) return "array";
  if (value === null) return "null";
  return typeof value as JsonSchema["type"];
}

function validateAgainstSchema(value: unknown, schemaNode: JsonSchema, root: JsonSchema, location = "$", errors: string[] = []): string[] {
  const node = schemaNode.$ref === undefined ? schemaNode : resolveRef(schemaNode.$ref, root);
  if (node.type !== undefined && valueType(value) !== node.type) {
    errors.push(`${location} must be ${node.type}, got ${valueType(value)}`);
    return errors;
  }
  if (node.enum !== undefined && !node.enum.includes(value)) {
    errors.push(`${location} must be one of ${node.enum.join(", ")}`);
  }
  if (node.type === "string" && typeof value === "string" && node.pattern !== undefined && !new RegExp(node.pattern).test(value)) {
    errors.push(`${location} must match ${node.pattern}`);
  }
  if (node.type === "number" && typeof value === "number") {
    if (node.minimum !== undefined && value < node.minimum) {
      errors.push(`${location} must be >= ${node.minimum}`);
    }
    if (node.exclusiveMinimum !== undefined && value <= node.exclusiveMinimum) {
      errors.push(`${location} must be > ${node.exclusiveMinimum}`);
    }
  }
  if (node.type === "array" && Array.isArray(value)) {
    if (node.minItems !== undefined && value.length < node.minItems) {
      errors.push(`${location} must contain at least ${node.minItems} items`);
    }
    if (node.items !== undefined) {
      value.forEach((item, index) => validateAgainstSchema(item, node.items!, root, `${location}[${index}]`, errors));
    }
  }
  if (node.type === "object" && typeof value === "object" && value !== null && !Array.isArray(value)) {
    const record = value as Record<string, unknown>;
    if (node.minProperties !== undefined && Object.keys(record).length < node.minProperties) {
      errors.push(`${location} must contain at least ${node.minProperties} properties`);
    }
    for (const requiredKey of node.required ?? []) {
      if (!(requiredKey in record)) {
        errors.push(`${location}.${requiredKey} is required`);
      }
    }
    const properties = node.properties ?? {};
    for (const [key, propertyValue] of Object.entries(record)) {
      if (properties[key] !== undefined) {
        validateAgainstSchema(propertyValue, properties[key], root, `${location}.${key}`, errors);
      } else if (node.additionalProperties === false) {
        errors.push(`${location}.${key} is not allowed`);
      } else if (typeof node.additionalProperties === "object") {
        validateAgainstSchema(propertyValue, node.additionalProperties, root, `${location}.${key}`, errors);
      }
    }
  }
  return errors;
}

function assertRowsMeetThreshold(rows: ReturnType<typeof contrastRows>): void {
  for (const row of rows) {
    assert.ok(
      row.ratio >= row.minimum,
      `${row.id} contrast ${row.ratio.toFixed(2)} is below ${row.minimum.toFixed(1)} for ${row.kind}`,
    );
  }
}

test("tokens.json matches tokens.schema.json", () => {
  const errors = validateAgainstSchema(tokens, schema, schema);
  assert.deepEqual(errors, []);
});

test("contrast ratio has a known black/white reference value", () => {
  assert.equal(contrastRatio("#000000", "#FFFFFF"), 21);
});

test("contrast rows reject an empty contrastPairs list", () => {
  assert.throws(() => contrastRows({ themes: tokens.themes, contrastPairs: [] }), /At least one contrast pair/);
});

test("contrast threshold assertion fails a known bad pair", () => {
  const badTokens: TokenSet = {
    themes: { light: { colors: { foreground: "#777777", background: "#777777" } } },
    contrastPairs: [{ id: "bad-body", theme: "light", foreground: "foreground", background: "background", kind: "body" }],
  };
  assert.throws(() => assertRowsMeetThreshold(contrastRows(badTokens)), /bad-body contrast 1\.00 is below 4\.5/);
});

test("light and dark themes expose the same colour keys", () => {
  const lightKeys = Object.keys(tokens.themes.light.colors).sort();
  const darkKeys = Object.keys(tokens.themes.dark.colors).sort();
  assert.deepEqual(darkKeys, lightKeys);
});

test("every typography step declares an Apple text style", () => {
  for (const [name, rawStep] of Object.entries(tokens.typography.scale)) {
    const step = rawStep as { readonly appleTextStyle?: unknown };
    assert.equal(typeof step.appleTextStyle, "string", `${name} must declare appleTextStyle`);
    assert.notEqual(step.appleTextStyle, "", `${name} appleTextStyle must not be empty`);
  }
});

test("declared foreground/background contrast pairs meet WCAG 2.2 AA thresholds", () => {
  const rows = contrastRows(tokens);
  assert.ok(rows.length > 0, "contrastPairs must not be empty");
  const table = rows.map((row) => ({
    id: row.id,
    theme: row.theme,
    kind: row.kind,
    ratio: row.ratio.toFixed(2),
    minimum: row.minimum.toFixed(1),
  }));
  console.table(table);

  assertRowsMeetThreshold(rows);
});
