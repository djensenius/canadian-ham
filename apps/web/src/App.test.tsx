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

import { generateMorseExamText, profileForName } from "@canadian-ham/morse-engine";

import { App, AppErrorBoundary, CitationLink, ExplanationPanel } from "./App";
import { answerMorseCourseSession, morseCourseSummaryMessage, type SessionState } from "./morse/course/MorseCoursePanel";
import { bankId, categories, loadQuestions, loadQuestionsFromUrl, manifest, type Answer, type Category, type Question } from "./data/bank";
import { explanationForQuestion, parseChoiceNotes } from "./data/explanations";
import { lessonQuizzesById, buildLessonQuizItems } from "./data/quizzes";
import { ProgressStore, defaultPreferences, type ExamAttempt, type ProgressExportV1, type WebPreferences } from "./lib/progressStore";
import { INTERFACE_LANGUAGE_STORAGE_KEY } from "./lib/i18n";
import { applyThemePreference, readStoredThemePreference, THEME_COLORS, THEME_STORAGE_KEY } from "./lib/theme";
import { buildExamAttempt, createMockExam } from "./lib/studyEngine";
import { buildMorseLessonExercises, parseMorseCourseFixture } from "@canadian-ham/morse-engine";
import courseFixture from "../../../fixtures/morse/course.json";

const fixedNow = "2026-01-02T03:04:05.000Z";
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

