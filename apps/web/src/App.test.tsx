import assert from "node:assert/strict";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import axe from "axe-core";
import { IDBFactory } from "fake-indexeddb";
import { afterEach, beforeEach, describe, it } from "vitest";

import { App } from "./App";
import { ProgressStore, type ExamAttempt } from "./lib/progressStore";
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
  const generatedItems = createMockExam(seed);
  return buildExamAttempt({
    seed,
    startedAt: "2026-01-02T00:00:00.000Z",
    submittedAt,
    timerEnabled: false,
    secondsElapsed: 0,
    generatedItems,
    selectedByQuestionId: new Map(generatedItems.map((item) => [item.questionId, 0])),
    flaggedQuestionIds: new Set(),
  });
}

describe("App accessibility and flows", () => {
  it("renders Home readiness states and has no axe violations", async () => {
    const store = createStore("home");
    const firstRender = render(<App store={store} now={() => fixedNow} seedFactory={() => "home-seed"} />);

    assert.match((await screen.findByText("Not enough data")).textContent ?? "", /Not enough data/);
    await expectNoAxeViolations(firstRender.container);

    const readyStore = createStore("ready-home");
    await readyStore.putExamAttempt(allCorrectAttempt("ready-a", "2026-01-02T01:00:00.000Z"));
    await readyStore.putExamAttempt(allCorrectAttempt("ready-b", "2026-01-03T01:00:00.000Z"));
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
    await expectNoAxeViolations(container);
  });
});
