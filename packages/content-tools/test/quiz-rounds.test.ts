import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { quizRoundIssues } from "../src/quiz-rounds.ts";
import { checkQuizzes } from "../src/check-quizzes.ts";

const ids = ["B-001-001-001", "B-001-001-002"];
const rounds = ["First", "Second"].map((title, index) => ({ sectionAnchor: title.toLowerCase(), title: { en: title, fr: `${title} FR` }, officialQuestionIds: [ids[index]!] }));
const links = new Map(ids.map((id, index) => [id, { lessonId: "L-001-01", sectionAnchor: rounds[index]!.sectionAnchor }]));
function issues(value: unknown, markdown = "## First\n## Second") {
  return quizRoundIssues(value, "L-001-01", ids, 0, markdown, links);
}

test("M1 round checker accepts complete teaching sections in heading order", () => {
  assert.deepEqual(issues(rounds), []);
});
test("M1 round checker rejects missing, duplicate, extra, empty and dropped items", () => {
  for (const value of [undefined, [], [null], [rounds[0]], [...rounds, rounds[0]], [{ ...rounds[0], officialQuestionIds: [] }, rounds[1]], [{ ...rounds[0], officialQuestionIds: ["B-001-001-003"] }, rounds[1]]]) {
    assert.ok(issues(value).length > 0, JSON.stringify(value));
  }
});
test("M1 round checker rejects reversed, repeated and unknown headings or wrong hint sections", () => {
  assert.ok(issues([...rounds].reverse()).some((issue) => issue.includes("heading order")));
  assert.ok(issues([rounds[0], { ...rounds[1], sectionAnchor: "first" }]).some((issue) => issue.includes("heading order")));
  assert.ok(issues(rounds, "## First").some((issue) => issue.includes("heading order")));
  assert.ok(issues([{ ...rounds[0], officialQuestionIds: [ids[1]] }, { ...rounds[1], officialQuestionIds: [ids[0]] }]).some((issue) => issue.includes("hint teaching section")));
});
test("an unknown or reversed section does not reset the highest heading index for later rounds", () => {
  const orderIssues = issues([rounds[1], { ...rounds[0], sectionAnchor: "unknown" }, rounds[0], rounds[1]])
    .filter((issue) => issue.includes("heading order"));
  assert.deepEqual(orderIssues.map((issue) => issue.split(" ")[0]), ["rounds[1]", "rounds[2]", "rounds[3]"]);
});
test("M1 round checker requires localized heading titles and keeps concept checks out", () => {
  for (const title of [{ en: "Wrong", fr: "Faux" }, { en: "First", fr: null }, { en: "First", fr: "" }]) {
    assert.ok(issues([{ ...rounds[0], title }, rounds[1]]).some((issue) => issue.includes("title")));
  }
  assert.ok(quizRoundIssues(rounds, "L-001-01", ids, 1, "## First\n## Second", links).some((issue) => issue.includes("official-only")));
});
test("all real M1 round mappings match hints, heading order and all 199 existing official items", async () => {
  const report = await checkQuizzes();
  assert.deepEqual(report.issues, []);
  let total = 0;
  for (let lesson = 1; lesson <= 6; lesson++) {
    const quiz = JSON.parse(await readFile(new URL(`../../../content/quizzes/QZ-L-001-0${lesson}-A.json`, import.meta.url), "utf8"));
    total += quiz.officialQuestionIds.length;
    assert.deepEqual(new Set(quiz.rounds.flatMap((round: { officialQuestionIds: string[] }) => round.officialQuestionIds)), new Set(quiz.officialQuestionIds));
  }
  assert.equal(total, 199);
});
