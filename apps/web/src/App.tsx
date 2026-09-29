import {
  computeReadiness,
  dueCount,
  weakSubsectionIds,
  type QuestionProgressRecord,
  type ReadinessResult,
} from "@canadian-ham/engine-ts";
import { useEffect, useMemo, useRef, useState } from "react";

import { LanguageToggle } from "./components/LanguageToggle";
import {
  allQuestionCount,
  bankId,
  categories,
  categoryName,
  manifest,
  questionsById,
  subsectionTitle,
  subsectionTitles,
  subsections,
  type Language,
  type Question,
} from "./data/bank";
import {
  defaultPreferences,
  defaultProgressStore,
  serializeProgressExport,
  validateProgressImport,
  type ExamAttempt,
  type PracticeMode,
  type ProgressExportV1,
  type ProgressStore,
  type WebPreferences,
} from "./lib/progressStore";
import {
  applyPracticeAnswer,
  buildExamAttempt,
  buildPracticeItems,
  createMockExam,
  examCategoryCounts,
  generatedExamQuestion,
  type PracticeItem,
  type PracticeScope,
} from "./lib/studyEngine";

type Route = "home" | "practice" | "mock" | "results" | "settings";
type View = Route;

interface AppProps {
  readonly initialView?: View;
  readonly initialScopeId?: string;
  readonly store?: ProgressStore;
  readonly now?: () => string;
  readonly seedFactory?: () => string;
}

interface PracticeSession {
  readonly seed: string;
  readonly scope: PracticeScope;
  readonly mode: PracticeMode;
  readonly items: readonly PracticeItem[];
  readonly currentIndex: number;
  readonly selectedByQuestionId: ReadonlyMap<string, number>;
  readonly submitted: boolean;
}

interface MockExamSession {
  readonly seed: string;
  readonly startedAt: string;
  readonly timerEnabled: boolean;
  readonly generatedItems: ReturnType<typeof createMockExam>;
  readonly currentIndex: number;
  readonly selectedByQuestionId: ReadonlyMap<string, number>;
  readonly flaggedQuestionIds: ReadonlySet<string>;
  readonly secondsElapsed: number;
  readonly timerRunning: boolean;
  readonly confirmingSubmit: boolean;
}

function defaultNow(): string {
  return new Date().toISOString();
}

function defaultSeed(): string {
  return globalThis.crypto?.randomUUID?.() ?? `seed-${Date.now().toString(36)}`;
}

