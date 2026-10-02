import {
  computeReadiness,
  dueCount,
  weakSubsectionIds,
  type QuestionProgressRecord,
  type ReadinessResult,
} from "@canadian-ham/engine-ts";
import { Component, createRef, useEffect, useMemo, useRef, useState, type MouseEvent, type ReactNode, type RefObject } from "react";

import { LanguageToggle } from "./components/LanguageToggle";
import { MarkdownContent } from "./components/MarkdownContent";
import { PwaStatus } from "./components/PwaStatus";
import {
  allQuestionCount,
  bankId,
  categories,
  categoryNameWithLanguage,
  loadQuestions,
  localizedCategoryNameWithLanguage,
  manifest,
  questionsById,
  subsectionTitle,
  subsectionTitles,
  subsections,
  type Language,
  type Question,
} from "./data/bank";
import { explanationForQuestion, mainExplanationText, parseChoiceNotes, type Explanation } from "./data/explanations";
import { lessonNeighbors, lessonsById, lessonsByModuleId, modules, modulesById, type LessonMeta } from "./data/lessons";
import { buildLessonQuizItems, lessonQuizzesById, type ConceptCheck, type LessonQuiz, type LessonQuizItem } from "./data/quizzes";
import {
  defaultPreferences,
  defaultProgressStore,
  serializeProgressExport,
  validateProgressImport,
  type ExamAttempt,
  type LessonProgressRecord,
  type LessonQuizAttempt,
  type PracticeMode,
  type ProgressExportV1,
  type ProgressStore,
  type WebPreferences,
} from "./lib/progressStore";
import {
  clearStoredInterfaceLanguage,
  interfaceLanguageTag,
  readStoredInterfaceLanguage,
  storeInterfaceLanguage,
  t,
  type InterfaceLanguage,
} from "./lib/i18n";
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

type Route = "home" | "learn" | "module" | "lesson" | "practice" | "mock" | "results" | "settings" | "about";
type View = Route;
type PreferencesPatch = Partial<WebPreferences>;

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
  readonly recoveryPreferences: WebPreferences | null;
}

export class AppErrorBoundary extends Component<AppErrorBoundaryProps, AppErrorBoundaryState> {
  override state: AppErrorBoundaryState = { errorMessage: null, recoveryPreferences: null };
  private readonly mainRef = createRef<HTMLElement>();

  static getDerivedStateFromError(error: unknown): AppErrorBoundaryState {
    return { errorMessage: formatError(error), recoveryPreferences: null };
  }

  private readonly handleSkipToMain = (event: MouseEvent<HTMLAnchorElement>): void => {
    event.preventDefault();
    this.mainRef.current?.focus();
  };

  override render(): ReactNode {
    if (this.state.errorMessage === null) {
      return this.props.children;
    }
    const recoveryPreferences = this.state.recoveryPreferences ?? { ...defaultPreferences, theme: readStoredThemePreference() };
    const interfaceLanguage = readStoredInterfaceLanguage();
    return (
      <div className="app-shell">
        <a className="skip-link" href="#main" onClick={this.handleSkipToMain}>{t(interfaceLanguage, "skipToMainContent")}</a>
        <header className="site-header" role="banner">
          <div className="brand-lockup">
            <HeaderMark />
            <div>
              <p className="eyebrow">{t(interfaceLanguage, "appEyebrow")}</p>
              <h1>{t(interfaceLanguage, "appName")}</h1>
            </div>
          </div>
        </header>
        <main id="main" ref={this.mainRef} tabIndex={-1}>
          <section className="card settings" aria-labelledby="app-recovery-title">
            <h2 id="app-recovery-title">{t(interfaceLanguage, "errorBoundaryTitle")}</h2>
            <p role="alert">{t(interfaceLanguage, "errorBoundaryRenderFailed", this.state.errorMessage)}</p>
            <p>{t(interfaceLanguage, "errorBoundaryResetAvailable")}</p>
            <Settings
              now={this.props.now}
              onProgressImported={() => this.setState({ errorMessage: null })}
              onReset={() => this.setState({ errorMessage: null })}
              onSetPreferences={async (preferencesPatch) => {
                const storedPreferences = await readRecoverablePreferences(this.props.store);
                const nextPreferences = { ...storedPreferences, ...preferencesPatch };
                await this.props.store.putPreferences(nextPreferences);
                applyThemePreference(nextPreferences.theme);
                mirrorThemePreference(nextPreferences.theme);
                this.setState({ recoveryPreferences: nextPreferences });
                return true;
              }}
              interfaceLanguage={interfaceLanguage}
              onInterfaceLanguageChange={(language) => { storeInterfaceLanguage(language); this.forceUpdate(); }}
              preferences={recoveryPreferences}
              statusMessage=""
              store={this.props.store}
            />
          </section>
        </main>
        <Footer interfaceLanguage={interfaceLanguage} />
      </div>
    );
  }
}

async function readRecoverablePreferences(store: ProgressStore): Promise<WebPreferences> {
  try {
    return await store.getPreferences();
  } catch {
    return { ...defaultPreferences, theme: readStoredThemePreference() };
  }
}

function routeFromHash(fallback: Route, hash = globalThis.location?.hash ?? ""): Route {
  const segments = hashSegments(hash);
  if (segments[0] === "learn" && segments.length >= 3) {
    return "lesson";
  }
  if (segments[0] === "learn" && segments.length >= 2) {
    return "module";
  }
  const route = segments[0] ?? "";
  return isRoute(route) ? route : fallback;
}