describe("App accessibility and flows", () => {
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

    window.location.hash = "#/learn/M5/L-005-01";
    window.dispatchEvent(new HashChangeEvent("hashchange"));
    await screen.findByText("Leçon offerte en anglais seulement.");
    assert.ok(container.querySelector('.lesson-article h2[lang="en"]'));
    assert.ok(container.querySelector('.lesson-article div[lang="en"]'));

    await user.click(within(primaryNav).getByRole("button", { name: "Exercices" }));
    await screen.findByRole("heading", { name: "Exercices" });

    await user.click(within(primaryNav).getByRole("button", { name: "Examen simulé" }));
    await screen.findByRole("heading", { name: "Examen simulé" });

    window.location.hash = "#/results";
    window.dispatchEvent(new HashChangeEvent("hashchange"));
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

  it("defaults the interface to French from navigator and keeps it out of progress exports", async () => {
    const originalLanguage = navigator.language;
    const originalLanguages = navigator.languages;
    Object.defineProperty(navigator, "language", { value: "fr-CA", configurable: true });
    Object.defineProperty(navigator, "languages", { value: ["fr-CA", "en-CA"], configurable: true });
    try {
      const store = createStore("french-default-localstorage");
      const user = userEvent.setup();
      render(<App store={store} now={() => fixedNow} seedFactory={() => "fr-default-seed"} />);

      await screen.findByRole("heading", { name: "Prêt pour la compétence de base avec distinction?" });
      const primaryNav = screen.getByRole("navigation", { name: "Principale" });
      await user.click(within(primaryNav).getByRole("button", { name: "Réglages" }));
      const interfaceLanguageGroup = await screen.findByRole("group", { name: "Langue de l’interface" });
      await user.click(within(interfaceLanguageGroup).getByRole("radio", { name: "English" }));

      assert.equal(window.localStorage.getItem(INTERFACE_LANGUAGE_STORAGE_KEY), "en");
      const exported = await store.exportData(fixedNow);
      assert.equal("interfaceLanguage" in exported.preferences, false);
    } finally {
      Object.defineProperty(navigator, "language", { value: originalLanguage, configurable: true });
      Object.defineProperty(navigator, "languages", { value: originalLanguages, configurable: true });
    }
  });

  it("does not re-read IndexedDB when switching interface language", async () => {
    window.location.hash = "#/settings";
    const store = createStore("interface-switch-no-indexeddb");
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

    const interfaceLanguageGroup = screen.getByRole("group", { name: "Interface language" });
    await user.click(within(interfaceLanguageGroup).getByRole("radio", { name: "Français" }));
    await screen.findByRole("heading", { name: "Réglages et données locales" });

    for (const spy of readSpies) {
      assert.equal(spy.mock.calls.length, 0);
    }
  });

  it("keeps the question-language toggle independent from interface language", async () => {
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "fr");
    window.location.hash = "#/practice";
    const store = createStore("question-language-independent");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "question-language-seed"} />);

    await screen.findByRole("heading", { name: "Exercices" });
    await screen.findByText(/Question 1 sur/);
    const frenchQuestionRadio = within(screen.getByRole("group", { name: "Langue des questions" })).getByRole("radio", { name: "Français" }) as HTMLInputElement;
    await user.click(frenchQuestionRadio);
    assert.equal(frenchQuestionRadio.checked, true);
    assert.ok(document.querySelector(".question-text[lang='fr-CA']"));

    const primaryNav = screen.getByRole("navigation", { name: "Principale" });
    await user.click(within(primaryNav).getByRole("button", { name: "Réglages" }));
    const interfaceLanguageGroup = await screen.findByRole("group", { name: "Langue de l’interface" });
    await user.click(within(interfaceLanguageGroup).getByRole("radio", { name: "English" }));
    await screen.findByRole("heading", { name: "Settings and local data" });
    const questionLanguageGroup = screen.getByRole("group", { name: "Question language" });
    assert.equal((within(questionLanguageGroup).getByRole("radio", { name: "Français" }) as HTMLInputElement).checked, true);
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
    assert.equal(screen.getByText(referenceSheetNote).className, "reference-note");
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

  it("automatically includes M4 and M6 lessons from content and renders them", async () => {
    window.location.hash = "#/learn";
    const store = createStore("m4-m6-lessons");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "m4-m6-seed"} />);

    await screen.findByRole("heading", { name: "Learn" });
    assert.ok(screen.getByRole("heading", { name: "Circuit Components" }));
    assert.ok(screen.getByRole("heading", { name: "Feedlines and Antenna Systems" }));

    window.location.hash = "#/learn/M4/L-004-01";
    window.dispatchEvent(new HashChangeEvent("hashchange"));
    await screen.findByRole("heading", { name: "Amplifiers and diodes" });
    await screen.findByRole("heading", { name: "QZ-L-004-01-A" });

    await user.click(screen.getByRole("button", { name: "Learn" }));
    window.location.hash = "#/learn/M6/L-006-01";
    window.dispatchEvent(new HashChangeEvent("hashchange"));
    await screen.findByRole("heading", { name: "Feedline basics and types" });
    await screen.findByRole("heading", { name: "QZ-L-006-01-A" });
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
    window.history.back();
    await waitFor(() => assert.equal(window.location.hash, "#/learn/M5/L-005-01"));
    window.dispatchEvent(new HashChangeEvent("hashchange"));
    await screen.findByRole("heading", { name: "Units, conductors, and current" });

    window.history.forward();
    await waitFor(() => assert.equal(window.location.hash, "#/learn/M5/L-005-02"));
    window.dispatchEvent(new HashChangeEvent("hashchange"));
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
    await user.click(screen.getByRole("button", { name: "Play Morse practice audio" }));

    assert.match(container.querySelector(".morse-playback-status")?.textContent ?? "", /Morse playback started\./);
    assert.equal(container.querySelector(".morse-live-status")?.textContent, "");
    await user.click(screen.getByRole("button", { name: "Stop Morse practice audio" }));
    assert.match(container.querySelector(".morse-live-status")?.textContent ?? "", /Morse playback stopped\./);
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
      fireEvent.click(screen.getByRole("button", { name: "Play Morse practice audio" }));
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
    const quickPlay = screen.getByRole("button", { name: "Play Morse practice audio" }) as HTMLButtonElement;
    const quickStop = screen.getByRole("button", { name: "Stop Morse practice audio" }) as HTMLButtonElement;
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
    const quickPlay = screen.getByRole("button", { name: "Play Morse practice audio" }) as HTMLButtonElement;
    const quickStop = screen.getByRole("button", { name: "Stop Morse practice audio" }) as HTMLButtonElement;
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

  it("reverts empty or invalid Morse number drafts and does not save unchanged values", async () => {
    window.location.hash = "#/morse";
    const store = new CountingPreferencesStore("morse-invalid-drafts");
    stores.push(store);
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "morse-invalid-seed"} />);

    await screen.findByRole("heading", { name: "Morse settings" });
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

    await user.clear(tone);
    await user.type(tone, "650");
    await user.keyboard("{Enter}");
    assert.equal(store.putPreferencesCount, 0);
    assert.equal(screen.queryByText("Morse settings saved."), null);
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

  it("keeps the root language stable and marks only question content as French", async () => {
    window.location.hash = "#/practice";
    const store = createStore("language-scope");
    const user = userEvent.setup();
    render(<App store={store} now={() => fixedNow} seedFactory={() => "language-seed"} />);

    await screen.findByRole("heading", { name: "Practice" });
    await screen.findByText(/Question 1 of/);
    await user.click(screen.getByLabelText("Français"));

    assert.equal(screen.getByText("Français").getAttribute("lang"), "fr");
    assert.equal(document.documentElement.lang, "en-CA");
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
