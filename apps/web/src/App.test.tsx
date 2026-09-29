import assert from "node:assert/strict";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import axe from "axe-core";
import { IDBFactory } from "fake-indexeddb";
import { afterEach, beforeEach, describe, it, vi } from "vitest";

import { App } from "./App";
import { bankId, questions } from "./data/bank";
import { ProgressStore, defaultPreferences, type ExamAttempt, type ProgressExportV1 } from "./lib/progressStore";
import { buildExamAttempt, createMockExam } from "./lib/studyEngine";

const fixedNow = "2026-01-02T03:04:05.000Z";
let stores: ProgressStore[] = [];

beforeEach(() => {
  Object.defineProperty(globalThis, "indexedDB", { value: new IDBFactory(), configurable: true });
  window.location.hash = "#/home";
  stores = [];
});

afterEach(async () => {
  cleanup();
  for (const store of stores) {
    await store.deleteDatabase();
  }
});

function createStore(name: string): ProgressStore {
  const store = new ProgressStore(name);
  stores.push(store);
  return store;
}

async function expectNoAxeViolations(container: Element): Promise<void> {
  const results = await axe.run(container);
  assert.deepEqual(results.violations, []);
}

function allCorrectAttempt(seed: string, submittedAt: string): ExamAttempt {
  return attemptWithCorrectCount(seed, submittedAt, 100);
}

function attemptWithCorrectCount(seed: string, submittedAt: string, correctCount: number): ExamAttempt {
  const generatedItems = createMockExam(seed);
  return buildExamAttempt({
    seed,
    startedAt: "2026-01-02T00:00:00.000Z",
    submittedAt,
    timerEnabled: false,
    secondsElapsed: 0,
    generatedItems,
    selectedByQuestionId: new Map(generatedItems.map((item, index) => [item.questionId, index < correctCount ? 0 : 1])),
    flaggedQuestionIds: new Set(),
  });
}

function readinessAttempt(seed: string, submittedAt: string, percent: number): ExamAttempt {
  const correctPerCategory = percent >= 80 ? 10 : percent >= 70 ? 7 : 6;
  return {
    ...allCorrectAttempt(seed, submittedAt),
    items: [],
    score: {
      correct: percent,
      total: 100,
      percent,
      passed: percent >= 70,
      honours: percent >= 80,
      categoryBreakdown: Array.from({ length: 8 }, (_, index) => ({
        categoryId: `B-${String(index + 1).padStart(3, "0")}`,
        correct: correctPerCategory,
        total: 10,
        percent: correctPerCategory * 10,
      })),
      weakSubsectionIds: [],
    },
  };
}

function progressExport(): ProgressExportV1 {
  return {
    schema: "canadian-ham.progress-export",
    version: 1,
    exportedAt: fixedNow,
    bankId,
    questionProgress: [],
    examAttempts: [allCorrectAttempt("imported", "2026-01-02T04:00:00.000Z")],
    preferences: defaultPreferences,
  };
}

