#!/usr/bin/env node
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const root = new URL("../", import.meta.url);
const read = (path) => readFileSync(new URL(path, root), "utf8");
const lesson = read("content/lessons/m2-operating-procedures/l-002-01-voice-repeater-and-simplex-procedure.md");
const source = read("apps/apple/Platforms/watchOS/WatchAlphabetReference.swift");

// Parse only the explicitly named ITU table, not unrelated lesson prose/tables.
function checkReference(lesson, source) {
  const table = lesson.match(/\| Letter \| ITU word \| Letter \| ITU word \|\r?\n([\s\S]*?)(?:\r?\n){2}/)?.[1];
  assert.ok(table, "L-002-01 must contain its ITU phonetic table");
  const lessonEntries = [...table.matchAll(/^\| ([A-Z]) \| ([^|]+?) \| ([A-Z]) \| ([^|]+?) \|$/gm)]
    .flatMap(([, first, firstWord, second, secondWord]) => [[first, firstWord], [second, secondWord]])
    .sort(([a], [b]) => a.localeCompare(b));
  const watchEntries = [...source.matchAll(/^\s*\("([A-Z])", "([^"]+)"\),$/gm)]
    .map(([, letter, word]) => [letter, word]);
  const alphabet = [..."ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
  assert.deepEqual(lessonEntries.map(([letter]) => letter), alphabet, "Lesson table must cover A–Z exactly once");
  assert.deepEqual(watchEntries.map(([letter]) => letter), alphabet, "Watch reference must cover A–Z exactly once, in order");
  assert.deepEqual(watchEntries, lessonEntries, "Watch ITU spellings must match L-002-01 verbatim");
}

if (process.argv.includes("--self-test")) {
  checkReference(lesson, source);
  for (const [name, mutated] of [
    ["alternate Alfa spelling", source.replace('("A", "Alfa")', '("A", "Alpha")')],
    ["duplicate letter", source.replace('("B", "Bravo")', '("A", "Bravo")')],
    ["missing Z", source.replace(/^\s*\("Z", "Zulu"\),$/m, "")],
    ["changed Juliett spelling", source.replace('("J", "Juliett")', '("J", "Juliet")')],
  ]) {
    assert.notEqual(mutated, source, `Fixture must mutate: ${name}`);
    assert.throws(() => checkReference(lesson, mutated), undefined, name);
  }
  assert.throws(() => checkReference(lesson.replace("| Letter | ITU word | Letter | ITU word |", ""), source));
  console.log("Watch alphabet reference self-test passed (spellings, duplicate, missing entry, missing table).");
} else {
  checkReference(lesson, source);
  console.log("Watch alphabet reference matches all 26 L-002-01 ITU phonetic spellings (including Alfa and Juliett).");
}
