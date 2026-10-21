import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { act, cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import axe from "axe-core";
import { StrictMode } from "react";
import { IDBFactory } from "fake-indexeddb";
import { afterEach, beforeEach, describe, it, vi } from "vitest";

import { type QuestionProgressRecord } from "@canadian-ham/engine-ts";
import { MORSE_BEACON_AREA_CSS_PIXELS, MORSE_LIGHT_ACCENT_RGB, MORSE_LIGHT_PAPER_INSET_RGB, evaluateMorseBeaconFlashSafety, generateMorseExamText, maxMorseFlashesPerSecond, morseBeaconPalette, morseSignalEvents, profileForName, textToTimedMorse } from "@canadian-ham/morse-engine";

import { App, AppErrorBoundary, CitationLink, ExplanationPanel } from "./App";
import { answerMorseCourseSession, morseCourseSummaryMessage, type SessionState } from "./morse/course/MorseCoursePanel";
import { ADVANCED_BANK_ID, advancedBank, bankId, categories, loadQuestions, loadQuestionsFromUrl, manifest, type Answer, type Category, type Question } from "./data/bank";
import { lessonHeadingAnchors, parseMarkdownBlocks } from "./components/MarkdownContent";
import { explanationForQuestion, parseChoiceNotes } from "./data/explanations";
import { basicQuestionHints, hintForQuestion, type QuestionHint } from "./data/hints";
import { lessonsById } from "./data/lessons";
import { lessonQuizzesById, buildLessonQuizItems } from "./data/quizzes";
import { ProgressStore, defaultPreferences, type ExamAttempt, type ProgressExportV1, type WebPreferences } from "./lib/progressStore";
import { INTERFACE_LANGUAGE_STORAGE_KEY, interfaceLanguageTag, t } from "./lib/i18n";
import { MorseOutputView, morseOutputSafetyNote } from "./lib/morseOutput";
import { applyThemePreference, readStoredThemePreference, THEME_COLORS, THEME_STORAGE_KEY } from "./lib/theme";
import { applyPracticeAnswer, buildExamAttempt, createMockExam } from "./lib/studyEngine";
import { buildMorseLessonExercises, parseMorseCourseFixture } from "@canadian-ham/morse-engine";
import courseFixture from "../../../fixtures/morse/course.json";

const fixedNow = "2026-01-02T03:04:05.000Z";
const lessonRenderAsyncTimeoutMs = 5_000;
const appFlowTestTimeoutMs = 10_000;
const lessonRenderWaitOptions = { timeout: lessonRenderAsyncTimeoutMs };
const referenceSheetNote = "In the real exam you are given ISED's reference sheet of formulas and block diagrams. The lessons teach everything on it.";
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
  vi.useRealTimers();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  for (const store of stores) {
    await store.deleteDatabase();
  }
});

function createStore(name: string): ProgressStore {
  const store = new ProgressStore(name);
  stores.push(store);
  return store;
}

async function setAppHash(hash: string): Promise<void> {
  await act(async () => {
    window.location.hash = hash;
    window.dispatchEvent(new HashChangeEvent("hashchange"));
  });
}

async function dispatchAppHashChange(): Promise<void> {
  await act(async () => {
    window.dispatchEvent(new HashChangeEvent("hashchange"));
  });
}

function getMain(container: HTMLElement): HTMLElement {
  const main = container.querySelector("main#main");
  assert.ok(main instanceof HTMLElement);
  return main;
}

function setViewportWidth(width: number): void {
  Object.defineProperty(window, "innerWidth", { value: width, configurable: true });
  window.dispatchEvent(new Event("resize"));
}

