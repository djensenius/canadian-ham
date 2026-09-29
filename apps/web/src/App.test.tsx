import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import axe from "axe-core";
import { IDBFactory } from "fake-indexeddb";
import { afterEach, beforeEach, describe, it, vi } from "vitest";

import { App, AppErrorBoundary } from "./App";
import { bankId, loadQuestions, loadQuestionsFromUrl, type Question } from "./data/bank";
import { ProgressStore, defaultPreferences, type ExamAttempt, type ProgressExportV1 } from "./lib/progressStore";
import { applyThemePreference, readStoredThemePreference, THEME_COLORS, THEME_STORAGE_KEY } from "./lib/theme";
import { buildExamAttempt, createMockExam } from "./lib/studyEngine";

const fixedNow = "2026-01-02T03:04:05.000Z";
let stores: ProgressStore[] = [];
let testQuestions: readonly Question[] = [];

beforeEach(async () => {
  Object.defineProperty(globalThis, "indexedDB", { value: new IDBFactory(), configurable: true });
  Object.defineProperty(window, "localStorage", { value: createMemoryStorage(), configurable: true });
  window.location.hash = "#/home";
  window.localStorage.clear();
  delete document.documentElement.dataset.theme;
  document.documentElement.lang = "en";
  document.head.querySelector('meta[name="theme-color"]')?.remove();
  stores = [];
  testQuestions = await loadQuestions();
});

afterEach(async () => {
  cleanup();
  vi.unstubAllGlobals();
  for (const store of stores) {
    await store.deleteDatabase();
  }
});

function createStore(name: string): ProgressStore {
  const store = new ProgressStore(name);
  stores.push(store);
  return store;
}

function createMemoryStorage(): Storage {
  const values = new Map<string, string>();
  return {
    get length() {
      return values.size;
    },
    clear: () => values.clear(),
    getItem: (key: string) => values.get(key) ?? null,
    key: (index: number) => [...values.keys()][index] ?? null,
    removeItem: (key: string) => { values.delete(key); },
    setItem: (key: string, value: string) => { values.set(key, value); },
  };
}

function webIndexHtml(): string {
  const moduleUrl = new URL(import.meta.url);
  const modulePath = moduleUrl.protocol === "file:"
    ? fileURLToPath(moduleUrl)
    : join(process.cwd(), moduleUrl.pathname.replace(/^\/+/, ""));
  return readFileSync(join(dirname(modulePath), "../index.html"), "utf8");
}

function extractInlineThemeScript(html: string): string {
  const match = html.match(/<script>([\s\S]*?)<\/script>/);
  assert.ok(match?.[1]);
  return match[1];
}

function extractCsp(html: string): string {
  const match = html.match(/<meta\s+http-equiv="Content-Security-Policy"\s+content="([^"]+)"/);
  assert.ok(match?.[1]);
  return match[1];
}

async function expectNoAxeViolations(container: Element): Promise<void> {
  const results = await axe.run(container);
  assert.deepEqual(results.violations, []);
}

function allCorrectAttempt(seed: string, submittedAt: string): ExamAttempt {
  return attemptWithCorrectCount(seed, submittedAt, 100);
}