function hashSegments(hash = globalThis.location?.hash ?? ""): readonly string[] {
  const normalizedHash = hash.replace(/^#\/?/, "");
  return normalizedHash.split("/").filter(Boolean);
}

function isRoute(value: string): value is Route {
  return value === "home" || value === "learn" || value === "practice" || value === "mock" || value === "results" || value === "settings" || value === "about";
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
  const initialPreferences = () => ({ ...defaultPreferences, theme: readStoredThemePreference() });
  const [locationHash, setLocationHash] = useState(() => globalThis.location?.hash ?? "");
  const [route, setRoute] = useState<Route>(() => routeFromHash(initialView));
  const [language, setLanguage] = useState<Language>("en");
  const [interfaceLanguage, setInterfaceLanguageState] = useState<InterfaceLanguage>(() => readStoredInterfaceLanguage());
  const [bankQuestions, setBankQuestions] = useState<readonly Question[] | null>(null);
  const [initialStoreLoaded, setInitialStoreLoaded] = useState(false);
  const [progress, setProgress] = useState<readonly QuestionProgressRecord[]>([]);
  const [examAttempts, setExamAttempts] = useState<readonly ExamAttempt[]>([]);
  const [lessonProgress, setLessonProgress] = useState<readonly LessonProgressRecord[]>([]);
  const [lessonQuizAttempts, setLessonQuizAttempts] = useState<readonly LessonQuizAttempt[]>([]);
  const [preferences, setPreferencesState] = useState<WebPreferences>(initialPreferences);
  const [practiceScope, setPracticeScope] = useState<PracticeScope>(() => scopeFromInitialId(initialScopeId));
  const [practiceSession, setPracticeSession] = useState<PracticeSession | null>(null);
  const [mockExam, setMockExam] = useState<MockExamSession | null>(null);
  const [latestResult, setLatestResult] = useState<ExamAttempt | null>(null);
  const [statusMessage, setStatusMessage] = useState("");
  const [alertMessage, setAlertMessage] = useState("");
  const mainRef = useRef<HTMLElement>(null);
  const previousRouteFocusRef = useRef({ locationHash, route });
  const interfaceLanguageRef = useRef(interfaceLanguage);
  const savedPreferencesRef = useRef(preferences);
  const latestRequestedPreferencesRef = useRef(preferences);
  const preferencesSaveQueueRef = useRef<Promise<void>>(Promise.resolve());
  const preferencesSaveSequenceRef = useRef(0);
  const savedPreferencesSequenceRef = useRef(0);

  useEffect(() => {
    interfaceLanguageRef.current = interfaceLanguage;
  }, [interfaceLanguage]);

  useEffect(() => {
    let cancelled = false;
    setInitialStoreLoaded(false);
    async function loadProgress(): Promise<void> {
      try {
        const [storedProgress, storedAttempts, storedLessonProgress, storedQuizAttempts, storedPreferences] = await Promise.all([
          store.getQuestionProgress(),
          store.getExamAttempts(),
          store.getLessonProgress(),
          store.getLessonQuizAttempts(),
          store.getPreferences(),
        ]);
        if (!cancelled) {
          setProgress(storedProgress);
          setExamAttempts(storedAttempts);
          setLessonProgress(storedLessonProgress);
          setLessonQuizAttempts(storedQuizAttempts);
          savedPreferencesRef.current = storedPreferences;
          latestRequestedPreferencesRef.current = storedPreferences;
          setPreferencesState(storedPreferences);
          setAlertMessage("");
        }
      } catch (error) {
        if (!cancelled) {
          setAlertMessage(t(interfaceLanguageRef.current, "errorOpenStorage", formatError(error)));
        }
      } finally {
        if (!cancelled) {
          setInitialStoreLoaded(true);
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
          setAlertMessage(t(interfaceLanguageRef.current, "errorLoadQuestionBank", formatError(error)));
        }
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const onHashChange = () => {
      const nextHash = window.location.hash;
      setLocationHash(nextHash);
      setRoute(routeFromHash("home", nextHash));
    };
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  useEffect(() => {
    const previousRouteFocus = previousRouteFocusRef.current;
    if (previousRouteFocus.locationHash === locationHash && previousRouteFocus.route === route) {
      return;
    }
    previousRouteFocusRef.current = { locationHash, route };
    mainRef.current?.focus();
  }, [locationHash, route]);

  useEffect(() => {
    document.documentElement.lang = interfaceLanguageTag(interfaceLanguage);
  }, [interfaceLanguage]);

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
    if (typeof media.addEventListener === "function") {
      media.addEventListener("change", onSystemThemeChange);
      return () => media.removeEventListener("change", onSystemThemeChange);
    }
    media.addListener?.(onSystemThemeChange);
    return () => media.removeListener?.(onSystemThemeChange);
  }, [preferences.theme]);

  const bankQuestionsById = useMemo(() => bankQuestions === null ? new Map<string, Question>() : questionsById(bankQuestions), [bankQuestions]);
  const latestAttempt = useMemo(() => latestSubmittedAttempt(examAttempts), [examAttempts]);
  const readiness = useMemo(() => buildReadiness(progress, examAttempts, now()), [examAttempts, now, progress]);
  const weakSubsections = useMemo(
    () => weakSubsectionIds(progress, latestAttempt?.items ?? []),
    [latestAttempt, progress],
  );
  const dueReviewCount = useMemo(() => dueCount(progress, now()), [now, progress]);
  const routeSegments = hashSegments(locationHash);
  const currentModuleId = route === "module" || route === "lesson" ? routeSegments[1] : undefined;
  const currentLessonId = route === "lesson" ? routeSegments[2] : undefined;

  function updateRouteForHash(nextHash: string): void {
    setLocationHash(nextHash);
    setRoute(routeFromHash("home", nextHash));
  }

  function navigate(nextRoute: Route): void {
    const nextHash = `#/${nextRoute}`;
    updateRouteForHash(nextHash);
    if (window.location.hash !== nextHash) {
      window.location.hash = `/${nextRoute}`;
    }
  }

  function navigateToModule(moduleId: string): void {
    const nextHash = `#/learn/${moduleId}`;
    updateRouteForHash(nextHash);
    if (window.location.hash !== nextHash) {
      window.location.hash = `/learn/${moduleId}`;
    }
  }

  function navigateToLesson(moduleId: string, lessonId: string): void {
    const nextHash = `#/learn/${moduleId}/${lessonId}`;
    updateRouteForHash(nextHash);
    if (window.location.hash !== nextHash) {
      window.location.hash = `/learn/${moduleId}/${lessonId}`;
    }
  }

  function handleSkipToMain(event: MouseEvent<HTMLAnchorElement>): void {
    event.preventDefault();
    mainRef.current?.focus();
  }

  function startPractice(scope: PracticeScope = practiceScope, mode: PracticeMode = preferences.practiceMode): void {
    if (bankQuestions === null) {
      setAlertMessage(t(interfaceLanguage, "errorQuestionBankLoading"));
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

  async function setPreferences(preferencesPatch: PreferencesPatch): Promise<boolean> {
    const nextPreferences = { ...latestRequestedPreferencesRef.current, ...preferencesPatch };
    latestRequestedPreferencesRef.current = nextPreferences;
    const saveSequence = preferencesSaveSequenceRef.current + 1;
    preferencesSaveSequenceRef.current = saveSequence;
    setPreferencesState(nextPreferences);

    const saveOperation = preferencesSaveQueueRef.current.then(() => store.putPreferences(nextPreferences));
    preferencesSaveQueueRef.current = saveOperation.catch(() => undefined);

    try {
      await saveOperation;
      if (saveSequence > savedPreferencesSequenceRef.current) {
        savedPreferencesSequenceRef.current = saveSequence;
        savedPreferencesRef.current = nextPreferences;
      }
      const savedLatestRequest = saveSequence === preferencesSaveSequenceRef.current;
      if (savedLatestRequest) {
        setAlertMessage("");
      }
      return savedLatestRequest;
    } catch (error) {
      if (saveSequence !== preferencesSaveSequenceRef.current) {
        return false;
      }
      const rollbackPreferences = savedPreferencesRef.current;
      latestRequestedPreferencesRef.current = rollbackPreferences;
      setPreferencesState(rollbackPreferences);
      setAlertMessage(t(interfaceLanguage, "errorSavePreferences", formatError(error)));
      throw error;
    }
  }

  function setInterfaceLanguage(nextLanguage: InterfaceLanguage): void {
    setInterfaceLanguageState(nextLanguage);
    storeInterfaceLanguage(nextLanguage);
  }

  async function commitProgress(nextProgress: readonly QuestionProgressRecord[]): Promise<void> {
    try {
      await store.putQuestionProgressMany(nextProgress);
      setProgress(nextProgress);
      setAlertMessage("");
    } catch (error) {
      setAlertMessage(t(interfaceLanguage, "errorSaveQuestionProgress", formatError(error)));
      throw error;
    }
  }

  async function markLessonRead(lesson: LessonMeta): Promise<void> {
    const existing = lessonProgress.find((record) => record.lessonId === lesson.id);
    const nextRecord: LessonProgressRecord = {
      lessonId: lesson.id,
      readAt: now(),
      readCount: (existing?.readCount ?? 0) + 1,
    };
    try {
      await store.putLessonProgress(nextRecord);
      setLessonProgress((current) => [...current.filter((record) => record.lessonId !== lesson.id), nextRecord].sort((a, b) => a.lessonId.localeCompare(b.lessonId)));
      setAlertMessage("");
    } catch (error) {
      setAlertMessage(t(interfaceLanguage, "errorSaveLessonProgress", formatError(error)));
    }
  }

  async function commitLessonQuizAttempt(attempt: LessonQuizAttempt, nextProgress: readonly QuestionProgressRecord[]): Promise<void> {
    try {
      await store.putLessonQuizAttemptWithQuestionProgress(attempt, nextProgress);
      setLessonQuizAttempts((current) => [...current, attempt].sort((a, b) => a.submittedAt.localeCompare(b.submittedAt)));
      setProgress(nextProgress);
      setAlertMessage("");
    } catch (error) {
      setAlertMessage(t(interfaceLanguage, "errorSaveLessonQuiz", formatError(error)));
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
      setAlertMessage(t(interfaceLanguage, "errorSaveMockExam", formatError(error)));
      throw error;
    }
  }

  return (
    <div className="app-shell" data-theme={preferences.theme === "system" ? undefined : preferences.theme}>
      <a className="skip-link" href="#main" onClick={handleSkipToMain}>{t(interfaceLanguage, "skipToMainContent")}</a>
      <header className="site-header" role="banner">
        <div className="brand-lockup">
          <HeaderMark />
          <div>
            <p className="eyebrow">{t(interfaceLanguage, "appEyebrow")}</p>
            <h1>{t(interfaceLanguage, "appName")}</h1>
          </div>
        </div>
        <div className="header-actions">
          <PwaStatus interfaceLanguage={interfaceLanguage} updateDisabled={mockExam !== null} />
          <LanguageToggle interfaceLanguage={interfaceLanguage} language={language} onLanguageChange={setLanguage} />
        </div>
      </header>

      <nav className="top-nav" aria-label={t(interfaceLanguage, "navPrimary")}>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "home" ? "page" : undefined} onClick={() => navigate("home")}>{t(interfaceLanguage, "navHome")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "learn" || route === "module" || route === "lesson" ? "page" : undefined} onClick={() => navigate("learn")}>{t(interfaceLanguage, "navLearn")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "practice" ? "page" : undefined} onClick={() => practiceSession === null ? startPractice(practiceScope) : navigate("practice")}>{t(interfaceLanguage, "navPractice")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "mock" ? "page" : undefined} onClick={() => navigate("mock")}>{t(interfaceLanguage, "navMockExam")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "settings" ? "page" : undefined} onClick={() => navigate("settings")}>{t(interfaceLanguage, "navSettings")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "about" ? "page" : undefined} onClick={() => navigate("about")}>{t(interfaceLanguage, "navAbout")}</button>
      </nav>

      <main id="main" ref={mainRef} tabIndex={-1}>
        {alertMessage ? <p className="alert-message" role="alert">{alertMessage}</p> : null}
        {!initialStoreLoaded ? <InitialStoreLoading interfaceLanguage={interfaceLanguage} /> : null}
        {initialStoreLoaded && route === "home" ? (
          <Home
            interfaceLanguage={interfaceLanguage}
            dueReviewCount={dueReviewCount}
            examAttempts={examAttempts}
            onNavigate={navigate}
            onStartPractice={startPractice}
            readiness={readiness}
            weakSubsections={weakSubsections}
          />
        ) : null}
        {initialStoreLoaded && route === "learn" ? (
          <Learn
            interfaceLanguage={interfaceLanguage}
            lessonProgress={lessonProgress}
            onOpenLesson={navigateToLesson}
            onOpenModule={navigateToModule}
          />
        ) : null}
        {initialStoreLoaded && route === "module" ? (
          <ModulePage
            interfaceLanguage={interfaceLanguage}
            lessonProgress={lessonProgress}
            moduleId={currentModuleId ?? ""}
            onOpenLesson={navigateToLesson}
          />
        ) : null}
        {initialStoreLoaded && route === "lesson" ? (
          <LessonPage
            interfaceLanguage={interfaceLanguage}
            attempts={lessonQuizAttempts}
            bankQuestionsById={bankQuestionsById}
            language={language}
            lessonId={currentLessonId ?? ""}
            lessonProgress={lessonProgress}
            moduleId={currentModuleId ?? ""}
            now={now}
            onLessonRead={(lesson) => void markLessonRead(lesson)}
            onOpenLesson={navigateToLesson}
            onOpenModule={navigateToModule}
            onQuizAttempt={(attempt, nextProgress) => void commitLessonQuizAttempt(attempt, nextProgress)}
            progress={progress}
          />
        ) : null}
        {initialStoreLoaded && route === "practice" ? (
          <Practice
            interfaceLanguage={interfaceLanguage}
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
        {initialStoreLoaded && route === "mock" ? (
          <MockExam
            interfaceLanguage={interfaceLanguage}
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
        {initialStoreLoaded && route === "results" ? (
          <Results attempt={latestResult ?? latestAttempt} interfaceLanguage={interfaceLanguage} language={language} onStartPractice={startPractice} questionsById={bankQuestionsById} />
        ) : null}
        {initialStoreLoaded && route === "settings" ? (
          <Settings
            interfaceLanguage={interfaceLanguage}
            now={now}
            onProgressImported={(data) => {
              setProgress(data.questionProgress);
              setExamAttempts(data.examAttempts);
              setLessonProgress(data.lessonProgress ?? []);
              setLessonQuizAttempts(data.lessonQuizAttempts ?? []);
              savedPreferencesRef.current = data.preferences;
              latestRequestedPreferencesRef.current = data.preferences;
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
              setLessonProgress([]);
              setLessonQuizAttempts([]);
              savedPreferencesRef.current = defaultPreferences;
              latestRequestedPreferencesRef.current = defaultPreferences;
              setPreferencesState(defaultPreferences);
              setPracticeScope({ type: "all" });
              setPracticeSession(null);
              setMockExam(null);
              setLatestResult(null);
              clearStoredInterfaceLanguage();
              const resetInterfaceLanguage = readStoredInterfaceLanguage();
              setInterfaceLanguageState(resetInterfaceLanguage);
              setAlertMessage("");
              setStatusMessage(t(resetInterfaceLanguage, "statusAllLocalProgressReset"));
            }}
            onInterfaceLanguageChange={setInterfaceLanguage}
            onSetPreferences={setPreferences}
            preferences={preferences}
            statusMessage={statusMessage}
            store={store}
          />
        ) : null}
        {initialStoreLoaded && route === "about" ? <About interfaceLanguage={interfaceLanguage} /> : null}
      </main>

      <Footer interfaceLanguage={interfaceLanguage} />
    </div>
  );
}

function InitialStoreLoading({ interfaceLanguage }: { readonly interfaceLanguage: InterfaceLanguage }) {
  return (
    <section className="card app-loading-compact" aria-labelledby="app-loading-title" role="status" aria-live="polite">
      <h2 id="app-loading-title">{t(interfaceLanguage, "loading")}</h2>
      <p>{t(interfaceLanguage, "loadingLocalProgress")}</p>
    </section>
  );
}

interface HomeProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly readiness: ReadinessResult;
  readonly weakSubsections: readonly string[];
  readonly dueReviewCount: number;
  readonly examAttempts: readonly ExamAttempt[];
  readonly onStartPractice: (scope: PracticeScope) => void;
  readonly onNavigate: (route: Route) => void;
}

function Home({ interfaceLanguage, readiness, weakSubsections, dueReviewCount, examAttempts, onStartPractice, onNavigate }: HomeProps) {
  const weakCategories = new Set(weakSubsections.map((id) => id.slice(0, 5)));
  return (
    <section className="card home" aria-labelledby="home-title">
      <div className="home-hero">
        <div>
          <p className="eyebrow">{t(interfaceLanguage, "homeEyebrow")}</p>
          <h2 id="home-title">{t(interfaceLanguage, "homeTitle")}</h2>
          <p>{t(interfaceLanguage, "homeIntro")}</p>
          <div className="action-row">
            <button type="button" className="primary-button" onClick={() => onStartPractice({ type: "all" })}>{t(interfaceLanguage, "homeStartPractice")}</button>
            <button type="button" className="secondary-button" onClick={() => onNavigate("learn")}>{t(interfaceLanguage, "homeLearn")}</button>
            <button type="button" className="secondary-button" onClick={() => onNavigate("mock")}>{t(interfaceLanguage, "homeMockExam")}</button>
          </div>
        </div>
      </div>
      <div className="readiness-panel" aria-labelledby="readiness-title">
        <h3 id="readiness-title">{t(interfaceLanguage, "readinessTitle")}</h3>
        <p><strong>{readinessLabel(interfaceLanguage, readiness.state)}</strong></p>
        <p>{readinessCopy(interfaceLanguage, readiness)}</p>
        <p>{t(interfaceLanguage, "readinessDueCount")} <strong>{dueReviewCount}</strong></p>
        <p>{t(interfaceLanguage, "readinessCompletedExams")} <strong>{examAttempts.length}</strong></p>
        {weakCategories.size > 0 ? (
          <p>{t(interfaceLanguage, "readinessWeakCategories")} {[...weakCategories].map((categoryId, index) => {
            const name = categoryNameWithLanguage(categoryId, interfaceLanguage);
            return <span key={categoryId}>{index > 0 ? ", " : null}<span lang={languageTag(name.language)}>{name.text}</span></span>;
          })}</p>
        ) : <p>{t(interfaceLanguage, "readinessNoWeakCategory")}</p>}
        {weakSubsections.length > 0 ? (
          <details>
            <summary>{t(interfaceLanguage, "readinessWeakSubsections")}</summary>
            <ul>
              {weakSubsections.slice(0, 12).map((subsectionId) => (
                <li key={subsectionId}>{subsectionId}{colonSeparator(interfaceLanguage)}<span lang={englishTextLang(interfaceLanguage)}>{subsectionTitle(subsectionId)}</span></li>
              ))}
            </ul>
          </details>
        ) : null}
        <div className="action-row">
          <button type="button" onClick={() => onStartPractice({ type: "weak" })}>{t(interfaceLanguage, "readinessPracticeWeak")}</button>
          <button type="button" onClick={() => onStartPractice({ type: "due" })}>{t(interfaceLanguage, "readinessReviewDue")}</button>
          <button type="button" onClick={() => onNavigate("mock")}>{t(interfaceLanguage, "readinessTakeMock")}</button>
        </div>
      </div>

      <div className="category-grid" aria-label={t(interfaceLanguage, "practiceCategoriesAria")}>
        <button className="category-card all-questions" type="button" onClick={() => onStartPractice({ type: "all" })}>
          <span>{t(interfaceLanguage, "allQuestions")}</span>
          <strong>{allQuestionCount}</strong>
          <small>{t(interfaceLanguage, "mixedAllCategories")}</small>
        </button>
        {categories.map((category) => {
          const name = localizedCategoryNameWithLanguage(category, interfaceLanguage);
          return (
            <button className="category-card" type="button" key={category.id} onClick={() => onStartPractice({ type: "category", categoryId: category.id })}>
              <span lang={languageTag(name.language)}>{name.text}</span>
              <strong>{category.questionCount}</strong>
              <small>{t(interfaceLanguage, "subsectionCount", category.subsectionCount)}</small>
            </button>
          );
        })}
      </div>
    </section>
  );
}

interface LearnProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly lessonProgress: readonly LessonProgressRecord[];
  readonly onOpenModule: (moduleId: string) => void;
  readonly onOpenLesson: (moduleId: string, lessonId: string) => void;
}

function Learn({ interfaceLanguage, lessonProgress, onOpenModule, onOpenLesson }: LearnProps) {
  const readLessonIds = new Set(lessonProgress.map((record) => record.lessonId));
  return (
    <section className="card learn" aria-labelledby="learn-title">
      <p className="eyebrow">{t(interfaceLanguage, "learnEyebrow")}</p>
      <h2 id="learn-title">{t(interfaceLanguage, "learnTitle")}</h2>
      <p>{t(interfaceLanguage, "learnIntro")}</p>
      <p className="reference-note">{t(interfaceLanguage, "referenceSheetNote")}</p>
      <div className="module-grid">
        {modules.map((module) => {
          const moduleLessons = lessonsByModuleId.get(module.id) ?? [];
          const readCount = moduleLessons.filter((lesson) => readLessonIds.has(lesson.id)).length;
          return (
            <article className="module-card" key={module.id}>
              <p className="eyebrow">{t(interfaceLanguage, "moduleLabel", module.order, module.categoryId)}</p>
              <h3 lang={englishTextLang(interfaceLanguage)}>{module.title.en}</h3>
              <p>{module.status === "outline" ? t(interfaceLanguage, "moduleOutlineAvailable") : t(interfaceLanguage, "moduleDraftAvailable")}</p>
              <p>{t(interfaceLanguage, "moduleLessonsMarkedRead", readCount, moduleLessons.length)}</p>
              <div className="action-row">
                <button type="button" onClick={() => onOpenModule(module.id)}>{t(interfaceLanguage, "moduleOpen")}</button>
                {moduleLessons[0] !== undefined ? <button type="button" className="secondary-button" onClick={() => onOpenLesson(module.id, moduleLessons[0]!.id)}>{t(interfaceLanguage, "moduleStart")}</button> : null}
              </div>
            </article>
          );
        })}
      </div>
    </section>
  );
}

function ModulePage({ interfaceLanguage, moduleId, lessonProgress, onOpenLesson }: { readonly interfaceLanguage: InterfaceLanguage; readonly moduleId: string; readonly lessonProgress: readonly LessonProgressRecord[]; readonly onOpenLesson: (moduleId: string, lessonId: string) => void }) {
  const module = modulesById.get(moduleId);
  if (module === undefined) {
    return (
      <section className="card module-page" aria-labelledby="module-title">
        <h2 id="module-title">{t(interfaceLanguage, "moduleNotFoundTitle")}</h2>
        <p>{t(interfaceLanguage, "moduleNotFoundCopy")}</p>
      </section>
    );
  }
  const moduleLessons = lessonsByModuleId.get(module.id) ?? [];
  const readLessonIds = new Set(lessonProgress.map((record) => record.lessonId));
  return (
    <section className="card module-page" aria-labelledby="module-title">
      <p className="eyebrow">{t(interfaceLanguage, "moduleLabel", module.order, module.categoryId)}</p>
      <h2 id="module-title" lang={englishTextLang(interfaceLanguage)}>{module.title.en}</h2>
      {interfaceLanguage === "fr" ? <p className="reference-note">{t(interfaceLanguage, "englishOnlyLessonNotice")}</p> : null}
      <div lang={englishTextLang(interfaceLanguage)}>
        <MarkdownContent interfaceLanguage={interfaceLanguage} markdown={module.body} title={module.title.en} />
      </div>
      <div className="lesson-list" aria-label={t(interfaceLanguage, "moduleLessonsAria", module.title.en)}>
        {moduleLessons.map((lesson) => (
          <article className="lesson-row" key={lesson.id}>
            <div>
              <p className="eyebrow">{t(interfaceLanguage, "lessonMeta", lesson.id, lesson.estimatedMinutes, lesson.covers.join(", "))}</p>
              <h3 lang={englishTextLang(interfaceLanguage)}>{lesson.title.en}</h3>
              <p>{lesson.status === "outline" ? t(interfaceLanguage, "lessonComingSoonStatus") : t(interfaceLanguage, "lessonReadyStatus")} · {readLessonIds.has(lesson.id) ? t(interfaceLanguage, "lessonMarkedRead") : t(interfaceLanguage, "lessonNotMarkedRead")}</p>
            </div>
            <button type="button" onClick={() => onOpenLesson(module.id, lesson.id)}>{lesson.status === "outline" ? t(interfaceLanguage, "lessonPreviewOutline") : t(interfaceLanguage, "lessonRead")}</button>
          </article>
        ))}
      </div>
    </section>
  );
}

interface LessonPageProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly moduleId: string;
  readonly lessonId: string;
  readonly language: Language;
  readonly bankQuestionsById: ReadonlyMap<string, Question>;
  readonly progress: readonly QuestionProgressRecord[];
  readonly lessonProgress: readonly LessonProgressRecord[];
  readonly attempts: readonly LessonQuizAttempt[];
  readonly now: () => string;
  readonly onLessonRead: (lesson: LessonMeta) => void;
  readonly onOpenModule: (moduleId: string) => void;
  readonly onOpenLesson: (moduleId: string, lessonId: string) => void;
  readonly onQuizAttempt: (attempt: LessonQuizAttempt, nextProgress: readonly QuestionProgressRecord[]) => void;
}

function LessonPage({ interfaceLanguage, moduleId, lessonId, language, bankQuestionsById, progress, lessonProgress, attempts, now, onLessonRead, onOpenModule, onOpenLesson, onQuizAttempt }: LessonPageProps) {
  const lesson = lessonsById.get(lessonId);
  const module = modulesById.get(moduleId) ?? (lesson !== undefined ? modulesById.get(lesson.moduleId) : undefined);
  if (lesson === undefined || module === undefined) {
    return (
      <section className="card lesson-page" aria-labelledby="lesson-title">
        <h2 id="lesson-title">{t(interfaceLanguage, "lessonNotFoundTitle")}</h2>
        <p>{t(interfaceLanguage, "lessonNotFoundCopy")}</p>
      </section>
    );
  }
  const neighbors = lessonNeighbors(lesson.id);
  const readRecord = lessonProgress.find((record) => record.lessonId === lesson.id);
  const lessonAttempts = attempts.filter((attempt) => attempt.lessonId === lesson.id);
  return (
    <section className="card lesson-page" aria-labelledby="lesson-title">
      <aside className="lesson-sidebar" aria-label={t(interfaceLanguage, "lessonModuleNavigation")}>
        <button type="button" className="secondary-button" onClick={() => onOpenModule(module.id)}>{t(interfaceLanguage, "lessonModuleOverview")}</button>
        <p className="eyebrow" lang={englishTextLang(interfaceLanguage)}>{module.title.en}</p>
        <ol>
          {(lessonsByModuleId.get(module.id) ?? []).map((moduleLesson) => (
            <li key={moduleLesson.id}>
              <button type="button" aria-current={moduleLesson.id === lesson.id ? "page" : undefined} onClick={() => onOpenLesson(module.id, moduleLesson.id)}><span lang={englishTextLang(interfaceLanguage)}>{moduleLesson.title.en}</span></button>
            </li>
          ))}
        </ol>
      </aside>
      <article className="lesson-article">
        <p className="eyebrow">{t(interfaceLanguage, "lessonMeta", lesson.id, lesson.estimatedMinutes, lesson.covers.join(", "))}</p>
        <h2 id="lesson-title" lang={englishTextLang(interfaceLanguage)}>{lesson.title.en}</h2>
        <p>{readRecord === undefined ? t(interfaceLanguage, "lessonNotMarkedYet") : t(interfaceLanguage, "lessonMarkedReadTimes", readRecord.readCount)}</p>
        {lesson.status === "outline" ? (
          <section className="coming-soon" aria-labelledby="coming-soon-title">
            <h3 id="coming-soon-title">{t(interfaceLanguage, "lessonComingSoonTitle")}</h3>
            <p>{t(interfaceLanguage, "lessonComingSoonCopy")}</p>
            <h4>{t(interfaceLanguage, "lessonObjectives")}</h4>
            {interfaceLanguage === "fr" ? <p className="reference-note">{t(interfaceLanguage, "englishOnlyContentNotice")}</p> : null}
            <ul>{lesson.objectives.map((objective) => <li key={objective} lang={englishTextLang(interfaceLanguage)}>{objective}</li>)}</ul>
            <h4>{t(interfaceLanguage, "lessonCoveredSubsections")}</h4>
            <ul>{lesson.covers.map((cover) => <li key={cover}>{cover}{colonSeparator(interfaceLanguage)}<span lang={englishTextLang(interfaceLanguage)}>{subsectionTitle(cover)}</span></li>)}</ul>
          </section>
        ) : (
          <>
            {interfaceLanguage === "fr" ? <p className="reference-note">{t(interfaceLanguage, "englishOnlyLessonNotice")}</p> : null}
            <div lang={englishTextLang(interfaceLanguage)}>
              <MarkdownContent interfaceLanguage={interfaceLanguage} markdown={lesson.body} title={lesson.title.en} />
            </div>
          </>
        )}
        <div className="action-row lesson-actions">
          <button type="button" onClick={() => onLessonRead(lesson)}>{t(interfaceLanguage, "lessonMarkRead")}</button>
          {neighbors.previous !== null ? <button type="button" className="secondary-button" onClick={() => onOpenLesson(neighbors.previous!.moduleId, neighbors.previous!.id)}>{interfaceLanguage === "fr" ? <>Précédente : <span lang="en">{neighbors.previous.title.en}</span></> : t(interfaceLanguage, "lessonPrevious", neighbors.previous.title.en)}</button> : null}
          {neighbors.next !== null ? <button type="button" className="secondary-button" onClick={() => onOpenLesson(neighbors.next!.moduleId, neighbors.next!.id)}>{interfaceLanguage === "fr" ? <>Suivante : <span lang="en">{neighbors.next.title.en}</span></> : t(interfaceLanguage, "lessonNext", neighbors.next.title.en)}</button> : null}
        </div>
        {lesson.quizIds.map((quizId) => {
          const quiz = lessonQuizzesById.get(quizId);
          return quiz === undefined ? (
            <p className="reference-note" key={quizId}>{t(interfaceLanguage, "lessonQuizComingSoon", quizId)}</p>
          ) : (
            <LessonQuizView
              attempts={lessonAttempts.filter((attempt) => attempt.quizId === quiz.id)}
              bankQuestionsById={bankQuestionsById}
              key={quiz.id}
              interfaceLanguage={interfaceLanguage}
              language={language}
              lesson={lesson}
              now={now}
              onQuizAttempt={onQuizAttempt}
              progress={progress}
              quiz={quiz}
            />
          );
        })}
      </article>
    </section>
  );
}

function LessonQuizView({ quiz, lesson, interfaceLanguage, language, bankQuestionsById, progress, attempts, now, onQuizAttempt }: { readonly quiz: LessonQuiz; readonly lesson: LessonMeta; readonly interfaceLanguage: InterfaceLanguage; readonly language: Language; readonly bankQuestionsById: ReadonlyMap<string, Question>; readonly progress: readonly QuestionProgressRecord[]; readonly attempts: readonly LessonQuizAttempt[]; readonly now: () => string; readonly onQuizAttempt: (attempt: LessonQuizAttempt, nextProgress: readonly QuestionProgressRecord[]) => void }) {
  const [seed, setSeed] = useState(() => `${quiz.id}:${Date.now().toString(36)}`);
  const [items, setItems] = useState(() => buildLessonQuizItems(quiz, seed));
  const [currentIndex, setCurrentIndex] = useState(0);
  const [selectedByItemId, setSelectedByItemId] = useState<ReadonlyMap<string, number>>(() => new Map());
  const [submittedAttemptId, setSubmittedAttemptId] = useState<string | null>(null);
  const currentItem = items[currentIndex];
  const allAnswered = items.every((item) => selectedByItemId.has(item.id));
  const latestAttempt = attempts[attempts.length - 1];

  function restart(): void {
    const nextSeed = `${quiz.id}:${Date.now().toString(36)}:${attempts.length + 1}`;
    setSeed(nextSeed);
    setItems(buildLessonQuizItems(quiz, nextSeed));
    setCurrentIndex(0);
    setSelectedByItemId(new Map());
    setSubmittedAttemptId(null);
  }

  function selectCurrent(displayIndex: number): void {
    if (currentItem === undefined || submittedAttemptId !== null || selectedByItemId.has(currentItem.id)) {
      return;
    }
    const selected = new Map(selectedByItemId);
    selected.set(currentItem.id, currentItem.choicePermutation[displayIndex]!);
    setSelectedByItemId(selected);
  }

  function submitQuiz(): void {
    let correct = 0;
    let nextProgress = progress;
    const officialQuestionIds: string[] = [];
    const incorrectOfficialQuestionIds: string[] = [];
    const incorrectConceptCheckIds: string[] = [];
    const submittedAt = now();
    for (const item of items) {
      const selected = selectedByItemId.get(item.id);
      if (item.type === "official") {
        officialQuestionIds.push(item.questionId);
        if (selected === 0) {
          correct += 1;
        } else {
          incorrectOfficialQuestionIds.push(item.questionId);
        }
        if (selected !== undefined) {
          nextProgress = applyPracticeAnswer(nextProgress, item.questionId, selected, submittedAt);
        }
      } else {
        const isCorrect = selected !== undefined && item.conceptCheck.choices[selected]?.isCorrect === true;
        if (isCorrect) {
          correct += 1;
        } else {
          incorrectConceptCheckIds.push(item.conceptCheck.id);
        }
      }
    }
    const attempt: LessonQuizAttempt = {
      id: `lesson-quiz-${submittedAt}-${quiz.id}-${seed}`,
      quizId: quiz.id,
      lessonId: lesson.id,
      submittedAt,
      correct,
      total: items.length,
      percent: items.length === 0 ? 0 : (correct / items.length) * 100,
      officialQuestionIds,
      incorrectOfficialQuestionIds,
      incorrectConceptCheckIds,
    };
    setSubmittedAttemptId(attempt.id);
    onQuizAttempt(attempt, nextProgress);
  }

  return (
    <section className="lesson-quiz" aria-labelledby={`${quiz.id}-title`}>
      <div className="lesson-quiz__header">
        <div>
          <p className="eyebrow">{t(interfaceLanguage, "lessonQuizEyebrow")}</p>
          <h3 id={`${quiz.id}-title`}>{quiz.id}</h3>
          <p>{t(interfaceLanguage, "lessonQuizSummary", items.length)}</p>
          {latestAttempt !== undefined ? <p>{t(interfaceLanguage, "lessonQuizLatestScore", latestAttempt.correct, latestAttempt.total, latestAttempt.percent.toFixed(0), attempts.length)}</p> : null}
        </div>
        <button type="button" className="secondary-button" onClick={restart}>{t(interfaceLanguage, "lessonQuizRetry")}</button>
      </div>
      {currentItem === undefined ? <p>{t(interfaceLanguage, "lessonQuizNoItems")}</p> : (
        <>
          <p>{t(interfaceLanguage, "questionProgress", currentIndex + 1, items.length)}</p>
          <LessonQuizQuestion interfaceLanguage={interfaceLanguage} item={currentItem} language={language} questionsById={bankQuestionsById} selectedSourceOrChoiceIndex={selectedByItemId.get(currentItem.id)} showCorrectness={selectedByItemId.has(currentItem.id)} onChoose={selectCurrent} />
          <div className="action-row">
            <button type="button" disabled={currentIndex === 0} onClick={() => setCurrentIndex(currentIndex - 1)}>{t(interfaceLanguage, "previous")}</button>
            <button type="button" disabled={currentIndex >= items.length - 1} onClick={() => setCurrentIndex(currentIndex + 1)}>{t(interfaceLanguage, "next")}</button>
            <button type="button" className="primary-button" disabled={!allAnswered || submittedAttemptId !== null} onClick={submitQuiz}>{t(interfaceLanguage, "lessonQuizSubmit")}</button>
          </div>
        </>
      )}
    </section>
  );
}

function useFocusOnAnswerChosen(answerableId: string, showCorrectness: boolean, feedbackRef: RefObject<HTMLElement | null>): void {
  const previous = useRef({ answerableId, showCorrectness });
  useEffect(() => {
    const answerWasJustChosen = previous.current.answerableId === answerableId && !previous.current.showCorrectness && showCorrectness;
    previous.current = { answerableId, showCorrectness };
    if (answerWasJustChosen) {
      feedbackRef.current?.focus();
    }
  }, [answerableId, showCorrectness, feedbackRef]);
}

function LessonQuizQuestion({ item, interfaceLanguage, language, questionsById, selectedSourceOrChoiceIndex, showCorrectness, onChoose }: { readonly item: LessonQuizItem; readonly interfaceLanguage: InterfaceLanguage; readonly language: Language; readonly questionsById: ReadonlyMap<string, Question>; readonly selectedSourceOrChoiceIndex: number | undefined; readonly showCorrectness: boolean; readonly onChoose: (displayIndex: number) => void }) {
  const feedbackRef = useRef<HTMLParagraphElement>(null);
  useFocusOnAnswerChosen(item.id, showCorrectness, feedbackRef);

  if (item.type === "official") {
    const question = questionsById.get(item.questionId);
    if (question === undefined) {
      return <p role="status">{t(interfaceLanguage, "officialQuestionLoading", item.questionId)}</p>;
    }
    return (
      <>
        <QuestionCard choicePermutation={item.choicePermutation} disabled={showCorrectness} headingLevel={4} interfaceLanguage={interfaceLanguage} language={language} onChoose={onChoose} question={question} selectedSourceIndex={selectedSourceOrChoiceIndex} showCorrectness={showCorrectness} />
        {showCorrectness ? (
          <div className="feedback">
            <p role="status" ref={feedbackRef} tabIndex={-1}>{selectedSourceOrChoiceIndex === 0 ? t(interfaceLanguage, "feedbackCorrectSentence") : t(interfaceLanguage, "feedbackIncorrectSentence")}</p>
            <ExplanationPanel explanation={explanationForQuestion(question.id)} interfaceLanguage={interfaceLanguage} language={language} choicePermutation={item.choicePermutation} />
          </div>
        ) : null}
      </>
    );
  }
  return <ConceptCheckCard conceptCheck={item.conceptCheck} choicePermutation={item.choicePermutation} disabled={showCorrectness} interfaceLanguage={interfaceLanguage} language={language} selectedChoiceIndex={selectedSourceOrChoiceIndex} showCorrectness={showCorrectness} onChoose={onChoose} />;
}

function ConceptCheckCard({ conceptCheck, choicePermutation, selectedChoiceIndex, showCorrectness, disabled, interfaceLanguage, language, onChoose }: { readonly conceptCheck: ConceptCheck; readonly choicePermutation: readonly number[]; readonly selectedChoiceIndex: number | undefined; readonly showCorrectness: boolean; readonly disabled: boolean; readonly interfaceLanguage: InterfaceLanguage; readonly language: Language; readonly onChoose: (displayIndex: number) => void }) {
  const feedbackRef = useRef<HTMLParagraphElement>(null);
  useFocusOnAnswerChosen(conceptCheck.id, showCorrectness, feedbackRef);
  const selectedChoice = selectedChoiceIndex === undefined ? undefined : conceptCheck.choices[selectedChoiceIndex];
  const prompt = conceptCheck.prompt[language] ?? conceptCheck.prompt.en;
  const promptLanguage = conceptCheck.prompt[language] === null ? "en" : language;
  return (
    <article className="question-panel" aria-labelledby={`concept-${conceptCheck.id}`}>
      <p className="question-meta">{t(interfaceLanguage, "conceptCheckMeta", conceptCheck.id)}</p>
      <h4 id={`concept-${conceptCheck.id}`}>{t(interfaceLanguage, "questionHeading")}</h4>
      <p className="question-text" lang={languageTag(promptLanguage)}>{prompt}</p>
      <div className="answers" role="group" aria-label={t(interfaceLanguage, "answerChoices")}>
        {choicePermutation.map((choiceIndex, displayIndex) => {
          const choice = conceptCheck.choices[choiceIndex]!;
          const selected = selectedChoiceIndex === choiceIndex;
          const correct = choice.isCorrect;
          const className = ["answer-button", showCorrectness && correct ? "is-correct" : "", showCorrectness && selected && !correct ? "is-incorrect" : ""].filter(Boolean).join(" ");
          return (
            <button aria-pressed={selected} className={className} data-testid="lesson-quiz-choice" disabled={disabled} key={choice.text.en} type="button" onClick={() => onChoose(displayIndex)}>
              <span className="answer-label">{String.fromCharCode(65 + displayIndex)}</span>
              <span lang={languageTag(choice.text[language] === null ? "en" : language)}>{choice.text[language] ?? choice.text.en}</span>
              {showCorrectness && correct ? <strong>{t(interfaceLanguage, "correctAnswer")}</strong> : null}
              {showCorrectness && selected && !correct ? <strong>{t(interfaceLanguage, "yourAnswer")}</strong> : null}
            </button>
          );
        })}
      </div>
      {showCorrectness ? (
        <div className="feedback">
          <p role="status" ref={feedbackRef} tabIndex={-1}>{selectedChoice?.isCorrect ? t(interfaceLanguage, "feedbackCorrectSentence") : t(interfaceLanguage, "feedbackIncorrectSentence")}</p>
          <p lang={languageTag(conceptCheck.explanation[language] === null ? "en" : language)}>{conceptCheck.explanation[language] ?? conceptCheck.explanation.en}</p>
        </div>
      ) : null}
    </article>
  );
}

interface PracticeProps {
  readonly interfaceLanguage: InterfaceLanguage;
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
  readonly onSetPreferences: (preferences: PreferencesPatch) => Promise<boolean>;
}

function Practice({
  interfaceLanguage,
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
    if (hasUnsubmittedReviewAnswers(session) && !window.confirm(t(interfaceLanguage, "practiceDiscardConfirm"))) {
      return;
    }
    const nextScope = scopeFromControls(scopeKind, categoryId, subsectionId);
    void onSetPreferences({ practiceMode: nextMode }).catch(() => {
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
      <h2 id="practice-title">{t(interfaceLanguage, "practiceTitle")}</h2>
      <div className="practice-topline">
        <label>
          {t(interfaceLanguage, "practiceScope")}
          <select value={scopeKind} onChange={(event) => setScopeKind(event.currentTarget.value)}>
            <option value="all">{t(interfaceLanguage, "practiceScopeAll")}</option>
            <option value="category">{t(interfaceLanguage, "practiceScopeCategory")}</option>
            <option value="subsection">{t(interfaceLanguage, "practiceScopeSubsection")}</option>
            <option value="weak">{t(interfaceLanguage, "practiceScopeWeak")}</option>
            <option value="due">{t(interfaceLanguage, "practiceScopeDue")}</option>
          </select>
        </label>
        {scopeKind === "category" ? (
          <label>
            {t(interfaceLanguage, "category")}
            <select value={categoryId} onChange={(event) => setCategoryId(event.currentTarget.value)}>
              {categories.map((category) => {
                const name = localizedCategoryNameWithLanguage(category, interfaceLanguage);
                return <option key={category.id} lang={languageTag(name.language)} value={category.id}>{name.text}</option>;
              })}
            </select>
          </label>
        ) : null}
        {scopeKind === "subsection" ? (
          <label>
            {t(interfaceLanguage, "subsection")}
            <select value={subsectionId} onChange={(event) => setSubsectionId(event.currentTarget.value)}>
              {subsectionTitles.map((subsection) => <option key={subsection.id} lang={englishTextLang(interfaceLanguage)} value={subsection.id}>{subsection.id}{colonSeparator(interfaceLanguage)}{subsection.title.en}</option>)}
            </select>
          </label>
        ) : null}
        <fieldset className="segmented-control">
          <legend>{t(interfaceLanguage, "feedbackMode")}</legend>
          <label><input type="radio" name="practice-mode" checked={preferences.practiceMode === "immediate"} onChange={() => restartWithControls("immediate")} /> {t(interfaceLanguage, "feedbackImmediate")}</label>
          <label><input type="radio" name="practice-mode" checked={preferences.practiceMode === "review-later"} onChange={() => restartWithControls("review-later")} /> {t(interfaceLanguage, "feedbackReviewLater")}</label>
        </fieldset>
        <button type="button" className="primary-button" onClick={() => restartWithControls()}>{t(interfaceLanguage, "practiceStartSet")}</button>
      </div>

      {session === null || currentItem === undefined ? (
        <div className="empty-state" role="status">
          <p>{t(interfaceLanguage, "practiceEmpty")}</p>
        </div>
      ) : (
        <div className="practice-layout">
          <aside className="session-outline" aria-label={t(interfaceLanguage, "practiceSessionOutline")}>
            <div className="session-summary" aria-label={t(interfaceLanguage, "practiceSessionProgress")}>
              <span>{t(interfaceLanguage, "questionProgress", session.currentIndex + 1, session.items.length)}</span>
              <span>{t(interfaceLanguage, "scopePrefix")} <ScopeValue interfaceLanguage={interfaceLanguage} scope={session.scope} /></span>
              <span>{t(interfaceLanguage, "modePrefix")} {session.mode === "immediate" ? t(interfaceLanguage, "feedbackImmediate") : t(interfaceLanguage, "feedbackReviewLater")}</span>
              <span>{t(interfaceLanguage, "seedPrefix")} {session.seed}</span>
            </div>
            <p>{t(interfaceLanguage, "answeredCount", session.selectedByQuestionId.size, session.items.length)}</p>
            <p>{t(interfaceLanguage, "currentSubsection")} <strong>{currentItem.question.subsectionId}</strong></p>
          </aside>
          <div className="practice-main">
            <QuestionCard
              choicePermutation={currentItem.choicePermutation}
              disabled={session.mode === "immediate" && isAnswered}
              interfaceLanguage={interfaceLanguage}
              language={language}
              onChoose={(displayIndex) => void chooseAnswer(currentItem, displayIndex)}
              question={currentItem.question}
              selectedSourceIndex={selectedSourceIndex}
              showCorrectness={session.mode === "immediate" && isAnswered}
            />
            <div className="feedback" role="status" aria-live="polite" ref={feedbackRef} tabIndex={-1}>
              {session.mode === "immediate" ? immediateFeedback(interfaceLanguage, currentItem.question, currentItem.choicePermutation, selectedSourceIndex, language) : (
                <p>{t(interfaceLanguage, "practiceReviewLaterHint")}</p>
              )}
            </div>
            <div className="action-row">
              <button type="button" disabled={session.currentIndex === 0} onClick={() => onSessionChange({ ...session, currentIndex: session.currentIndex - 1 })}>{t(interfaceLanguage, "previous")}</button>
              <button type="button" disabled={session.currentIndex >= session.items.length - 1} onClick={() => onSessionChange({ ...session, currentIndex: session.currentIndex + 1 })}>{t(interfaceLanguage, "next")}</button>
              {session.mode === "review-later" ? (
                <button type="button" className="primary-button" disabled={!allAnswered || session.submitted || submittingPractice} onClick={() => void submitReviewLater()}>{submittingPractice ? t(interfaceLanguage, "practiceSubmittingSet") : t(interfaceLanguage, "practiceSubmitSet")}</button>
              ) : null}
            </div>
            {session.submitted ? <div ref={reviewRef} tabIndex={-1}><PracticeReview interfaceLanguage={interfaceLanguage} session={session} language={language} /></div> : null}
          </div>
        </div>
      )}
    </section>
  );
}

interface QuestionCardProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly question: Question;
  readonly choicePermutation: readonly number[];
  readonly selectedSourceIndex: number | undefined;
  readonly showCorrectness: boolean;
  readonly disabled: boolean;
  readonly language: Language;
  readonly onChoose: (displayIndex: number) => void;
  readonly headingLevel?: 3 | 4;
}

function QuestionCard({ interfaceLanguage, question, choicePermutation, selectedSourceIndex, showCorrectness, disabled, language, onChoose, headingLevel = 3 }: QuestionCardProps) {
  const HeadingTag = `h${headingLevel}` as "h3" | "h4";
  return (
    <article className="question-panel" aria-labelledby={`question-${question.id}`}>
      <p className="question-meta">{question.id} · {question.categoryId} · <span lang={englishTextLang(interfaceLanguage)}>{subsectionTitle(question.subsectionId)}</span></p>
      <HeadingTag id={`question-${question.id}`}>{t(interfaceLanguage, "questionHeading")}</HeadingTag>
      <p className="question-text" lang={languageTag(language)}>{question.text[language]}</p>
      <div className="answers" role="group" aria-label={t(interfaceLanguage, "answerChoices")}>
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
              {showCorrectness && correct ? <strong>{t(interfaceLanguage, "correctAnswer")}</strong> : null}
              {showCorrectness && selected && !correct ? <strong>{t(interfaceLanguage, "yourAnswer")}</strong> : null}
            </button>
          );
        })}
      </div>
    </article>
  );
}

function PracticeReview({ interfaceLanguage, session, language }: { readonly interfaceLanguage: InterfaceLanguage; readonly session: PracticeSession; readonly language: Language }) {
  return (
    <section className="review-panel" aria-labelledby="practice-review-title">
      <h3 id="practice-review-title">{t(interfaceLanguage, "practiceSetReview")}</h3>
      <ol>
        {session.items.map((item) => {
          const selected = session.selectedByQuestionId.get(item.question.id);
          const correctAnswer = item.question.answers.find((answer) => answer.sourceIndex === 0)!;
          const selectedAnswer = item.question.answers.find((answer) => answer.sourceIndex === selected);
          return (
            <li key={item.question.id}>
              <strong>{item.question.id}</strong> — {selected === 0 ? t(interfaceLanguage, "correct") : t(interfaceLanguage, "incorrect")}
              <p lang={languageTag(language)}>{item.question.text[language]}</p>
              <p>{t(interfaceLanguage, "yourAnswerPrefix")} <span lang={languageTag(language)}>{selectedAnswer?.text[language] ?? t(interfaceLanguage, "unanswered")}</span></p>
              <p>{t(interfaceLanguage, "correctAnswerPrefix")} <span lang={languageTag(language)}>{correctAnswer.text[language]}</span></p>
              <ExplanationPanel explanation={explanationForQuestion(item.question.id)} interfaceLanguage={interfaceLanguage} language={language} choicePermutation={item.choicePermutation} />
              <p>{item.question.categoryId}; <span lang={englishTextLang(interfaceLanguage)}>{subsectionTitle(item.question.subsectionId)}</span></p>
            </li>
          );
        })}
      </ol>
    </section>
  );
}

export function ExplanationPanel({ explanation, interfaceLanguage = "en", language, choicePermutation }: { readonly explanation: Explanation | null; readonly interfaceLanguage?: InterfaceLanguage; readonly language: Language; readonly choicePermutation?: readonly number[] }) {
  if (explanation === null) {
    return <p className="explanation-panel explanation-panel--missing">{t(interfaceLanguage, "noExplanation")}</p>;
  }
  const explanationLanguage: Language = explanation.body[language] === null ? "en" : language;
  const choiceNotes = parseChoiceNotes(explanation, language);
  return (
    <section className="explanation-panel" aria-label={t(interfaceLanguage, "explanationAria", explanation.questionId)}>
      <h4>{t(interfaceLanguage, "explanationTitle")}</h4>
      {interfaceLanguage === "fr" && explanation.body.fr === null ? <p className="reference-note">{t(interfaceLanguage, "englishOnlyExplanationNotice")}</p> : null}
      {mainExplanationText(explanation, language).split(/\n\n+/).map((paragraph) => <p key={paragraph} lang={languageTag(explanationLanguage)}>{paragraph}</p>)}
      {choiceNotes.length > 0 ? (
        <ul>
          {choiceNotes.map((note) => {
            const displayIndex = choicePermutation?.findIndex((sourceIndex) => sourceIndex === note.sourceIndex);
            const label = displayIndex === undefined || displayIndex < 0 ? t(interfaceLanguage, "sourceIndex", note.sourceIndex) : t(interfaceLanguage, "displayedChoice", String.fromCharCode(65 + displayIndex));
            return <li key={note.sourceIndex} lang={languageTag(explanationLanguage)}><strong>{label}{interfaceLanguage === "fr" ? " :" : ":"}</strong> {note.note}</li>;
          })}
        </ul>
      ) : null}
      {explanation.citations.length > 0 ? (
        <p className="question-meta">{t(interfaceLanguage, "citationsPrefix")} {explanation.citations.map((citation, index) => <CitationLink citation={citation} interfaceLanguage={interfaceLanguage} key={`${citation.type}-${citation.id ?? index}`} />).reduce<ReactNode[]>((nodes, element, index) => index === 0 ? [element] : [...nodes, ", ", element], [])}</p>
      ) : null}
    </section>
  );
}

function isHttpsUrl(rawUrl: string): boolean {
  try {
    return new URL(rawUrl).protocol === "https:";
  } catch {
    return false;
  }
}

export function CitationLink({ citation, interfaceLanguage = "en" }: { readonly citation: Explanation["citations"][number]; readonly interfaceLanguage?: InterfaceLanguage }) {
  if (citation.type === "lesson" && citation.id !== undefined) {
    const lesson = lessonsById.get(citation.id);
    if (lesson !== undefined) {
      return <a href={`#/learn/${lesson.moduleId}/${lesson.id}`}>{citation.id}</a>;
    }
  }
  if (citation.url !== undefined && isHttpsUrl(citation.url)) {
    return (
      <a href={citation.url} target="_blank" rel="noopener noreferrer">
        {citation.id ?? citation.type} <span className="external-site-hint">{t(interfaceLanguage, "externalSiteHint")}</span> <span className="new-tab-hint">{t(interfaceLanguage, "newTabHint")}</span>
      </a>
    );
  }
  return <>{citation.id ?? citation.type}</>;
}

interface MockExamProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly exam: MockExamSession | null;
  readonly language: Language;
  readonly questions: readonly Question[] | null;
  readonly preferences: WebPreferences;
  readonly now: () => string;
  readonly seedFactory: () => string;
  readonly onExamChange: (exam: MockExamSession | null) => void;
  readonly onSubmitExam: (attempt: ExamAttempt) => Promise<void>;
}

function MockExam({ interfaceLanguage, exam, language, questions, preferences, now, seedFactory, onExamChange, onSubmitExam }: MockExamProps) {
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
          setTimerAnnouncement(t(interfaceLanguage, "mockTimerMilestone", Math.floor(nextSecondsElapsed / 60)));
        }
        onExamChange({ ...exam, secondsElapsed: nextSecondsElapsed });
      }, 1000);
      return () => window.clearInterval(id);
    }
    return undefined;
  }, [exam, interfaceLanguage, onExamChange]);

  useEffect(() => {
    if (exam?.confirmingSubmit) {
      confirmRef.current?.focus();
    }
  }, [exam?.confirmingSubmit]);

  function startExam(): void {
    if (questions === null) {
      setTimerAnnouncement(t(interfaceLanguage, "mockQuestionBankLoading"));
      return;
    }
    const selectedSeed = seed.trim() || seedFactory();
    setSubmittingExam(false);
    setTimerAnnouncement(timerEnabled ? t(interfaceLanguage, "mockTimerStarted") : "");
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
        <h2 id="mock-title">{t(interfaceLanguage, "mockTitle")}</h2>
        <p>{t(interfaceLanguage, "mockIntro")}</p>
        <label>
          {t(interfaceLanguage, "seedOptional")}
          <input value={seed} onChange={(event) => setSeed(event.currentTarget.value)} placeholder={t(interfaceLanguage, "seedPlaceholder")} />
        </label>
        <label><input type="checkbox" checked={timerEnabled} onChange={(event) => setTimerEnabled(event.currentTarget.checked)} /> {t(interfaceLanguage, "timerEnable")}</label>
        <p id="timer-note">{t(interfaceLanguage, "timerNote")}</p>
        <p className="reference-note">{t(interfaceLanguage, "referenceSheetNote")}</p>
        <button type="button" className="primary-button" disabled={questions === null} onClick={startExam}>{questions === null ? t(interfaceLanguage, "loadingQuestionBank") : t(interfaceLanguage, "startMockExam")}</button>
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

  function jumpToQuestionMap(): void {
    const navigator = document.getElementById("question-map");
    if (navigator === null) {
      return;
    }
    const prefersReducedMotion = typeof window.matchMedia === "function" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    navigator.focus();
    navigator.scrollIntoView({ block: "start", behavior: prefersReducedMotion ? "auto" : "smooth" });
  }

  return (
    <section className="card mock-exam mock-exam--running" aria-labelledby="mock-title">
      <h2 id="mock-title">{t(interfaceLanguage, "mockTitle")}</h2>
      <div className="session-summary" aria-label={t(interfaceLanguage, "mockProgressAria")}>
        <span>{t(interfaceLanguage, "questionProgress", exam.currentIndex + 1, exam.generatedItems.length)}</span>
        <span>{t(interfaceLanguage, "seedWithColon", exam.seed)}</span>
        <span>{t(interfaceLanguage, "answeredCount", exam.selectedByQuestionId.size, exam.generatedItems.length)}</span>
      </div>
      {exam.timerEnabled ? (
        <div className="timer-panel">
          <span role="timer" aria-live="off" aria-label={t(interfaceLanguage, "timerElapsedAria", formatElapsedForSpeech(interfaceLanguage, exam.secondsElapsed))}>{t(interfaceLanguage, "timerElapsed", formatElapsed(exam.secondsElapsed))}</span>
          <button
            type="button"
            onClick={() => {
              const nextRunning = !exam.timerRunning;
              setTimerAnnouncement(nextRunning ? t(interfaceLanguage, "timerResumed") : t(interfaceLanguage, "timerPaused"));
              onExamChange({ ...exam, timerRunning: nextRunning });
            }}
          >{exam.timerRunning ? t(interfaceLanguage, "pauseTimer") : t(interfaceLanguage, "resumeTimer")}</button>
          <span className="sr-only" role="status" aria-live="polite">{timerAnnouncement}</span>
        </div>
      ) : <p className="timer-off-note">{t(interfaceLanguage, "timerOff")}</p>}
      <button className="secondary-button question-map-link" type="button" onClick={jumpToQuestionMap}>{t(interfaceLanguage, "jumpQuestionMap")}</button>
      <QuestionCard
        choicePermutation={item.choicePermutation}
        disabled={false}
        interfaceLanguage={interfaceLanguage}
        language={language}
        onChoose={choose}
        question={question}
        selectedSourceIndex={selectedSourceIndex}
        showCorrectness={false}
      />
      <div className="action-row">
        <button type="button" onClick={toggleFlag}>{exam.flaggedQuestionIds.has(question.id) ? t(interfaceLanguage, "removeFlag") : t(interfaceLanguage, "flagForReview")}</button>
        <button type="button" disabled={exam.currentIndex === 0} onClick={() => onExamChange({ ...exam, currentIndex: exam.currentIndex - 1 })}>{t(interfaceLanguage, "previous")}</button>
        <button type="button" disabled={exam.currentIndex >= exam.generatedItems.length - 1} onClick={() => onExamChange({ ...exam, currentIndex: exam.currentIndex + 1 })}>{t(interfaceLanguage, "next")}</button>
        <button type="button" ref={submitButtonRef} onClick={() => onExamChange({ ...exam, confirmingSubmit: true })}>{t(interfaceLanguage, "submitExam")}</button>
      </div>
      <nav id="question-map" className="question-navigator" aria-label={t(interfaceLanguage, "questionNavigator")} tabIndex={-1}>
        {exam.generatedItems.map((candidate, index) => {
          const answered = exam.selectedByQuestionId.has(candidate.questionId);
          const flagged = exam.flaggedQuestionIds.has(candidate.questionId);
          return (
            <button
              className={index === exam.currentIndex ? "current" : ""}
              key={candidate.questionId}
              type="button"
              aria-current={index === exam.currentIndex ? "step" : undefined}
              aria-label={t(interfaceLanguage, "questionNavigatorLabel", index + 1, index === exam.currentIndex, answered, flagged)}
              onClick={() => onExamChange({ ...exam, currentIndex: index })}
            >
              {index === exam.currentIndex ? <span aria-hidden="true">● </span> : null}{index + 1}{flagged ? " ⚑" : ""}{answered ? " ✓" : ""}
            </button>
          );
        })}
      </nav>
      {exam.confirmingSubmit ? (
        <section className="confirm-panel" aria-labelledby="submit-confirm-title" role="alertdialog" aria-modal="false" ref={confirmRef} tabIndex={-1}>
          <h3 id="submit-confirm-title">{t(interfaceLanguage, "submitMockTitle")}</h3>
          <p>{unanswered.length === 0 ? t(interfaceLanguage, "allQuestionsAnswered") : t(interfaceLanguage, "unansweredScoredIncorrect", unanswered.length)}</p>
          {unanswered.length > 0 ? (
            <details open>
              <summary>{t(interfaceLanguage, "unansweredQuestions")}</summary>
              <ol>{unanswered.map((candidate) => <li key={candidate.questionId}>{t(interfaceLanguage, "questionNumberWithId", candidate.position, candidate.questionId)}</li>)}</ol>
            </details>
          ) : null}
          <div className="action-row">
            <button type="button" onClick={() => { onExamChange({ ...exam, confirmingSubmit: false }); window.setTimeout(() => submitButtonRef.current?.focus(), 0); }}>{t(interfaceLanguage, "continueExam")}</button>
            <button type="button" className="danger" disabled={submittingExam} onClick={() => void confirmSubmit()}>{submittingExam ? t(interfaceLanguage, "submittingExam") : t(interfaceLanguage, "confirmSubmit")}</button>
          </div>
        </section>
      ) : null}
    </section>
  );
}