describe("App accessibility and flows", () => {
  it("renders all Home readiness states and has no axe violations", async () => {
    const store = createStore("home");
    const firstRender = render(<App store={store} now={() => fixedNow} seedFactory={() => "home-seed"} />);

    assert.match((await screen.findByText("Not enough data")).textContent ?? "", /Not enough data/);
    await expectNoAxeViolations(firstRender.container);

    const needsReviewStore = createStore("needs-review-home");
    await needsReviewStore.putExamAttempt(readinessAttempt("needs-a", "2026-01-02T01:00:00.000Z", 85));
    await needsReviewStore.putExamAttempt(readinessAttempt("needs-b", "2026-01-03T01:00:00.000Z", 85));
    for (const question of questions.slice(0, 5)) {
      await needsReviewStore.putQuestionProgress({
        questionId: question.id,
        bankId,
        attempts: 1,
        correctAttempts: 0,
        lastAttemptedAt: "2026-01-01T00:00:00.000Z",
        lastResult: "incorrect",
        recentResults: [false],
        leitner: { box: 0, dueAt: "2026-01-01T00:00:00.000Z" },
        notes: null,
      });
    }
    cleanup();
    render(<App store={needsReviewStore} now={() => fixedNow} seedFactory={() => "home-seed"} />);
    assert.match((await screen.findByText("Needs review")).textContent ?? "", /Needs review/);

    const passStore = createStore("pass-home");
    await passStore.putExamAttempt(readinessAttempt("pass-a", "2026-01-02T01:00:00.000Z", 75));
    await passStore.putExamAttempt(readinessAttempt("pass-b", "2026-01-03T01:00:00.000Z", 75));
    cleanup();
    render(<App store={passStore} now={() => fixedNow} seedFactory={() => "home-seed"} />);
    assert.match((await screen.findByText("Pass-ready")).textContent ?? "", /Pass-ready/);

    const readyStore = createStore("ready-home");
    await readyStore.putExamAttempt(readinessAttempt("ready-a", "2026-01-02T01:00:00.000Z", 85));
    await readyStore.putExamAttempt(readinessAttempt("ready-b", "2026-01-03T01:00:00.000Z", 85));
    cleanup();
    render(<App store={readyStore} now={() => fixedNow} seedFactory={() => "home-seed"} />);
    assert.match((await screen.findByText("Honours-ready")).textContent ?? "", /Honours-ready/);
  });

  it("renders Practice with immediate feedback, progress persistence, and no axe violations", async () => {
    window.location.hash = "#/practice";
    const store = createStore("practice");
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "practice-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    await expectNoAxeViolations(container);

    const choices = screen.getAllByTestId("answer-choice");
    fireEvent.click(choices[0]!);
    await screen.findByRole("status");
    await waitFor(async () => assert.equal((await store.getQuestionProgress()).length, 1));
  });

  it("renders Mock exam, supports keyboard operation, and has no axe violations", async () => {
    window.location.hash = "#/mock";
    const store = createStore("mock");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "mock-seed"} />);

    await screen.findByRole("heading", { name: "Mock exam" });
    await expectNoAxeViolations(container);

    await user.click(screen.getByRole("button", { name: "Start mock exam" }));
    await screen.findByText(/Question 1 of 100/);
    const firstChoice = screen.getAllByTestId("answer-choice")[0]!;
    firstChoice.focus();
    await user.keyboard("{Enter}");
    assert.equal(firstChoice.getAttribute("aria-pressed"), "true");

    const flag = screen.getByRole("button", { name: "Flag for review" });
    flag.focus();
    await user.keyboard("{Enter}");
    assert.ok(screen.getByRole("button", { name: "Remove flag" }));

    const questionTwo = screen.getByRole("button", { name: /Question 2, unanswered/ });
    questionTwo.focus();
    await user.keyboard("{Enter}");
    assert.match(screen.getByLabelText("Mock exam progress").textContent ?? "", /Question 2 of 100/);
    await expectNoAxeViolations(container);
  });

  it("shows Results boundary messages at 69, 70, 79, and 80 percent", async () => {
    const cases = [
      { correct: 69, message: /Below pass threshold/ },
      { correct: 70, message: /Pass achieved/ },
      { correct: 79, message: /Pass achieved/ },
      { correct: 80, message: /Basic with Honours ready/ },
    ];

    for (const [index, testCase] of cases.entries()) {
      window.location.hash = "#/results";
      const store = createStore(`results-${testCase.correct}`);
      await store.putExamAttempt(attemptWithCorrectCount(`score-${testCase.correct}`, `2026-01-02T01:${String(index).padStart(2, "0")}:00.000Z`, testCase.correct));
      render(<App store={store} now={() => fixedNow} seedFactory={() => "score-seed"} />);
      await screen.findByRole("heading", { name: "Mock exam results" });
      assert.match(screen.getByText(testCase.message).textContent ?? "", testCase.message);
      cleanup();
    }
  });

  it("supports review-later practice submission and review", async () => {
    window.location.hash = "#/practice";
    const store = createStore("review-later");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "review-later-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await user.click(screen.getByLabelText("Review later"));
    for (let index = 0; index < 10; index += 1) {
      await user.click(screen.getAllByTestId("answer-choice")[0]!);
      const next = screen.getByRole("button", { name: "Next" });
      if (!next.hasAttribute("disabled")) {
        await user.click(next);
      }
    }
    await user.click(screen.getByRole("button", { name: "Submit practice set" }));
    await screen.findByRole("heading", { name: "Practice set review" });
    assert.equal((await store.getQuestionProgress()).length, 10);
  });

  it("surfaces Settings import/reset UI errors and confirmations with focus management", async () => {
    window.location.hash = "#/settings";
    const store = createStore("settings");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "settings-seed"} />);

    await screen.findByRole("heading", { name: "Settings and local data" });
    const fileInput = screen.getByLabelText("Import progress JSON");
    await user.upload(fileInput, new File(["{not json"], "bad.json", { type: "application/json" }));
    await screen.findByRole("alert");
    assert.match(screen.getByRole("alert").textContent ?? "", /not valid JSON/);

    await user.upload(fileInput, new File([JSON.stringify(progressExport())], "progress.json", { type: "application/json" }));
    await screen.findByText(/Import file is valid/);
    await user.click(screen.getByRole("button", { name: "Confirm import and replace local data" }));
    await screen.findByText(/Import complete/);
    assert.equal((await store.getExamAttempts()).length, 1);
    assert.equal(document.activeElement?.getAttribute("role"), "status");

    const resetButton = screen.getByRole("button", { name: "Reset all data" });
    await user.click(resetButton);
    const dialog = await screen.findByRole("alertdialog", { name: "Reset all local data?" });
    assert.equal(document.activeElement, dialog);
    await user.click(screen.getByRole("button", { name: "Cancel reset" }));
    assert.equal(document.activeElement, resetButton);
    await user.click(resetButton);
    await user.click(screen.getByRole("button", { name: "Confirm reset all data" }));
    await screen.findByText(/All local progress was reset/);
    assert.equal((await store.getExamAttempts()).length, 0);
  });

  it("announces timer start, pause, and resume without making the visible timer live", async () => {
    window.location.hash = "#/mock";
    const store = createStore("timer");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "timer-seed"} />);

    await user.click(await screen.findByLabelText("Enable optional timer"));
    await user.click(screen.getByRole("button", { name: "Start mock exam" }));
    const timer = screen.getByRole("timer");
    assert.equal(timer.getAttribute("aria-live"), "off");
    assert.match(screen.getByRole("status").textContent ?? "", /Timer started/);
    await user.click(screen.getByRole("button", { name: "Pause timer" }));
    assert.match(screen.getByRole("status").textContent ?? "", /Timer paused/);
    await user.click(screen.getByRole("button", { name: "Resume timer" }));
    assert.match(screen.getByRole("status").textContent ?? "", /Timer resumed/);
  });

  it("allows Tab traversal inside the question navigator", async () => {
    window.location.hash = "#/mock";
    const store = createStore("navigator-tab");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "navigator-seed"} />);

    await user.click(await screen.findByRole("button", { name: "Start mock exam" }));
    const firstNavigatorButton = screen.getByRole("button", { name: /Question 1, current, unanswered/ });
    firstNavigatorButton.focus();
    await user.tab();
    assert.equal(document.activeElement, screen.getByRole("button", { name: /Question 2, unanswered/ }));
  });

  it("submits a mock exam to Results with unanswered questions listed and no axe violations", async () => {
    window.location.hash = "#/mock";
    const store = createStore("results");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "results-seed"} />);

    await user.click(await screen.findByRole("button", { name: "Start mock exam" }));
    await user.click(screen.getAllByTestId("answer-choice")[0]!);
    await user.click(screen.getByRole("button", { name: "Submit exam" }));
    assert.match(screen.getByText(/unanswered questions will be scored incorrect/).textContent ?? "", /99/);
    await user.click(screen.getByRole("button", { name: "Confirm submit" }));

    await screen.findByRole("heading", { name: "Mock exam results" });
    assert.match(screen.getByText(/Pass threshold is 70%; honours threshold is 80%/).textContent ?? "", /70%/);
    assert.equal((await store.getExamAttempts()).length, 1);
    assert.equal(document.activeElement?.tagName, "MAIN");

    await user.click(screen.getByRole("button", { name: "Mock exam" }));
    await screen.findByRole("button", { name: "Start mock exam" });
    assert.equal((await store.getExamAttempts()).length, 1);
    await expectNoAxeViolations(container);
  });
});