function attemptWithCorrectCount(seed: string, submittedAt: string, correctCount: number): ExamAttempt {
  const generatedItems = createMockExam(seed, testQuestions);
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
    for (const question of testQuestions.slice(0, 5)) {
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

  it("renders Learn and module pages in study order with no axe violations", async () => {
    window.location.hash = "#/learn";
    const store = createStore("learn");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "learn-seed"} />);

    await screen.findByRole("heading", { name: "Learn" });
    const moduleEyebrows = [...container.querySelectorAll(".module-card .eyebrow")].map((element) => element.textContent ?? "");
    assert.match(moduleEyebrows[0] ?? "", /Module 1 · B-005/);
    await expectNoAxeViolations(container);

    await user.click(screen.getAllByRole("button", { name: "Open module" })[0]!);
    await screen.findByRole("heading", { name: "Basic Electronics and Theory" });
    assert.match(screen.getAllByText(/L-005-01/).map((element) => element.textContent ?? "").join(" "), /30 min/);
    await expectNoAxeViolations(container);
  });

  it("renders lesson Markdown, stores read progress, and has no axe violations", async () => {
    window.location.hash = "#/learn/M5/L-005-01";
    const store = createStore("lesson");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "lesson-seed"} />);

    await screen.findByRole("heading", { name: "Units, conductors, and current" });
    assert.ok(screen.getByRole("img", { name: /horizontal metric-prefix ladder/i }));
    assert.ok(container.querySelector("table th[scope='col']"));
    await user.click(screen.getByRole("button", { name: "Mark lesson read" }));
    await waitFor(async () => assert.equal((await store.getLessonProgress()).length, 1));
    await expectNoAxeViolations(container);
  });

  it("renders lesson quizzes with official explanations and stores attempts without concept Leitner updates", async () => {
    window.location.hash = "#/learn/M5/L-005-01";
    const store = createStore("lesson-quiz");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "lesson-quiz-seed"} />);

    await screen.findByRole("heading", { name: "QZ-L-005-01-A" });
    for (let index = 0; index < 11; index += 1) {
      const choices = screen.queryAllByTestId("lesson-quiz-choice");
      if (choices.length > 0) {
        await user.click(choices[0]!);
      } else {
        await user.click(screen.getAllByTestId("answer-choice")[0]!);
      }
      const next = screen.getByRole("button", { name: "Next" });
      if (!next.hasAttribute("disabled")) {
        await user.click(next);
      }
    }
    await user.click(screen.getByRole("button", { name: "Submit lesson quiz" }));
    await waitFor(async () => assert.equal((await store.getLessonQuizAttempts()).length, 1));
    const progress = await store.getQuestionProgress();
    assert.ok(progress.length > 0);
    assert.ok(progress.length <= 8);
    await expectNoAxeViolations(container);
  });

  it("renders Practice with immediate feedback, progress persistence, and no axe violations", async () => {
    window.location.hash = "#/practice";
    const store = createStore("practice");
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "practice-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    await expectNoAxeViolations(container);

    const questionMeta = document.querySelector(".question-meta")?.textContent ?? "";
    const questionId = questionMeta.match(/B-\d{3}-\d{3}-\d{3}/)?.[0];
    const displayedQuestion = testQuestions.find((question) => question.id === questionId);
    assert.ok(displayedQuestion);
    const correctAnswerText = displayedQuestion.answers.find((answer) => answer.sourceIndex === 0)?.text.en;
    assert.ok(correctAnswerText);
    const choices = screen.getAllByTestId("answer-choice");
    const wrongChoice = choices.find((choice) => !(choice.textContent ?? "").includes(correctAnswerText));
    assert.ok(wrongChoice);
    fireEvent.click(wrongChoice);
    await screen.findByRole("status");
    const correctChoice = document.querySelector(".answer-button.is-correct");
    const incorrectChoice = document.querySelector(".answer-button.is-incorrect");
    assert.ok(correctChoice);
    assert.ok(incorrectChoice);
    assert.equal(correctChoice.querySelector(".answer-state-icon")?.textContent, "✓");
    assert.equal(correctChoice.querySelector(".answer-state-icon")?.getAttribute("aria-hidden"), "true");
    assert.equal(incorrectChoice.querySelector(".answer-state-icon")?.textContent, "✕");
    assert.equal(incorrectChoice.querySelector(".answer-state-icon")?.getAttribute("aria-hidden"), "true");
    await waitFor(async () => assert.equal((await store.getQuestionProgress()).length, 1));
  });

  it("renders Mock exam with narrow DOM order, supports keyboard operation, and has no axe violations", async () => {
    window.location.hash = "#/mock";
    const store = createStore("mock");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "mock-seed"} />);

    await screen.findByRole("heading", { name: "Mock exam" });
    await expectNoAxeViolations(container);

    await user.click(screen.getByRole("button", { name: "Start mock exam" }));
    await screen.findByText(/Question 1 of 100/);
    const originalScrollIntoView = HTMLElement.prototype.scrollIntoView;
    const scrollIntoView = vi.fn();
    Object.defineProperty(HTMLElement.prototype, "scrollIntoView", { configurable: true, value: scrollIntoView });
    vi.stubGlobal("matchMedia", vi.fn((query: string) => ({
      matches: query === "(prefers-reduced-motion: reduce)",
      media: query,
      onchange: null,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
      dispatchEvent: () => true,
    })));
    const mapButton = screen.getByRole("button", { name: "Jump to question map" });
    const navigator = screen.getByRole("navigation", { name: "Question navigator" });
    const questionPanel = document.querySelector(".question-panel");
    const actionRow = document.querySelector(".mock-exam--running > .action-row");
    assert.ok(questionPanel);
    assert.ok(actionRow);
    assert.equal(mapButton.tagName, "BUTTON");
    assert.equal(navigator.getAttribute("id"), "question-map");
    assert.ok(questionPanel.compareDocumentPosition(actionRow) & Node.DOCUMENT_POSITION_FOLLOWING);
    assert.ok(actionRow.compareDocumentPosition(navigator) & Node.DOCUMENT_POSITION_FOLLOWING);
    assert.equal(window.location.hash, "#/mock");
    await user.click(mapButton);
    assert.ok(screen.getByText(/Question 1 of 100/));
    assert.equal(document.activeElement, navigator);
    assert.equal(window.location.hash, "#/mock");
    assert.deepEqual(scrollIntoView.mock.calls[0]?.[0], { block: "start", behavior: "auto" });
    if (originalScrollIntoView === undefined) {
      delete (HTMLElement.prototype as Partial<HTMLElement>).scrollIntoView;
    } else {
      Object.defineProperty(HTMLElement.prototype, "scrollIntoView", { configurable: true, value: originalScrollIntoView });
    }
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

  it("renders Results with category breakdown and no axe violations", async () => {
    window.location.hash = "#/results";
    const store = createStore("results-axe");
    await store.putExamAttempt(attemptWithCorrectCount("results-axe", "2026-01-02T01:00:00.000Z", 80));
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "results-seed"} />);

    await screen.findByRole("heading", { name: "Mock exam results" });
    assert.match(screen.getByText(/Basic with Honours ready/).textContent ?? "", /Basic with Honours/);
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

  it("renders Settings theme controls and no axe violations", async () => {
    window.location.hash = "#/settings";
    const store = createStore("settings-axe");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "settings-seed"} />);

    await screen.findByRole("heading", { name: "Settings and local data" });
    await expectNoAxeViolations(container);
    await user.click(screen.getByLabelText("Dark"));
    await waitFor(async () => {
      assert.equal((await store.getPreferences()).theme, "dark");
      assert.equal(document.documentElement.dataset.theme, "dark");
    });
    assert.equal(window.localStorage.getItem(THEME_STORAGE_KEY), "dark");
  });

  it("applies the mirrored stored theme before IndexedDB preferences load", async () => {
    const themeColor = document.createElement("meta");
    themeColor.setAttribute("name", "theme-color");
    document.head.append(themeColor);
    window.localStorage.setItem(THEME_STORAGE_KEY, "dark");

    assert.equal(readStoredThemePreference(), "dark");
    applyThemePreference(readStoredThemePreference());

    assert.equal(document.documentElement.dataset.theme, "dark");
    assert.equal(themeColor.getAttribute("content"), THEME_COLORS.dark);
  });

  it("keeps the inline theme script hash in the CSP and applies stored themes", () => {
    const html = webIndexHtml();
    const script = extractInlineThemeScript(html);
    const csp = extractCsp(html);
    const hash = createHash("sha256").update(script).digest("base64");
    const runThemeScript = () => new Function("window", "document", "localStorage", script)(window, document, window.localStorage);
    const themeColor = document.createElement("meta");
    themeColor.setAttribute("name", "theme-color");
    document.head.append(themeColor);

    assert.ok(csp.includes(`'sha256-${hash}'`));
    assert.doesNotMatch(csp, /script-src[^;]*'unsafe-inline'/);
    assert.doesNotMatch(csp, /style-src[^;]*'unsafe-inline'/);

    window.localStorage.setItem(THEME_STORAGE_KEY, "dark");
    runThemeScript();
    assert.equal(document.documentElement.dataset.theme, "dark");
    assert.equal(themeColor.getAttribute("content"), THEME_COLORS.dark);

    window.localStorage.setItem(THEME_STORAGE_KEY, "light");
    runThemeScript();
    assert.equal(document.documentElement.dataset.theme, "light");
    assert.equal(themeColor.getAttribute("content"), THEME_COLORS.light);
  });

  it("preserves stored preferences and re-renders theme radios in recovery settings", async () => {
    const store = createStore("error-boundary-theme");
    const user = userEvent.setup();
    await store.putPreferences({ ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "light" });
    function BrokenContent() {
      throw new Error("corrupt local progress");
      return null;
    }

    render(<AppErrorBoundary store={store} now={() => fixedNow}><BrokenContent /></AppErrorBoundary>);
    await screen.findByText(/The app could not render saved progress/);
    await user.click(screen.getByLabelText("Dark"));
    await screen.findByText(/Theme preference saved: Dark/);

    assert.deepEqual(await store.getPreferences(), { ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "dark" });
    assert.equal((screen.getByLabelText("Dark") as HTMLInputElement).checked, true);
    assert.equal(document.documentElement.dataset.theme, "dark");
  });

  it("keeps the root language stable and marks only question content as French", async () => {
    window.location.hash = "#/practice";
    const store = createStore("language-scope");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "language-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    await user.click(screen.getByLabelText("Français"));

    assert.equal(screen.getByText("Français").getAttribute("lang"), "fr");
    assert.equal(document.documentElement.lang, "en");
    assert.ok(document.querySelector(".question-text[lang='fr-CA']"));
  });

  it("labels reference sheet links with new-tab hints and licensing notes", async () => {
    const store = createStore("reference-links");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "reference-seed"} />);

    const studyLink = await screen.findByRole("link", { name: "Study reference sheet (opens in new tab)" });
    assert.match(studyLink.getAttribute("href") ?? "", /Reference.*Training.*Basic.*2025\.pdf/);
    assert.equal(studyLink.getAttribute("target"), "_blank");
    assert.match(studyLink.getAttribute("rel") ?? "", /noreferrer/);
    assert.match(screen.getByLabelText("Study reference sheet attribution").textContent ?? "", /Private-development access only/);

    await user.click(screen.getAllByRole("button", { name: "Mock exam" })[0]!);
    const examLink = await screen.findByRole("link", { name: "Open exam reference sheet (opens in new tab)" });
    assert.match(examLink.getAttribute("href") ?? "", /Reference.*Exam.*Basic.*2025\.pdf/);
    assert.equal(examLink.getAttribute("target"), "_blank");
    assert.match(examLink.getAttribute("rel") ?? "", /noreferrer/);
    assert.match(screen.getByLabelText("Exam reference sheet attribution").textContent ?? "", /may be used while writing the exam/);
  });

  it("surfaces bundled question-bank fetch failures", async () => {
    const fetchMock = vi.fn(async () => new Response("not found", { status: 503, statusText: "Service Unavailable" }));
    vi.stubGlobal("fetch", fetchMock);

    await assert.rejects(loadQuestionsFromUrl("/questions.json"), /503 Service Unavailable/);
    assert.equal(fetchMock.mock.calls.length, 1);
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