function Results({ attempt, interfaceLanguage, language, onStartPractice, questionsById }: { readonly attempt: ExamAttempt | null; readonly interfaceLanguage: InterfaceLanguage; readonly language: Language; readonly onStartPractice: (scope: PracticeScope) => void; readonly questionsById: ReadonlyMap<string, Question> }) {
  if (attempt === null) {
    return (
      <section className="card results" aria-labelledby="results-title">
        <h2 id="results-title">{t(interfaceLanguage, "resultsTitle")}</h2>
        <p>{t(interfaceLanguage, "noMockResult")}</p>
      </section>
    );
  }
  const wrongItems = attempt.items.filter((item) => !item.isCorrect);
  return (
    <section className="card results" aria-labelledby="results-title">
      <h2 id="results-title">{t(interfaceLanguage, "mockResultsTitle")}</h2>
      <p><strong>{attempt.score.correct} / {attempt.score.total}</strong> ({attempt.score.percent.toFixed(0)}{interfaceLanguage === "fr" ? " %" : "%"})</p>
      <p>{attempt.score.honours ? t(interfaceLanguage, "resultHonours") : attempt.score.passed ? t(interfaceLanguage, "resultPass") : t(interfaceLanguage, "resultBelowPass")}</p>
      <p>{t(interfaceLanguage, "passThresholdCopy")}</p>
      <h3>{t(interfaceLanguage, "categoryBreakdown")}</h3>
      <ul>
        {attempt.score.categoryBreakdown.map((entry) => (
          <li key={entry.categoryId}><CategoryNameText categoryId={entry.categoryId} interfaceLanguage={interfaceLanguage} />{colonSeparator(interfaceLanguage)}{entry.correct}/{entry.total} ({entry.percent.toFixed(0)}{interfaceLanguage === "fr" ? " %" : "%"})</li>
        ))}
      </ul>
      <button type="button" onClick={() => onStartPractice({ type: "weak" })}>{t(interfaceLanguage, "readinessPracticeWeak")}</button>
      <section className="review-panel" aria-labelledby="wrong-review-title">
        <h3 id="wrong-review-title">{t(interfaceLanguage, "reviewWrongAnswers")}</h3>
        {wrongItems.length === 0 ? <p>{t(interfaceLanguage, "noWrongAnswers")}</p> : (
          <ol>
            {wrongItems.map((item) => {
              const question = questionsById.get(item.questionId);
              const selected = question?.answers.find((answer) => answer.sourceIndex === item.selectedSourceIndex);
              const correct = question?.answers.find((answer) => answer.sourceIndex === 0);
              return (
                <li key={item.questionId}>
                  <strong>{item.questionId}</strong>
                  {question === undefined ? (
                    <p>{t(interfaceLanguage, "questionTextLoading")}</p>
                  ) : (
                    <>
                      <p lang={languageTag(language)}>{question.text[language]}</p>
                      <p>{t(interfaceLanguage, "yourAnswerPrefix")} <span lang={languageTag(language)}>{selected?.text[language] ?? t(interfaceLanguage, "unanswered")}</span></p>
                      <p>{t(interfaceLanguage, "correctAnswerPrefix")} <span lang={languageTag(language)}>{correct?.text[language] ?? t(interfaceLanguage, "loading")}</span></p>
                      <ExplanationPanel explanation={explanationForQuestion(question.id)} interfaceLanguage={interfaceLanguage} language={language} choicePermutation={item.choicePermutation} />
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

const rbr4CitationUrl = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service";

function About({ interfaceLanguage }: { readonly interfaceLanguage: InterfaceLanguage }) {
  const legalLang = englishTextLang(interfaceLanguage);

  return (
    <section className="card about" aria-labelledby="about-title">
      <p className="eyebrow">{t(interfaceLanguage, "navAbout")}</p>
      <h2 id="about-title">{t(interfaceLanguage, "aboutTitle")}</h2>
      <p>{t(interfaceLanguage, "aboutIntro")}</p>

      <section aria-labelledby="about-bank-heading">
        <h3 id="about-bank-heading">{t(interfaceLanguage, "aboutBankHeading")}</h3>
        <p>{t(interfaceLanguage, "aboutBankVersion", bankId, manifest.effectiveDate)}</p>
        <p>{t(interfaceLanguage, "aboutQuestionBankCounts", manifest.counts.questions, manifest.counts.categories, manifest.counts.subsections)}</p>
      </section>

      <section aria-labelledby="about-sources-heading">
        <h3 id="about-sources-heading">{t(interfaceLanguage, "aboutSourcesHeading")}</h3>
        <ul>
          <li>{t(interfaceLanguage, "aboutQuestionBankSource", manifest.effectiveDate, manifest.source.url)}</li>
          <li>{t(interfaceLanguage, "aboutRbr4Source", rbr4CitationUrl)}</li>
          <li>{t(interfaceLanguage, "aboutReferenceSheetSource")}</li>
        </ul>
      </section>

      <section aria-labelledby="about-attribution-heading">
        <h3 id="about-attribution-heading">{t(interfaceLanguage, "aboutAttributionHeading")}</h3>
        <p className="legal-status" lang={legalLang}>{t(interfaceLanguage, "aboutLegalStatus")}</p>
        <blockquote lang={legalLang}>
          <p>{t(interfaceLanguage, "aboutAttributionText")}</p>
        </blockquote>
      </section>

      <section aria-labelledby="about-disclaimer-heading">
        <h3 id="about-disclaimer-heading">{t(interfaceLanguage, "aboutDisclaimerHeading")}</h3>
        <p lang={legalLang}>{t(interfaceLanguage, "aboutDisclaimerText")}</p>
      </section>

      <section aria-labelledby="about-privacy-heading">
        <h3 id="about-privacy-heading">{t(interfaceLanguage, "aboutPrivacyHeading")}</h3>
        <p>{t(interfaceLanguage, "settingsPrivacyCopy")}</p>
      </section>
    </section>
  );
}

interface SettingsProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly store: ProgressStore;
  readonly now: () => string;
  readonly preferences: WebPreferences;
  readonly statusMessage: string;
  readonly onProgressImported: (data: ProgressExportV1) => void;
  readonly onReset: () => void;
  readonly onInterfaceLanguageChange: (language: InterfaceLanguage) => void;
  readonly onSetPreferences: (preferences: PreferencesPatch) => Promise<boolean>;
}

function Settings({ interfaceLanguage, store, now, preferences, statusMessage, onProgressImported, onReset, onInterfaceLanguageChange, onSetPreferences }: SettingsProps) {
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
      setMessage(t(interfaceLanguage, "exportPrepared"));
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorExport", formatError(error))]);
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
      setMessage(t(interfaceLanguage, "importValid", result.data.questionProgress.length, result.data.examAttempts.length, result.data.lessonProgress?.length ?? 0, result.data.lessonQuizAttempts?.length ?? 0));
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorImportJson", error instanceof Error ? error.message : String(error))]);
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
      setMessage(t(interfaceLanguage, "importComplete"));
      window.setTimeout(() => statusRef.current?.focus(), 0);
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorImport", formatError(error))]);
    }
  }

  async function resetAll(): Promise<void> {
    try {
      await store.resetAllData();
      onReset();
      setConfirmReset(false);
      setErrors([]);
      setMessage(t(interfaceLanguage, "resetComplete"));
      window.setTimeout(() => statusRef.current?.focus(), 0);
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorReset", formatError(error))]);
    }
  }

  async function chooseTheme(theme: WebPreferences["theme"]): Promise<void> {
    try {
      const savedLatestRequest = await onSetPreferences({ theme });
      if (!savedLatestRequest) {
        return;
      }
      setErrors([]);
      setMessage(t(interfaceLanguage, "themeSaved", theme === "system" ? t(interfaceLanguage, "themeSystem") : theme === "light" ? t(interfaceLanguage, "themeLight") : t(interfaceLanguage, "themeDark")));
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorThemeSave", formatError(error))]);
    }
  }

  function chooseInterfaceLanguage(language: InterfaceLanguage): void {
    try {
      onInterfaceLanguageChange(language);
      setErrors([]);
      setMessage(t(language, "interfaceLanguageSaved", language === "fr" ? t(language, "languageFrench") : t(language, "languageEnglish")));
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorInterfaceLanguageSave", formatError(error))]);
    }
  }

  return (
    <section className="card settings" aria-labelledby="settings-title">
      <h2 id="settings-title">{t(interfaceLanguage, "settingsTitle")}</h2>
      <p>{t(interfaceLanguage, "settingsPrivacyCopy")}</p>
      <p>{t(interfaceLanguage, "activeBank", bankId, manifest.effectiveDate)}</p>
      <fieldset className="segmented-control theme-toggle">
        <legend>{t(interfaceLanguage, "themeLegend")}</legend>
        <label><input type="radio" name="theme" checked={preferences.theme === "system"} onChange={() => void chooseTheme("system")} /> {t(interfaceLanguage, "themeSystem")}</label>
        <label><input type="radio" name="theme" checked={preferences.theme === "light"} onChange={() => void chooseTheme("light")} /> {t(interfaceLanguage, "themeLight")}</label>
        <label><input type="radio" name="theme" checked={preferences.theme === "dark"} onChange={() => void chooseTheme("dark")} /> {t(interfaceLanguage, "themeDark")}</label>
      </fieldset>
      <fieldset className="segmented-control interface-language-toggle">
        <legend>{t(interfaceLanguage, "languageInterfaceLegend")}</legend>
        <label><input type="radio" name="interface-language" checked={interfaceLanguage === "en"} onChange={() => chooseInterfaceLanguage("en")} /> <span lang={englishTextLang(interfaceLanguage)}>{t(interfaceLanguage, "languageEnglish")}</span></label>
        <label><input type="radio" name="interface-language" checked={interfaceLanguage === "fr"} onChange={() => chooseInterfaceLanguage("fr")} /> <span lang="fr">{t(interfaceLanguage, "languageFrench")}</span></label>
      </fieldset>
      <div className="action-row">
        <button type="button" onClick={() => void exportProgress()}>{t(interfaceLanguage, "exportProgress")}</button>
        <label className="file-control">
          {t(interfaceLanguage, "importProgress")}
          <input type="file" accept="application/json,.json" onChange={(event) => void handleImport(event.currentTarget.files?.[0])} />
        </label>
        <button type="button" className="danger" ref={resetButtonRef} onClick={() => setConfirmReset(true)}>{t(interfaceLanguage, "resetAllData")}</button>
      </div>
      {pendingImport !== null ? <button type="button" className="primary-button" onClick={() => void confirmImport()}>{t(interfaceLanguage, "confirmImport")}</button> : null}
      {confirmReset ? (
        <div className="confirm-panel" role="alertdialog" aria-labelledby="reset-title" aria-modal="false" ref={resetDialogRef} tabIndex={-1}>
          <h3 id="reset-title">{t(interfaceLanguage, "resetTitle")}</h3>
          <p>{t(interfaceLanguage, "resetCopy")}</p>
          <button type="button" onClick={() => { setConfirmReset(false); window.setTimeout(() => resetButtonRef.current?.focus(), 0); }}>{t(interfaceLanguage, "cancelReset")}</button>
          <button type="button" className="danger" onClick={() => void resetAll()}>{t(interfaceLanguage, "confirmResetAllData")}</button>
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
    reader.onerror = () => reject(reader.error ?? new Error(t(readStoredInterfaceLanguage(), "fileReadError")));
    reader.onload = () => resolve(String(reader.result ?? ""));
    reader.readAsText(file);
  });
}

function Footer({ interfaceLanguage }: { readonly interfaceLanguage: InterfaceLanguage }) {
  return (
    <footer className="site-footer">
      <p lang={englishTextLang(interfaceLanguage)}>{t(interfaceLanguage, "footerISED")}</p>
      <p lang={englishTextLang(interfaceLanguage)}>{t(interfaceLanguage, "footerIndependent")}</p>
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

function CategoryNameText({ categoryId, interfaceLanguage }: { readonly categoryId: string; readonly interfaceLanguage: InterfaceLanguage }) {
  const name = categoryNameWithLanguage(categoryId, interfaceLanguage);
  return <span lang={languageTag(name.language)}>{name.text}</span>;
}

function ScopeValue({ interfaceLanguage, scope }: { readonly interfaceLanguage: InterfaceLanguage; readonly scope: PracticeScope }) {
  if (scope.type === "category") {
    return <CategoryNameText categoryId={scope.categoryId} interfaceLanguage={interfaceLanguage} />;
  }
  if (scope.type === "subsection") {
    return <>{scope.subsectionId}{colonSeparator(interfaceLanguage)}<span lang={englishTextLang(interfaceLanguage)}>{subsectionTitle(scope.subsectionId)}</span></>;
  }
  if (scope.type === "weak") {
    return <>{t(interfaceLanguage, "practiceScopeWeak")}</>;
  }
  if (scope.type === "due") {
    return <>{t(interfaceLanguage, "practiceScopeDue")}</>;
  }
  return <>{t(interfaceLanguage, "practiceScopeAll")}</>;
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

function languageTag(language: Language): "en" | "fr-CA" {
  return language === "fr" ? "fr-CA" : "en";
}

function englishTextLang(interfaceLanguage: InterfaceLanguage): "en" | undefined {
  return interfaceLanguage === "fr" ? "en" : undefined;
}

function colonSeparator(interfaceLanguage: InterfaceLanguage): ": " | " : " {
  return interfaceLanguage === "fr" ? " : " : ": ";
}

function readinessLabel(interfaceLanguage: InterfaceLanguage, state: ReadinessResult["state"]): string {
  switch (state) {
    case "honours-ready": return t(interfaceLanguage, "readinessHonoursReady");
    case "pass-ready": return t(interfaceLanguage, "readinessPassReady");
    case "needs-review": return t(interfaceLanguage, "readinessNeedsReview");
    case "not-enough-data": return t(interfaceLanguage, "readinessNotEnoughData");
  }
}

function readinessCopy(interfaceLanguage: InterfaceLanguage, readiness: ReadinessResult): string {
  if (readiness.state === "honours-ready") {
    return t(interfaceLanguage, "readinessHonoursCopy");
  }
  if (readiness.state === "pass-ready") {
    return t(interfaceLanguage, "readinessPassCopy");
  }
  if (readiness.state === "not-enough-data") {
    return t(interfaceLanguage, "readinessNotEnoughCopy");
  }
  const reason = readiness.reasons[0];
  if (reason?.type === "due-review") {
    return t(interfaceLanguage, "readinessDueReviewCopy");
  }
  if (reason?.type === "weak-categories") {
    return t(interfaceLanguage, "readinessWeakCategoriesCopy");
  }
  return t(interfaceLanguage, "readinessRecentResultsCopy");
}

function immediateFeedback(interfaceLanguage: InterfaceLanguage, question: Question, choicePermutation: readonly number[], selectedSourceIndex: number | undefined, language: Language) {
  if (selectedSourceIndex === undefined) {
    return <p>{t(interfaceLanguage, "feedbackChooseAnswer")}</p>;
  }
  const correctAnswer = question.answers.find((answer) => answer.sourceIndex === 0)!;
  return (
    <>
      {selectedSourceIndex === 0 ? (
        <p>{t(interfaceLanguage, "feedbackCorrectWithAnswer")} <strong lang={languageTag(language)}>{correctAnswer.text[language]}</strong></p>
      ) : (
        <p>{t(interfaceLanguage, "feedbackIncorrectWithAnswer")} <strong lang={languageTag(language)}>{correctAnswer.text[language]}</strong></p>
      )}
      <ExplanationPanel explanation={explanationForQuestion(question.id)} interfaceLanguage={interfaceLanguage} language={language} choicePermutation={choicePermutation} />
    </>
  );
}

function formatElapsed(secondsElapsed: number): string {
  const minutes = Math.floor(secondsElapsed / 60).toString().padStart(2, "0");
  const seconds = (secondsElapsed % 60).toString().padStart(2, "0");
  return `${minutes}:${seconds}`;
}

function formatElapsedForSpeech(interfaceLanguage: InterfaceLanguage, secondsElapsed: number): string {
  const minutes = Math.floor(secondsElapsed / 60);
  const seconds = secondsElapsed % 60;
  return t(interfaceLanguage, "elapsedSpeech", minutes, seconds);
}

export const webExamCategoryCounts = examCategoryCounts;
