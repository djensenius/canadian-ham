#!/usr/bin/env node
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const DEFAULT_PERMISSION_PATH = "docs/content-licensing.md";

export function extractPermissionRecord(markdown) {
  const headingMatch = markdown.match(/^## Permission record\s*$/mu);
  if (headingMatch === null || headingMatch.index === undefined) {
    throw new Error("docs/content-licensing.md does not contain a '## Permission record' section.");
  }

  const sectionStart = headingMatch.index + headingMatch[0].length;
  const rest = markdown.slice(sectionStart);
  const nextHeading = rest.search(/^##\s+/mu);
  const section = nextHeading === -1 ? rest : rest.slice(0, nextHeading);
  const fields = new Map();

  for (const line of section.split(/\r?\n/u)) {
    const trimmed = line.trim();
    if (!trimmed.startsWith("|") || /^\|\s*-+\s*\|/u.test(trimmed) || /^\|\s*Field\s*\|/iu.test(trimmed)) {
      continue;
    }
    const cells = trimmed
      .slice(1, trimmed.endsWith("|") ? -1 : undefined)
      .split("|")
      .map((cell) => cell.trim());
    if (cells.length >= 2) {
      fields.set(cells[0], cells.slice(1).join(" | "));
    }
  }

  return fields;
}

export function checkReleasePermission(markdown) {
  const fields = extractPermissionRecord(markdown);
  const requestStatus = fields.get("Request status") ?? "";
  const referenceNumber = fields.get("ISED reference number") ?? "";
  const permissionDate = fields.get("Permission date") ?? "";

  const errors = [];
  if (!isGrantedStatus(requestStatus)) {
    errors.push("Request status must record ISED permission as granted.");
  }
  if (!isConcreteValue(referenceNumber)) {
    errors.push("ISED reference number must be recorded.");
  }
  const permissionDateMatch = permissionDate.match(/\b(\d{4}-\d{2}-\d{2})\b/u);
  if (!isConcreteValue(permissionDate) || permissionDateMatch === null || !isValidIsoDate(permissionDateMatch[1])) {
    errors.push("Permission date must be recorded in YYYY-MM-DD form.");
  }

  return {
    ok: errors.length === 0,
    errors,
  };
}

function isGrantedStatus(value) {
  const normalized = value.trim().toLowerCase();
  if (/\bnot\s+(?:yet\s+)?granted\b/u.test(normalized)) {
    return false;
  }
  if (/\b(revoked|withdrawn|rescinded|cancell?ed|expired|suspended)\b/u.test(normalized)) {
    return false;
  }

  // The status cell has several `;`-separated parts (e.g. "Drafted (...); sent: ...; granted: ...").
  // Exactly one part may mention a grant, and it must be the whole part: "granted: yes" or
  // "granted: YYYY-MM-DD", optionally followed by one bracketed note.
  const grantParts = normalized
    .split(";")
    .map((part) => part.trim())
    .filter((part) => /\bgranted\b/u.test(part));
  if (grantParts.length !== 1) {
    return false;
  }

  const grantMatch = grantParts[0].match(/^granted\s*:\s*(yes|\d{4}-\d{2}-\d{2})(?:\s*\([^)]*\))?$/u);
  if (grantMatch === null) {
    return false;
  }

  const grantedValue = grantMatch[1];
  return grantedValue === "yes" || isValidIsoDate(grantedValue);
}

function isValidIsoDate(value) {
  const match = value.match(/^(\d{4})-(\d{2})-(\d{2})$/u);
  if (match === null) {
    return false;
  }

  const [, yearText, monthText, dayText] = match;
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);
  if (month < 1 || month > 12) {
    return false;
  }

  const daysInMonth = [31, isLeapYear(year) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  return day >= 1 && day <= daysInMonth;
}

function isLeapYear(year) {
  return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
}

function isConcreteValue(value) {
  const normalized = value.trim().toLowerCase();
  return normalized.length > 0 && !/\b(pending|todo|tbd|fill\s+in|not\s+recorded)\b/u.test(normalized);
}

async function runCli(argv) {
  if (argv.includes("--self-test")) {
    runSelfTest();
    console.log("release permission gate self-test passed.");
    return 0;
  }

  const target = argv.find((arg) => !arg.startsWith("-")) ?? DEFAULT_PERMISSION_PATH;
  const markdown = await readFile(path.resolve(process.cwd(), target), "utf8");
  const result = checkReleasePermission(markdown);
  if (!result.ok) {
    console.error("release permission gate failed:");
    for (const error of result.errors) {
      console.error(`- ${error}`);
    }
    return 1;
  }
  console.log("release permission gate passed: ISED permission is recorded as granted with a reference number and date.");
  return 0;
}

function runSelfTest() {
  const pending = permissionRecord({
    status: "Drafted (2026-09-28 owner decision); sent: pending; granted: pending",
    reference: "Pending: fill in permission reference number",
    date: "Pending: fill in permission date",
  });
  assert.deepEqual(checkReleasePermission(pending), {
    ok: false,
    errors: [
      "Request status must record ISED permission as granted.",
      "ISED reference number must be recorded.",
      "Permission date must be recorded in YYYY-MM-DD form.",
    ],
  });

  assert.deepEqual(checkReleasePermission(permissionRecord({
    status: "Granted: yes (written permission received)",
    reference: VALID_REFERENCE,
    date: VALID_PERMISSION_DATE,
  })), { ok: true, errors: [] });

  assert.deepEqual(checkReleasePermission(permissionRecord({
    status: "Granted: 2026-10-02 (written permission received)",
    reference: VALID_REFERENCE,
    date: VALID_PERMISSION_DATE,
  })), { ok: true, errors: [] });

  for (const status of [
    "Granted: no",
    "Granted: refused",
    "Granted: denied",
    "Granted: pending",
    "Granted: TBD",
    "Granted: not yet",
    "Not yet granted",
    "Not granted",
    "Permission requested; awaiting reply",
    "Granted: 2026-02-30",
    "Granted: yes but revoked 2026-11-01",
    "Sent: yes; granted: pending; granted: yes",
    "Granted: yes-ish",
    "Granted: 2026-10-02-revoked",
    "Granted: yes; later withdrawn",
  ]) {
    assert.deepEqual(checkReleasePermission(permissionRecord({
      status,
      reference: VALID_REFERENCE,
      date: VALID_PERMISSION_DATE,
    })), {
      ok: false,
      errors: ["Request status must record ISED permission as granted."],
    });
  }

  const impossibleDate = permissionRecord({
    status: "Granted: yes",
    reference: VALID_REFERENCE,
    date: "2026-13-40",
  });
  assert.deepEqual(checkReleasePermission(impossibleDate), {
    ok: false,
    errors: ["Permission date must be recorded in YYYY-MM-DD form."],
  });

  const missingDate = permissionRecord({
    status: "Granted: yes",
    reference: VALID_REFERENCE,
    date: "October 2, 2026",
  });
  assert.deepEqual(checkReleasePermission(missingDate), {
    ok: false,
    errors: ["Permission date must be recorded in YYYY-MM-DD form."],
  });
}

const VALID_REFERENCE = "ISED-ABC-12345";
const VALID_PERMISSION_DATE = "2026-10-02";

function permissionRecord({ status, reference, date }) {
  return `# Content licensing and attribution plan\n\n## Permission record\n\n| Field | Value |\n|---|---|\n| Permission holder | Owner / project maintainer |\n| Request status | ${status} |\n| ISED reference number | ${reference} |\n| Permission date | ${date} |\n\n## Interim private-development policy\n`;
}

function isDirectCliInvocation() {
  return process.argv[1] !== undefined && fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);
}

if (isDirectCliInvocation()) {
  runCli(process.argv.slice(2)).then((exitCode) => {
    process.exitCode = exitCode;
  }).catch((error) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`release permission gate error: ${message}`);
    process.exitCode = 1;
  });
}
