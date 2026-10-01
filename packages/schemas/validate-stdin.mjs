#!/usr/bin/env node
import process from "node:process";

import { validateDataAgainstSchema } from "./validate.mjs";

const schemaFile = process.argv[2];
if (schemaFile === undefined) {
  console.error("Usage: node packages/schemas/validate-stdin.mjs <schema-file>");
  process.exit(2);
}

const input = await readStdin();
const data = JSON.parse(input);
const errors = validateDataAgainstSchema(data, schemaFile);
if (errors.length > 0) {
  console.error(`Schema validation failed for stdin against ${schemaFile}:`);
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log(`Schema validation passed for stdin against ${schemaFile}.`);

function readStdin() {
  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => {
      data += chunk;
    });
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", reject);
  });
}
