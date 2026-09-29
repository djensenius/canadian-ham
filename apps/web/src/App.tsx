import {
  computeReadiness,
  dueCount,
  weakSubsectionIds,
  type QuestionProgressRecord,
  type ReadinessResult,
} from "@canadian-ham/engine-ts";
import { Component, useEffect, useMemo, useRef, useState, type ReactNode } from "react";

import { LanguageToggle } from "./components/LanguageToggle";
import examReferenceSheetUrl from "../../../content/sources/ised/basic-2025-07-15/reference/Reference Material for Amateur Radio Exam Basic EN 2025.pdf?url";
import studyReferenceSheetUrl from "../../../content/sources/ised/basic-2025-07-15/reference/Reference Material for Amateur Radio Training Basic EN 2025.pdf?url";
import {
  allQuestionCount,
  bankId,
  categories,
  categoryName,
  loadQuestions,
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
import { applyThemePreference, mirrorThemePreference, readStoredThemePreference } from "./lib/theme";
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

interface AppErrorBoundaryProps {
  readonly store: ProgressStore;
  readonly now: () => string;
  readonly children: ReactNode;
}

interface AppErrorBoundaryState {
  readonly errorMessage: string | null;
}

class AppErrorBoundary extends Component<AppErrorBoundaryProps, AppErrorBoundaryState> {
  override state: AppErrorBoundaryState = { errorMessage: null };

  static getDerivedStateFromError(error: unknown): AppErrorBoundaryState {
    return { errorMessage: formatError(error) };
  }

  override render(): ReactNode {
    if (this.state.errorMessage === null) {
      return this.props.children;
    }
    return (
      <div className="app-shell">
        <header className="site-header" role="banner">
          <div className="brand-lockup">
            <HeaderMark />
            <div>
              <p className="eyebrow">Canadian Amateur Radio Basic</p>
              <h1>Canadian Ham</h1>
            </div>
          </div>
        </header>
        <main tabIndex={-1}>
          <section className="card settings" aria-labelledby="app-recovery-title">
            <h2 id="app-recovery-title">Settings and local data</h2>
            <p role="alert">The app could not render saved progress: {this.state.errorMessage}</p>
            <p>Reset remains available so invalid local data can be cleared on this device.</p>
            <Settings
              now={this.props.now}
              onProgressImported={() => this.setState({ errorMessage: null })}
              onReset={() => this.setState({ errorMessage: null })}
              onSetPreferences={async (preferences) => {
                await this.props.store.putPreferences(preferences);
                applyThemePreference(preferences.theme);
                mirrorThemePreference(preferences.theme);
              }}
              preferences={{ ...defaultPreferences, theme: readStoredThemePreference() }}
              statusMessage=""
              store={this.props.store}
            />
          </section>
        </main>
        <Footer />
      </div>
    );
  }
}

function routeFromHash(fallback: Route): Route {
  const hash = globalThis.location?.hash.replace(/^#\/?/, "") ?? "";
  return isRoute(hash) ? hash : fallback;
}

function isRoute(value: string): value is Route {
  return value === "home" || value === "practice" || value === "mock" || value === "results" || value === "settings";
}

export function App(props: AppProps) {
  return <AppErrorBoundary store={props.store ?? defaultProgressStore} now={props.now ?? defaultNow}><AppContent {...props} /></AppErrorBoundary>;
}

function HeaderMark() {
  return (
    <svg className="header-mark" viewBox="0 0 64 64" aria-hidden="true" focusable="false">
      <rect width="64" height="64" rx="14" />
      <path strokeWidth="6" d="M19 55 C20 44 23 33 27 23" />
      <path strokeWidth="2.2" d="M35 18 C38 23 40 29 39 36" />
      <path strokeWidth="2.6" d="M45 11 C49 19 50 29 48 42" />
      <path strokeWidth="3" d="M56 5 C62 17 63 31 59 48" />
    </svg>
  );
}

function AppContent({
  initialView = "home",
  initialScopeId = "all",
  store = defaultProgressStore,
  now = defaultNow,
  seedFactory = defaultSeed,
}: AppProps) {
  const [route, setRoute] = useState<Route>(() => routeFromHash(initialView));
  const [language, setLanguage] = useState<Language>("en");
  const [bankQuestions, setBankQuestions] = useState<readonly Question[] | null>(null);
  const [progress, setProgress] = useState<readonly QuestionProgressRecord[]>([]);
  const [examAttempts, setExamAttempts] = useState<readonly ExamAttempt[]>([]);
  const [preferences, setPreferencesState] = useState<WebPreferences>(() => ({ ...defaultPreferences, theme: readStoredThemePreference() }));
  const [practiceScope, setPracticeScope] = useState<PracticeScope>(() => scopeFromInitialId(initialScopeId));
  const [practiceSession, setPracticeSession] = useState<PracticeSession | null>(null);
  const [mockExam, setMockExam] = useState<MockExamSession | null>(null);
  const [latestResult, setLatestResult] = useState<ExamAttempt | null>(null);
  const [statusMessage, setStatusMessage] = useState("");
  const [alertMessage, setAlertMessage] = useState("");
  const mainRef = useRef<HTMLElement>(null);

  useEffect(() => {
    let cancelled = false;
    async function loadProgress(): Promise<void> {
      try {
        const [storedProgress, storedAttempts, storedPreferences] = await Promise.all([
          store.getQuestionProgress(),
          store.getExamAttempts(),
          store.getPreferences(),
        ]);
        if (!cancelled) {
          setProgress(storedProgress);
          setExamAttempts(storedAttempts);
          setPreferencesState(storedPreferences);
          setAlertMessage("");
        }
      } catch (error) {
        if (!cancelled) {
          setAlertMessage(`Unable to open local progress storage: ${formatError(error)}`);
        }
      }
    }
    void loadProgress();
    return () => {
      cancelled = true;
    };
  }, [store]);

  useEffect(() => {
    let cancelled = false;
    loadQuestions()
      .then((questions) => {
        if (!cancelled) {
          setBankQuestions(questions);
        }
      })
      .catch((error: unknown) => {
        if (!cancelled) {
          setAlertMessage(`Unable to load bundled question bank: ${formatError(error)}`);
        }
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const onHashChange = () => setRoute(routeFromHash("home"));
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  useEffect(() => {
    mainRef.current?.focus();
  }, [route]);

  useEffect(() => {
    applyThemePreference(preferences.theme);
    mirrorThemePreference(preferences.theme);
    if (preferences.theme !== "system") {
      return undefined;
    }
    const media = window.matchMedia?.("(prefers-color-scheme: dark)");
    if (media === undefined) {
      return undefined;
    }
    const onSystemThemeChange = () => applyThemePreference("system");
    media.addEventListener("change", onSystemThemeChange);
    return () => media.removeEventListener("change", onSystemThemeChange);
  }, [preferences.theme]);

  const bankQuestionsById = useMemo(() => bankQuestions === null ? new Map<string, Question>() : questionsById(bankQuestions), [bankQuestions]);
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
    if (bankQuestions === null) {
      setAlertMessage("Question bank is still loading locally. Try again in a moment.");
      return;
    }
    const seed = seedFactory();
    const items = buildPracticeItems({
      questions: bankQuestions,
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
    try {
      await store.putPreferences(nextPreferences);
      setAlertMessage("");
    } catch (error) {
      setAlertMessage(`Unable to save preferences locally: ${formatError(error)}`);
      throw error;
    }
  }

  async function commitProgress(nextProgress: readonly QuestionProgressRecord[]): Promise<void> {
    try {
      await store.putQuestionProgressMany(nextProgress);
      setProgress(nextProgress);
      setAlertMessage("");
    } catch (error) {
      setAlertMessage(`Unable to save question progress locally: ${formatError(error)}`);
      throw error;
    }
  }

  async function handleExamSubmitted(attempt: ExamAttempt): Promise<void> {
    let nextProgress = progress;
    for (const item of attempt.items) {
      nextProgress = applyPracticeAnswer(nextProgress, item.questionId, item.selectedSourceIndex ?? -1, attempt.submittedAt);
    }
    try {
      await store.putExamAttempt(attempt);
      await store.putQuestionProgressMany(nextProgress);
      setLatestResult(attempt);
      setExamAttempts((current) => [...current.filter((existing) => existing.id !== attempt.id), attempt]);
      setProgress(nextProgress);
      setMockExam(null);
      setAlertMessage("");
      navigate("results");
    } catch (error) {
      setAlertMessage(`Unable to save mock exam locally: ${formatError(error)}`);
      throw error;
    }
  }

  return (
    <div className="app-shell" data-theme={preferences.theme === "system" ? undefined : preferences.theme}>
      <header className="site-header" role="banner">
        <div className="brand-lockup">
          <HeaderMark />
          <div>
            <p className="eyebrow">Canadian Amateur Radio Basic</p>
            <h1>Canadian Ham</h1>
          </div>
        </div>
        <LanguageToggle language={language} onLanguageChange={setLanguage} />
      </header>

      <nav className="top-nav" aria-label="Primary">
        <button type="button" aria-current={route === "home" ? "page" : undefined} onClick={() => navigate("home")}>Home</button>
        <button type="button" aria-current={route === "practice" ? "page" : undefined} onClick={() => practiceSession === null ? startPractice(practiceScope) : navigate("practice")}>Practice</button>
        <button type="button" aria-current={route === "mock" ? "page" : undefined} onClick={() => navigate("mock")}>Mock exam</button>
        <button type="button" aria-current={route === "settings" ? "page" : undefined} onClick={() => navigate("settings")}>Settings</button>
      </nav>

      <main ref={mainRef} tabIndex={-1}>
        {alertMessage ? <p className="alert-message" role="alert">{alertMessage}</p> : null}
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
            bankReady={bankQuestions !== null}
            activeScope={practiceScope}
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
            questions={bankQuestions}
            now={now}
            onExamChange={setMockExam}
            onSubmitExam={handleExamSubmitted}
            preferences={preferences}
            seedFactory={seedFactory}
          />
        ) : null}
        {route === "results" ? (
          <Results attempt={latestResult ?? latestAttempt} language={language} onStartPractice={startPractice} questionsById={bankQuestionsById} />
        ) : null}
        {route === "settings" ? (
          <Settings
            now={now}
            onProgressImported={(data) => {
              setProgress(data.questionProgress);
              setExamAttempts(data.examAttempts);
              setPreferencesState(data.preferences);
              setPracticeSession(null);
              setMockExam(null);
              setLatestResult(null);
              setPracticeScope({ type: "all" });
              setAlertMessage("");
            }}
            onReset={() => {
              setProgress([]);
              setExamAttempts([]);
              setPreferencesState(defaultPreferences);
              setPracticeScope({ type: "all" });
              setPracticeSession(null);
              setMockExam(null);
              setLatestResult(null);
              setAlertMessage("");
              setStatusMessage("All local progress was reset.");
            }}
            onSetPreferences={setPreferences}
            preferences={preferences}
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
      <div className="home-hero">
        <div>
          <p className="eyebrow">Offline, private, 2025 bank</p>
          <h2 id="home-title">Ready for Basic with Honours?</h2>
          <p>
            Practice with the committed 2025-07-15 Basic EN/FR question bank. Progress stays in this browser only.
          </p>
          <div className="action-row">
            <button type="button" className="primary-button" onClick={() => onStartPractice({ type: "all" })}>Start practice</button>
            <button type="button" className="secondary-button" onClick={() => onNavigate("mock")}>Mock exam</button>
            <a className="button secondary-button" href={studyReferenceSheetUrl} target="_blank" rel="noreferrer">Study reference sheet <span className="new-tab-hint">(opens in new tab)</span></a>
          </div>
        </div>
        <div className="reference-note" aria-label="Study reference sheet attribution">
          <strong>Study reference sheet</strong>
          <p>Labelled ISED training reference material for formulas and block diagrams. Private-development access only; public release is blocked until permission is recorded.</p>
        </div>
      </div>
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
  readonly activeScope: PracticeScope;
  readonly language: Language;
  readonly bankReady: boolean;
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
  activeScope,
  language,
  bankReady,
  now,
  preferences,
  progress,
  session,
  startPractice,
  onSessionChange,
  onProgressChange,
  onSetPreferences,
}: PracticeProps) {
  const [scopeKind, setScopeKind] = useState(() => controlsFromScope(activeScope).scopeKind);
  const [categoryId, setCategoryId] = useState(() => controlsFromScope(activeScope).categoryId);
  const [subsectionId, setSubsectionId] = useState(() => controlsFromScope(activeScope).subsectionId);
  const [submittingPractice, setSubmittingPractice] = useState(false);
  const feedbackRef = useRef<HTMLDivElement>(null);
  const reviewRef = useRef<HTMLDivElement>(null);
  const currentItem = session?.items[session.currentIndex];
  const selectedSourceIndex = currentItem === undefined ? undefined : session?.selectedByQuestionId.get(currentItem.question.id);
  const isAnswered = selectedSourceIndex !== undefined;
  const allAnswered = session !== null && session.items.every((item) => session.selectedByQuestionId.has(item.question.id));

  useEffect(() => {
    if (session === null && bankReady) {
      startPractice(activeScope, preferences.practiceMode);
    }
  }, [bankReady]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    const controls = controlsFromScope(session?.scope ?? activeScope);
    setScopeKind(controls.scopeKind);
    setCategoryId(controls.categoryId);
    setSubsectionId(controls.subsectionId);
  }, [activeScope, session?.scope]);

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
    if (hasUnsubmittedReviewAnswers(session) && !window.confirm("Discard unsubmitted practice answers and start a new set?")) {
      return;
    }
    const nextScope = scopeFromControls(scopeKind, categoryId, subsectionId);
    void onSetPreferences({ ...preferences, practiceMode: nextMode }).catch(() => {
      // The parent surfaces IndexedDB failures in a role=alert message.
    });
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
      try {
        await onProgressChange(nextProgress);
      } catch {
        // The parent surfaces IndexedDB failures in a role=alert message.
      }
    }
  }

  async function submitReviewLater(): Promise<void> {
    if (session === null || submittingPractice) {
      return;
    }
    setSubmittingPractice(true);
    try {
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
    } catch {
      // The parent surfaces IndexedDB failures in a role=alert message.
    } finally {
      setSubmittingPractice(false);
    }
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
        <button type="button" className="primary-button" onClick={() => restartWithControls()}>Start set</button>
      </div>

      {session === null || currentItem === undefined ? (
        <div className="empty-state" role="status">
          <p>No questions are available for this scope yet. Try all questions or a category.</p>
        </div>
      ) : (
        <div className="practice-layout">
          <aside className="session-outline" aria-label="Practice session outline">
            <div className="session-summary" aria-label="Practice session progress">
              <span>Question {session.currentIndex + 1} of {session.items.length}</span>
              <span>Scope: {scopeLabel(session.scope)}</span>
              <span>Mode: {session.mode === "immediate" ? "Immediate feedback" : "Review later"}</span>
              <span>Seed {session.seed}</span>
            </div>
            <p>Answered: <strong>{session.selectedByQuestionId.size} of {session.items.length}</strong></p>
            <p>Current subsection: <strong>{currentItem.question.subsectionId}</strong></p>
          </aside>
          <div className="practice-main">
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
                <button type="button" className="primary-button" disabled={!allAnswered || session.submitted || submittingPractice} onClick={() => void submitReviewLater()}>{submittingPractice ? "Submitting practice set" : "Submit practice set"}</button>
              ) : null}
            </div>
            {session.submitted ? <div ref={reviewRef} tabIndex={-1}><PracticeReview session={session} language={language} /></div> : null}
          </div>
        </div>
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
      <p className="question-text" lang={languageTag(language)}>{question.text[language]}</p>
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
              <span lang={languageTag(language)}>{answer.text[language]}</span>
              {showCorrectness && correct ? <span className="answer-state-icon" aria-hidden="true">✓</span> : null}
              {showCorrectness && selected && !correct ? <span className="answer-state-icon" aria-hidden="true">✕</span> : null}
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
              <p lang={languageTag(language)}>{item.question.text[language]}</p>
              <p>Your answer: <span lang={languageTag(language)}>{selectedAnswer?.text[language] ?? "Unanswered"}</span></p>
              <p>Correct answer: <span lang={languageTag(language)}>{correctAnswer.text[language]}</span></p>
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
  readonly questions: readonly Question[] | null;
  readonly preferences: WebPreferences;
  readonly now: () => string;
  readonly seedFactory: () => string;
  readonly onExamChange: (exam: MockExamSession | null) => void;
  readonly onSubmitExam: (attempt: ExamAttempt) => Promise<void>;
}

function MockExam({ exam, language, questions, preferences, now, seedFactory, onExamChange, onSubmitExam }: MockExamProps) {
  const [seed, setSeed] = useState("");
  const [timerEnabled, setTimerEnabled] = useState(preferences.examTimerEnabled);
  const [timerAnnouncement, setTimerAnnouncement] = useState("");
  const [submittingExam, setSubmittingExam] = useState(false);
  const examQuestionsById = useMemo(() => questions === null ? new Map<string, Question>() : questionsById(questions), [questions]);
  const confirmRef = useRef<HTMLElement>(null);
  const submitButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (exam?.timerEnabled && exam.timerRunning) {
      const id = window.setInterval(() => {
        const nextSecondsElapsed = exam.secondsElapsed + 1;
        if (nextSecondsElapsed > 0 && nextSecondsElapsed % 900 === 0) {
          setTimerAnnouncement(`Timer milestone: ${Math.floor(nextSecondsElapsed / 60)} minutes elapsed.`);
        }
        onExamChange({ ...exam, secondsElapsed: nextSecondsElapsed });
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
    if (questions === null) {
      setTimerAnnouncement("Question bank is still loading locally.");
      return;
    }
    const selectedSeed = seed.trim() || seedFactory();
    setSubmittingExam(false);
    setTimerAnnouncement(timerEnabled ? "Timer started." : "");
    onExamChange({
      seed: selectedSeed,
      startedAt: now(),
      timerEnabled,
      generatedItems: createMockExam(selectedSeed, questions),
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
        <div className="reference-note" aria-label="Exam reference sheet attribution">
          <strong>Exam reference sheet</strong>
          <p>The unlabelled ISED exam reference material PDF contains formulas and block diagrams and may be used while writing the exam. Private-development access only; public release is blocked until permission is recorded.</p>
          <a className="button secondary-button" href={examReferenceSheetUrl} target="_blank" rel="noreferrer">Open exam reference sheet <span className="new-tab-hint">(opens in new tab)</span></a>
        </div>
        <button type="button" className="primary-button" disabled={questions === null} onClick={startExam}>{questions === null ? "Loading question bank" : "Start mock exam"}</button>
      </section>
    );
  }

  const item = exam.generatedItems[exam.currentIndex]!;
  const question = generatedExamQuestion(item, examQuestionsById);
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
    if (exam === null || submittingExam) {
      return;
    }
    setSubmittingExam(true);
    const selected = new Map<string, number | null>();
    for (const generatedItem of exam.generatedItems) {
      selected.set(generatedItem.questionId, exam.selectedByQuestionId.get(generatedItem.questionId) ?? null);
    }
    try {
      await onSubmitExam(buildExamAttempt({
        seed: exam.seed,
        startedAt: exam.startedAt,
        submittedAt: now(),
        timerEnabled: exam.timerEnabled,
        secondsElapsed: exam.secondsElapsed,
        generatedItems: exam.generatedItems,
        selectedByQuestionId: selected,
        flaggedQuestionIds: exam.flaggedQuestionIds,
      }));
    } catch {
      setSubmittingExam(false);
    }
  }

  return (
    <section className="card mock-exam" aria-labelledby="mock-title">
      <h2 id="mock-title">Mock exam</h2>
      <div className="session-summary" aria-label="Mock exam progress">
        <span>Question {exam.currentIndex + 1} of {exam.generatedItems.length}</span>
        <span>Seed: {exam.seed}</span>
        <span>Answered: {exam.selectedByQuestionId.size} of {exam.generatedItems.length}</span>
      </div>
      <div className="exam-tool-row">
        <a className="button secondary-button" href={examReferenceSheetUrl} target="_blank" rel="noreferrer">Exam reference sheet <span className="new-tab-hint">(opens in new tab)</span></a>
        <span>The PDF contains formulas and block diagrams; ISED source, private-development build.</span>
      </div>
      {exam.timerEnabled ? (
        <div className="timer-panel">
          <span role="timer" aria-live="off" aria-label={`Timer elapsed ${formatElapsedForSpeech(exam.secondsElapsed)}`}>Timer elapsed: {formatElapsed(exam.secondsElapsed)}</span>
          <button
            type="button"
            onClick={() => {
              const nextRunning = !exam.timerRunning;
              setTimerAnnouncement(nextRunning ? "Timer resumed." : "Timer paused.");
              onExamChange({ ...exam, timerRunning: nextRunning });
            }}
          >{exam.timerRunning ? "Pause timer" : "Resume timer"}</button>
          <span className="sr-only" role="status" aria-live="polite">{timerAnnouncement}</span>
        </div>
      ) : <p className="timer-off-note">Timer off. No time pressure by default.</p>}
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
        <button type="button" ref={submitButtonRef} onClick={() => onExamChange({ ...exam, confirmingSubmit: true })}>Submit exam</button>
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
              aria-current={index === exam.currentIndex ? "step" : undefined}
              aria-label={`Question ${index + 1}${index === exam.currentIndex ? ", current" : ""}${answered ? ", answered" : ", unanswered"}${flagged ? ", flagged" : ""}`}
              onClick={() => onExamChange({ ...exam, currentIndex: index })}
            >
              {index === exam.currentIndex ? <span aria-hidden="true">● </span> : null}{index + 1}{flagged ? " ⚑" : ""}{answered ? " ✓" : ""}
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
            <button type="button" onClick={() => { onExamChange({ ...exam, confirmingSubmit: false }); window.setTimeout(() => submitButtonRef.current?.focus(), 0); }}>Continue exam</button>
            <button type="button" className="danger" disabled={submittingExam} onClick={() => void confirmSubmit()}>{submittingExam ? "Submitting exam" : "Confirm submit"}</button>
          </div>
        </section>
      ) : null}
    </section>
  );
}

function Results({ attempt, language, onStartPractice, questionsById }: { readonly attempt: ExamAttempt | null; readonly language: Language; readonly onStartPractice: (scope: PracticeScope) => void; readonly questionsById: ReadonlyMap<string, Question> }) {
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
              const question = questionsById.get(item.questionId);
              const selected = question?.answers.find((answer) => answer.sourceIndex === item.selectedSourceIndex);
              const correct = question?.answers.find((answer) => answer.sourceIndex === 0);
              return (
                <li key={item.questionId}>
                  <strong>{item.questionId}</strong>
                  {question === undefined ? (
                    <p>Question text is loading from the bundled bank.</p>
                  ) : (
                    <>
                      <p lang={languageTag(language)}>{question.text[language]}</p>
                      <p>Your answer: <span lang={languageTag(language)}>{selected?.text[language] ?? "Unanswered"}</span></p>
                      <p>Correct answer: <span lang={languageTag(language)}>{correct?.text[language] ?? "Loading"}</span></p>
                    </>
                  )}
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
  readonly preferences: WebPreferences;
  readonly statusMessage: string;
  readonly onProgressImported: (data: ProgressExportV1) => void;
  readonly onReset: () => void;
  readonly onSetPreferences: (preferences: WebPreferences) => Promise<void>;
}

function Settings({ store, now, preferences, statusMessage, onProgressImported, onReset, onSetPreferences }: SettingsProps) {
  const [errors, setErrors] = useState<readonly string[]>([]);
  const [pendingImport, setPendingImport] = useState<ProgressExportV1 | null>(null);
  const [message, setMessage] = useState(statusMessage);
  const [confirmReset, setConfirmReset] = useState(false);
  const resetButtonRef = useRef<HTMLButtonElement>(null);
  const resetDialogRef = useRef<HTMLDivElement>(null);
  const statusRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setMessage(statusMessage);
  }, [statusMessage]);

  useEffect(() => {
    if (confirmReset) {
      resetDialogRef.current?.focus();
    }
  }, [confirmReset]);

  async function exportProgress(): Promise<void> {
    setErrors([]);
    try {
      const data = await store.exportData(now());
      const blob = new Blob([serializeProgressExport(data)], { type: "application/json" });
      const href = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = href;
      anchor.download = `canadian-ham-progress-${data.exportedAt.slice(0, 10)}.json`;
      anchor.hidden = true;
      document.body.append(anchor);
      anchor.click();
      anchor.remove();
      window.setTimeout(() => URL.revokeObjectURL(href), 0);
      setMessage("Progress export was prepared locally. Nothing was uploaded.");
    } catch (error) {
      setErrors([`Unable to export local progress: ${formatError(error)}`]);
    }
  }

  async function handleImport(file: File | undefined): Promise<void> {
    setMessage("");
    setErrors([]);
    setPendingImport(null);
    if (file === undefined) {
      return;
    }
    try {
      const parsed = JSON.parse(await readFileText(file)) as unknown;
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
    try {
      await store.importData(pendingImport);
      onProgressImported(pendingImport);
      setPendingImport(null);
      setErrors([]);
      setMessage("Import complete. Imported progress replaced the previous local data.");
      window.setTimeout(() => statusRef.current?.focus(), 0);
    } catch (error) {
      setErrors([`Unable to import local progress: ${formatError(error)}`]);
    }
  }

  async function resetAll(): Promise<void> {
    try {
      await store.resetAllData();
      onReset();
      setConfirmReset(false);
      setErrors([]);
      setMessage("All local data was reset.");
      window.setTimeout(() => statusRef.current?.focus(), 0);
    } catch (error) {
      setErrors([`Unable to reset local progress: ${formatError(error)}`]);
    }
  }

  async function chooseTheme(theme: WebPreferences["theme"]): Promise<void> {
    try {
      await onSetPreferences({ ...preferences, theme });
      setErrors([]);
      setMessage(`Theme preference saved: ${theme === "system" ? "System" : theme === "light" ? "Light" : "Dark"}.`);
    } catch (error) {
      setErrors([`Unable to save theme preference: ${formatError(error)}`]);
    }
  }

  return (
    <section className="card settings" aria-labelledby="settings-title">
      <h2 id="settings-title">Settings and local data</h2>
      <p>No accounts, analytics, telemetry, network sync, remote assets, or third-party runtime SDKs are used. Progress stays in IndexedDB on this device unless you export it.</p>
      <p>Active bank: {bankId}, effective {manifest.effectiveDate}. Export/import/reset are user initiated.</p>
      <fieldset className="segmented-control theme-toggle">
        <legend>Theme</legend>
        <label><input type="radio" name="theme" checked={preferences.theme === "system"} onChange={() => void chooseTheme("system")} /> System</label>
        <label><input type="radio" name="theme" checked={preferences.theme === "light"} onChange={() => void chooseTheme("light")} /> Light</label>
        <label><input type="radio" name="theme" checked={preferences.theme === "dark"} onChange={() => void chooseTheme("dark")} /> Dark</label>
      </fieldset>
      <div className="action-row">
        <button type="button" onClick={() => void exportProgress()}>Export progress JSON</button>
        <label className="file-control">
          Import progress JSON
          <input type="file" accept="application/json,.json" onChange={(event) => void handleImport(event.currentTarget.files?.[0])} />
        </label>
        <button type="button" className="danger" ref={resetButtonRef} onClick={() => setConfirmReset(true)}>Reset all data</button>
      </div>
      {pendingImport !== null ? <button type="button" className="primary-button" onClick={() => void confirmImport()}>Confirm import and replace local data</button> : null}
      {confirmReset ? (
        <div className="confirm-panel" role="alertdialog" aria-labelledby="reset-title" aria-modal="false" ref={resetDialogRef} tabIndex={-1}>
          <h3 id="reset-title">Reset all local data?</h3>
          <p>This deletes browser-local question progress, mock exam attempts, and preferences. Bundled content remains available offline.</p>
          <button type="button" onClick={() => { setConfirmReset(false); window.setTimeout(() => resetButtonRef.current?.focus(), 0); }}>Cancel reset</button>
          <button type="button" className="danger" onClick={() => void resetAll()}>Confirm reset all data</button>
        </div>
      ) : null}
      <div role="status" aria-live="polite" ref={statusRef} tabIndex={-1}>
        {message ? <p>{message}</p> : null}
      </div>
      {errors.length > 0 ? <div role="alert"><ul>{errors.map((error) => <li key={error}>{error}</li>)}</ul></div> : null}
    </section>
  );
}

function readFileText(file: File): Promise<string> {
  if (typeof file.text === "function") {
    return file.text();
  }
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(reader.error ?? new Error("Unable to read file."));
    reader.onload = () => resolve(String(reader.result ?? ""));
    reader.readAsText(file);
  });
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

function formatError(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
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

function controlsFromScope(scope: PracticeScope): { scopeKind: string; categoryId: string; subsectionId: string } {
  return {
    scopeKind: scope.type,
    categoryId: scope.type === "category" ? scope.categoryId : categories[0]?.id ?? "B-001",
    subsectionId: scope.type === "subsection" ? scope.subsectionId : subsections[0]?.id ?? "B-001-001",
  };
}

function scopeLabel(scope: PracticeScope): string {
  if (scope.type === "category") {
    return categoryName(scope.categoryId);
  }
  if (scope.type === "subsection") {
    return `${scope.subsectionId}: ${subsectionTitle(scope.subsectionId)}`;
  }
  if (scope.type === "weak") {
    return "Weak areas";
  }
  if (scope.type === "due") {
    return "Due review";
  }
  return "All questions";
}

function hasUnsubmittedReviewAnswers(session: PracticeSession | null): boolean {
  return session !== null && session.mode === "review-later" && !session.submitted && session.selectedByQuestionId.size > 0;
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

function languageTag(language: Language): "en-CA" | "fr-CA" {
  return language === "fr" ? "fr-CA" : "en-CA";
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
    <p>Correct. The correct answer is: <strong lang={languageTag(language)}>{correctAnswer.text[language]}</strong></p>
  ) : (
    <p>Incorrect. The correct answer is: <strong lang={languageTag(language)}>{correctAnswer.text[language]}</strong></p>
  );
}

function formatElapsed(secondsElapsed: number): string {
  const minutes = Math.floor(secondsElapsed / 60).toString().padStart(2, "0");
  const seconds = (secondsElapsed % 60).toString().padStart(2, "0");
  return `${minutes}:${seconds}`;
}

function formatElapsedForSpeech(secondsElapsed: number): string {
  const minutes = Math.floor(secondsElapsed / 60);
  const seconds = secondsElapsed % 60;
  return `${minutes} minute${minutes === 1 ? "" : "s"} ${seconds} second${seconds === 1 ? "" : "s"}`;
}

export const webExamCategoryCounts = examCategoryCounts;