function stubReducedMotion(matches: boolean): void {
  Object.defineProperty(window, "matchMedia", {
    value: (query: string) => ({
      matches: query === "(prefers-reduced-motion: reduce)" ? matches : false,
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false,
    }),
    configurable: true,
  });
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

function localDateString(value: string): string {
  const date = new Date(value);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function currentPracticeQuestionId(): string {
  const questionMeta = document.querySelector(".question-meta")?.textContent ?? "";
  const questionId = questionMeta.match(/B-\d{3}-\d{3}-\d{3}/)?.[0];
  assert.ok(questionId);
  return questionId;
}

function correctAnswerChoiceForCurrentQuestion(): HTMLElement {
  const questionId = currentPracticeQuestionId();
  const displayedQuestion = testQuestions.find((question) => question.id === questionId);
  assert.ok(displayedQuestion);
  const correctAnswerText = displayedQuestion.answers.find((answer) => answer.sourceIndex === 0)?.text.en;
  assert.ok(correctAnswerText);
  const correctChoice = screen.getAllByTestId("answer-choice").find((choice) => (choice.textContent ?? "").includes(correctAnswerText));
  assert.ok(correctChoice);
  return correctChoice;
}

async function startDueReviewForQuestion(questionId: string): Promise<void> {
  const user = userEvent.setup();
  await user.selectOptions(screen.getByLabelText("Practice scope"), "due");
  await user.click(screen.getByRole("button", { name: "Start set" }));
  await waitFor(() => assert.equal(currentPracticeQuestionId(), questionId));
}

function weakDueProgressRecord(questionId: string): QuestionProgressRecord {
  return {
    questionId,
    bankId: "basic-2025-07-15",
    attempts: 3,
    correctAttempts: 2,
    lastAttemptedAt: "2026-01-01T00:00:00.000Z",
    lastResult: "incorrect",
    lastAnsweredWithHelp: false,
    recentResults: [true, true, false],
    recentAnsweredWithHelp: [false, false, false],
    leitner: { box: 0, dueAt: fixedNow },
    notes: null,
  };
}

function lessonHeadingTextForHintLink(hint: QuestionHint): string | null {
  const sectionAnchor = hint.lessonLink.sectionAnchor;
  if (sectionAnchor === undefined) {
    return null;
  }
  const lesson = lessonsById.get(hint.lessonLink.lessonId);
  assert.ok(lesson);
  const anchors = lessonHeadingAnchors(lesson.body, lesson.title.en);
  const headingBlocks = parseMarkdownBlocks(lesson.body, lesson.title.en).filter((block): block is Extract<ReturnType<typeof parseMarkdownBlocks>[number], { readonly type: "heading" }> => block.type === "heading");
  const headingIndex = anchors.indexOf(sectionAnchor);
  return headingIndex === -1 ? null : headingBlocks[headingIndex]?.text ?? null;
}

class DelayedInitialPreferencesStore extends ProgressStore {
  private readonly releaseInitialPreferencesPromise: Promise<void>;
  private releaseInitialPreferencesPromiseResolve: (() => void) | null = null;
  private readonly initialPreferencesReadStartedPromise: Promise<void>;
  private initialPreferencesReadStartedResolve: (() => void) | null = null;
  private readonly initialPreferencesReturnedPromise: Promise<void>;
  private initialPreferencesReturnedResolve: (() => void) | null = null;
  private preferencesReadCount = 0;

  constructor(name: string) {
    super(name);
    this.releaseInitialPreferencesPromise = new Promise((resolve) => {
      this.releaseInitialPreferencesPromiseResolve = resolve;
    });
    this.initialPreferencesReadStartedPromise = new Promise((resolve) => {
      this.initialPreferencesReadStartedResolve = resolve;
    });
    this.initialPreferencesReturnedPromise = new Promise((resolve) => {
      this.initialPreferencesReturnedResolve = resolve;
    });
  }

  get initialPreferencesReadStarted(): Promise<void> {
    return this.initialPreferencesReadStartedPromise;
  }

  get initialPreferencesReturned(): Promise<void> {
    return this.initialPreferencesReturnedPromise;
  }

  releaseInitialPreferences(): void {
    this.releaseInitialPreferencesPromiseResolve?.();
  }

  override async getPreferences(): Promise<WebPreferences> {
    if (this.preferencesReadCount === 0) {
      this.preferencesReadCount += 1;
      this.initialPreferencesReadStartedResolve?.();
      await this.releaseInitialPreferencesPromise;
      const preferences = await super.getPreferences();
      this.initialPreferencesReturnedResolve?.();
      return preferences;
    }
    this.preferencesReadCount += 1;
    return super.getPreferences();
  }
}

class FailingPreferencesStore extends ProgressStore {
  failNextPreferencesSave = true;

  override async putPreferences(preferences: WebPreferences): Promise<void> {
    if (this.failNextPreferencesSave) {
      this.failNextPreferencesSave = false;
      throw new Error("simulated preferences failure");
    }
    await super.putPreferences(preferences);
  }
}

class CountingPreferencesStore extends ProgressStore {
  putPreferencesCount = 0;

  override async putPreferences(preferences: WebPreferences): Promise<void> {
    this.putPreferencesCount += 1;
    await super.putPreferences(preferences);
  }
}

class FailingMorseCourseStore extends ProgressStore {
  failNextMorseCourseSave = true;

  override async putMorseCourseProgress(progress: import("@canadian-ham/morse-engine").MorseCourseProgressExport): Promise<void> {
    if (this.failNextMorseCourseSave) {
      this.failNextMorseCourseSave = false;
      throw new Error("simulated Morse course save failure");
    }
    await super.putMorseCourseProgress(progress);
  }
}

class DelayedPreferencesStore extends ProgressStore {
  readonly pendingPreferenceSaves: Array<{
    readonly preferences: WebPreferences;
    readonly resolve: () => void;
    readonly reject: (error: Error) => void;
  }> = [];

  override async putPreferences(preferences: WebPreferences): Promise<void> {
    await new Promise<void>((resolve, reject) => {
      this.pendingPreferenceSaves.push({ preferences, resolve, reject });
    });
    await super.putPreferences(preferences);
  }

  releaseNextPreferenceSave(): void {
    const nextSave = this.pendingPreferenceSaves.shift();
    assert.ok(nextSave);
    nextSave.resolve();
  }

  rejectNextPreferenceSave(error = new Error("simulated preferences failure")): void {
    const nextSave = this.pendingPreferenceSaves.shift();
    assert.ok(nextSave);
    nextSave.reject(error);
  }
}

class MockMorseAudioParam {
  setValueAtTime(): this {
    return this;
  }

  linearRampToValueAtTime(): this {
    return this;
  }
}

class MockMorseAudioNode {
  connect(): AudioNode {
    return this as unknown as AudioNode;
  }

  disconnect(): void {}
}

class MockMorseOscillatorNode extends MockMorseAudioNode {
  type: OscillatorType = "sine";
  readonly frequency = new MockMorseAudioParam();

  start(): void {}

  stop(): void {}
}

class MockMorseGainNode extends MockMorseAudioNode {
  readonly gain = new MockMorseAudioParam();
}

interface StubMorseOscillatorStopCounter {
  stopCalls(): number;
}

function stubMorseAudioContext(): { readonly stopCalls: () => number; readonly oscillators: () => readonly StubMorseOscillatorStopCounter[] } {
  let stopCalls = 0;
  const oscillators: StubMorseOscillatorStopCounter[] = [];

  class CountingMorseOscillatorNode extends MockMorseOscillatorNode {
    #stopCalls = 0;

    override stop(): void {
      stopCalls += 1;
      this.#stopCalls += 1;
    }

    stopCalls(): number {
      return this.#stopCalls;
    }
  }

  class MockMorseAudioContext {
    readonly currentTime = 0;
    readonly destination = new MockMorseAudioNode() as unknown as AudioDestinationNode;
    readonly state: AudioContextState = "running";

    createOscillator(): OscillatorNode {
      const oscillator = new CountingMorseOscillatorNode();
      oscillators.push(oscillator);
      return oscillator as unknown as OscillatorNode;
    }

    createGain(): GainNode {
      return new MockMorseGainNode() as unknown as GainNode;
    }

    async resume(): Promise<void> {}

    async close(): Promise<void> {}
  }

  vi.stubGlobal("AudioContext", MockMorseAudioContext);
  vi.stubGlobal("webkitAudioContext", undefined);
  return { stopCalls: () => stopCalls, oscillators: () => oscillators };
}

function stubFailingMorseAudioContext(message = "simulated audio-start failure"): void {
  class FailingMorseAudioContext {
    readonly currentTime = 0;
    readonly destination = new MockMorseAudioNode() as unknown as AudioDestinationNode;
    readonly state: AudioContextState = "running";

    createOscillator(): OscillatorNode {
      throw new Error(message);
    }

    createGain(): GainNode {
      return new MockMorseGainNode() as unknown as GainNode;
    }

    async resume(): Promise<void> {}

    async close(): Promise<void> {}
  }

  vi.stubGlobal("AudioContext", FailingMorseAudioContext);
  vi.stubGlobal("webkitAudioContext", undefined);
}

function morsePreferences(_enabled = true): WebPreferences {
  return { ...defaultPreferences, morse: { ...defaultPreferences.morse } };
}

function webIndexHtml(): string {
  const moduleUrl = new URL(import.meta.url);
  const modulePath = moduleUrl.protocol === "file:"
    ? fileURLToPath(moduleUrl)
    : join(process.cwd(), moduleUrl.pathname.replace(/^\/+/, ""));
  return readFileSync(join(dirname(modulePath), "../index.html"), "utf8");
}

function webStylesCss(): string {
  const moduleUrl = new URL(import.meta.url);
  const modulePath = moduleUrl.protocol === "file:"
    ? fileURLToPath(moduleUrl)
    : join(process.cwd(), moduleUrl.pathname.replace(/^\/+/, ""));
  return readFileSync(join(dirname(modulePath), "styles.css"), "utf8");
}

function cssRuleBlocks(css: string, selector: string): string[] {
  const escapedSelector = selector.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const openingPattern = new RegExp(`^(?<indent>\\s*)${escapedSelector}\\s*{\\s*$`);
  const lines = css.split("\n");
  const blocks: string[] = [];
  for (let openingIndex = 0; openingIndex < lines.length; openingIndex += 1) {
    const openingMatch = openingPattern.exec(lines[openingIndex]!);
    if (openingMatch === null) {
      continue;
    }
    const indent = openingMatch.groups?.indent ?? "";
    const closingIndex = lines.findIndex((line, index) => index > openingIndex && line === `${indent}}`);
    if (closingIndex >= 0) {
      blocks.push(lines.slice(openingIndex + 1, closingIndex).join("\n"));
    }
  }
  return blocks;
}

function cssRuleBlock(css: string, selector: string): string {
  return cssRuleBlocks(css, selector)[0] ?? "";
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

function assertNoPdfLinks(container: Element): void {
  assert.equal(container.querySelector('a[href*=".pdf"]'), null);
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
      bankId,
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

function assertChoiceNoteMapping(quizId: string): void {
  const quiz = lessonQuizzesById.get(quizId);
  assert.ok(quiz);
  for (let seedIndex = 0; seedIndex < 100; seedIndex += 1) {
    const officialItem = buildLessonQuizItems(quiz, `mapping-${quizId}-${seedIndex}`).find((item) => item.type === "official" && item.choicePermutation.some((sourceIndex, displayIndex) => sourceIndex !== displayIndex));
    if (officialItem?.type !== "official") {
      continue;
    }
    const question = testQuestions.find((candidate) => candidate.id === officialItem.questionId);
    const explanation = explanationForQuestion(officialItem.questionId);
    assert.ok(question);
    assert.ok(explanation);
    const notes = parseChoiceNotes(explanation, "en");
    assert.ok(notes.length > 0);
    for (const note of notes) {
      const displayedIndex = officialItem.choicePermutation.findIndex((sourceIndex) => sourceIndex === note.sourceIndex);
      const answer: Answer | undefined = question.answers.find((candidate) => candidate.sourceIndex === note.sourceIndex);
      assert.ok(displayedIndex >= 0, `${officialItem.questionId} sourceIndex ${note.sourceIndex} is displayed`);
      assert.ok(answer, `${officialItem.questionId} sourceIndex ${note.sourceIndex} has an answer`);
      assert.match(note.note, new RegExp(escapeRegExp(answer.text.en.slice(0, 12))));
      assert.equal(officialItem.choicePermutation[displayedIndex], note.sourceIndex);
    }
    return;
  }
  assert.fail(`No shuffled official item found for ${quizId}.`);
}

function shuffledOfficialItemWithChoiceNotes(quizId: string): { readonly seed: string; readonly nowValue: number; readonly itemIndex: number; readonly item: Extract<ReturnType<typeof buildLessonQuizItems>[number], { readonly type: "official" }> } {
  const quiz = lessonQuizzesById.get(quizId);
  assert.ok(quiz);
  for (let nowValue = 1; nowValue < 500; nowValue += 1) {
    const seed = `${quizId}:${nowValue.toString(36)}`;
    const items = buildLessonQuizItems(quiz, seed);
    const itemIndex = items.findIndex((item) => {
      if (item.type !== "official" || !item.choicePermutation.some((sourceIndex, displayIndex) => sourceIndex !== displayIndex)) {
        return false;
      }
      const explanation = explanationForQuestion(item.questionId);
      return explanation !== null && parseChoiceNotes(explanation, "en").length > 0;
    });
    const item = items[itemIndex];
    if (item?.type === "official") {
      return { seed, nowValue, itemIndex, item };
    }
  }
  assert.fail(`No shuffled official item with notes found for ${quizId}.`);
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function chooseFirstLessonQuizOption(user: ReturnType<typeof userEvent.setup>): Promise<void> {
  const choices = screen.queryAllByTestId("lesson-quiz-choice");
  if (choices.length > 0) {
    await user.click(choices[0]!);
    return;
  }
  await user.click(screen.getAllByTestId("answer-choice")[0]!);
}

function clickFirstLessonQuizOption(root: ParentNode = document): void {
  const choice = root.querySelector<HTMLElement>('[data-testid="lesson-quiz-choice"]')
    ?? root.querySelector<HTMLElement>('[data-testid="answer-choice"]');
  assert.ok(choice);
  fireEvent.click(choice);
}

function getLessonQuizSection(): HTMLElement {
  const quizSection = document.querySelector<HTMLElement>(".lesson-quiz");
  assert.ok(quizSection);
  return quizSection;
}

function progressExport(): ProgressExportV1 {
  return {
    schema: "canadian-ham.progress-export",
    version: 1,
    exportedAt: fixedNow,
    bankId,
    questionProgress: [],
    examAttempts: [allCorrectAttempt("imported", "2026-01-02T04:00:00.000Z")],
    lessonProgress: [{ lessonId: "L-005-01", readAt: fixedNow, readCount: 1 }],
    lessonQuizAttempts: [{ id: "imported-lesson-quiz", quizId: "QZ-L-005-01-A", lessonId: "L-005-01", submittedAt: fixedNow, correct: 1, total: 1, percent: 100, officialQuestionIds: ["B-005-001-001"], incorrectOfficialQuestionIds: [], incorrectConceptCheckIds: [] }],
    preferences: defaultPreferences,
  };
}

describe("App accessibility and flows", { timeout: appFlowTestTimeoutMs }, () => {
  it("offers a localized skip link as the first focus stop and keeps route focus management", async () => {
    const store = createStore("skip-link");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "skip-seed"} />);

    await screen.findByRole("heading", { name: "Ready for Basic with Honours?" });
    const skipLink = screen.getByRole("link", { name: "Skip to main content" });
    assert.equal(skipLink.getAttribute("href"), "#main");

    await user.tab();
    assert.equal(document.activeElement, skipLink);
    await user.keyboard("{Enter}");
    const main = document.querySelector("main#main");
    assert.ok(main);
    await waitFor(() => assert.equal(document.activeElement, main));
    assert.equal(window.location.hash, "#/home");

    const primaryNav = screen.getByRole("navigation", { name: "Primary" });
    await user.click(within(primaryNav).getByRole("button", { name: "Learn" }));
    await screen.findByRole("heading", { name: "Learn" });
    await waitFor(() => assert.equal(document.activeElement, main));
    await expectNoAxeViolations(container);
  });

  it("keeps the skip link as the first focus stop under React StrictMode", async () => {
    const store = createStore("skip-link-strict-mode");
    const user = userEvent.setup();
    render(
      <StrictMode>
        <App store={store} now={() => fixedNow} seedFactory={() => "skip-strict-seed"} />
      </StrictMode>,
    );

    await screen.findByRole("heading", { name: "Ready for Basic with Honours?" });
    const skipLink = screen.getByRole("link", { name: "Skip to main content" });
    await user.tab();

    assert.equal(document.activeElement, skipLink);
  });

  it("marks English fallback category names with lang=en in the French interface", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    const category = categories[0]!;
    const originalCategory: Category = { ...category, name: { ...category.name } };
    try {
      Object.assign(category, {
        name: { ...category.name, fr: null },
        frenchNameStatus: "pending verification",
      });
      const store = createStore("french-category-fallback-language");
      render(<App store={store} now={() => fixedNow} seedFactory={() => "category-fallback-seed"} />);

      const fallbackName = await screen.findByText(category.name.en);
      assert.equal(fallbackName.getAttribute("lang"), "en");
    } finally {
      Object.assign(category, originalCategory);
    }
  });

  it("renders main screens in French, sets document language, and has no axe violations", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    const store = createStore("french-main-screens");
    await store.putExamAttempt(allCorrectAttempt("fr-results", "2026-01-02T04:00:00.000Z"));
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "fr-seed"} />);

    await screen.findByRole("heading", { name: "Prêt pour la compétence de base avec distinction?" });
    assert.equal(document.documentElement.lang, "fr-CA");
    assert.ok(screen.getByText("Règlements et politiques"));
    assert.ok(screen.getByText("Descentes d'antenne et systèmes d'antenne"));
    assert.ok(screen.getByRole("link", { name: "Aller au contenu principal" }));
    await expectNoAxeViolations(container);

    const primaryNav = screen.getByRole("navigation", { name: "Principale" });
    await user.click(within(primaryNav).getByRole("button", { name: "Apprendre" }));
    await screen.findByRole("heading", { name: "Apprendre" });

    await setAppHash("#/learn/M5/L-005-01");
    await screen.findByText("Leçon offerte en anglais seulement.");
    assert.ok(container.querySelector('.lesson-article h2[lang="en"]'));
    assert.ok(container.querySelector('.lesson-article div[lang="en"]'));

    await user.click(within(primaryNav).getByRole("button", { name: "Exercices" }));
    await screen.findByRole("heading", { name: "Exercices" });

    await user.click(within(primaryNav).getByRole("button", { name: "Examen simulé" }));
    await screen.findByRole("heading", { name: "Examen simulé" });

    await setAppHash("#/results");
    await screen.findByRole("heading", { name: "Résultats de l’examen simulé" });
    assert.ok(screen.getByText(/Brouillage et suppression/));

    await user.click(within(primaryNav).getByRole("button", { name: "Réglages" }));
    await screen.findByRole("heading", { name: "Réglages et données locales" });
    for (const englishLabel of screen.getAllByText("English")) {
      assert.equal(englishLabel.getAttribute("lang"), "en");
    }
  });

  it("has no axe violations on French Practice feedback and Mock exam start", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/practice";
    const store = createStore("french-practice-mock-axe");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "fr-practice-seed"} />);

    await screen.findByRole("heading", { name: "Exercices" });
    await screen.findByText(/Question 1 sur/);
    await user.click(screen.getAllByTestId("answer-choice")[0]!);
    await screen.findByRole("status");
    await expectNoAxeViolations(container);

    const primaryNav = screen.getByRole("navigation", { name: "Principale" });
    await user.click(within(primaryNav).getByRole("button", { name: "Examen simulé" }));
    await screen.findByRole("heading", { name: "Examen simulé" });
    await expectNoAxeViolations(container);
  });

  it("defaults language to French from navigator and exports the Settings override", async () => {
    const originalLanguage = navigator.language;
    const originalLanguages = navigator.languages;
    Object.defineProperty(navigator, "language", { value: "fr-CA", configurable: true });
    Object.defineProperty(navigator, "languages", { value: ["fr-CA", "en-CA"], configurable: true });
    try {
      const store = createStore("french-default-language-setting");
      const user = userEvent.setup();
      render(<App store={store} now={() => fixedNow} seedFactory={() => "fr-default-seed"} />);

      await screen.findByRole("heading", { name: "Prêt pour la compétence de base avec distinction?" });
      const primaryNav = screen.getByRole("navigation", { name: "Principale" });
      await user.click(within(primaryNav).getByRole("button", { name: "Réglages" }));
      const languageGroup = await screen.findByRole("group", { name: "Langue" });
      await user.click(within(languageGroup).getByRole("radio", { name: "English" }));

      assert.equal(window.localStorage.getItem(INTERFACE_LANGUAGE_STORAGE_KEY), "en");
      await screen.findByRole("heading", { name: "Settings and local data" });
      const exported = await store.exportData(fixedNow);
      assert.equal(exported.preferences.language, "en");
    } finally {
      Object.defineProperty(navigator, "language", { value: originalLanguage, configurable: true });
      Object.defineProperty(navigator, "languages", { value: originalLanguages, configurable: true });
    }
  });

  it("does not re-read IndexedDB when switching the Language setting", async () => {
    window.location.hash = "#/settings";
    const store = createStore("language-switch-no-indexeddb");
    const readSpies = [
      vi.spyOn(store, "getQuestionProgress"),
      vi.spyOn(store, "getExamAttempts"),
      vi.spyOn(store, "getLessonProgress"),
      vi.spyOn(store, "getLessonQuizAttempts"),
      vi.spyOn(store, "getPreferences"),
    ];
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "switch-language-seed"} />);

    await screen.findByRole("heading", { name: "Settings and local data" });
    for (const spy of readSpies) {
      spy.mockClear();
    }

    const languageGroup = screen.getByRole("group", { name: "Language" });
    await user.click(within(languageGroup).getByRole("radio", { name: "Français" }));
    await screen.findByRole("heading", { name: "Réglages et données locales" });
    assert.equal(window.localStorage.getItem(INTERFACE_LANGUAGE_STORAGE_KEY), "fr");

    for (const spy of readSpies) {
      assert.equal(spy.mock.calls.length, 0);
    }
  });

  it("keeps the language picker out of practice and changes language through Settings", async () => {
    window.location.hash = "#/practice";
    const store = createStore("language-setting-practice");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "language-setting-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    assert.equal(screen.queryByRole("group", { name: "Question language" }), null);

    const primaryNav = screen.getByRole("navigation", { name: "Primary" });
    await user.click(within(primaryNav).getByRole("button", { name: "Settings" }));
    const languageGroup = await screen.findByRole("group", { name: "Language" });
    await user.click(within(languageGroup).getByRole("radio", { name: "Français" }));
    await screen.findByRole("heading", { name: "Réglages et données locales" });
    await user.click(within(screen.getByRole("navigation", { name: "Principale" })).getByRole("button", { name: "Exercices" }));
    await screen.findByText(/Question 1 sur/);
    assert.equal(screen.queryByRole("group", { name: "Langue des questions" }), null);
    assert.ok(document.querySelector(".question-text[lang='fr-CA']"));
    assert.equal((await store.getPreferences()).language, "fr");
    assert.equal(window.localStorage.getItem(INTERFACE_LANGUAGE_STORAGE_KEY), "fr");
  });

  it("shows the French explanation notice only when no French explanation body exists", () => {
    const withFrenchExplanation = {
      id: "EXP-FR",
      questionId: "B-TEST-001",
      bankId,
      status: "draft",
      body: { en: "English explanation.", fr: "Explication française." },
      citations: [],
      licenseClass: "original" as const,
    };
    render(<ExplanationPanel explanation={withFrenchExplanation} interfaceLanguage="fr" language="fr" />);
    assert.equal(screen.queryByText("Explication offerte en anglais seulement."), null);
    cleanup();

    render(<ExplanationPanel explanation={{ ...withFrenchExplanation, body: { en: "English explanation.", fr: null } }} interfaceLanguage="fr" language="fr" />);
    assert.ok(screen.getByText("Explication offerte en anglais seulement."));
  });

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
        lastAnsweredWithHelp: false,
        recentResults: [false],
        recentAnsweredWithHelp: [false],
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
    assert.equal(screen.getByText(referenceSheetNote).className, "reference-note");
    const moduleEyebrows = [...container.querySelectorAll(".module-card .eyebrow")].map((element) => element.textContent ?? "");
    assert.match(moduleEyebrows[0] ?? "", /Module 1 · B-005/);
    await expectNoAxeViolations(container);

    await user.click(screen.getAllByRole("button", { name: "Open module" })[0]!);
    await screen.findByRole("heading", { name: "Basic Electronics and Theory" });
    assert.match(screen.getAllByText(/L-005-01/).map((element) => element.textContent ?? "").join(" "), /30 min/);
    await expectNoAxeViolations(container);
  });

  it("shows Exam day guidance in Learn and opens L-001-01 without rendering or fetching an ISED link", async () => {
    window.location.hash = "#/learn";
    const store = createStore("learn-exam-day");
    const user = userEvent.setup();
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "learn-exam-day-seed"} />);

    await screen.findByRole("heading", { name: "Learn" });
    assert.ok(screen.getByRole("heading", { name: "Exam day" }));
    assert.equal(container.querySelector('a[href*="ised-isde.canada.ca"]'), null);

    await user.click(screen.getByRole("button", { name: "Read exam-day guidance" }));

    await screen.findByRole("heading", { name: "Authority, certificates, and exams" });
    assert.equal(window.location.hash, "#/learn/M1/L-001-01");
    assert.equal(container.querySelector('a[href*="ised-isde.canada.ca"]'), null);
    assert.equal(document.querySelector('link[href*="ised-isde.canada.ca"][rel~="preload"], link[href*="ised-isde.canada.ca"][rel~="prefetch"]'), null);
    assert.equal(fetchMock.mock.calls.length, 0);
  });

  it("renders lesson Markdown, stores read progress, and has no axe violations", async () => {
    window.location.hash = "#/learn/M5/L-005-01";
    const store = createStore("lesson");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "lesson-seed"} />);

    await screen.findByRole("heading", { name: "Units, conductors, and current" });
    assert.equal(screen.queryByText("Illustration placeholder"), null);
    assert.equal(screen.queryByText(/Draw a simple ink-brush ladder/u), null);
    assert.ok(container.querySelector("table th[scope='col']"));
    await user.click(screen.getByRole("button", { name: "Mark lesson read" }));
    await waitFor(async () => assert.equal((await store.getLessonProgress()).length, 1));
    await expectNoAxeViolations(container);

    cleanup();
    window.location.hash = "#/learn/M5/L-005-02";
    const figureStore = createStore("lesson-figures");
    const figureRender = render(<App store={figureStore} now={() => fixedNow} seedFactory={() => "lesson-figure-seed"} />);

    await screen.findByRole("heading", { name: "Power and Ohm’s law" });
    assert.ok(screen.getByRole("img", { name: /Power triangle with P above I and E/i }));
    assert.ok(screen.getByRole("img", { name: /Ohm’s law triangle with E above I and R/i }));
    assert.ok(screen.getByRole("img", { name: /Ohm’s law and power wheel/i }));
    assert.ok(screen.getByText("Figure text equivalent"));
    await expectNoAxeViolations(figureRender.container);

    cleanup();
    window.location.hash = "#/learn/M6/L-006-03";
    const codeStore = createStore("lesson-code-block");
    const codeRender = render(<App store={codeStore} now={() => fixedNow} seedFactory={() => "lesson-code-seed"} />);

    await screen.findByRole("heading", { name: "Polarization, dipoles, and wavelength" });
    const codeBlocks = screen.getAllByRole("group", { name: "Lesson code block (text)" });
    assert.ok(codeBlocks.length >= 2);
    assert.equal(codeBlocks[0]?.tagName, "PRE");
    assert.equal(codeBlocks[0]?.getAttribute("tabindex"), "0");
    assert.match(codeBlocks[0]?.textContent ?? "", /wavelength in metres = 300 \/ frequency in MHz/);
    await expectNoAxeViolations(codeRender.container);
  });

  it("renders lesson prerequisites as localized accessible links", async () => {
    window.location.hash = "#/learn/M4/L-004-01";
    const store = createStore("lesson-prerequisites");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "lesson-prerequisites-seed"} />);

    await screen.findByRole("heading", { name: "Amplifiers and diodes" });
    const prerequisites = screen.getByRole("region", { name: "Before this lesson" });
    const prerequisiteLink = within(prerequisites).getByRole("link", { name: "Power and Ohm’s law" });
    assert.equal(prerequisiteLink.getAttribute("href"), "#/learn/M5/L-005-02");
    assert.ok(within(prerequisites).getByRole("link", { name: "AC and decibels" }));
    await expectNoAxeViolations(container);

    fireEvent.click(prerequisiteLink, { ctrlKey: true });
    assert.equal(window.location.hash, "#/learn/M4/L-004-01");
    assert.ok(screen.getByRole("heading", { name: "Amplifiers and diodes" }));

    await user.click(prerequisiteLink);
    await screen.findByRole("heading", { name: "Power and Ohm’s law" });
    assert.equal(window.location.hash, "#/learn/M5/L-005-02");

    cleanup();
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/learn/M5/L-005-02";
    const frenchStore = createStore("lesson-prerequisites-fr");
    const frenchRender = render(<App store={frenchStore} now={() => fixedNow} seedFactory={() => "lesson-prerequisites-fr-seed"} />);

    await screen.findByRole("heading", { name: "Power and Ohm’s law" });
    const frenchPrerequisites = screen.getByRole("region", { name: "Avant cette leçon" });
    assert.ok(within(frenchPrerequisites).getByRole("link", { name: "Units, conductors, and current" }));
    assert.ok(frenchRender.container.querySelector(".lesson-prerequisites a span[lang='en']"));
    await expectNoAxeViolations(frenchRender.container);
  });

  it("automatically includes M4 and M6 lessons from content and renders them", async () => {
    window.location.hash = "#/learn";
    const store = createStore("m4-m6-lessons");
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "m4-m6-seed"} />);
    const main = getMain(container);
    const mainView = within(main);

    await mainView.findByRole("heading", { name: "Learn" }, lessonRenderWaitOptions);
    assert.ok(mainView.getByRole("heading", { name: "Circuit Components" }));
    assert.ok(mainView.getByRole("heading", { name: "Feedlines and Antenna Systems" }));

    await setAppHash("#/learn/M4/L-004-01");
    await mainView.findByRole("heading", { name: "Amplifiers and diodes" }, lessonRenderWaitOptions);
    const m4Quiz = await mainView.findByRole("heading", { name: "QZ-L-004-01-A" }, lessonRenderWaitOptions);
    const m4QuizSection = m4Quiz.closest("section");
    assert.ok(m4QuizSection instanceof HTMLElement);
    const m4Choices = await within(m4QuizSection).findByRole("group", { name: "Answer choices" }, lessonRenderWaitOptions);
    assert.equal(within(m4Choices).getAllByRole("button").length, 4);

    await setAppHash("#/learn/M6/L-006-01");
    await mainView.findByRole("heading", { name: "Feedline basics and types" }, lessonRenderWaitOptions);
    const m6Quiz = await mainView.findByRole("heading", { name: "QZ-L-006-01-A" }, lessonRenderWaitOptions);
    const m6QuizSection = m6Quiz.closest("section");
    assert.ok(m6QuizSection instanceof HTMLElement);
    const m6Choices = await within(m6QuizSection).findByRole("group", { name: "Answer choices" }, lessonRenderWaitOptions);
    assert.equal(within(m6Choices).getAllByRole("button").length, 4);
  });

  it("updates lesson navigation state for next, previous, sidebar, and browser history", async () => {
    window.location.hash = "#/learn/M5/L-005-01";
    const store = createStore("lesson-navigation");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "lesson-nav-seed"} />);

    await screen.findByRole("heading", { name: "Units, conductors, and current" });
    await user.click(screen.getByRole("button", { name: /^Next:/ }));
    await screen.findByRole("heading", { name: "Power and Ohm’s law" });
    await waitFor(() => assert.equal(document.activeElement?.tagName, "MAIN"));
    assert.equal(window.location.hash, "#/learn/M5/L-005-02");

    await user.click(screen.getByRole("button", { name: "Units, conductors, and current" }));
    await screen.findByRole("heading", { name: "Units, conductors, and current" });
    assert.equal(window.location.hash, "#/learn/M5/L-005-01");

    await user.click(screen.getByRole("button", { name: /^Next:/ }));
    await screen.findByRole("heading", { name: "Power and Ohm’s law" });
    await user.click(screen.getByRole("button", { name: /^Previous:/ }));
    await screen.findByRole("heading", { name: "Units, conductors, and current" });

    await user.click(screen.getByRole("button", { name: /^Next:/ }));
    await screen.findByRole("heading", { name: "Power and Ohm’s law" });
    await act(async () => {
      window.history.back();
    });
    await waitFor(() => assert.equal(window.location.hash, "#/learn/M5/L-005-01"));
    await dispatchAppHashChange();
    await screen.findByRole("heading", { name: "Units, conductors, and current" });

    await act(async () => {
      window.history.forward();
    });
    await waitFor(() => assert.equal(window.location.hash, "#/learn/M5/L-005-02"));
    await dispatchAppHashChange();
    await screen.findByRole("heading", { name: "Power and Ohm’s law" });
  });

  it("maps shuffled explanation notes to displayed choices for real M4 and M6 questions", () => {
    assertChoiceNoteMapping("QZ-L-004-01-A");
    assertChoiceNoteMapping("QZ-L-006-01-A");
  });

  it("renders displayed choice note labels according to the shuffled button letters", async () => {
    const target = shuffledOfficialItemWithChoiceNotes("QZ-L-004-01-A");
    const explanation = explanationForQuestion(target.item.questionId);
    assert.ok(explanation);
    window.location.hash = "#/learn/M4/L-004-01";
    const store = createStore("rendered-note-mapping");
    const user = userEvent.setup();
    vi.spyOn(Date, "now").mockReturnValue(target.nowValue);
    render(<App store={store} now={() => fixedNow} seedFactory={() => target.seed} />);

    await screen.findByRole("heading", { name: "QZ-L-004-01-A" });
    for (let index = 0; index < target.itemIndex; index += 1) {
      await user.click(screen.getByRole("button", { name: "Next" }));
    }

    const buttons = screen.getAllByTestId("answer-choice");
    const renderedLetters = buttons.map((button) => button.querySelector(".answer-label")?.textContent ?? "");
    await user.click(buttons[0]!);
    await screen.findByRole("status");

    for (const note of parseChoiceNotes(explanation, "en")) {
      const displayIndex = target.item.choicePermutation.findIndex((sourceIndex) => sourceIndex === note.sourceIndex);
      assert.ok(displayIndex >= 0);
      const renderedLetter = renderedLetters[displayIndex];
      assert.ok(renderedLetter);
      assert.equal(screen.getAllByText((_content, element) => element?.tagName === "STRONG" && element.textContent === `Displayed choice ${renderedLetter}:`).length, 1);
    }
  });

  it("keeps focus on lesson quiz navigation when revisiting answered items", async () => {
    window.location.hash = "#/learn/M5/L-005-01";
    const store = createStore("lesson-quiz-revisit-focus");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "lesson-quiz-seed"} />);

    await screen.findByRole("heading", { name: "QZ-L-005-01-A" });
    await chooseFirstLessonQuizOption(user);
    assert.equal(document.activeElement, await screen.findByRole("status"));

    await user.click(screen.getByRole("button", { name: "Next" }));
    await chooseFirstLessonQuizOption(user);
    assert.equal(document.activeElement, await screen.findByRole("status"));

    await user.click(screen.getByRole("button", { name: "Previous" }));
    const next = screen.getByRole("button", { name: "Next" });
    await user.click(next);

    assert.equal(document.activeElement, next);
  });

  it("stores lesson quiz attempts with official explanations and without concept Leitner updates", async () => {
    window.location.hash = "#/learn/M5/L-005-01";
    const store = createStore("lesson-quiz");
    render(<App store={store} now={() => fixedNow} seedFactory={() => "lesson-quiz-seed"} />);

    await screen.findByRole("heading", { name: "QZ-L-005-01-A" });
    for (let index = 0; index < 11; index += 1) {
      clickFirstLessonQuizOption();
      await screen.findByRole("status");
      const next = screen.getByRole("button", { name: "Next" });
      if (!next.hasAttribute("disabled")) {
        fireEvent.click(next);
      }
    }
    fireEvent.click(screen.getByRole("button", { name: "Submit lesson quiz" }));
    await waitFor(async () => assert.equal((await store.getLessonQuizAttempts()).length, 1));
    const attempts = await store.getLessonQuizAttempts();
    assert.equal(attempts[0]?.total, 11);
    assert.equal(attempts[0]?.officialQuestionIds.length, 8);
    assert.ok((attempts[0]?.incorrectConceptCheckIds.length ?? 0) <= 3);
    const progress = await store.getQuestionProgress();
    assert.ok(progress.length > 0);
    assert.ok(progress.length <= 8);
    assert.ok(progress.every((record) => attempts[0]?.officialQuestionIds.includes(record.questionId)));
  });

  it("has no axe violations on answered and submitted lesson quiz UI", async () => {
    window.location.hash = "#/learn/M5/L-005-01";
    const store = createStore("lesson-quiz-axe");
    render(<App store={store} now={() => fixedNow} seedFactory={() => "lesson-quiz-seed"} />);

    await screen.findByRole("heading", { name: "QZ-L-005-01-A" });
    const quizSection = getLessonQuizSection();
    clickFirstLessonQuizOption(quizSection);
    await waitFor(() => assert.ok(quizSection.querySelector('[role="status"]')));
    await expectNoAxeViolations(quizSection);

    for (let index = 1; index < 11; index += 1) {
      fireEvent.click(within(quizSection).getByRole("button", { name: "Next" }));
      clickFirstLessonQuizOption(quizSection);
      await waitFor(() => assert.ok(quizSection.querySelector('[role="status"]')));
    }
    fireEvent.click(within(quizSection).getByRole("button", { name: "Submit lesson quiz" }));
    await waitFor(async () => assert.equal((await store.getLessonQuizAttempts()).length, 1));
    await expectNoAxeViolations(quizSection);
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

  it("bundles Basic hints offline and exposes the Hint tool in practice but never mock exams", async () => {
    assert.equal(basicQuestionHints.length, testQuestions.length);

    window.location.hash = "#/practice";
    const practiceStore = createStore("practice-hint-availability");
    const practiceUser = userEvent.setup();
    render(<App store={practiceStore} now={() => fixedNow} seedFactory={() => "practice-hint-availability"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    const hint = hintForQuestion(currentPracticeQuestionId(), "basic-2025-07-15");
    assert.ok(hint);
    await practiceUser.click(screen.getByRole("button", { name: "Hint" }));
    await screen.findByRole("heading", { name: "Hint" });
    await practiceUser.click(screen.getByRole("button", { name: "Show Hint 1" }));
    assert.match(screen.getByRole("region", { name: "Hint" }).textContent ?? "", new RegExp(hint.hints[0]!.en.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "u"));

    cleanup();
    window.location.hash = "#/practice";
    const reviewStore = createStore("review-hint-availability");
    await reviewStore.putQuestionProgressMany(applyPracticeAnswer([], testQuestions[0]!.id, 1, fixedNow));
    render(<App store={reviewStore} now={() => fixedNow} seedFactory={() => "review-hint-availability"} />);
    await screen.findByRole("heading", { name: "Practice" });
    await practiceUser.selectOptions(screen.getByLabelText("Practice scope"), "due");
    await practiceUser.click(screen.getByRole("button", { name: "Start set" }));
    await screen.findByText(/Scope: Due review/);
    assert.ok(screen.getByRole("button", { name: "Hint" }));

    cleanup();
    window.location.hash = "#/mock";
    const mockStore = createStore("mock-hint-availability");
    render(<App store={mockStore} now={() => fixedNow} seedFactory={() => "mock-hint-availability"} />);

    await screen.findByRole("heading", { name: "Mock exam" });
    await practiceUser.click(await screen.findByRole("button", { name: "Start mock exam" }));
    await screen.findByText(/Question 1 of/);
    assert.equal(screen.queryByRole("button", { name: "Hint" }), null);
  });

  it("records answered-with-help only after a hint is visible for 0.5 seconds and keeps helped correct answers due now", async () => {
    window.location.hash = "#/practice";
    const earlyStore = createStore("hint-progress-early");
    render(<App store={earlyStore} now={() => fixedNow} seedFactory={() => "hint-progress-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Hint" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(screen.getByRole("button", { name: "Show Hint 1" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(499); });
      fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    } finally {
      vi.useRealTimers();
    }
    await waitFor(async () => assert.equal((await earlyStore.getQuestionProgress()).length, 1));
    const earlyRecord = (await earlyStore.getQuestionProgress())[0]!;
    assert.equal(earlyRecord.lastAnsweredWithHelp, false);
    assert.equal(earlyRecord.leitner.box, 1);
    assert.notEqual(earlyRecord.leitner.dueAt, fixedNow);

    cleanup();
    window.location.hash = "#/practice";
    const helpedQuestionId = "B-005-004-002";
    const helpedStore = createStore("hint-progress-helped");
    await helpedStore.putQuestionProgressMany([weakDueProgressRecord(helpedQuestionId)]);
    render(<App store={helpedStore} now={() => fixedNow} seedFactory={() => "hint-progress-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    await startDueReviewForQuestion(helpedQuestionId);
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Hint" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(screen.getByRole("button", { name: "Show Hint 1" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(500); });
      fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    } finally {
      vi.useRealTimers();
    }
    await waitFor(async () => assert.equal((await helpedStore.getQuestionProgress())[0]?.attempts, 4));
    const helpedRecord = (await helpedStore.getQuestionProgress()).find((record) => record.questionId === helpedQuestionId)!;
    assert.equal(helpedRecord.lastAnsweredWithHelp, true);
    assert.deepEqual(helpedRecord.recentAnsweredWithHelp, [false, false, false, true]);
    assert.equal(helpedRecord.leitner.box, 0);
    assert.equal(helpedRecord.leitner.dueAt, fixedNow);

    fireEvent.click(screen.getByRole("button", { name: "Home" }));
    await screen.findByRole("heading", { name: "Ready for Basic with Honours?" });
    fireEvent.click(screen.getByText("Weak subsections"));
    assert.ok(screen.getByText(new RegExp(testQuestions.find((question) => question.id === helpedQuestionId)?.subsectionId ?? "^$", "u")));
  });

  it("does not restart hint qualification on re-render and does not count hints closed or left before 0.5 seconds", async () => {
    const stableTimerQuestionId = "B-005-004-002";
    window.location.hash = "#/practice";
    const stableStore = createStore("hint-stable-rerender");
    await stableStore.putQuestionProgressMany(applyPracticeAnswer([], stableTimerQuestionId, 1, fixedNow));
    render(<App store={stableStore} now={() => fixedNow} seedFactory={() => "hint-stable-rerender"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await startDueReviewForQuestion(stableTimerQuestionId);
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Hint" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(screen.getByRole("button", { name: "Show Hint 1" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(300); });
      fireEvent.click(screen.getByRole("button", { name: "Show Hint 2" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(300); });
      fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    } finally {
      vi.useRealTimers();
    }
    await waitFor(async () => assert.equal((await stableStore.getQuestionProgress()).find((record) => record.questionId === stableTimerQuestionId)?.lastAnsweredWithHelp, true));

    cleanup();
    window.location.hash = "#/practice";
    const closedStore = createStore("hint-closed-before-qualified");
    render(<App store={closedStore} now={() => fixedNow} seedFactory={() => "hint-closed-before-qualified"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Hint" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(screen.getByRole("button", { name: "Show Hint 1" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(499); });
      fireEvent.click(screen.getByRole("button", { name: "Close tool" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(100); });
      fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    } finally {
      vi.useRealTimers();
    }
    await waitFor(async () => assert.equal((await closedStore.getQuestionProgress())[0]?.lastAnsweredWithHelp, false));

    cleanup();
    window.location.hash = "#/practice";
    const changedStore = createStore("hint-question-changed-before-qualified");
    render(<App store={changedStore} now={() => fixedNow} seedFactory={() => "hint-question-changed-before-qualified"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    const firstQuestionId = currentPracticeQuestionId();
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Hint" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(screen.getByRole("button", { name: "Show Hint 1" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(499); });
      fireEvent.click(screen.getByRole("button", { name: "Next" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(100); });
      fireEvent.click(screen.getByRole("button", { name: "Previous" }));
      fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    } finally {
      vi.useRealTimers();
    }
    await waitFor(async () => assert.equal((await changedStore.getQuestionProgress()).find((record) => record.questionId === firstQuestionId)?.lastAnsweredWithHelp, false));
  });

  it("opens the generic lesson link at the anchored heading without discarding helped practice state", async () => {
    window.location.hash = "#/practice";
    const store = createStore("hint-lesson-link");
    render(<App store={store} now={() => fixedNow} seedFactory={() => "hint-lesson-link"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    const questionId = currentPracticeQuestionId();
    const hint = hintForQuestion(questionId, "basic-2025-07-15");
    assert.ok(hint);
    assert.ok(hint.lessonLink.sectionAnchor);
    const linkedLesson = lessonsById.get(hint.lessonLink.lessonId);
    assert.ok(linkedLesson);
    const linkedHeadingText = lessonHeadingTextForHintLink(hint);
    assert.ok(linkedHeadingText);

    fireEvent.click(screen.getByRole("button", { name: "Hint" }));
    const hintPanel = await screen.findByRole("region", { name: "Hint" });
    vi.useFakeTimers();
    try {
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(within(hintPanel).getByRole("button", { name: "Show Hint 1" }));
      if (hint.hints.length === 2) {
        fireEvent.click(within(hintPanel).getByRole("button", { name: "Show Hint 2" }));
      }
      await act(async () => { await vi.advanceTimersByTimeAsync(500); });
    } finally {
      vi.useRealTimers();
    }
    assert.equal((hintPanel.textContent ?? "").includes(linkedLesson.title.en), false);
    assert.equal((hintPanel.textContent ?? "").includes(linkedHeadingText), false);
    const lessonLink = within(hintPanel).getByRole("link", { name: "Review in lesson" }) as HTMLAnchorElement;
    assert.equal(lessonLink.getAttribute("href")?.endsWith(`/${hint.lessonLink.lessonId}`), true);
    for (const attribute of Array.from(lessonLink.attributes)) {
      assert.equal(attribute.value.includes(hint.lessonLink.sectionAnchor), false, `${attribute.name} leaked the section anchor`);
      assert.equal(attribute.value.includes(linkedHeadingText), false, `${attribute.name} leaked the linked heading text`);
    }

    fireEvent.click(lessonLink);
    await screen.findByRole("heading", { name: linkedLesson.title.en });
    await waitFor(() => assert.equal(document.activeElement?.id, hint.lessonLink.sectionAnchor));

    fireEvent.click(screen.getByRole("button", { name: "Practice" }));
    await screen.findByText(new RegExp(questionId));
    fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    await waitFor(async () => assert.equal((await store.getQuestionProgress())[0]?.lastAnsweredWithHelp, true));
  });

  it("keeps helped state across the lesson link in review-later mode", async () => {
    const questionId = "B-005-004-002";
    const store = createStore("hint-lesson-link-review-later");
    await store.putPreferences({ ...defaultPreferences, practiceMode: "review-later" });
    await store.putQuestionProgressMany(applyPracticeAnswer([], questionId, 1, fixedNow));
    window.location.hash = "#/practice";
    render(<App store={store} now={() => fixedNow} seedFactory={() => "hint-lesson-link-review-later"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await startDueReviewForQuestion(questionId);
    const hint = hintForQuestion(questionId, "basic-2025-07-15");
    assert.ok(hint);
    assert.ok(hint.lessonLink.sectionAnchor);
    const linkedLesson = lessonsById.get(hint.lessonLink.lessonId);
    assert.ok(linkedLesson);

    fireEvent.click(screen.getByRole("button", { name: "Hint" }));
    const hintPanel = await screen.findByRole("region", { name: "Hint" });
    vi.useFakeTimers();
    try {
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(within(hintPanel).getByRole("button", { name: "Show Hint 1" }));
      fireEvent.click(within(hintPanel).getByRole("button", { name: "Show Hint 2" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(500); });
    } finally {
      vi.useRealTimers();
    }
    fireEvent.click(within(hintPanel).getByRole("link", { name: "Review in lesson" }));
    await screen.findByRole("heading", { name: linkedLesson.title.en });

    fireEvent.click(screen.getByRole("button", { name: "Practice" }));
    await screen.findByText(new RegExp(questionId));
    fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    fireEvent.click(screen.getByRole("button", { name: "Submit practice set" }));
    await waitFor(async () => assert.equal((await store.getQuestionProgress()).find((record) => record.questionId === questionId)?.lastAnsweredWithHelp, true));
  });

  it("counts review-later hints viewed after selection but does not change immediate answers already scored", async () => {
    const reviewLaterQuestionId = "B-005-004-002";
    const reviewLaterStore = createStore("hint-review-later-after-selection");
    await reviewLaterStore.putPreferences({ ...defaultPreferences, practiceMode: "review-later" });
    await reviewLaterStore.putQuestionProgressMany(applyPracticeAnswer([], reviewLaterQuestionId, 1, fixedNow));
    window.location.hash = "#/practice";
    render(<App store={reviewLaterStore} now={() => fixedNow} seedFactory={() => "hint-review-later-after-selection"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await startDueReviewForQuestion(reviewLaterQuestionId);
    fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Hint" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(screen.getByRole("button", { name: "Show Hint 1" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(500); });
    } finally {
      vi.useRealTimers();
    }
    fireEvent.click(screen.getByRole("button", { name: "Submit practice set" }));
    await waitFor(async () => assert.equal((await reviewLaterStore.getQuestionProgress()).find((record) => record.questionId === reviewLaterQuestionId)?.lastAnsweredWithHelp, true));

    cleanup();
    window.location.hash = "#/practice";
    const immediateStore = createStore("hint-immediate-after-scored");
    render(<App store={immediateStore} now={() => fixedNow} seedFactory={() => "hint-immediate-after-scored"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    fireEvent.click(correctAnswerChoiceForCurrentQuestion());
    await waitFor(async () => assert.equal((await immediateStore.getQuestionProgress())[0]?.lastAnsweredWithHelp, false));
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Hint" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(0); });
      fireEvent.click(screen.getByRole("button", { name: "Show Hint 1" }));
      await act(async () => { await vi.advanceTimersByTimeAsync(500); });
    } finally {
      vi.useRealTimers();
    }
    assert.equal(screen.getByTestId("hint-live-status").textContent?.includes("This answer will be recorded with help."), false);
    assert.equal((await immediateStore.getQuestionProgress())[0]?.lastAnsweredWithHelp, false);
  });

  it("shows localized French hint content in the App without panel-styled lesson notes", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/practice";
    const store = createStore("hint-french-app-display");
    render(<App store={store} now={() => fixedNow} seedFactory={() => "hint-french-app-display"} />);

    await screen.findByRole("heading", { name: "Exercices" });
    await screen.findByText(/Question 1 sur/u);
    const hint = hintForQuestion(currentPracticeQuestionId(), "basic-2025-07-15");
    assert.ok(hint);
    fireEvent.click(screen.getByRole("button", { name: "Indice" }));
    const hintPanel = await screen.findByRole("region", { name: "Indice" });
    fireEvent.click(within(hintPanel).getByRole("button", { name: "Afficher l’indice 1" }));
    assert.match(hintPanel.textContent ?? "", new RegExp(hint.hints[0]!.fr.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "u"));
    if (hint.hints.length === 2) {
      fireEvent.click(within(hintPanel).getByRole("button", { name: "Afficher l’indice 2" }));
    }
    assert.ok(within(hintPanel).getByRole("link", { name: "Revoir dans la leçon" }));
    const notice = screen.getByText(/Leçon offerte en anglais seulement/u);
    assert.equal(notice.classList.contains("hint-lesson-link__notice"), true);
    assert.equal(notice.classList.contains("reference-note"), false);
  });

  it("keeps practice questions and answers operable with calculator or reference tools open at phone, tablet, and desktop widths", async () => {
    for (const width of [320, 768, 1280]) {
      for (const toolName of ["Calculator", "Reference sheet"]) {
        cleanup();
        setViewportWidth(width);
        window.location.hash = "#/practice";
        const store = createStore(`practice-tools-${width}-${toolName}`);
        const user = userEvent.setup();
        render(<App store={store} now={() => fixedNow} seedFactory={() => `practice-tools-${width}-${toolName}`} />);

        await screen.findByRole("heading", { name: "Practice" });
        await screen.findByText(/Question 1 of/);
        const toolButton = screen.getByRole("button", { name: toolName });
        await user.click(toolButton);
        await screen.findByRole("heading", { name: toolName });
        assert.ok(document.querySelector(".question-panel")?.textContent?.includes("Question"));
        const answer = screen.getAllByTestId("answer-choice")[0]!;
        assert.equal((answer as HTMLButtonElement).disabled, false);
        await user.click(answer);
        assert.equal(answer.getAttribute("aria-pressed"), "true");
        assert.equal(screen.getAllByTestId("answer-choice").length, 4);
      }
    }
  });

  it("opens and closes practice calculator with focus return, scoped keyboard input, spoken live output, and light/dark axe coverage", async () => {
    for (const theme of ["light", "dark"] as const) {
      cleanup();
      setViewportWidth(1280);
      window.location.hash = "#/practice";
      const store = createStore(`practice-calculator-${theme}`);
      await store.putPreferences({ ...defaultPreferences, theme });
      const user = userEvent.setup();
      const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => `practice-calculator-${theme}`} />);

      await screen.findByRole("heading", { name: "Practice" });
      await screen.findByText(/Question 1 of/);
      const calculatorButton = screen.getByRole("button", { name: "Calculator" });
      await user.click(calculatorButton);
      const calculator = await screen.findByRole("region", { name: "Calculator" });
      await waitFor(() => assert.equal(document.activeElement, calculator));

      await user.keyboard("1+2{Enter}");
      assert.equal(screen.getByLabelText("Calculator display: 3").getAttribute("aria-live"), "off");
      assert.equal(screen.getByLabelText("Calculator display: 3").textContent, "3");
      assert.equal(screen.getByTestId("calculator-live-result").textContent, "Calculator result: 3");

      const firstAnswer = screen.getAllByTestId("answer-choice")[0]!;
      firstAnswer.focus();
      await user.keyboard("9+9");
      assert.equal(screen.getByLabelText("Calculator display: 3").textContent, "3");
      assert.equal((firstAnswer as HTMLButtonElement).disabled, false);
      await user.click(firstAnswer);
      assert.equal(firstAnswer.getAttribute("aria-pressed"), "true");

      await expectNoAxeViolations(container);
      await user.click(screen.getByRole("button", { name: "Close tool" }));
      await waitFor(() => assert.equal(document.activeElement, calculatorButton));
    }
  });

  it("lets focused calculator buttons act as buttons and ignores modified shortcut keys", async () => {
    window.location.hash = "#/practice";
    const store = createStore("calculator-button-keyboard");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "calculator-button-keyboard"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    await user.click(screen.getByRole("button", { name: "Calculator" }));
    await screen.findByRole("heading", { name: "Calculator" });

    const sevenButton = () => screen.getByRole("button", { name: "Digit 7" });
    let seven = sevenButton();
    seven.focus();
    await user.keyboard("{Enter}");
    seven = sevenButton();
    assert.equal(document.activeElement, seven);
    assert.equal(screen.getByLabelText("Calculator display: 7").textContent, "7");
    await user.keyboard(" ");
    seven = sevenButton();
    assert.equal(document.activeElement, seven);

    await user.click(screen.getByRole("button", { name: "All clear" }));
    seven = sevenButton();
    seven.focus();
    fireEvent.click(seven, { detail: 1 });
    seven = sevenButton();
    assert.equal(document.activeElement, seven);
    assert.equal(screen.getByLabelText("Calculator display: 7").textContent, "7");

    seven = sevenButton();
    seven.focus();
    fireEvent.keyDown(seven, { key: "+" });
    seven = sevenButton();
    fireEvent.keyDown(seven, { key: "2" });
    seven = sevenButton();
    assert.equal(document.activeElement, seven);
    assert.equal(screen.getByLabelText("Calculator display: 2").textContent, "2");
    fireEvent.keyDown(seven, { key: "Enter" });
    fireEvent.keyUp(seven, { key: "Enter" });
    fireEvent.click(seven);
    seven = sevenButton();
    assert.equal(document.activeElement, seven);
    assert.equal(document.querySelector<HTMLElement>(".calculator-display")?.textContent, "7");
    await user.keyboard("{Escape}");
    assert.equal(document.querySelector<HTMLElement>(".calculator-display")?.textContent, "0");

    const calculator = screen.getByRole("region", { name: "Calculator" });
    calculator.focus();
    fireEvent.keyDown(calculator, { key: "1", ctrlKey: true });
    fireEvent.keyDown(calculator, { key: "+", metaKey: true });
    fireEvent.keyDown(calculator, { key: "x", altKey: true });
    assert.equal(screen.getByLabelText("Calculator display: 0").textContent, "0");
  });

  it("keeps calculator state when switching tools or closing, then clears it for a new practice set", async () => {
    window.location.hash = "#/practice";
    const store = createStore("calculator-state-retention");
    const seeds = ["calculator-state-a", "calculator-state-b"];
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => seeds.shift() ?? "calculator-state-c"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    const calculatorButton = screen.getByRole("button", { name: "Calculator" });
    await user.click(calculatorButton);
    await user.keyboard("4+5{Enter}");
    assert.equal(screen.getByLabelText("Calculator display: 9").textContent, "9");

    await user.click(screen.getByRole("button", { name: "Reference sheet" }));
    await screen.findByRole("heading", { name: "Reference sheet" });
    await user.click(calculatorButton);
    assert.equal(screen.getByLabelText("Calculator display: 9").textContent, "9");

    await user.click(screen.getByRole("button", { name: "Close tool" }));
    await user.click(calculatorButton);
    assert.equal(screen.getByLabelText("Calculator display: 9").textContent, "9");

    await user.click(screen.getByRole("button", { name: "Start set" }));
    await screen.findByText(/Seed calculator-state-b/);
    await user.click(screen.getByRole("button", { name: "Calculator" }));
    assert.equal(screen.getByLabelText("Calculator display: 0").textContent, "0");

    await user.click(screen.getByRole("button", { name: "Start set" }));
    await screen.findByText(/Seed calculator-state-c/);
    await user.click(screen.getByRole("button", { name: "Calculator" }));
    await user.keyboard("6");
    assert.equal(screen.getByLabelText("Calculator display: 6").textContent, "6");
    await user.click(screen.getByRole("button", { name: "Start set" }));
    await screen.findByText(/Seed calculator-state-c/);
    await user.click(screen.getByRole("button", { name: "Calculator" }));
    assert.equal(screen.getByLabelText("Calculator display: 0").textContent, "0");
  });

  it("uses real drawer/side-panel states without reserving an empty tool column and keeps DOM order visual", async () => {
    const css = webStylesCss();
    const panelRules = cssRuleBlocks(css, ".exam-tool-panel");
    assert.match(panelRules[0] ?? "", /position: sticky;/);
    assert.match(panelRules[0] ?? "", /bottom: 0;/);
    assert.match(panelRules[0] ?? "", /max-height: min\(24rem, 48svh\);/);
    assert.match(panelRules[1] ?? "", /max-height: calc\(100svh - \(2 \* var\(--ch-space-lg\)\)\);/);
    assert.equal(cssRuleBlock(css, ".exam-tools-shell--open .exam-tools-content"), "");
    assert.match(cssRuleBlock(css, "html:has(.exam-tools-shell--open)"), /scroll-padding-block-end: calc\(min\(24rem, 48svh\) \+ var\(--ch-space-lg\)\);/);
    assert.match(cssRuleBlock(css, ".exam-tools-shell--practice.exam-tools-shell--open"), /grid-template-columns: minmax\(0, 1fr\) minmax\(18rem, 0\.42fr\);/);
    assert.match(cssRuleBlock(css, ".mock-exam-body"), /grid-template-columns: minmax\(0, 1fr\) minmax\(12rem, 0\.3fr\);/);
    assert.match(cssRuleBlock(css, ".exam-tools-shell--mock.exam-tools-shell--open .mock-exam-body"), /grid-template-columns: 1fr;/);
    assert.doesNotMatch(cssRuleBlock(css, ".mock-exam-body"), /gap:/);
    assert.match(cssRuleBlocks(css, ".calculator-help").at(-1) ?? "", /display: none;/);
    assert.doesNotMatch(cssRuleBlock(css, ".exam-tools-shell"), /grid-template-columns/);

    window.location.hash = "#/practice";
    const store = createStore("exam-tools-dom-order");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "exam-tools-dom-order"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    const shell = screen.getByTestId("practice-exam-tools");
    assert.equal(shell.classList.contains("exam-tools-shell--open"), false);
    await user.click(screen.getByRole("button", { name: "Reference sheet" }));
    assert.equal(shell.classList.contains("exam-tools-shell--open"), true);

    const toolbar = document.querySelector(".exam-tools-toolbar");
    const questionPanel = document.querySelector(".question-panel");
    const panel = screen.getByTestId("exam-tool-panel");
    assert.ok(toolbar);
    assert.ok(questionPanel);
    assert.ok(toolbar.compareDocumentPosition(questionPanel) & Node.DOCUMENT_POSITION_FOLLOWING);
    assert.ok(questionPanel.compareDocumentPosition(panel) & Node.DOCUMENT_POSITION_FOLLOWING);

    cleanup();
    window.location.hash = "#/mock";
    const mockStore = createStore("mock-tools-dom-order");
    render(<App store={mockStore} now={() => fixedNow} seedFactory={() => "mock-tools-dom-order"} />);
    await user.click(await screen.findByRole("button", { name: "Start mock exam" }));
    const mockQuestionPanel = document.querySelector(".mock-question-stack .question-panel");
    const navigator = screen.getByRole("navigation", { name: "Question navigator" });
    assert.ok(mockQuestionPanel);
    assert.ok(mockQuestionPanel.compareDocumentPosition(navigator) & Node.DOCUMENT_POSITION_FOLLOWING);
    const mockShell = screen.getByTestId("mock-exam-tools");
    assert.equal(mockShell.classList.contains("exam-tools-shell--open"), false);
    await user.click(screen.getByRole("button", { name: "Calculator" }));
    assert.equal(mockShell.classList.contains("exam-tools-shell--open"), true);
  });

  it("disables the Basic reference sheet in Advanced mock exams", async () => {
    window.location.hash = "#/mock";
    const store = createStore("advanced-tools-disabled");
    await store.putPreferences({ ...defaultPreferences, activeBankId: ADVANCED_BANK_ID });
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "advanced-tools-disabled"} />);

    await screen.findByRole("heading", { name: "Mock exam" });
    await user.click(await screen.findByRole("button", { name: "Start mock exam" }));
    await screen.findByText(/Question 1 of 50/);
    const referenceButton = screen.getByRole("button", { name: "Reference sheet" }) as HTMLButtonElement;
    assert.equal(referenceButton.disabled, true);
    assert.equal(referenceButton.getAttribute("aria-disabled"), "true");
  });

  it("localizes calculator decimal input and live announcements in French", async () => {
    setViewportWidth(768);
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/practice";
    const store = createStore("practice-calculator-fr");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "practice-calculator-fr"} />);

    await screen.findByRole("heading", { name: "Exercices" });
    await screen.findByText(/Question 1 sur/);
    await user.click(screen.getByRole("button", { name: "Calculatrice" }));
    await screen.findByRole("heading", { name: "Calculatrice" });
    await user.click(screen.getByRole("button", { name: "Chiffre 1" }));
    await user.click(screen.getByRole("button", { name: "Virgule décimale" }));
    await user.click(screen.getByRole("button", { name: "Chiffre 5" }));

    const display = document.querySelector<HTMLElement>(".calculator-display");
    assert.equal(display?.textContent, "1,5");
    assert.match(display?.getAttribute("aria-label") ?? "", /1,5/);
    assert.equal(screen.getByTestId("calculator-live-result").textContent, "Résultat de la calculatrice : 1,5");
  });

  it("keeps French reference sheet labels localized while marking sheet content English", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/practice";
    const store = createStore("reference-sheet-fr-labels");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "reference-sheet-fr-labels"} />);

    await screen.findByRole("heading", { name: "Exercices" });
    await screen.findByText(/Question 1 sur/);
    await user.click(screen.getByRole("button", { name: "Feuille de référence" }));
    const referencePanel = await screen.findByRole("region", { name: "Feuille de référence" });
    assert.equal(referencePanel.getAttribute("lang"), null);
    const ohmsHeading = within(referencePanel).getByRole("heading", { level: 3, name: "Ohm's law" });
    assert.equal(ohmsHeading.getAttribute("lang"), "en");
    const tableRegion = within(referencePanel).getByRole("region", { name: "Tableau de la feuille de référence 1" });
    assert.equal(tableRegion.getAttribute("lang"), null);
    assert.equal(tableRegion.querySelector("table")?.getAttribute("lang"), "en");
  });

  it("opens the Basic reference sheet with focus return and passes axe in light and dark", async () => {
    for (const theme of ["light", "dark"] as const) {
      cleanup();
      setViewportWidth(theme === "light" ? 320 : 1280);
      window.location.hash = "#/practice";
      const store = createStore(`practice-reference-${theme}`);
      await store.putPreferences({ ...defaultPreferences, theme });
      const user = userEvent.setup();
      const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => `practice-reference-${theme}`} />);

      await screen.findByRole("heading", { name: "Practice" });
      await screen.findByText(/Question 1 of/);
      const referenceButton = screen.getByRole("button", { name: "Reference sheet" });
      await user.click(referenceButton);
      const referencePanel = await screen.findByRole("region", { name: "Reference sheet" });
      await waitFor(() => assert.equal(document.activeElement, referencePanel));
      assert.equal(within(referencePanel).queryByRole("heading", { name: "Original Basic formula and reference study aid" }), null);
      assert.ok(within(referencePanel).getByRole("heading", { level: 3, name: "Ohm's law" }));
      assert.match(referencePanel.textContent ?? "", /E = I x R/);
      assert.match(referencePanel.textContent ?? "", /143 \/ f\(MHz\)/);
      assert.ok(within(referencePanel).getByRole("region", { name: "Reference sheet table 1" }));
      await expectNoAxeViolations(container);
      if (theme === "light") {
        await user.keyboard("{Escape}");
      } else {
        await user.click(screen.getByRole("button", { name: "Close tool" }));
      }
      await waitFor(() => assert.equal(document.activeElement, referenceButton));
    }
  });

  it("keeps mock exam tools non-modal while the timer continues", async () => {
    setViewportWidth(1280);
    window.location.hash = "#/mock";
    const store = createStore("mock-tools-timer");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "mock-tools-timer"} />);

    await screen.findByRole("heading", { name: "Mock exam" });
    await user.click(screen.getByLabelText("Enable optional timer"));
    await user.click(screen.getByRole("button", { name: "Start mock exam" }));
    await screen.findByText(/Question 1 of 100/);
    await user.click(screen.getByRole("button", { name: "Calculator" }));
    await screen.findByRole("heading", { name: "Calculator" });

    await waitFor(() => assert.match(screen.getByRole("timer").textContent ?? "", /00:01/), { timeout: 1500 });
    const firstAnswer = screen.getAllByTestId("answer-choice")[0]!;
    await user.click(firstAnswer);
    assert.equal(firstAnswer.getAttribute("aria-pressed"), "true");
    await expectNoAxeViolations(container);

    await user.click(screen.getByRole("button", { name: "Reference sheet" }));
    await screen.findByRole("heading", { name: "Reference sheet" });
    assert.match(screen.getByRole("region", { name: "Reference sheet" }).textContent ?? "", /Metric prefixes/);
  });

  it("switches to Advanced, persists the course, hides lessons, and generates a 50-question no-Honours mock", async () => {
    window.location.hash = "#/home";
    const store = createStore("advanced-course-switcher");
    const user = userEvent.setup();
    const { container, unmount } = render(<App store={store} now={() => fixedNow} seedFactory={() => "advanced-web-seed"} />);

    await screen.findByRole("heading", { name: "Ready for Basic with Honours?" });
    await user.click(screen.getByRole("radio", { name: "Advanced" }));
    await screen.findByRole("heading", { name: "Ready for the Advanced qualification?" });
    assert.equal((await store.getPreferences()).activeBankId, ADVANCED_BANK_ID);

    await user.click(screen.getAllByRole("button", { name: "Learn" })[0]!);
    await screen.findByRole("heading", { name: "Advanced lessons are coming" });
    assert.equal(screen.queryByText(referenceSheetNote), null);

    await user.click(screen.getByRole("button", { name: "Mock exam" }));
    assert.match(screen.getByText(/Generate 50 Advanced questions/).textContent ?? "", /Generate 50 Advanced questions/);
    assert.match(screen.getByText(/No ISED reference sheet/).textContent ?? "", /No ISED reference sheet/);
    await user.click(await screen.findByRole("button", { name: "Start mock exam" }));
    await screen.findByText(/Question 1 of 50/);
    assert.equal(screen.queryByText(referenceSheetNote), null);

    await expectNoAxeViolations(container);
    unmount();

    window.location.hash = "#/home";
    render(<App store={store} now={() => fixedNow} seedFactory={() => "advanced-web-seed-2"} />);
    await screen.findByRole("heading", { name: "Ready for the Advanced qualification?" });
  });

  it("confirms before a course switch discards an unfinished mock exam", async () => {
    window.location.hash = "#/mock";
    const store = createStore("course-switch-confirmation");
    render(<App store={store} now={() => fixedNow} seedFactory={() => "course-switch-confirmation-seed"} />);

    await screen.findByRole("heading", { name: "Mock exam" });
    fireEvent.click(screen.getByRole("button", { name: "Start mock exam" }));
    await screen.findByText(/Question 1 of 100/);

    fireEvent.click(screen.getByRole("radio", { name: "Advanced" }));
    const dialog = await screen.findByRole("alertdialog", { name: "Switch course?" });
    assert.equal(document.activeElement, dialog);
    assert.match(dialog.textContent ?? "", /discard the unfinished practice or mock exam session/);
    await expectNoAxeViolations(dialog);

    fireEvent.keyDown(dialog, { key: "Escape" });
    assert.equal(screen.queryByRole("alertdialog", { name: "Switch course?" }), null);
    assert.equal((screen.getByRole("radio", { name: "Basic" }) as HTMLInputElement).checked, true);
    assert.ok(screen.getByText(/Question 1 of 100/));
    assert.equal((await store.getPreferences()).activeBankId, bankId);

    fireEvent.click(screen.getByRole("radio", { name: "Advanced" }));
    const cancelDialog = await screen.findByRole("alertdialog", { name: "Switch course?" });
    fireEvent.click(within(cancelDialog).getByRole("button", { name: "Cancel course switch" }));
    assert.equal(screen.queryByRole("alertdialog", { name: "Switch course?" }), null);
    const courseSwitcher = screen.getByRole("group", { name: "Course selection" });
    await waitFor(() => assert.ok(document.activeElement === courseSwitcher, "course switcher focused after Cancel"));
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.ok(document.activeElement === courseSwitcher, "focus stays on the course switcher after Cancel");
    assert.equal((screen.getByRole("radio", { name: "Basic" }) as HTMLInputElement).checked, true);
    assert.ok(screen.getByText(/Question 1 of 100/));
    assert.equal((await store.getPreferences()).activeBankId, bankId);

    fireEvent.click(screen.getByRole("radio", { name: "Advanced" }));
    fireEvent.click(within(await screen.findByRole("alertdialog", { name: "Switch course?" })).getByRole("button", { name: "Switch course" }));
    await screen.findByRole("heading", { name: "Mock exam" });
    assert.match(screen.getByText(/Generate 50 Advanced questions/).textContent ?? "", /Generate 50 Advanced questions/);
    assert.equal((await store.getPreferences()).activeBankId, ADVANCED_BANK_ID);
    await waitFor(() => assert.ok(document.activeElement === screen.getByRole("group", { name: "Course selection" }), "course switcher focused after Confirm"));
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.ok(document.activeElement === screen.getByRole("group", { name: "Course selection" }), "focus stays on the course switcher after Confirm");
  });

  it("clears a stale course switch warning once the exam is submitted", async () => {
    window.location.hash = "#/mock";
    const store = createStore("course-switch-stale-warning");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "course-switch-stale-seed"} />);

    await user.click(await screen.findByRole("button", { name: "Start mock exam" }));
    // Leave the warning open, submit the exam, then pick Advanced again.
    await user.click(screen.getByRole("radio", { name: "Advanced" }));
    await screen.findByRole("alertdialog", { name: "Switch course?" });
    await user.click(screen.getAllByTestId("answer-choice")[0]!);
    await user.click(screen.getByRole("button", { name: "Submit exam" }));
    await user.click(screen.getByRole("button", { name: "Confirm submit" }));
    await screen.findByRole("heading", { name: "Mock exam results" });
    await user.click(screen.getByRole("radio", { name: "Advanced" }));
    await waitFor(async () => assert.equal((await store.getPreferences()).activeBankId, ADVANCED_BANK_ID));
    assert.ok(screen.queryByRole("alertdialog", { name: "Switch course?" }) === null, "no stale warning after switching");
  });

  it("does not confirm a course switch for an unanswered practice session", async () => {
    window.location.hash = "#/practice";
    const store = createStore("course-switch-unanswered-practice");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "course-switch-unanswered-practice-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);

    await user.click(screen.getByRole("radio", { name: "Advanced" }));

    assert.equal(screen.queryByRole("alertdialog", { name: "Switch course?" }), null);
    await waitFor(async () => assert.equal((await store.getPreferences()).activeBankId, ADVANCED_BANK_ID));
  });

  it("confirms before a course switch discards a partially answered immediate-practice session", async () => {
    window.location.hash = "#/practice";
    const store = createStore("course-switch-answered-immediate-practice");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "course-switch-answered-immediate-practice-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await user.click(screen.getByRole("button", { name: "Start set" }));
    await user.click((await screen.findAllByTestId("answer-choice"))[0]!);
    await screen.findByRole("status");

    await user.click(screen.getByRole("radio", { name: "Advanced" }));
    let dialog = await screen.findByRole("alertdialog", { name: "Switch course?" });
    assert.match(dialog.textContent ?? "", /discard the unfinished practice or mock exam session/);

    await user.click(within(dialog).getByRole("button", { name: "Cancel course switch" }));
    assert.equal(screen.queryByRole("alertdialog", { name: "Switch course?" }), null);
    assert.equal((screen.getByRole("radio", { name: "Basic" }) as HTMLInputElement).checked, true);
    assert.ok(screen.getByRole("status").textContent?.trim(), "Cancel should keep the answered immediate-practice feedback");

    await user.click(screen.getByRole("radio", { name: "Advanced" }));
    dialog = await screen.findByRole("alertdialog", { name: "Switch course?" });
    await user.click(within(dialog).getByRole("button", { name: "Switch course" }));
    await waitFor(async () => assert.equal((await store.getPreferences()).activeBankId, ADVANCED_BANK_ID));
    await waitFor(() => assert.match(document.querySelector(".question-meta")?.textContent ?? "", /A-00[1-7]-/));
  });

  it("confirms before a course switch discards a fully answered unsubmitted review-later practice session", async () => {
    window.location.hash = "#/practice";
    const store = createStore("course-switch-review-later-unsubmitted");
    await store.putPreferences({ ...defaultPreferences, practiceMode: "review-later" });
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "course-switch-review-later-unsubmitted-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await user.click(screen.getByRole("button", { name: "Start set" }));
    await answerEveryReviewLaterQuestion(user);
    assert.equal((screen.getByRole("button", { name: "Submit practice set" }) as HTMLButtonElement).disabled, false);

    await user.click(screen.getByRole("radio", { name: "Advanced" }));
    let dialog = await screen.findByRole("alertdialog", { name: "Switch course?" });
    assert.match(dialog.textContent ?? "", /discard the unfinished practice or mock exam session/);

    await user.click(within(dialog).getByRole("button", { name: "Cancel course switch" }));
    assert.equal(screen.queryByRole("alertdialog", { name: "Switch course?" }), null);
    assert.equal((screen.getByRole("radio", { name: "Basic" }) as HTMLInputElement).checked, true);
    assert.equal((screen.getByRole("button", { name: "Submit practice set" }) as HTMLButtonElement).disabled, false);

    await user.click(screen.getByRole("radio", { name: "Advanced" }));
    dialog = await screen.findByRole("alertdialog", { name: "Switch course?" });
    await user.click(within(dialog).getByRole("button", { name: "Switch course" }));
    await waitFor(async () => assert.equal((await store.getPreferences()).activeBankId, ADVANCED_BANK_ID));
    await waitFor(() => assert.match(document.querySelector(".question-meta")?.textContent ?? "", /A-00[1-7]-/));
  });

  it("does not confirm a course switch after a review-later practice session is submitted", async () => {
    window.location.hash = "#/practice";
    const store = createStore("course-switch-review-later-submitted");
    await store.putPreferences({ ...defaultPreferences, practiceMode: "review-later" });
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "course-switch-review-later-submitted-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await user.click(screen.getByRole("button", { name: "Start set" }));
    await answerEveryReviewLaterQuestion(user);
    await user.click(screen.getByRole("button", { name: "Submit practice set" }));
    await screen.findByRole("heading", { name: "Practice set review" });

    await user.click(screen.getByRole("radio", { name: "Advanced" }));

    assert.equal(screen.queryByRole("alertdialog", { name: "Switch course?" }), null);
    await waitFor(async () => assert.equal((await store.getPreferences()).activeBankId, ADVANCED_BANK_ID));
  });

  async function answerEveryReviewLaterQuestion(user: ReturnType<typeof userEvent.setup>): Promise<void> {
    for (;;) {
      await user.click((await screen.findAllByTestId("answer-choice"))[0]!);
      const next = screen.getByRole("button", { name: "Next" }) as HTMLButtonElement;
      if (next.disabled) {
        return;
      }
      await user.click(next);
    }
  }

  it("renders the French interface with Advanced selected and tags verified Advanced category names as French", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/home";
    const store = createStore("advanced-french-ui");
    await store.putPreferences({ ...defaultPreferences, activeBankId: ADVANCED_BANK_ID });
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "advanced-fr-seed"} />);

    await screen.findByRole("heading", { name: "Prêt pour la compétence supérieure?" });
    const courseGroup = screen.getByRole("group", { name: "Sélection du cours" });
    assert.equal((within(courseGroup).getByRole("radio", { name: "Compétence supérieure" }) as HTMLInputElement).value, ADVANCED_BANK_ID);

    const advancedCategoryName = advancedBank.categories[0]?.name.fr;
    assert.ok(advancedCategoryName);
    const categoryName = await screen.findByText(advancedCategoryName);
    assert.equal(categoryName.getAttribute("lang"), "fr-CA");

    const primaryNav = screen.getByRole("navigation", { name: "Principale" });
    await user.click(within(primaryNav).getByRole("button", { name: "Examen simulé" }));
    await screen.findByRole("heading", { name: "Examen simulé" });
    assert.ok(screen.getByText("ISDE ne fournit pas de feuille de référence pour l’examen de compétence supérieure. N’utilisez pas la feuille de référence de la compétence de base comme matériel autorisé à l’examen de compétence supérieure."));
  });

  it("scores Advanced mocks at 70 percent without Honours", async () => {
    assert.equal(advancedBank.subsections.length, 50);
    const advancedQuestions = await loadQuestions(ADVANCED_BANK_ID);
    const generatedItems = createMockExam("advanced-scoring", advancedQuestions, advancedBank);
    const attempt = buildExamAttempt({
      bank: advancedBank,
      seed: "advanced-scoring",
      startedAt: "2026-01-02T00:00:00.000Z",
      submittedAt: "2026-01-02T01:00:00.000Z",
      timerEnabled: false,
      secondsElapsed: 0,
      generatedItems,
      selectedByQuestionId: new Map(generatedItems.map((item, index) => [item.questionId, index < 35 ? 0 : 1])),
      flaggedQuestionIds: new Set(),
    });

    assert.equal(generatedItems.length, 50);
    assert.equal(new Set(generatedItems.map((item) => item.subsectionId)).size, 50);
    assert.equal(attempt.bankId, ADVANCED_BANK_ID);
    assert.equal(attempt.score.percent, 70);
    assert.equal(attempt.score.passed, true);
    assert.equal(attempt.score.honours, false);
  });

  it("renders Mock exam with narrow DOM order, supports keyboard operation, and has no axe violations", async () => {
    window.location.hash = "#/mock";
    const store = createStore("mock");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "mock-seed"} />);

    await screen.findByRole("heading", { name: "Mock exam" });
    assert.equal(screen.getByText(referenceSheetNote).className, "reference-note");
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
    const actionRow = document.querySelector(".mock-question-stack > .action-row");
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
      await user.click((await screen.findAllByTestId("answer-choice"))[0]!);
      const next = screen.getByRole("button", { name: "Next" });
      if (!next.hasAttribute("disabled")) {
        await user.click(next);
      }
    }
    await user.click(screen.getByRole("button", { name: "Submit practice set" }));
    await screen.findByRole("heading", { name: "Practice set review" });
    assert.equal((await store.getQuestionProgress()).length, 10);
  });

  it("renders About content with source, bank, legal language tags, and no axe violations", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/about";
    const store = createStore("about-content");
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "about-seed"} />);

    await screen.findByRole("heading", { name: "À propos de Canadian Ham" });
    assert.equal(document.documentElement.lang, "fr-CA");
    assert.ok(screen.getByText((text) => text.includes(bankId) && text.includes(manifest.effectiveDate)));
    const questionBankSource = screen.getByText((text) => text.includes(manifest.source.url));
    assert.equal(questionBankSource.closest("a"), null);
    const rbr4Source = screen.getByText((text) => text.includes("RBR-4") && text.includes("ised-isde.canada.ca"));
    assert.equal(rbr4Source.closest("a"), null);
    assert.ok(screen.getByText(/ISDE fournit la feuille de référence de l’examen de compétence de base/));
    assert.ok(screen.getByText(/aucun compte, aucune analytique, aucune télémétrie, aucune publicité/));
    const attributionHeading = screen.getByRole("heading", { name: "Attribution" });
    assert.equal(attributionHeading.getAttribute("lang"), null);
    const attributionSection = attributionHeading.closest("section");
    assert.ok(attributionSection);
    const attribution = within(attributionSection).getByText(/used with permission/);
    assert.equal(attribution.closest("blockquote")?.getAttribute("lang"), "en");
    const disclaimerHeading = screen.getByRole("heading", { name: "Avis de non-responsabilité" });
    assert.equal(disclaimerHeading.getAttribute("lang"), null);
    const disclaimerSection = disclaimerHeading.closest("section");
    assert.ok(disclaimerSection);
    const disclaimer = within(disclaimerSection).getByText(/canadian-ham is an independent study tool/);
    assert.equal(disclaimer.getAttribute("lang"), "en");
    const legalStatus = within(attributionSection).getByText(/Draft attribution, not in effect/);
    assert.equal(legalStatus.getAttribute("lang"), "en");
    assert.match(legalStatus.textContent ?? "", /has not yet been granted/);
    assert.equal(container.querySelectorAll("main section[aria-labelledby]").length >= 6, true);
    await expectNoAxeViolations(container);
  });

  it("makes Morse reachable as a top-level section with the course path and settings", async () => {
    window.location.hash = "#/home";
    const store = createStore("morse-top-level");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-top-level-seed"} />);

    await screen.findByRole("heading", { name: "Ready for Basic with Honours?" });
    const primaryNav = screen.getByRole("navigation", { name: "Primary" });
    await user.click(within(primaryNav).getByRole("button", { name: "Morse" }));

    await screen.findByRole("heading", { name: "Morse course path" });
    assert.equal(window.location.hash, "#/morse");
    assert.ok(screen.getByText("Preview"));
    assert.ok(screen.getByRole("heading", { name: "Learn (course)" }));
    assert.ok(screen.getByRole("button", { name: /Lesson 1, K M, Current/ }));
    assert.ok(screen.getByRole("button", { name: /Lesson 2, R, Locked/ }));
    assert.ok(screen.getAllByRole("heading", { name: "Copy practice" }).length >= 1);
    assert.ok(screen.getAllByRole("heading", { name: "Exam" }).length >= 1);
    assert.ok(screen.getByRole("heading", { name: "Morse settings" }));
    assert.equal(screen.getByText("Hidden until playback finishes.").textContent, "Hidden until playback finishes.");
    await expectNoAxeViolations(container);
  });

  it("completes the first Morse lesson and persists unlock progress", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-course-flow");
    stubMorseAudioContext();
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-course-flow-seed"} />);

    await screen.findByRole("heading", { name: "Morse course path" });
    const course = parseMorseCourseFixture(courseFixture);
    const firstLesson = course.lessons[0]!;
    const exercises = buildMorseLessonExercises({ lesson: firstLesson, seed: "morse-course-flow-seed" });
    await user.click(screen.getByRole("button", { name: /Lesson 1, K M, Current/ }));
    const session = await screen.findByRole("region", { name: "Lesson 1 session" });
    for (const exercise of exercises) {
      if (exercise.kind === "meet") {
        await user.click(within(session).getByRole("button", { name: "Next" }));
      } else if (exercise.kind === "choose") {
        await user.click(within(session).getByRole("button", { name: exercise.character }));
      } else {
        const expected = exercise.kind === "type-character" ? exercise.character : exercise.text;
        const field = within(session).getByLabelText("Your copy");
        fireEvent.change(field, { target: { value: expected } });
        await user.click(within(session).getByRole("button", { name: "Check" }));
      }
    }

    await screen.findByText("Great work. The next lesson is unlocked.");
    const saved = await store.getMorseCourseProgress();
    assert.equal(saved?.lessonProgress[0]?.lessonId, "koch-001");
    assert.equal(saved?.lessonProgress[0]?.bestAccuracy, 1);
    assert.equal(saved?.lessonProgress[0]?.attempts, 1);
    assert.equal(saved?.dailyActivity[0]?.date, localDateString(fixedNow));
    assert.equal(screen.getByRole("button", { name: /Lesson 2, R, Current/ }).getAttribute("disabled"), null);
    assert.equal(within(session).queryByRole("button", { name: "Check" }), null);
  });

  it("surfaces Morse course playback failures accessibly", async () => {
    window.location.hash = "#/morse";
    vi.stubGlobal("AudioContext", undefined);
    vi.stubGlobal("webkitAudioContext", undefined);
    const store = createStore("morse-course-playback-failure");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-course-playback-failure-seed"} />);

    await screen.findByRole("heading", { name: "Morse course path" });
    await user.click(screen.getByRole("button", { name: /Lesson 1, K M, Current/ }));
    const session = await screen.findByRole("region", { name: "Lesson 1 session" });
    await user.click(within(session).getByRole("button", { name: "Play character" }));

    const alert = await screen.findByRole("alert");
    assert.match(alert.textContent ?? "", /Morse playback could not start: Web Audio is not available in this browser\./);
  });

  it("surfaces Morse course save failures before presenting unlock progress", async () => {
    window.location.hash = "#/morse";
    const store = new FailingMorseCourseStore("morse-course-save-failure");
    stores.push(store);
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-course-save-failure-seed"} />);

    await screen.findByRole("heading", { name: "Morse course path" });
    const course = parseMorseCourseFixture(courseFixture);
    const firstLesson = course.lessons[0]!;
    const exercises = buildMorseLessonExercises({ lesson: firstLesson, seed: "morse-course-save-failure-seed" });
    await user.click(screen.getByRole("button", { name: /Lesson 1, K M, Current/ }));
    const session = await screen.findByRole("region", { name: "Lesson 1 session" });
    for (const exercise of exercises) {
      if (exercise.kind === "meet") {
        await user.click(within(session).getByRole("button", { name: "Next" }));
      } else if (exercise.kind === "choose") {
        await user.click(within(session).getByRole("button", { name: exercise.character }));
      } else {
        const expected = exercise.kind === "type-character" ? exercise.character : exercise.text;
        const field = within(session).getByLabelText("Your copy");
        fireEvent.change(field, { target: { value: expected } });
        await user.click(within(session).getByRole("button", { name: "Check" }));
      }
    }

    const alert = await screen.findByRole("alert");
    assert.match(alert.textContent ?? "", /Unable to save Morse course progress: simulated Morse course save failure/);
    assert.ok(screen.getByText("Progress was not saved. Try again before relying on this result."));
    assert.equal(screen.queryByText("Great work. The next lesson is unlocked."), null);
    assert.equal((screen.getByRole("button", { name: /Lesson 2, R, Locked/ }) as HTMLButtonElement).disabled, true);
    assert.equal(await store.getMorseCourseProgress(), undefined);
  });

  it("leaves a completed Morse lesson session unchanged when an answer is resubmitted", () => {
    const completedSession: SessionState = {
      mode: "lesson",
      lesson: parseMorseCourseFixture(courseFixture).lessons[0]!,
      exercises: [{ kind: "type-character", character: "K" }],
      index: 0,
      correct: 1,
      total: 1,
      characterResults: [{ character: "K", correct: true }],
      feedback: "Correct.",
      done: true,
    };

    assert.equal(answerMorseCourseSession(completedSession, false, [{ character: "K", correct: false }], "en"), completedSession);
  });

  it("uses Morse course summary copy for review sessions and the final lesson", () => {
    const course = parseMorseCourseFixture(courseFixture);
    const reviewSession: SessionState = {
      mode: "review",
      lesson: null,
      exercises: [{ kind: "type-character", character: "K" }],
      index: 0,
      correct: 1,
      total: 1,
      characterResults: [{ character: "K", correct: true }],
      feedback: "Correct.",
      done: true,
    };
    const finalLessonSession: SessionState = { ...reviewSession, mode: "lesson", lesson: course.lessons[39]! };

    assert.equal(morseCourseSummaryMessage("en", reviewSession, 100, course.lessons.length), "Review complete. Practice progress was saved.");
    assert.equal(morseCourseSummaryMessage("en", finalLessonSession, 100, course.lessons.length), "Great work. All Morse lessons are complete.");
    assert.equal(morseCourseSummaryMessage("en", finalLessonSession, 80, course.lessons.length), "Reach 90% accuracy to complete this lesson.");
  });

  it("shows the correct answer on a missed Morse lesson item and keeps summary accessible", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-course-miss");
    stubMorseAudioContext();
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-course-miss-seed"} />);

    await screen.findByRole("heading", { name: "Morse course path" });
    const course = parseMorseCourseFixture(courseFixture);
    const firstLesson = course.lessons[0]!;
    const exercises = buildMorseLessonExercises({ lesson: firstLesson, seed: "morse-course-miss-seed" });
    await user.click(screen.getByRole("button", { name: /Lesson 1, K M, Current/ }));
    const session = await screen.findByRole("region", { name: "Lesson 1 session" });
    for (const exercise of exercises) {
      if (exercise.kind === "meet") {
        await user.click(within(session).getByRole("button", { name: "Next" }));
      } else if (exercise.kind === "choose") {
        const wrong = exercise.options.find((option) => option !== exercise.character)!;
        await user.click(within(session).getByRole("button", { name: wrong }));
        assert.match(session.textContent ?? "", new RegExp(`Correct answer: ${exercise.character.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`));
        break;
      }
    }
    await expectNoAxeViolations(container);
  });

  it("shows Morse start status visually without placing it in the live region", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-visual-start-status");
    await store.putPreferences(morsePreferences(true));
    stubMorseAudioContext();
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-visual-start-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    await user.click(screen.getByRole("button", { name: "Play Morse practice output" }));

    assert.match(container.querySelector(".morse-playback-status")?.textContent ?? "", /Morse playback started\./);
    assert.equal(container.querySelector(".morse-live-status")?.textContent, "");
    await user.click(screen.getByRole("button", { name: "Stop Morse practice output" }));
    assert.match(container.querySelector(".morse-live-status")?.textContent ?? "", /Morse playback stopped\./);
  });

  it("runs visual beacon playback with fake timers", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-beacon-fake-timer");
    await store.putPreferences({ ...morsePreferences(true), morse: { ...defaultPreferences.morse, outputMode: "visualBeacon" } });
    stubReducedMotion(false);
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-beacon-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Play Morse practice output" }));
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1);
      });
      assert.ok(container.querySelector(".morse-beacon-lamp.active"), "Beacon should be active for the first Morse element");
      await act(async () => {
        await vi.advanceTimersByTimeAsync(120_000);
      });
      assert.equal(container.querySelector(".morse-beacon-lamp.active"), null, "Beacon should be inactive after playback finishes");
    } finally {
      vi.useRealTimers();
    }
  });

  it("uses the non-flashing Morse tape when reduced motion is requested", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-reduced-motion-tape");
    await store.putPreferences({ ...morsePreferences(true), morse: { ...defaultPreferences.morse, outputMode: "visualBeacon" } });
    stubReducedMotion(true);
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-reduced-motion-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Play Morse practice output" }));
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1);
      });
      assert.equal(container.querySelector(".morse-beacon-lamp"), null);
      assert.match(container.querySelector(".morse-visual-tape")?.textContent ?? "", /[.\-·]/);
      assert.match(container.querySelector(".morse-output-view")?.textContent ?? "", /Reduced-motion preference is on/);
    } finally {
      vi.useRealTimers();
    }
  });

  it("passes axe on static Morse beacon and tape output states", async () => {
    const sequence = textToTimedMorse("5", profileForName("isedParis"));
    const flashesPerSecond = maxMorseFlashesPerSecond(morseSignalEvents(sequence));
    const safety = evaluateMorseBeaconFlashSafety({ palette: morseBeaconPalette({ accent: MORSE_LIGHT_ACCENT_RGB, background: MORSE_LIGHT_PAPER_INSET_RGB }), flashesPerSecond });
    const safetyNote = morseOutputSafetyNote("en", false, safety, flashesPerSecond);
    const beacon = render(<MorseOutputView interfaceLanguage="en" state={{ mode: "visualBeacon", beaconActive: true, tape: "", safetyNote }} />);
    assert.ok(beacon.container.textContent?.includes(safetyNote));
    assert.match(safetyNote, /square points/);
    assert.ok(safetyNote.includes(new Intl.NumberFormat(interfaceLanguageTag("en")).format(MORSE_BEACON_AREA_CSS_PIXELS)));
    await expectNoAxeViolations(beacon.container);
    beacon.unmount();

    const tape = render(<MorseOutputView interfaceLanguage="fr" state={{ mode: "visualTape", beaconActive: false, tape: ".-.", safetyNote: t("fr", "morseOutputReducedMotionTape") }} />);
    assert.match(tape.container.textContent ?? "", /\.\-\./);
    await expectNoAxeViolations(tape.container);
  });

  it("announces Morse finish after playback completes", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-finished-status");
    await store.putPreferences(morsePreferences(true));
    stubMorseAudioContext();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-finished-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    vi.useFakeTimers();
    try {
      fireEvent.click(screen.getByRole("button", { name: "Play Morse practice output" }));
      assert.match(container.querySelector(".morse-playback-status")?.textContent ?? "", /Morse playback started\./);

      await act(async () => {
        await vi.advanceTimersByTimeAsync(120_000);
      });

      assert.match(container.querySelector(".morse-live-status")?.textContent ?? "", /Morse playback finished\./);
    } finally {
      vi.useRealTimers();
    }
  });

  it("runs Morse copy practice with typed copy and an accessible diff", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-copy-practice");
    await store.putPreferences(morsePreferences(true));
    stubMorseAudioContext();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-copy-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    const copyHeading = screen.getAllByRole("heading", { name: "Copy practice" }).at(-1);
    assert.ok(copyHeading);
    const copySection = copyHeading.closest("section");
    assert.ok(copySection);
    vi.useFakeTimers();
    try {
      fireEvent.click(within(copySection).getByRole("button", { name: "Start copy practice" }));
      const copyInput = within(copySection).getByLabelText("Your copy");
      fireEvent.change(copyInput, { target: { value: "THE NET OPENS AT NOON. QSX" } });
      await act(async () => {
        await vi.advanceTimersByTimeAsync(90_000);
      });
      fireEvent.click(within(copySection).getByRole("button", { name: "Check copy" }));
    } finally {
      vi.useRealTimers();
    }

    assert.ok(within(copySection).getByRole("heading", { name: "Character diff" }));
    assert.ok(copySection.querySelector('[aria-label="Wrong: expected ?, received X"]'));
    assert.match(copySection.textContent ?? "", /Practice accuracy: \d+%\./);
    assert.match(copySection.textContent ?? "", /wrong/i);
    assert.match(copySection.textContent ?? "", /total errors/i);
    assert.doesNotMatch(copySection.textContent ?? "", /Exam rule|PASS|FAIL/);
    await expectNoAxeViolations(container);
  });

  it("clears Morse copy and exam state when audio startup fails", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-audio-start-failure");
    await store.putPreferences(morsePreferences(true));
    stubFailingMorseAudioContext();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-audio-failure-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    const copyHeading = screen.getAllByRole("heading", { name: "Copy practice" }).at(-1);
    assert.ok(copyHeading);
    const copySection = copyHeading.closest("section");
    assert.ok(copySection);
    fireEvent.click(within(copySection).getByRole("button", { name: "Start copy practice" }));

    await waitFor(() => assert.match(copySection.textContent ?? "", /Morse playback could not start: simulated audio-start failure/));
    const copyInput = within(copySection).getByLabelText("Your copy") as HTMLTextAreaElement;
    assert.equal(copyInput.value, "");
    assert.equal(copyInput.disabled, true);
    assert.equal((within(copySection).getByRole("button", { name: "Check copy" }) as HTMLButtonElement).disabled, true);
    assert.equal(copySection.querySelector(".morse-duration"), null);
    assert.equal(within(copySection).queryByRole("heading", { name: "Character diff" }), null);

    const examHeading = screen.getAllByRole("heading", { name: "Exam" }).at(-1);
    assert.ok(examHeading);
    const examSection = examHeading.closest("section");
    assert.ok(examSection);
    fireEvent.click(within(examSection).getByRole("button", { name: "Start simulated exam" }));

    await waitFor(() => assert.match(examSection.textContent ?? "", /Morse playback could not start: simulated audio-start failure/));
    const examInput = within(examSection).getByLabelText("Your copy") as HTMLTextAreaElement;
    assert.equal(examInput.value, "");
    assert.equal(examInput.disabled, true);
    assert.doesNotMatch(examSection.textContent ?? "", /Generated exam/);
  });

  it("coordinates course audio with the shared one-player-at-a-time Morse controller", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-course-one-player-at-a-time");
    await store.putPreferences(morsePreferences(true));
    const audio = stubMorseAudioContext();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-course-one-player-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    const quickPlay = screen.getByRole("button", { name: "Play Morse practice output" }) as HTMLButtonElement;
    const quickStop = screen.getByRole("button", { name: "Stop Morse practice output" }) as HTMLButtonElement;
    fireEvent.click(quickPlay);
    await waitFor(() => assert.equal(quickStop.disabled, false));
    const quickOscillator = audio.oscillators().at(-1);
    assert.ok(quickOscillator);
    const quickStopCallsAfterStart = quickOscillator.stopCalls();

    fireEvent.click(screen.getByRole("button", { name: /Lesson 1, K M, Current/ }));
    const session = await screen.findByRole("region", { name: "Lesson 1 session" });
    fireEvent.click(within(session).getByRole("button", { name: "Play character" }));
    await waitFor(() => assert.equal(quickStop.disabled, true));
    assert.ok(quickOscillator.stopCalls() > quickStopCallsAfterStart, "Starting course audio should stop the Quick listen oscillator");
    assert.match(container.querySelector(".morse-playback-status")?.textContent ?? "", /Morse playback stopped\./);
    const courseOscillator = audio.oscillators().at(-1);
    assert.ok(courseOscillator);
    const courseStopCallsAfterStart = courseOscillator.stopCalls();

    const copyHeading = screen.getAllByRole("heading", { name: "Copy practice" }).at(-1);
    assert.ok(copyHeading);
    const copySection = copyHeading.closest("section");
    assert.ok(copySection);
    const copyStop = within(copySection).getByRole("button", { name: "Stop" }) as HTMLButtonElement;
    fireEvent.click(within(copySection).getByRole("button", { name: "Start copy practice" }));
    await waitFor(() => assert.equal(copyStop.disabled, false));
    assert.ok(courseOscillator.stopCalls() > courseStopCallsAfterStart, "Starting copy practice should stop the course oscillator");
  });

  it("stops any active Morse playback before starting another player", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-one-player-at-a-time");
    await store.putPreferences(morsePreferences(true));
    stubMorseAudioContext();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-one-player-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    const quickPlay = screen.getByRole("button", { name: "Play Morse practice output" }) as HTMLButtonElement;
    const quickStop = screen.getByRole("button", { name: "Stop Morse practice output" }) as HTMLButtonElement;
    fireEvent.click(quickPlay);
    await waitFor(() => assert.equal(quickStop.disabled, false));

    const copyHeading = screen.getAllByRole("heading", { name: "Copy practice" }).at(-1);
    assert.ok(copyHeading);
    const copySection = copyHeading.closest("section");
    assert.ok(copySection);
    const copyStop = within(copySection).getByRole("button", { name: "Stop" }) as HTMLButtonElement;
    fireEvent.click(within(copySection).getByRole("button", { name: "Start copy practice" }));
    await waitFor(() => assert.equal(copyStop.disabled, false));
    assert.equal(quickStop.disabled, true);
    assert.match(container.querySelector(".morse-playback-status")?.textContent ?? "", /Morse playback stopped\./);

    const examHeading = screen.getAllByRole("heading", { name: "Exam" }).at(-1);
    assert.ok(examHeading);
    const examSection = examHeading.closest("section");
    assert.ok(examSection);
    fireEvent.click(within(examSection).getByRole("button", { name: "Start simulated exam" }));
    await waitFor(() => assert.match(examSection.textContent ?? "", /Exam playback started/));
    assert.equal(copyStop.disabled, true);
    assert.match(copySection.textContent ?? "", /Morse playback stopped\./);
  });

  it("localizes Morse diff token screen-reader labels in French", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/morse";
    const store = createStore("morse-copy-practice-fr");
    await store.putPreferences(morsePreferences(true));
    stubMorseAudioContext();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-copy-fr-seed"} />);

    await screen.findByRole("heading", { name: "Écoute rapide" });
    const copyHeading = screen.getAllByRole("heading", { name: "Copie" }).at(-1);
    assert.ok(copyHeading);
    const copySection = copyHeading.closest("section");
    assert.ok(copySection);
    vi.useFakeTimers();
    try {
      fireEvent.click(within(copySection).getByRole("button", { name: "Démarrer la copie" }));
      fireEvent.change(within(copySection).getByLabelText("Votre copie"), { target: { value: "THE NET OPENS AT NOON. QSX" } });
      await act(async () => {
        await vi.advanceTimersByTimeAsync(90_000);
      });
      fireEvent.click(within(copySection).getByRole("button", { name: "Vérifier la copie" }));
    } finally {
      vi.useRealTimers();
    }

    assert.ok(within(copySection).getByRole("heading", { name: "Différence par caractère" }));
    assert.ok(copySection.querySelector('[aria-label="Erroné : attendu ?, reçu X"]'));
  });

  it("runs the simulated Morse exam through playback, review, grading, axe, and diff", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-exam-flow");
    await store.putPreferences(morsePreferences(true));
    stubMorseAudioContext();
    const examSeed = "web-isedParis-morse-exam-seed";
    const generatedExam = generateMorseExamText({ seed: examSeed, profile: profileForName("isedParis") });
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-exam-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    const examHeading = screen.getAllByRole("heading", { name: "Exam" }).at(-1);
    assert.ok(examHeading);
    const examSection = examHeading.closest("section");
    assert.ok(examSection);
    vi.useFakeTimers();
    try {
      fireEvent.click(within(examSection).getByRole("button", { name: "Start simulated exam" }));
      fireEvent.change(within(examSection).getByLabelText("Your copy"), { target: { value: "ABC" } });
      await act(async () => {
        await vi.advanceTimersByTimeAsync(Math.ceil(generatedExam.durationSeconds * 1000) + 80);
      });
      assert.match(examSection.textContent ?? "", /Review time remaining/);
      await act(async () => {
        await vi.advanceTimersByTimeAsync(121_000);
      });
    } finally {
      vi.useRealTimers();
    }

    assert.match(examSection.textContent ?? "", /FAIL/);
    assert.match(examSection.textContent ?? "", /Exam rule:/);
    assert.doesNotMatch(examSection.textContent ?? "", /Practice accuracy/);
    assert.ok(within(examSection).getByRole("heading", { name: "Character diff" }));
    await expectNoAxeViolations(container);
  });

  it("opens #/morse directly without waiting on retired preview gating", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-direct");
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-direct-seed"} />);

    await screen.findByRole("heading", { name: "Quick listen" });
    assert.equal(window.location.hash, "#/morse");
  });

  it("waits for stored Morse preferences before rendering #/morse", async () => {
    window.location.hash = "#/morse";
    const store = new DelayedInitialPreferencesStore("morse-stored-enabled-redirect");
    stores.push(store);
    await store.putPreferences(morsePreferences(true));
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-stored-enabled-seed"} />);

    await store.initialPreferencesReadStarted;
    assert.equal(window.location.hash, "#/morse");
    store.releaseInitialPreferences();
    await store.initialPreferencesReturned;

    await screen.findByRole("heading", { name: "Quick listen" });
    assert.equal(window.location.hash, "#/morse");
  });

  it("lets Morse number inputs accept multi-digit drafts before committing", async () => {
    window.location.hash = "#/morse";
    const store = createStore("morse-number-drafts");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-drafts-seed"} />);

    await screen.findByRole("heading", { name: "Morse settings" });
    const tone = screen.getByLabelText("Tone") as HTMLInputElement;
    await user.clear(tone);
    await user.type(tone, "700");
    assert.equal(tone.value, "700");
    assert.equal((await store.getPreferences()).morse.toneHz, 650);
    await user.keyboard("{Enter}");
    await waitFor(async () => assert.equal((await store.getPreferences()).morse.toneHz, 700));

    assert.equal((screen.getByLabelText("Character speed") as HTMLInputElement).value, "12");
    assert.equal((screen.getByLabelText("Effective speed") as HTMLInputElement).value, "5");
    await user.selectOptions(screen.getByLabelText("Timing profile"), "general");
    await waitFor(async () => assert.equal((await store.getPreferences()).morse.timingProfile, "general"));
    const characterSpeed = screen.getByLabelText("Character speed") as HTMLInputElement;
    await user.clear(characterSpeed);
    await user.type(characterSpeed, "20");
    assert.equal(characterSpeed.value, "20");
    await user.keyboard("{Enter}");
    await waitFor(async () => assert.equal((await store.getPreferences()).morse.characterWpm, 20));
  });

  it("reverts empty or invalid Morse number drafts with a polite explanation and does not save unchanged values", async () => {
    window.location.hash = "#/morse";
    const store = new CountingPreferencesStore("morse-invalid-drafts");
    stores.push(store);
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-invalid-seed"} />);

    const settingsHeading = await screen.findByRole("heading", { name: "Morse settings" });
    const settingsSection = settingsHeading.closest("section");
    assert.ok(settingsSection);
    const tone = screen.getByLabelText("Tone") as HTMLInputElement;
    await user.clear(tone);
    fireEvent.blur(tone);
    assert.equal(tone.value, "650");
    assert.equal((await store.getPreferences()).morse.toneHz, 650);
    assert.equal(store.putPreferencesCount, 0);

    await user.clear(tone);
    await user.type(tone, "999");
    fireEvent.blur(tone);
    assert.equal(tone.value, "650");
    assert.equal((await store.getPreferences()).morse.toneHz, 650);
    assert.equal(store.putPreferencesCount, 0);
    assert.equal(within(settingsSection).getByRole("status").textContent, "Tone reverted to the saved value. Enter a whole number from 400 to 900.");

    await user.clear(tone);
    await user.type(tone, "650");
    await user.keyboard("{Enter}");
    assert.equal(store.putPreferencesCount, 0);
    assert.equal(screen.queryByText("Morse trainer settings saved locally."), null, "an unchanged commit must not report a save");
    await expectNoAxeViolations(container);
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

  it("gates practice answering until the initial IndexedDB load finishes", async () => {
    window.location.hash = "#/practice";
    const store = new DelayedInitialPreferencesStore("practice-load-gate");
    stores.push(store);
    render(<App store={store} now={() => fixedNow} seedFactory={() => "practice-race-seed"} />);

    await store.initialPreferencesReadStarted;
    assert.ok(screen.getByRole("status", { name: /Loading/ }));
    assert.equal(screen.queryByTestId("answer-choice"), null);

    await act(async () => {
      store.releaseInitialPreferences();
      await store.initialPreferencesReturned;
    });

    await screen.findByRole("heading", { name: "Practice" });
    fireEvent.click(screen.getAllByTestId("answer-choice")[0]!);
    await waitFor(async () => assert.equal((await store.getQuestionProgress()).length, 1));
  });

  it("keeps stored preference fields when a gated theme change is the first user edit", async () => {
    window.location.hash = "#/settings";
    const store = new DelayedInitialPreferencesStore("settings-theme-load-race");
    stores.push(store);
    await store.putPreferences({ ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "light" });
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "settings-race-seed"} />);

    await store.initialPreferencesReadStarted;
    assert.ok(screen.getByRole("status", { name: /Loading/ }));
    assert.equal(screen.queryByLabelText("Dark"), null);

    await act(async () => {
      store.releaseInitialPreferences();
      await store.initialPreferencesReturned;
    });

    await screen.findByRole("heading", { name: "Settings and local data" });
    await user.click(screen.getByLabelText("Dark"));
    await waitFor(async () => {
      assert.deepEqual(await store.getPreferences(), { ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "dark" });
      assert.equal(document.documentElement.dataset.theme, "dark");
    });
    assert.equal(window.localStorage.getItem(THEME_STORAGE_KEY), "dark");
  });

  it("persists two quick preference edits to different fields", async () => {
    window.location.hash = "#/practice";
    const store = new DelayedPreferencesStore("settings-overlapping-preference-saves");
    stores.push(store);
    render(<App store={store} now={() => fixedNow} seedFactory={() => "settings-overlap-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    fireEvent.click(screen.getByLabelText("Review later"));
    await waitFor(() => assert.equal(store.pendingPreferenceSaves.length, 1));

    const primaryNav = screen.getByRole("navigation", { name: "Primary" });
    fireEvent.click(within(primaryNav).getByRole("button", { name: "Settings" }));
    await screen.findByRole("heading", { name: "Settings and local data" });
    fireEvent.click(screen.getByLabelText("Dark"));

    assert.deepEqual(store.pendingPreferenceSaves[0]?.preferences, { ...defaultPreferences, practiceMode: "review-later" });
    store.releaseNextPreferenceSave();
    await waitFor(() => assert.equal(store.pendingPreferenceSaves.length, 1));
    assert.deepEqual(store.pendingPreferenceSaves[0]?.preferences, { ...defaultPreferences, practiceMode: "review-later", theme: "dark" });
    store.releaseNextPreferenceSave();
    await waitFor(async () => assert.deepEqual(await store.getPreferences(), { ...defaultPreferences, practiceMode: "review-later", theme: "dark" }));
  });

  it("does not announce Theme saved for a superseded failed preference save", async () => {
    window.location.hash = "#/settings";
    const store = new DelayedPreferencesStore("settings-superseded-failed-theme-save");
    stores.push(store);
    render(<App store={store} now={() => fixedNow} seedFactory={() => "settings-stale-failure-seed"} />);

    await screen.findByRole("heading", { name: "Settings and local data" });
    fireEvent.click(screen.getByLabelText("Dark"));
    await waitFor(() => assert.equal(store.pendingPreferenceSaves.length, 1));
    fireEvent.click(screen.getByLabelText("Light"));

    assert.deepEqual(store.pendingPreferenceSaves[0]?.preferences, { ...defaultPreferences, theme: "dark" });
    store.rejectNextPreferenceSave(new Error("simulated stale preferences failure"));
    await waitFor(() => assert.equal(store.pendingPreferenceSaves.length, 1));
    assert.equal(screen.queryByText(/Theme preference saved:/), null);
    assert.deepEqual(store.pendingPreferenceSaves[0]?.preferences, { ...defaultPreferences, theme: "light" });

    store.releaseNextPreferenceSave();
    await screen.findByText(/Theme preference saved: Light/);
    await waitFor(async () => assert.equal((await store.getPreferences()).theme, "light"));
  });

  it("rolls back an in-memory preference change when saving it fails", async () => {
    window.location.hash = "#/settings";
    const store = new FailingPreferencesStore("settings-theme-save-failure");
    stores.push(store);
    store.failNextPreferencesSave = false;
    await store.putPreferences({ ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "light" });
    store.failNextPreferencesSave = true;
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "settings-save-failure-seed"} />);

    await screen.findByRole("heading", { name: "Settings and local data" });
    await user.click(screen.getByLabelText("Dark"));

    await waitFor(() => {
      assert.equal((screen.getByLabelText("Light") as HTMLInputElement).checked, true);
      assert.equal((screen.getByLabelText("Dark") as HTMLInputElement).checked, false);
      assert.equal(document.documentElement.dataset.theme, "light");
    });
    assert.deepEqual(await store.getPreferences(), { ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "light" });
    assert.ok(screen.getAllByRole("alert").some((alert) => /simulated preferences failure/.test(alert.textContent ?? "")));
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

  it("keeps the recovery skip link focused without appending #main to the route", async () => {
    const store = createStore("error-boundary-skip-link");
    const user = userEvent.setup();
    function BrokenContent() {
      throw new Error("corrupt local progress");
      return null;
    }

    render(<AppErrorBoundary store={store} now={() => fixedNow}><BrokenContent /></AppErrorBoundary>);
    await screen.findByText(/The app could not render saved progress/);
    const skipLink = screen.getByRole("link", { name: "Skip to main content" });
    await user.click(skipLink);

    const main = document.querySelector("main#main");
    assert.ok(main);
    await waitFor(() => assert.equal(document.activeElement, main));
    assert.equal(window.location.hash, "#/home");
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

  it("sets the root and question language from the Settings language preference", async () => {
    window.location.hash = "#/settings";
    const store = createStore("language-scope");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "language-seed"} />);

    await screen.findByRole("heading", { name: "Settings and local data" });
    const languageGroup = screen.getByRole("group", { name: "Language" });
    await user.click(within(languageGroup).getByRole("radio", { name: "Français" }));

    await screen.findByRole("heading", { name: "Réglages et données locales" });
    assert.equal(screen.getByText("Français").getAttribute("lang"), "fr");
    assert.equal(document.documentElement.lang, "fr-CA");

    await user.click(within(screen.getByRole("navigation", { name: "Principale" })).getByRole("button", { name: "Exercices" }));
    await screen.findByText(/Question 1 sur/);
    assert.ok(document.querySelector(".question-text[lang='fr-CA']"));
  });

  it("does not render reference PDF links", async () => {
    const store = createStore("reference-links-removed");
    const user = userEvent.setup();
    const { container } = render(<App store={store} now={() => fixedNow} seedFactory={() => "reference-seed"} />);

    await screen.findByRole("heading", { name: "Ready for Basic with Honours?" });
    assert.equal(screen.queryByRole("link", { name: /reference sheet/i }), null);
    assert.equal(screen.queryByText(/Reference Material.*\.pdf/i), null);
    assertNoPdfLinks(container);

    await user.click(screen.getAllByRole("button", { name: "Learn" })[0]!);
    await screen.findByRole("heading", { name: "Learn" });
    assert.equal(screen.getByText(referenceSheetNote).className, "reference-note");
    assertNoPdfLinks(container);

    await user.click(screen.getAllByRole("button", { name: "Mock exam" })[0]!);
    await screen.findByRole("heading", { name: "Mock exam" });
    assert.equal(screen.getByText(referenceSheetNote).className, "reference-note");
    assert.equal(screen.queryByRole("link", { name: /reference sheet/i }), null);
    assert.equal(screen.queryByText(/\.pdf/i), null);
    assertNoPdfLinks(container);
  });

  it("renders the B-001-017-009 explanation panel citation as a user-activated external link without preloading or fetching it", () => {
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);
    const explanation = explanationForQuestion("B-001-017-009");
    assert.ok(explanation);
    const citation = explanation.citations.find((candidate) => candidate.url !== undefined);
    assert.ok(citation?.url);

    render(<ExplanationPanel explanation={explanation} language="en" />);

    const panel = screen.getByRole("region", { name: "Explanation for B-001-017-009" });
    const citationLink = within(panel).getByRole("link", { name: `${citation.id ?? citation.type} (external site) (opens in new tab)` });
    assert.equal(citationLink.getAttribute("href"), citation.url);
    assert.equal(citationLink.getAttribute("target"), "_blank");
    assert.equal(citationLink.getAttribute("rel"), "noopener noreferrer");
    assert.ok(within(citationLink).getByText("(external site)"));
    assert.ok(within(citationLink).getByText("(opens in new tab)"));
    assert.equal(document.querySelector(`link[href="${citation.url}"][rel~="preload"], link[href="${citation.url}"][rel~="prefetch"]`), null);
    assert.equal(fetchMock.mock.calls.length, 0);
  });

  it("renders non-https citation urls as plain text", () => {
    render(<CitationLink citation={{ type: "rbr-4", url: "javascript:alert(1)" }} />);

    assert.equal(screen.getByText("rbr-4").textContent, "rbr-4");
    assert.equal(screen.queryByRole("link", { name: /rbr-4/ }), null);
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

    await screen.findByRole("heading", { name: "Mock exam results" }, { timeout: 5000 });
    assert.match(screen.getByText(/Pass threshold is 70%; honours threshold is 80%/).textContent ?? "", /70%/);
    assert.equal((await store.getExamAttempts()).length, 1);
    assert.equal(document.activeElement?.tagName, "MAIN");

    await user.click(screen.getByRole("button", { name: "Mock exam" }));
    await screen.findByRole("button", { name: "Start mock exam" });
    assert.equal((await store.getExamAttempts()).length, 1);
    await expectNoAxeViolations(container);
  });
});