function routeFromHash(fallback: Route): Route {
  const hash = globalThis.location?.hash.replace(/^#\/?/, "") ?? "";
  return isRoute(hash) ? hash : fallback;
}

function isRoute(value: string): value is Route {
  return value === "home" || value === "practice" || value === "mock" || value === "results" || value === "settings";
}

export function App({
  initialView = "home",
  initialScopeId = "all",
  store = defaultProgressStore,
  now = defaultNow,
  seedFactory = defaultSeed,
}: AppProps) {
  const [route, setRoute] = useState<Route>(() => routeFromHash(initialView));
  const [language, setLanguage] = useState<Language>("en");
  const [progress, setProgress] = useState<readonly QuestionProgressRecord[]>([]);
  const [examAttempts, setExamAttempts] = useState<readonly ExamAttempt[]>([]);
  const [preferences, setPreferencesState] = useState<WebPreferences>(defaultPreferences);
  const [practiceScope, setPracticeScope] = useState<PracticeScope>(() => scopeFromInitialId(initialScopeId));
  const [practiceSession, setPracticeSession] = useState<PracticeSession | null>(null);
  const [mockExam, setMockExam] = useState<MockExamSession | null>(null);
  const [latestResult, setLatestResult] = useState<ExamAttempt | null>(null);
  const [statusMessage, setStatusMessage] = useState("");
  const mainRef = useRef<HTMLElement>(null);

  useEffect(() => {
    let cancelled = false;
    async function loadProgress(): Promise<void> {
      const [storedProgress, storedAttempts, storedPreferences] = await Promise.all([
        store.getQuestionProgress(),
        store.getExamAttempts(),
        store.getPreferences(),
      ]);
      if (!cancelled) {
        setProgress(storedProgress);
        setExamAttempts(storedAttempts);
        setPreferencesState(storedPreferences);
      }
    }
    void loadProgress();
    return () => {
      cancelled = true;
    };
  }, [store]);

  useEffect(() => {
    const onHashChange = () => setRoute(routeFromHash("home"));
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  useEffect(() => {
    mainRef.current?.focus();
  }, [route]);

  const latestAttempt = useMemo(() => latestSubmittedAttempt(examAttempts), [examAttempts]);
  const readiness = useMemo(() => buildReadiness(progress, examAttempts, now()), [examAttempts, now, progress]);
  const weakSubsections = useMemo(
    () => weakSubsectionIds(progress, latestAttempt?.items ?? []),
    [latestAttempt, progress],
  );
  const dueReviewCount = useMemo(() => dueCount(progress, now()), [now, progress]);

  function navigate(nextRoute: Route): void {
    setRoute(nextRoute);
    if (window.location.hash !== `#/${nextRoute}`) {
      window.location.hash = `/${nextRoute}`;
    }
  }

  function startPractice(scope: PracticeScope = practiceScope, mode: PracticeMode = preferences.practiceMode): void {
    const seed = seedFactory();
    const items = buildPracticeItems({
      scope,
      progress,
      latestExamItems: latestAttempt?.items,
      seed,
      now: now(),
      limit: 10,
    });
    setPracticeScope(scope);
    setPracticeSession({
      seed,
      scope,
      mode,
      items,
      currentIndex: 0,
      selectedByQuestionId: new Map(),
      submitted: false,
    });
    navigate("practice");
  }

  async function setPreferences(nextPreferences: WebPreferences): Promise<void> {
    setPreferencesState(nextPreferences);
    await store.putPreferences(nextPreferences);
  }

  async function commitProgress(nextProgress: readonly QuestionProgressRecord[]): Promise<void> {
    setProgress(nextProgress);
    await store.putQuestionProgressMany(nextProgress);
  }

  async function handleExamSubmitted(attempt: ExamAttempt): Promise<void> {
    setLatestResult(attempt);
    setExamAttempts((current) => [...current.filter((existing) => existing.id !== attempt.id), attempt]);
    await store.putExamAttempt(attempt);
    let nextProgress = progress;
    for (const item of attempt.items) {
      nextProgress = applyPracticeAnswer(nextProgress, item.questionId, item.selectedSourceIndex ?? -1, attempt.submittedAt);
    }
    await commitProgress(nextProgress);
    navigate("results");
  }

  return (
    <div className="app-shell">
      <header className="site-header" role="banner">
        <div>
          <p className="eyebrow">Canadian Amateur Radio Basic</p>
          <h1>canadian-ham study app</h1>
        </div>
        <LanguageToggle language={language} onLanguageChange={setLanguage} />
      </header>

      <nav className="top-nav" aria-label="Primary">
        <button type="button" onClick={() => navigate("home")}>Home</button>
        <button type="button" onClick={() => startPractice({ type: "all" })}>Practice</button>
        <button type="button" onClick={() => navigate("mock")}>Mock exam</button>
        <button type="button" onClick={() => navigate("settings")}>Settings</button>
      </nav>

      <main ref={mainRef} tabIndex={-1}>
        {route === "home" ? (
          <Home
            dueReviewCount={dueReviewCount}
            examAttempts={examAttempts}
            onNavigate={navigate}
            onStartPractice={startPractice}
            readiness={readiness}
            weakSubsections={weakSubsections}
          />
        ) : null}
        {route === "practice" ? (
          <Practice
            language={language}
            now={now}
            onProgressChange={commitProgress}
            onSessionChange={setPracticeSession}
            onSetPreferences={setPreferences}
            preferences={preferences}
            progress={progress}
            session={practiceSession}
            startPractice={startPractice}
          />
        ) : null}
        {route === "mock" ? (
          <MockExam
            exam={mockExam}
            language={language}
            now={now}
            onExamChange={setMockExam}
            onSubmitExam={handleExamSubmitted}
            preferences={preferences}
            seedFactory={seedFactory}
          />
        ) : null}
        {route === "results" ? (
          <Results attempt={latestResult ?? latestAttempt} language={language} onStartPractice={startPractice} />
        ) : null}
        {route === "settings" ? (
          <Settings
            now={now}
            onProgressImported={(data) => {
              setProgress(data.questionProgress);
              setExamAttempts(data.examAttempts);
              setPreferencesState(data.preferences);
            }}
            onReset={() => {
              setProgress([]);
              setExamAttempts([]);
              setPracticeSession(null);
              setLatestResult(null);
              setStatusMessage("All local progress was reset.");
            }}
            statusMessage={statusMessage}
            store={store}
          />
        ) : null}
      </main>

      <Footer />
    </div>
  );
}

interface HomeProps {
  readonly readiness: ReadinessResult;
  readonly weakSubsections: readonly string[];
  readonly dueReviewCount: number;
  readonly examAttempts: readonly ExamAttempt[];
  readonly onStartPractice: (scope: PracticeScope) => void;
  readonly onNavigate: (route: Route) => void;
}

function Home({ readiness, weakSubsections, dueReviewCount, examAttempts, onStartPractice, onNavigate }: HomeProps) {
  const weakCategories = new Set(weakSubsections.map((id) => id.slice(0, 5)));
  return (
    <section className="card home" aria-labelledby="home-title">
      <h2 id="home-title">Readiness and practice</h2>
      <p>
        Practice with the committed 2025-07-15 Basic question/answer bank. Progress stays in this browser only.
      </p>
      <div className="readiness-panel" aria-labelledby="readiness-title">
        <h3 id="readiness-title">Readiness guidance</h3>
        <p><strong>{readinessLabel(readiness.state)}</strong></p>
        <p>{readinessCopy(readiness)}</p>
        <p>Due review count: <strong>{dueReviewCount}</strong></p>
        <p>Completed mock exams: <strong>{examAttempts.length}</strong></p>
        {weakCategories.size > 0 ? (
          <p>Weak categories: {[...weakCategories].map(categoryName).join(", ")}</p>
        ) : <p>No weak category has enough local data yet.</p>}
        {weakSubsections.length > 0 ? (
          <details>
            <summary>Weak subsections</summary>
            <ul>
              {weakSubsections.slice(0, 12).map((subsectionId) => (
                <li key={subsectionId}>{subsectionId}: {subsectionTitle(subsectionId)}</li>
              ))}
            </ul>
          </details>
        ) : null}
        <div className="action-row">
          <button type="button" onClick={() => onStartPractice({ type: "weak" })}>Practice weak areas</button>
          <button type="button" onClick={() => onStartPractice({ type: "due" })}>Review due</button>
          <button type="button" onClick={() => onNavigate("mock")}>Take a mock exam</button>
        </div>
      </div>

      <div className="category-grid" aria-label="Practice categories">
        <button className="category-card all-questions" type="button" onClick={() => onStartPractice({ type: "all" })}>
          <span>All questions</span>
          <strong>{allQuestionCount}</strong>
          <small>Mixed across all categories</small>
        </button>
        {categories.map((category) => (
          <button className="category-card" type="button" key={category.id} onClick={() => onStartPractice({ type: "category", categoryId: category.id })}>
            <span>{category.name.en}</span>
            <strong>{category.questionCount}</strong>
            <small>{category.subsectionCount} subsections</small>
          </button>
        ))}
      </div>
    </section>
  );
}

interface PracticeProps {
  readonly language: Language;
  readonly now: () => string;
  readonly preferences: WebPreferences;
  readonly progress: readonly QuestionProgressRecord[];
  readonly session: PracticeSession | null;
  readonly startPractice: (scope?: PracticeScope, mode?: PracticeMode) => void;
  readonly onSessionChange: (session: PracticeSession | null) => void;
  readonly onProgressChange: (progress: readonly QuestionProgressRecord[]) => Promise<void>;
  readonly onSetPreferences: (preferences: WebPreferences) => Promise<void>;
}

function Practice({
  language,
  now,
  preferences,
  progress,
  session,
  startPractice,
  onSessionChange,
  onProgressChange,
  onSetPreferences,
}: PracticeProps) {
  const [scopeKind, setScopeKind] = useState("all");
  const [categoryId, setCategoryId] = useState(categories[0]?.id ?? "B-001");
  const [subsectionId, setSubsectionId] = useState(subsections[0]?.id ?? "B-001-001");
  const feedbackRef = useRef<HTMLDivElement>(null);
  const reviewRef = useRef<HTMLDivElement>(null);
  const currentItem = session?.items[session.currentIndex];
  const selectedSourceIndex = currentItem === undefined ? undefined : session?.selectedByQuestionId.get(currentItem.question.id);
  const isAnswered = selectedSourceIndex !== undefined;
  const allAnswered = session !== null && session.items.every((item) => session.selectedByQuestionId.has(item.question.id));

  useEffect(() => {
    if (session === null) {
      startPractice(scopeFromControls(scopeKind, categoryId, subsectionId), preferences.practiceMode);
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (isAnswered && preferences.practiceMode === "immediate") {
      feedbackRef.current?.focus();
    }
  }, [isAnswered, preferences.practiceMode]);

  useEffect(() => {
    if (session?.submitted) {
      reviewRef.current?.focus();
    }
  }, [session?.submitted]);

  function restartWithControls(nextMode = preferences.practiceMode): void {
    const nextScope = scopeFromControls(scopeKind, categoryId, subsectionId);
    void onSetPreferences({ ...preferences, practiceMode: nextMode });
    startPractice(nextScope, nextMode);
  }

  async function chooseAnswer(item: PracticeItem, displayIndex: number): Promise<void> {
    if (session === null || (session.mode === "immediate" && session.selectedByQuestionId.has(item.question.id))) {
      return;
    }
    const sourceIndex = item.choicePermutation[displayIndex]!;
    const selected = new Map(session.selectedByQuestionId);
    selected.set(item.question.id, sourceIndex);
    const nextSession = { ...session, selectedByQuestionId: selected };
    onSessionChange(nextSession);
    if (session.mode === "immediate") {
      const nextProgress = applyPracticeAnswer(progress, item.question.id, sourceIndex, now());
      await onProgressChange(nextProgress);
    }
  }

  async function submitReviewLater(): Promise<void> {
    if (session === null) {
      return;
    }
    let nextProgress = progress;
    const submittedAt = now();
    for (const item of session.items) {
      const sourceIndex = session.selectedByQuestionId.get(item.question.id);
      if (sourceIndex !== undefined) {
        nextProgress = applyPracticeAnswer(nextProgress, item.question.id, sourceIndex, submittedAt);
      }
    }
    await onProgressChange(nextProgress);
    onSessionChange({ ...session, submitted: true });
  }

  return (
    <section className="card practice" aria-labelledby="practice-title">
      <h2 id="practice-title">Practice</h2>
      <div className="practice-topline">
        <label>
          Practice scope
          <select value={scopeKind} onChange={(event) => setScopeKind(event.currentTarget.value)}>
            <option value="all">All questions</option>
            <option value="category">Category</option>
            <option value="subsection">Subsection</option>
            <option value="weak">Weak areas</option>
            <option value="due">Due review</option>
          </select>
        </label>
        {scopeKind === "category" ? (
          <label>
            Category
            <select value={categoryId} onChange={(event) => setCategoryId(event.currentTarget.value)}>
              {categories.map((category) => <option key={category.id} value={category.id}>{category.name.en}</option>)}
            </select>
          </label>
        ) : null}
        {scopeKind === "subsection" ? (
          <label>
            Subsection
            <select value={subsectionId} onChange={(event) => setSubsectionId(event.currentTarget.value)}>
              {subsectionTitles.map((subsection) => <option key={subsection.id} value={subsection.id}>{subsection.id}: {subsection.title.en}</option>)}
            </select>
          </label>
        ) : null}
        <fieldset className="segmented-control">
          <legend>Feedback mode</legend>
          <label><input type="radio" name="practice-mode" checked={preferences.practiceMode === "immediate"} onChange={() => restartWithControls("immediate")} /> Immediate feedback</label>
          <label><input type="radio" name="practice-mode" checked={preferences.practiceMode === "review-later"} onChange={() => restartWithControls("review-later")} /> Review later</label>
        </fieldset>
        <button type="button" onClick={() => restartWithControls()}>Start set</button>
      </div>

      {session === null || currentItem === undefined ? (
        <div className="empty-state" role="status">
          <p>No questions are available for this scope yet. Try all questions or a category.</p>
        </div>
      ) : (
        <>
          <div className="session-summary" aria-label="Practice session progress">
            <span>Question {session.currentIndex + 1} of {session.items.length}</span>
            <span>Seed {session.seed}</span>
          </div>
          <QuestionCard
            choicePermutation={currentItem.choicePermutation}
            disabled={session.mode === "immediate" && isAnswered}
            language={language}
            onChoose={(displayIndex) => void chooseAnswer(currentItem, displayIndex)}
            question={currentItem.question}
            selectedSourceIndex={selectedSourceIndex}
            showCorrectness={session.mode === "immediate" && isAnswered}
          />
          <div className="feedback" role="status" aria-live="polite" ref={feedbackRef} tabIndex={-1}>
            {session.mode === "immediate" ? immediateFeedback(currentItem.question, selectedSourceIndex, language) : (
              <p>Review-later mode: answer all questions, then submit the set to see results.</p>
            )}
          </div>
          <div className="action-row">
            <button type="button" disabled={session.currentIndex === 0} onClick={() => onSessionChange({ ...session, currentIndex: session.currentIndex - 1 })}>Previous</button>
            <button type="button" disabled={session.currentIndex >= session.items.length - 1} onClick={() => onSessionChange({ ...session, currentIndex: session.currentIndex + 1 })}>Next</button>
            {session.mode === "review-later" ? (
              <button type="button" disabled={!allAnswered || session.submitted} onClick={() => void submitReviewLater()}>Submit practice set</button>
            ) : null}
          </div>
          {session.submitted ? <div ref={reviewRef} tabIndex={-1}><PracticeReview session={session} language={language} /></div> : null}
        </>
      )}
    </section>
  );
}

interface QuestionCardProps {
  readonly question: Question;
  readonly choicePermutation: readonly number[];
  readonly selectedSourceIndex: number | undefined;
  readonly showCorrectness: boolean;
  readonly disabled: boolean;
  readonly language: Language;
  readonly onChoose: (displayIndex: number) => void;
}

function QuestionCard({ question, choicePermutation, selectedSourceIndex, showCorrectness, disabled, language, onChoose }: QuestionCardProps) {
  return (
    <article className="question-panel" aria-labelledby={`question-${question.id}`}>
      <p className="question-meta">{question.id} · {question.categoryId} · {subsectionTitle(question.subsectionId)}</p>
      <h3 id={`question-${question.id}`}>Question</h3>
      <p className="question-text" lang={language}>{question.text[language]}</p>
      <div className="answers" role="group" aria-label="Answer choices">
        {choicePermutation.map((sourceIndex, displayIndex) => {
          const answer = question.answers.find((candidate) => candidate.sourceIndex === sourceIndex)!;
          const selected = selectedSourceIndex === sourceIndex;
          const correct = sourceIndex === 0;
          const className = [
            "answer-button",
            showCorrectness && correct ? "is-correct" : "",
            showCorrectness && selected && !correct ? "is-incorrect" : "",
          ].filter(Boolean).join(" ");
          return (
            <button
              aria-pressed={selected}
              className={className}
              data-testid="answer-choice"
              disabled={disabled}
              key={sourceIndex}
              type="button"
              onClick={() => onChoose(displayIndex)}
            >
              <span className="answer-label">{String.fromCharCode(65 + displayIndex)}</span>
              <span lang={language}>{answer.text[language]}</span>
              {showCorrectness && correct ? <strong>Correct answer</strong> : null}
              {showCorrectness && selected && !correct ? <strong>Your answer</strong> : null}
            </button>
          );
        })}
      </div>
    </article>
  );
}

function PracticeReview({ session, language }: { readonly session: PracticeSession; readonly language: Language }) {
  return (
    <section className="review-panel" aria-labelledby="practice-review-title">
      <h3 id="practice-review-title">Practice set review</h3>
      <ol>
        {session.items.map((item) => {
          const selected = session.selectedByQuestionId.get(item.question.id);
          const correctAnswer = item.question.answers.find((answer) => answer.sourceIndex === 0)!;
          const selectedAnswer = item.question.answers.find((answer) => answer.sourceIndex === selected);
          return (
            <li key={item.question.id}>
              <strong>{item.question.id}</strong> — {selected === 0 ? "Correct" : "Incorrect"}
              <p lang={language}>{item.question.text[language]}</p>
              <p>Your answer: <span lang={language}>{selectedAnswer?.text[language] ?? "Unanswered"}</span></p>
              <p>Correct answer: <span lang={language}>{correctAnswer.text[language]}</span></p>
              <p>{item.question.categoryId}; {subsectionTitle(item.question.subsectionId)}</p>
            </li>
          );
        })}
      </ol>
    </section>
  );
}

interface MockExamProps {
  readonly exam: MockExamSession | null;
  readonly language: Language;
  readonly preferences: WebPreferences;
  readonly now: () => string;
  readonly seedFactory: () => string;
  readonly onExamChange: (exam: MockExamSession | null) => void;
  readonly onSubmitExam: (attempt: ExamAttempt) => Promise<void>;
}

function MockExam({ exam, language, preferences, now, seedFactory, onExamChange, onSubmitExam }: MockExamProps) {
  const [seed, setSeed] = useState("");
  const [timerEnabled, setTimerEnabled] = useState(preferences.examTimerEnabled);
  const liveRef = useRef<HTMLDivElement>(null);
  const confirmRef = useRef<HTMLElement>(null);

  useEffect(() => {
    if (exam?.timerEnabled && exam.timerRunning) {
      const id = window.setInterval(() => {
        onExamChange({ ...exam, secondsElapsed: exam.secondsElapsed + 1 });
      }, 1000);
      return () => window.clearInterval(id);
    }
    return undefined;
  }, [exam, onExamChange]);

  useEffect(() => {
    if (exam?.confirmingSubmit) {
      confirmRef.current?.focus();
    }
  }, [exam?.confirmingSubmit]);

  function startExam(): void {
    const selectedSeed = seed.trim() || seedFactory();
    onExamChange({
      seed: selectedSeed,
      startedAt: now(),
      timerEnabled,
      generatedItems: createMockExam(selectedSeed),
      currentIndex: 0,
      selectedByQuestionId: new Map(),
      flaggedQuestionIds: new Set(),
      secondsElapsed: 0,
      timerRunning: timerEnabled,
      confirmingSubmit: false,
    });
  }

  if (exam === null) {
    return (
      <section className="card mock-exam" aria-labelledby="mock-title">
        <h2 id="mock-title">Mock exam</h2>
        <p>Generate 100 questions: one from each subsection. Unanswered questions count as incorrect when submitted.</p>
        <label>
          Seed (optional)
          <input value={seed} onChange={(event) => setSeed(event.currentTarget.value)} placeholder="Leave blank for a local random seed" />
        </label>
        <label><input type="checkbox" checked={timerEnabled} onChange={(event) => setTimerEnabled(event.currentTarget.checked)} /> Enable optional timer</label>
        <p id="timer-note">Timer is off by default because the official time limit is unverified.</p>
        <div className="reference-placeholder" aria-label="Reference sheet placeholder">
          T-308 reference sheet slot: exam reference material link will be added in a later task.
        </div>
        <button type="button" onClick={startExam}>Start mock exam</button>
      </section>
    );
  }

  const item = exam.generatedItems[exam.currentIndex]!;
  const question = generatedExamQuestion(item);
  const selectedSourceIndex = exam.selectedByQuestionId.get(question.id);
  const unanswered = exam.generatedItems.filter((candidate) => !exam.selectedByQuestionId.has(candidate.questionId));

  function choose(displayIndex: number): void {
    const sourceIndex = item.choicePermutation[displayIndex]!;
    const selected = new Map(exam!.selectedByQuestionId);
    selected.set(question.id, sourceIndex);
    onExamChange({ ...exam!, selectedByQuestionId: selected });
  }

  function toggleFlag(): void {
    const flagged = new Set(exam!.flaggedQuestionIds);
    if (flagged.has(question.id)) {
      flagged.delete(question.id);
    } else {
      flagged.add(question.id);
    }
    onExamChange({ ...exam!, flaggedQuestionIds: flagged });
  }

  async function confirmSubmit(): Promise<void> {
    const selected = new Map<string, number | null>();
    for (const generatedItem of exam!.generatedItems) {
      selected.set(generatedItem.questionId, exam!.selectedByQuestionId.get(generatedItem.questionId) ?? null);
    }
    await onSubmitExam(buildExamAttempt({
      seed: exam!.seed,
      startedAt: exam!.startedAt,
      submittedAt: now(),
      timerEnabled: exam!.timerEnabled,
      secondsElapsed: exam!.secondsElapsed,
      generatedItems: exam!.generatedItems,
      selectedByQuestionId: selected,
      flaggedQuestionIds: exam!.flaggedQuestionIds,
    }));
  }

  return (
    <section className="card mock-exam" aria-labelledby="mock-title">
      <h2 id="mock-title">Mock exam</h2>
      <div className="session-summary" aria-label="Mock exam progress">
        <span>Question {exam.currentIndex + 1} of {exam.generatedItems.length}</span>
        <span>Seed: {exam.seed}</span>
        <span>Answered: {exam.selectedByQuestionId.size} of {exam.generatedItems.length}</span>
      </div>
      {exam.timerEnabled ? (
        <div className="timer-panel" role="status" aria-live="polite" ref={liveRef}>
          Timer elapsed: {formatElapsed(exam.secondsElapsed)}
          <button type="button" onClick={() => onExamChange({ ...exam, timerRunning: !exam.timerRunning })}>{exam.timerRunning ? "Pause timer" : "Resume timer"}</button>
        </div>
      ) : <p>Timer off. No time pressure by default.</p>}
      <QuestionCard
        choicePermutation={item.choicePermutation}
        disabled={false}
        language={language}
        onChoose={choose}
        question={question}
        selectedSourceIndex={selectedSourceIndex}
        showCorrectness={false}
      />
      <div className="action-row">
        <button type="button" onClick={toggleFlag}>{exam.flaggedQuestionIds.has(question.id) ? "Remove flag" : "Flag for review"}</button>
        <button type="button" disabled={exam.currentIndex === 0} onClick={() => onExamChange({ ...exam, currentIndex: exam.currentIndex - 1 })}>Previous</button>
        <button type="button" disabled={exam.currentIndex >= exam.generatedItems.length - 1} onClick={() => onExamChange({ ...exam, currentIndex: exam.currentIndex + 1 })}>Next</button>
        <button type="button" onClick={() => onExamChange({ ...exam, confirmingSubmit: true })}>Submit exam</button>
      </div>
      <nav className="question-navigator" aria-label="Question navigator">
        {exam.generatedItems.map((candidate, index) => {
          const answered = exam.selectedByQuestionId.has(candidate.questionId);
          const flagged = exam.flaggedQuestionIds.has(candidate.questionId);
          return (
            <button
              className={index === exam.currentIndex ? "current" : ""}
              key={candidate.questionId}
              type="button"
              aria-label={`Question ${index + 1}${answered ? ", answered" : ", unanswered"}${flagged ? ", flagged" : ""}`}
              onClick={() => onExamChange({ ...exam, currentIndex: index })}
            >
              {index + 1}{flagged ? " ⚑" : ""}{answered ? " ✓" : ""}
            </button>
          );
        })}
      </nav>
      {exam.confirmingSubmit ? (
        <section className="confirm-panel" aria-labelledby="submit-confirm-title" role="alertdialog" aria-modal="false" ref={confirmRef} tabIndex={-1}>
          <h3 id="submit-confirm-title">Submit mock exam?</h3>
          <p>{unanswered.length === 0 ? "All questions are answered." : `${unanswered.length} unanswered questions will be scored incorrect.`}</p>
          {unanswered.length > 0 ? (
            <details open>
              <summary>Unanswered questions</summary>
              <ol>{unanswered.map((candidate) => <li key={candidate.questionId}>Question {candidate.position}: {candidate.questionId}</li>)}</ol>
            </details>
          ) : null}
          <div className="action-row">
            <button type="button" onClick={() => onExamChange({ ...exam, confirmingSubmit: false })}>Continue exam</button>
            <button type="button" onClick={() => void confirmSubmit()}>Confirm submit</button>
          </div>
        </section>
      ) : null}
    </section>
  );
}

function Results({ attempt, language, onStartPractice }: { readonly attempt: ExamAttempt | null; readonly language: Language; readonly onStartPractice: (scope: PracticeScope) => void }) {
  if (attempt === null) {
    return (
      <section className="card results" aria-labelledby="results-title">
        <h2 id="results-title">Results</h2>
        <p>No mock exam result has been saved yet.</p>
      </section>
    );
  }
  const wrongItems = attempt.items.filter((item) => !item.isCorrect);
  return (
    <section className="card results" aria-labelledby="results-title">
      <h2 id="results-title">Mock exam results</h2>
      <p><strong>{attempt.score.correct} / {attempt.score.total}</strong> ({attempt.score.percent.toFixed(0)}%)</p>
      <p>{attempt.score.honours ? "Basic with Honours ready for this attempt." : attempt.score.passed ? "Pass achieved for this attempt; keep practising for honours." : "Below pass threshold for this attempt."}</p>
      <p>Pass threshold is 70%; honours threshold is 80%.</p>
      <h3>Category breakdown</h3>
      <ul>
        {attempt.score.categoryBreakdown.map((entry) => (
          <li key={entry.categoryId}>{categoryName(entry.categoryId)}: {entry.correct}/{entry.total} ({entry.percent.toFixed(0)}%)</li>
        ))}
      </ul>
      <button type="button" onClick={() => onStartPractice({ type: "weak" })}>Practice weak areas</button>
      <section className="review-panel" aria-labelledby="wrong-review-title">
        <h3 id="wrong-review-title">Review wrong answers</h3>
        {wrongItems.length === 0 ? <p>No wrong answers on this attempt.</p> : (
          <ol>
            {wrongItems.map((item) => {
              const question = questionsById.get(item.questionId)!;
              const selected = question.answers.find((answer) => answer.sourceIndex === item.selectedSourceIndex);
              const correct = question.answers.find((answer) => answer.sourceIndex === 0)!;
              return (
                <li key={item.questionId}>
                  <strong>{item.questionId}</strong>
                  <p lang={language}>{question.text[language]}</p>
                  <p>Your answer: <span lang={language}>{selected?.text[language] ?? "Unanswered"}</span></p>
                  <p>Correct answer: <span lang={language}>{correct.text[language]}</span></p>
                </li>
              );
            })}
          </ol>
        )}
      </section>
    </section>
  );
}

interface SettingsProps {
  readonly store: ProgressStore;
  readonly now: () => string;
  readonly statusMessage: string;
  readonly onProgressImported: (data: ProgressExportV1) => void;
  readonly onReset: () => void;
}

function Settings({ store, now, statusMessage, onProgressImported, onReset }: SettingsProps) {
  const [errors, setErrors] = useState<readonly string[]>([]);
  const [pendingImport, setPendingImport] = useState<ProgressExportV1 | null>(null);
  const [message, setMessage] = useState(statusMessage);
  const [confirmReset, setConfirmReset] = useState(false);

  async function exportProgress(): Promise<void> {
    const data = await store.exportData(now());
    const blob = new Blob([serializeProgressExport(data)], { type: "application/json" });
    const href = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = href;
    anchor.download = `canadian-ham-progress-${data.exportedAt.slice(0, 10)}.json`;
    anchor.click();
    URL.revokeObjectURL(href);
    setMessage("Progress export was prepared locally. Nothing was uploaded.");
  }

  async function handleImport(file: File | undefined): Promise<void> {
    setMessage("");
    setErrors([]);
    setPendingImport(null);
    if (file === undefined) {
      return;
    }
    try {
      const parsed = JSON.parse(await file.text()) as unknown;
      const result = validateProgressImport(parsed);
      if (!result.ok || result.data === undefined) {
        setErrors(result.errors);
        return;
      }
      setPendingImport(result.data);
      setMessage(`Import file is valid: ${result.data.questionProgress.length} question records and ${result.data.examAttempts.length} exam attempts. Confirm to replace local data.`);
    } catch (error) {
      setErrors([`Import file is not valid JSON: ${error instanceof Error ? error.message : String(error)}`]);
    }
  }

  async function confirmImport(): Promise<void> {
    if (pendingImport === null) {
      return;
    }
    await store.importData(pendingImport);
    onProgressImported(pendingImport);
    setPendingImport(null);
    setMessage("Import complete. Imported progress replaced the previous local data.");
  }

  async function resetAll(): Promise<void> {
    await store.resetAllData();
    onReset();
    setConfirmReset(false);
    setMessage("All local data was reset.");
  }

  return (
    <section className="card settings" aria-labelledby="settings-title">
      <h2 id="settings-title">Settings and local data</h2>
      <p>No accounts, analytics, telemetry, network sync, remote assets, or third-party runtime SDKs are used. Progress stays in IndexedDB on this device unless you export it.</p>
      <p>Active bank: {bankId}, effective {manifest.effectiveDate}. Export/import/reset are user initiated.</p>
      <div className="action-row">
        <button type="button" onClick={() => void exportProgress()}>Export progress JSON</button>
        <label className="file-control">
          Import progress JSON
          <input type="file" accept="application/json,.json" onChange={(event) => void handleImport(event.currentTarget.files?.[0])} />
        </label>
        <button type="button" className="danger" onClick={() => setConfirmReset(true)}>Reset all data</button>
      </div>
      {pendingImport !== null ? <button type="button" onClick={() => void confirmImport()}>Confirm import and replace local data</button> : null}
      {confirmReset ? (
        <div className="confirm-panel" role="alertdialog" aria-labelledby="reset-title" aria-modal="false">
          <h3 id="reset-title">Reset all local data?</h3>
          <p>This deletes browser-local question progress, mock exam attempts, and preferences. Bundled content remains available offline.</p>
          <button type="button" onClick={() => setConfirmReset(false)}>Cancel reset</button>
          <button type="button" className="danger" onClick={() => void resetAll()}>Confirm reset all data</button>
        </div>
      ) : null}
      <div role="status" aria-live="polite">
        {message ? <p>{message}</p> : null}
        {errors.length > 0 ? <ul>{errors.map((error) => <li key={error}>{error}</li>)}</ul> : null}
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="site-footer">
      <p>
        Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank and related reference material. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page. Written permission is pending; this private-development build is not for public release.
      </p>
      <p>
        canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.
      </p>
    </footer>
  );
}

function scopeFromInitialId(scopeId: string): PracticeScope {
  if (scopeId === "all") {
    return { type: "all" };
  }
  if (scopeId.length === 5) {
    return { type: "category", categoryId: scopeId };
  }
  if (scopeId.length === 9) {
    return { type: "subsection", subsectionId: scopeId };
  }
  return { type: "all" };
}

function scopeFromControls(scopeKind: string, categoryId: string, subsectionId: string): PracticeScope {
  if (scopeKind === "category") {
    return { type: "category", categoryId };
  }
  if (scopeKind === "subsection") {
    return { type: "subsection", subsectionId };
  }
  if (scopeKind === "weak") {
    return { type: "weak" };
  }
  if (scopeKind === "due") {
    return { type: "due" };
  }
  return { type: "all" };
}

function buildReadiness(progress: readonly QuestionProgressRecord[], attempts: readonly ExamAttempt[], now: string): ReadinessResult {
  return computeReadiness({
    completedExams: attempts.map((attempt) => ({
      submittedAt: attempt.submittedAt,
      score: attempt.score,
      categoryBreakdown: attempt.score.categoryBreakdown,
    })),
    dueReviewCount: dueCount(progress, now),
  });
}

function latestSubmittedAttempt(attempts: readonly ExamAttempt[]): ExamAttempt | null {
  return [...attempts].sort((a, b) => Date.parse(b.submittedAt) - Date.parse(a.submittedAt))[0] ?? null;
}

function readinessLabel(state: ReadinessResult["state"]): string {
  switch (state) {
    case "honours-ready": return "Honours-ready";
    case "pass-ready": return "Pass-ready";
    case "needs-review": return "Needs review";
    case "not-enough-data": return "Not enough data";
  }
}

function readinessCopy(readiness: ReadinessResult): string {
  if (readiness.state === "honours-ready") {
    return "Two of your recent mock exams are at or above the 80% Basic with Honours threshold.";
  }
  if (readiness.state === "pass-ready") {
    return "Two recent mock exams are at or above 70%; keep practising weak areas to target honours.";
  }
  if (readiness.state === "not-enough-data") {
    return "Complete at least two mock exams before the app claims pass or honours readiness.";
  }
  const reason = readiness.reasons[0];
  if (reason?.type === "due-review") {
    return "Your Leitner due-review count is high enough to review before relying on exam scores.";
  }
  if (reason?.type === "weak-categories") {
    return "One or more categories are below 70% across the considered mock exams.";
  }
  return "Recent results do not yet meet the pass-ready rule.";
}

function immediateFeedback(question: Question, selectedSourceIndex: number | undefined, language: Language) {
  if (selectedSourceIndex === undefined) {
    return <p>Choose an answer to see immediate feedback.</p>;
  }
  const correctAnswer = question.answers.find((answer) => answer.sourceIndex === 0)!;
  return selectedSourceIndex === 0 ? (
    <p>Correct. The correct answer is: <strong lang={language}>{correctAnswer.text[language]}</strong></p>
  ) : (
    <p>Incorrect. The correct answer is: <strong lang={language}>{correctAnswer.text[language]}</strong></p>
  );
}

function formatElapsed(secondsElapsed: number): string {
  const minutes = Math.floor(secondsElapsed / 60).toString().padStart(2, "0");
  const seconds = (secondsElapsed % 60).toString().padStart(2, "0");
  return `${minutes}:${seconds}`;
}

export const webExamCategoryCounts = examCategoryCounts;
