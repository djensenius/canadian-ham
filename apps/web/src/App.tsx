import {
  applyCalculatorKey,
  createCalculatorState,
  type CalculatorKey,
  type CalculatorState,
} from "@canadian-ham/calculator-engine";
import {
  computeReadiness,
  dueCount,
  weakSubsectionIds,
  type QuestionProgressRecord,
  type ReadinessResult,
} from "@canadian-ham/engine-ts";
import { Component, createRef, useEffect, useMemo, useRef, useState, type KeyboardEvent, type MouseEvent, type ReactNode, type RefObject } from "react";

import { textToTimedMorse } from "@canadian-ham/morse-engine";
import { MorseCoursePanel } from "./morse/course/MorseCoursePanel";

import { HintTool } from "./components/HintTool";
import { MarkdownContent } from "./components/MarkdownContent";
import { PwaStatus } from "./components/PwaStatus";
import {
  bankCatalog,
  bankDataForId,
  categoryNameWithLanguage,
  loadQuestions,
  localizedCategoryNameWithLanguage,
  questionsById,
  subsectionTitle,
  type BankData,
  type CourseBankId,
  type Language,
  type Question,
} from "./data/bank";
import { explanationForQuestion, mainExplanationText, parseChoiceNotes, type Explanation } from "./data/explanations";
import { hintForQuestion, type QuestionHint } from "./data/hints";
import { lessonNeighbors, lessonsById, lessonsByModuleId, modules, modulesById, type LessonMeta } from "./data/lessons";
import { buildLessonQuizItems, lessonQuizzesById, type ConceptCheck, type LessonQuiz, type LessonQuizItem } from "./data/quizzes";
import { basicReferenceSheetMarkdownForWeb } from "./data/referenceSheet";
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
  mirrorStoredInterfaceLanguagePreference,
  readStoredInterfaceLanguageOverride,
  t,
  type InterfaceLanguage,
} from "./lib/i18n";
import { MorseOutputView, useWebMorseOutput } from "./lib/morseOutput";
import { morseISEDExamPreset, morseTimingFromPreferences, normalizeMorsePreferences, type WebMorseTimingProfileName } from "./lib/morseSettings";
import { MorseCopyExamSection, type MorsePlaybackCoordinator } from "./morse/copyExam/MorseCopyExamSection";
import { MorseSendingPracticeSection } from "./morse/sending/MorseSendingPracticeSection";
import { resolveLanguagePreference } from "./lib/languagePreference";
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

type Route = "home" | "learn" | "module" | "lesson" | "practice" | "mock" | "results" | "morse" | "settings" | "about";
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
  readonly instanceId: string;
  readonly seed: string;
  readonly scope: PracticeScope;
  readonly mode: PracticeMode;
  readonly items: readonly PracticeItem[];
  readonly currentIndex: number;
  readonly selectedByQuestionId: ReadonlyMap<string, number>;
  readonly submitted: boolean;
}

interface MockExamSession {
  readonly instanceId: string;
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

type ExamToolKind = "calculator" | "reference" | "hint";

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
    const recoveryPreferences = this.state.recoveryPreferences ?? migrateLegacyStoredLanguagePreference({ ...defaultPreferences, theme: readStoredThemePreference() });
    const interfaceLanguage = resolveLanguagePreference(recoveryPreferences.language);
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
              activeBank={bankDataForId(recoveryPreferences.activeBankId)}
              now={this.props.now}
              onProgressImported={() => this.setState({ errorMessage: null })}
              onReset={() => this.setState({ errorMessage: null })}
              onSetPreferences={async (preferencesPatch) => {
                const storedPreferences = await readRecoverablePreferences(this.props.store);
                const nextPreferences = { ...storedPreferences, ...preferencesPatch };
                await this.props.store.putPreferences(nextPreferences);
                applyThemePreference(nextPreferences.theme);
                mirrorThemePreference(nextPreferences.theme);
                mirrorStoredInterfaceLanguagePreference(nextPreferences.language);
                this.setState({ recoveryPreferences: nextPreferences });
                return true;
              }}
              interfaceLanguage={interfaceLanguage}
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
    return migrateLegacyStoredLanguagePreference(await store.getPreferences());
  } catch {
    return migrateLegacyStoredLanguagePreference({ ...defaultPreferences, theme: readStoredThemePreference() });
  }
}

function migrateLegacyStoredLanguagePreference(preferences: WebPreferences): WebPreferences {
  const legacyLanguage = readStoredInterfaceLanguageOverride();
  return preferences.language === "system" && legacyLanguage !== null ? { ...preferences, language: legacyLanguage } : preferences;
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
  return value === "home" || value === "learn" || value === "practice" || value === "mock" || value === "results" || value === "morse" || value === "settings" || value === "about";
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
  const initialPreferences = () => migrateLegacyStoredLanguagePreference({ ...defaultPreferences, theme: readStoredThemePreference() });
  const [locationHash, setLocationHash] = useState(() => globalThis.location?.hash ?? "");
  const [route, setRoute] = useState<Route>(() => routeFromHash(initialView));
  // Loaded questions are tagged with their course and only exposed while that course is active,
  // so a render never sees the previous course's questions after a switch.
  const [loadedBankQuestions, setLoadedBankQuestions] = useState<{ readonly bankId: CourseBankId; readonly questions: readonly Question[] } | null>(null);
  const [initialStoreLoaded, setInitialStoreLoaded] = useState(false);
  const [progress, setProgress] = useState<readonly QuestionProgressRecord[]>([]);
  const [examAttempts, setExamAttempts] = useState<readonly ExamAttempt[]>([]);
  const [lessonProgress, setLessonProgress] = useState<readonly LessonProgressRecord[]>([]);
  const [lessonQuizAttempts, setLessonQuizAttempts] = useState<readonly LessonQuizAttempt[]>([]);
  const [preferences, setPreferencesState] = useState<WebPreferences>(initialPreferences);
  const language = resolveLanguagePreference(preferences.language);
  const interfaceLanguage: InterfaceLanguage = language;
  const [practiceScope, setPracticeScope] = useState<PracticeScope>(() => scopeFromInitialId(initialScopeId));
  const [practiceSession, setPracticeSession] = useState<PracticeSession | null>(null);
  const [mockExam, setMockExam] = useState<MockExamSession | null>(null);
  const [latestResult, setLatestResult] = useState<ExamAttempt | null>(null);
  const [pendingCourseSwitch, setPendingCourseSwitch] = useState<CourseBankId | null>(null);
  const [statusMessage, setStatusMessage] = useState("");
  const [alertMessage, setAlertMessage] = useState("");
  const mainRef = useRef<HTMLElement>(null);
  const courseSwitcherRef = useRef<HTMLFieldSetElement>(null);
  const courseSwitchDialogRef = useRef<HTMLElement>(null);
  const previousRouteFocusRef = useRef({ locationHash, route });
  const interfaceLanguageRef = useRef(interfaceLanguage);
  const savedPreferencesRef = useRef(preferences);
  const latestRequestedPreferencesRef = useRef(preferences);
  const preferencesSaveQueueRef = useRef<Promise<void>>(Promise.resolve());
  const practiceSessionInstanceRef = useRef(0);
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
          const migratedPreferences = migrateLegacyStoredLanguagePreference(storedPreferences);
          savedPreferencesRef.current = migratedPreferences;
          latestRequestedPreferencesRef.current = migratedPreferences;
          setPreferencesState(migratedPreferences);
          if (migratedPreferences !== storedPreferences) {
            await store.putPreferences(migratedPreferences);
          }
          mirrorStoredInterfaceLanguagePreference(migratedPreferences.language);
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
    const bankId = preferences.activeBankId;
    loadQuestions(bankId)
      .then((questions) => {
        if (!cancelled) {
          setLoadedBankQuestions({ bankId, questions });
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
  }, [preferences.activeBankId]);

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
    if (pendingCourseSwitch !== null) {
      courseSwitchDialogRef.current?.focus();
    }
  }, [pendingCourseSwitch]);

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

  const activeBank = useMemo(() => bankDataForId(preferences.activeBankId), [preferences.activeBankId]);
  const bankQuestions = loadedBankQuestions?.bankId === preferences.activeBankId ? loadedBankQuestions.questions : null;
  const activeProgress = useMemo(() => progress.filter((record) => record.bankId === activeBank.bankId), [activeBank.bankId, progress]);
  const activeExamAttempts = useMemo(() => examAttempts.filter((attempt) => attempt.bankId === activeBank.bankId), [activeBank.bankId, examAttempts]);
  const bankQuestionsById = useMemo(() => bankQuestions === null ? new Map<string, Question>() : questionsById(bankQuestions), [bankQuestions]);
  const latestAttempt = useMemo(() => latestSubmittedAttempt(activeExamAttempts), [activeExamAttempts]);
  const readiness = useMemo(() => buildReadiness(activeBank, activeProgress, activeExamAttempts, now()), [activeBank, activeExamAttempts, now, activeProgress]);
  const weakSubsections = useMemo(
    () => weakSubsectionIds(activeProgress, latestAttempt?.items ?? []),
    [latestAttempt, activeProgress],
  );
  const dueReviewCount = useMemo(() => dueCount(activeProgress, now()), [now, activeProgress]);
  const routeSegments = hashSegments(locationHash);
  const currentModuleId = route === "module" || route === "lesson" ? routeSegments[1] : undefined;
  const currentLessonId = route === "lesson" ? routeSegments[2] : undefined;
  const currentLessonAnchor = route === "lesson" ? routeSegments[3] : undefined;

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

  function navigateToLesson(moduleId: string, lessonId: string, sectionAnchor?: string): void {
    const anchorSegment = sectionAnchor === undefined ? "" : `/${sectionAnchor}`;
    const nextHash = `#/learn/${moduleId}/${lessonId}${anchorSegment}`;
    updateRouteForHash(nextHash);
    if (window.location.hash !== nextHash) {
      window.location.hash = `/learn/${moduleId}/${lessonId}${anchorSegment}`;
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
      progress: activeProgress,
      latestExamItems: latestAttempt?.items,
      seed,
      now: now(),
      limit: 10,
    });
    setPracticeScope(scope);
    practiceSessionInstanceRef.current += 1;
    setPracticeSession({
      instanceId: `practice-${practiceSessionInstanceRef.current}`,
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
        mirrorStoredInterfaceLanguagePreference(nextPreferences.language);
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

  function requestCourseChange(nextBankId: CourseBankId): void {
    if (nextBankId === activeBank.bankId) {
      // Choosing the current course again dismisses any pending switch warning.
      setPendingCourseSwitch(null);
      return;
    }
    if (mockExam !== null || hasUnfinishedPracticeSession(practiceSession)) {
      setPendingCourseSwitch(nextBankId);
      return;
    }
    // Nothing left to discard (for example, the exam was submitted while the warning was open).
    setPendingCourseSwitch(null);
    void setCourse(nextBankId).catch(() => undefined);
  }

  async function confirmCourseSwitch(): Promise<void> {
    if (pendingCourseSwitch === null) {
      return;
    }
    const nextBankId = pendingCourseSwitch;
    setPendingCourseSwitch(null);
    try {
      await setCourse(nextBankId);
    } finally {
      // Return focus to the switcher (or main as a fallback), also when the save fails.
      window.setTimeout(() => {
        const switcher = courseSwitcherRef.current;
        if (switcher !== null) {
          switcher.focus();
        } else {
          mainRef.current?.focus();
        }
      }, 0);
    }
  }

  function cancelCourseSwitch(): void {
    setPendingCourseSwitch(null);
    window.setTimeout(() => courseSwitcherRef.current?.focus(), 0);
  }

  function handleCourseSwitchDialogKeyDown(event: KeyboardEvent<HTMLElement>): void {
    if (event.key === "Escape") {
      event.preventDefault();
      cancelCourseSwitch();
    }
  }

  async function setCourse(nextBankId: CourseBankId): Promise<void> {
    if (nextBankId === activeBank.bankId) {
      return;
    }
    const nextBank = bankDataForId(nextBankId);
    // Clear course-specific sessions in the same render as the optimistic bank change,
    // so a session is never shown or scored against the other course's questions.
    const previous = { practiceScope, practiceSession, mockExam, latestResult };
    setPracticeScope({ type: "all" });
    setPracticeSession(null);
    setMockExam(null);
    setLatestResult(null);
    try {
      await setPreferences({ activeBankId: nextBank.bankId });
    } catch (error) {
      // The bank change was rolled back; restore the previous course's sessions.
      setPracticeScope(previous.practiceScope);
      setPracticeSession(previous.practiceSession);
      setMockExam(previous.mockExam);
      setLatestResult(previous.latestResult);
      throw error;
    }
    setAlertMessage(t(interfaceLanguage, "courseChanged", nextBank.course === "advanced" ? t(interfaceLanguage, "courseAdvanced") : t(interfaceLanguage, "courseBasic")));
  }

  async function commitProgress(nextProgress: readonly QuestionProgressRecord[]): Promise<void> {
    try {
      await store.putQuestionProgressMany(nextProgress);
      setProgress((current) => mergeBankProgress(current, nextProgress, activeBank.bankId));
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
      setProgress((current) => mergeBankProgress(current, nextProgress, activeBank.bankId));
      setAlertMessage("");
    } catch (error) {
      setAlertMessage(t(interfaceLanguage, "errorSaveLessonQuiz", formatError(error)));
    }
  }

  async function handleExamSubmitted(attempt: ExamAttempt): Promise<void> {
    let nextProgress = activeProgress;
    for (const item of attempt.items) {
      nextProgress = applyPracticeAnswer(nextProgress, item.questionId, item.selectedSourceIndex ?? -1, attempt.submittedAt, attempt.bankId);
    }
    try {
      await store.putExamAttempt(attempt);
      await store.putQuestionProgressMany(nextProgress);
      setExamAttempts((current) => [...current.filter((existing) => existing.id !== attempt.id), attempt]);
      setProgress((current) => mergeBankProgress(current, nextProgress, attempt.bankId));
      // If the course changed while saving, keep the saved records but don't show this
      // attempt's results or clear the other course's exam.
      if (latestRequestedPreferencesRef.current.activeBankId !== attempt.bankId) {
        return;
      }
      setLatestResult(attempt);
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
          <CourseSwitcher activeBank={activeBank} fieldsetRef={courseSwitcherRef} interfaceLanguage={interfaceLanguage} onCourseChange={requestCourseChange} />
          <PwaStatus interfaceLanguage={interfaceLanguage} updateDisabled={mockExam !== null} />
        </div>
      </header>

      {pendingCourseSwitch !== null ? (
        <section className="confirm-panel course-switch-confirm" role="alertdialog" aria-labelledby="course-switch-confirm-title" aria-describedby="course-switch-confirm-copy" aria-modal="false" ref={courseSwitchDialogRef} tabIndex={-1} onKeyDown={handleCourseSwitchDialogKeyDown}>
          <h2 id="course-switch-confirm-title">{t(interfaceLanguage, "courseSwitchConfirmTitle")}</h2>
          <p id="course-switch-confirm-copy">{t(interfaceLanguage, "courseSwitchConfirmCopy")}</p>
          <div className="action-row">
            <button type="button" onClick={cancelCourseSwitch}>{t(interfaceLanguage, "courseSwitchCancel")}</button>
            <button type="button" className="danger" onClick={() => void confirmCourseSwitch().catch(() => undefined)}>{t(interfaceLanguage, "courseSwitchConfirm")}</button>
          </div>
        </section>
      ) : null}

      <nav className="top-nav" aria-label={t(interfaceLanguage, "navPrimary")}>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "home" ? "page" : undefined} onClick={() => navigate("home")}>{t(interfaceLanguage, "navHome")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "learn" || route === "module" || route === "lesson" ? "page" : undefined} onClick={() => navigate("learn")}>{t(interfaceLanguage, "navLearn")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "practice" ? "page" : undefined} onClick={() => practiceSession === null ? startPractice(practiceScope) : navigate("practice")}>{t(interfaceLanguage, "navPractice")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "mock" ? "page" : undefined} onClick={() => navigate("mock")}>{t(interfaceLanguage, "navMockExam")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "morse" ? "page" : undefined} onClick={() => navigate("morse")}>{t(interfaceLanguage, "navMorse")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "settings" ? "page" : undefined} onClick={() => navigate("settings")}>{t(interfaceLanguage, "navSettings")}</button>
        <button type="button" disabled={!initialStoreLoaded} aria-current={route === "about" ? "page" : undefined} onClick={() => navigate("about")}>{t(interfaceLanguage, "navAbout")}</button>
      </nav>

      <main id="main" ref={mainRef} tabIndex={-1}>
        {alertMessage ? <p className="alert-message" role="alert">{alertMessage}</p> : null}
        {!initialStoreLoaded ? <InitialStoreLoading interfaceLanguage={interfaceLanguage} /> : null}
        {initialStoreLoaded && route === "home" ? (
          <Home
            interfaceLanguage={interfaceLanguage}
            activeBank={activeBank}
            dueReviewCount={dueReviewCount}
            examAttempts={activeExamAttempts}
            onNavigate={navigate}
            onStartPractice={startPractice}
            readiness={readiness}
            weakSubsections={weakSubsections}
          />
        ) : null}
        {initialStoreLoaded && route === "learn" ? (
          activeBank.hasLessons ? (
            <Learn
              interfaceLanguage={interfaceLanguage}
              lessonProgress={lessonProgress}
              onOpenLesson={navigateToLesson}
              onOpenModule={navigateToModule}
            />
          ) : <AdvancedLessonsComingSoon interfaceLanguage={interfaceLanguage} />
        ) : null}
        {initialStoreLoaded && route === "module" ? (
          activeBank.hasLessons ? <ModulePage
            interfaceLanguage={interfaceLanguage}
            lessonProgress={lessonProgress}
            moduleId={currentModuleId ?? ""}
            onOpenLesson={navigateToLesson}
          /> : <AdvancedLessonsComingSoon interfaceLanguage={interfaceLanguage} />
        ) : null}
        {initialStoreLoaded && route === "lesson" ? (
          activeBank.hasLessons ? <LessonPage
            interfaceLanguage={interfaceLanguage}
            attempts={lessonQuizAttempts}
            bankQuestionsById={bankQuestionsById}
            language={language}
            lessonId={currentLessonId ?? ""}
            lessonProgress={lessonProgress}
            moduleId={currentModuleId ?? ""}
            now={now}
            targetAnchor={currentLessonAnchor}
            onLessonRead={(lesson) => void markLessonRead(lesson)}
            onOpenLesson={navigateToLesson}
            onOpenModule={navigateToModule}
            onQuizAttempt={(attempt, nextProgress) => void commitLessonQuizAttempt(attempt, nextProgress)}
            progress={activeProgress}
          /> : <AdvancedLessonsComingSoon interfaceLanguage={interfaceLanguage} />
        ) : null}
        {initialStoreLoaded && route === "practice" ? (
          <Practice
            interfaceLanguage={interfaceLanguage}
            language={language}
            bankReady={bankQuestions !== null}
            activeBank={activeBank}
            activeScope={practiceScope}
            now={now}
            onOpenLesson={(lessonId, sectionAnchor) => {
              const lesson = lessonsById.get(lessonId);
              if (lesson !== undefined) {
                navigateToLesson(lesson.moduleId, lesson.id, sectionAnchor);
              }
            }}
            onProgressChange={commitProgress}
            onSessionChange={setPracticeSession}
            onSetPreferences={setPreferences}
            preferences={preferences}
            progress={activeProgress}
            session={practiceSession}
            startPractice={startPractice}
          />
        ) : null}
        {initialStoreLoaded && route === "mock" ? (
          <MockExam
            interfaceLanguage={interfaceLanguage}
            activeBank={activeBank}
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
          <Results activeBank={activeBank} attempt={latestResult ?? latestAttempt} interfaceLanguage={interfaceLanguage} language={language} onStartPractice={startPractice} questionsById={bankQuestionsById} />
        ) : null}
        {initialStoreLoaded && route === "morse" ? (
          <MorseSection interfaceLanguage={interfaceLanguage} now={now} onSetPreferences={setPreferences} preferences={preferences} seedFactory={seedFactory} store={store} />
        ) : null}
        {initialStoreLoaded && route === "settings" ? (
          <Settings
            interfaceLanguage={interfaceLanguage}
            now={now}
            onProgressImported={(data) => {
              const importBank = bankDataForId(data.bankId);
              const importedPreferences = { ...data.preferences, activeBankId: importBank.bankId };
              setProgress((current) => mergeBankProgress(current, data.questionProgress, data.bankId));
              setExamAttempts((current) => mergeBankExamAttempts(current, data.examAttempts, data.bankId));
              if (importBank.hasLessons) {
                setLessonProgress(data.lessonProgress ?? []);
                setLessonQuizAttempts(data.lessonQuizAttempts ?? []);
              }
              savedPreferencesRef.current = importedPreferences;
              latestRequestedPreferencesRef.current = importedPreferences;
              mirrorStoredInterfaceLanguagePreference(importedPreferences.language);
              setPreferencesState(importedPreferences);
              setPracticeSession(null);
              setMockExam(null);
              setLatestResult(null);
              setPracticeScope({ type: "all" });
              setPendingCourseSwitch(null);
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
              setPendingCourseSwitch(null);
              clearStoredInterfaceLanguage();
              const resetInterfaceLanguage = resolveLanguagePreference(defaultPreferences.language);
              setAlertMessage("");
              setStatusMessage(t(resetInterfaceLanguage, "statusAllLocalProgressReset"));
            }}
            onSetPreferences={setPreferences}
            activeBank={activeBank}
            preferences={preferences}
            statusMessage={statusMessage}
            store={store}
          />
        ) : null}
        {initialStoreLoaded && route === "about" ? <About activeBank={activeBank} interfaceLanguage={interfaceLanguage} /> : null}
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

function CourseSwitcher({ activeBank, fieldsetRef, interfaceLanguage, onCourseChange }: { readonly activeBank: BankData; readonly fieldsetRef?: RefObject<HTMLFieldSetElement | null>; readonly interfaceLanguage: InterfaceLanguage; readonly onCourseChange: (bankId: CourseBankId) => void }) {
  return (
    <fieldset className="course-switcher" aria-label={t(interfaceLanguage, "courseSwitcherAria")} ref={fieldsetRef} tabIndex={-1}>
      <legend>{t(interfaceLanguage, "courseSwitcherLegend")}</legend>
      {bankCatalog.map((bank) => (
        <label key={bank.bankId}>
          <input type="radio" name="course" value={bank.bankId} checked={activeBank.bankId === bank.bankId} onChange={() => onCourseChange(bank.bankId)} />
          {bank.course === "advanced" ? t(interfaceLanguage, "courseAdvanced") : t(interfaceLanguage, "courseBasic")}
        </label>
      ))}
    </fieldset>
  );
}

function AdvancedLessonsComingSoon({ interfaceLanguage }: { readonly interfaceLanguage: InterfaceLanguage }) {
  return (
    <section className="card learn" aria-labelledby="advanced-lessons-title">
      <p className="eyebrow">{t(interfaceLanguage, "advancedLessonsEyebrow")}</p>
      <h2 id="advanced-lessons-title">{t(interfaceLanguage, "advancedLessonsTitle")}</h2>
      <p>{t(interfaceLanguage, "advancedLessonsComingSoon")}</p>
    </section>
  );
}

interface HomeProps {
  readonly activeBank: BankData;
  readonly interfaceLanguage: InterfaceLanguage;
  readonly readiness: ReadinessResult;
  readonly weakSubsections: readonly string[];
  readonly dueReviewCount: number;
  readonly examAttempts: readonly ExamAttempt[];
  readonly onStartPractice: (scope: PracticeScope) => void;
  readonly onNavigate: (route: Route) => void;
}

function Home({ activeBank, interfaceLanguage, readiness, weakSubsections, dueReviewCount, examAttempts, onStartPractice, onNavigate }: HomeProps) {
  const weakCategories = new Set(weakSubsections.map((id) => id.slice(0, 5)));
  return (
    <section className="card home" aria-labelledby="home-title">
      <div className="home-hero">
        <div>
          <p className="eyebrow">{activeBank.course === "advanced" ? t(interfaceLanguage, "advancedHomeEyebrow") : t(interfaceLanguage, "homeEyebrow")}</p>
          <h2 id="home-title">{activeBank.course === "advanced" ? t(interfaceLanguage, "advancedHomeTitle") : t(interfaceLanguage, "homeTitle")}</h2>
          <p>{activeBank.course === "advanced" ? t(interfaceLanguage, "advancedHomeIntro") : t(interfaceLanguage, "homeIntro")}</p>
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
            const name = categoryNameWithLanguage(categoryId, interfaceLanguage, activeBank);
            return <span key={categoryId}>{index > 0 ? ", " : null}<span lang={languageTag(name.language)}>{name.text}</span></span>;
          })}</p>
        ) : <p>{t(interfaceLanguage, "readinessNoWeakCategory")}</p>}
        {weakSubsections.length > 0 ? (
          <details>
            <summary>{t(interfaceLanguage, "readinessWeakSubsections")}</summary>
            <ul>
              {weakSubsections.slice(0, 12).map((subsectionId) => (
                <li key={subsectionId}>{subsectionId}{colonSeparator(interfaceLanguage)}<span lang={englishTextLang(interfaceLanguage)}>{subsectionTitle(subsectionId, activeBank)}</span></li>
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
          <strong>{activeBank.allQuestionCount}</strong>
          <small>{t(interfaceLanguage, "mixedAllCategories")}</small>
        </button>
        {activeBank.categories.map((category) => {
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
      <section className="reference-note" aria-labelledby="exam-day-learn-heading">
        <h3 id="exam-day-learn-heading">{t(interfaceLanguage, "examDayHeading")}</h3>
        <p>{t(interfaceLanguage, "examDayLearnCopy")}</p>
        <button type="button" className="secondary-button" onClick={() => onOpenLesson("M1", "L-001-01")}>{t(interfaceLanguage, "examDayLessonLink")}</button>
      </section>
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
  readonly targetAnchor?: string;
  readonly onLessonRead: (lesson: LessonMeta) => void;
  readonly onOpenModule: (moduleId: string) => void;
  readonly onOpenLesson: (moduleId: string, lessonId: string) => void;
  readonly onQuizAttempt: (attempt: LessonQuizAttempt, nextProgress: readonly QuestionProgressRecord[]) => void;
}

function LessonPrerequisites({ interfaceLanguage, lesson, onOpenLesson }: { readonly interfaceLanguage: InterfaceLanguage; readonly lesson: LessonMeta; readonly onOpenLesson: (moduleId: string, lessonId: string) => void }) {
  const prerequisiteLessons = lesson.prerequisites.flatMap((prerequisiteId) => {
    const prerequisiteLesson = lessonsById.get(prerequisiteId);
    return prerequisiteLesson === undefined ? [] : [prerequisiteLesson];
  });
  if (prerequisiteLessons.length === 0) {
    return null;
  }
  const headingId = `lesson-prerequisites-${lesson.id}`;
  return (
    <section className="lesson-prerequisites" aria-labelledby={headingId}>
      <h3 id={headingId}>{t(interfaceLanguage, "lessonPrerequisitesHeading")}</h3>
      <ul>
        {prerequisiteLessons.map((prerequisiteLesson) => (
          <li key={prerequisiteLesson.id}>
            <a href={`#/learn/${prerequisiteLesson.moduleId}/${prerequisiteLesson.id}`} onClick={(event: MouseEvent<HTMLAnchorElement>) => {
              if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) {
                return;
              }
              event.preventDefault();
              onOpenLesson(prerequisiteLesson.moduleId, prerequisiteLesson.id);
            }}><span lang={englishTextLang(interfaceLanguage)}>{prerequisiteLesson.title.en}</span></a>
          </li>
        ))}
      </ul>
    </section>
  );
}

function LessonPage({ interfaceLanguage, moduleId, lessonId, language, bankQuestionsById, progress, lessonProgress, attempts, now, targetAnchor, onLessonRead, onOpenModule, onOpenLesson, onQuizAttempt }: LessonPageProps) {
  const lesson = lessonsById.get(lessonId);
  const module = modulesById.get(moduleId) ?? (lesson !== undefined ? modulesById.get(lesson.moduleId) : undefined);
  useEffect(() => {
    if (targetAnchor === undefined) {
      return;
    }
    const timer = window.setTimeout(() => {
      document.getElementById(targetAnchor)?.focus();
    }, 0);
    return () => window.clearTimeout(timer);
  }, [lessonId, targetAnchor]);
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
        <LessonPrerequisites interfaceLanguage={interfaceLanguage} lesson={lesson} onOpenLesson={onOpenLesson} />
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
  readonly activeBank: BankData;
  readonly activeScope: PracticeScope;
  readonly language: Language;
  readonly bankReady: boolean;
  readonly now: () => string;
  readonly onOpenLesson: (lessonId: string, sectionAnchor?: string) => void;
  readonly preferences: WebPreferences;
  readonly progress: readonly QuestionProgressRecord[];
  readonly session: PracticeSession | null;
  readonly startPractice: (scope?: PracticeScope, mode?: PracticeMode) => void;
  readonly onSessionChange: (session: PracticeSession | null) => void;
  readonly onProgressChange: (progress: readonly QuestionProgressRecord[]) => Promise<void>;
  readonly onSetPreferences: (preferences: PreferencesPatch) => Promise<boolean>;
}

function hintLessonHref(hint: QuestionHint): string {
  const lesson = lessonsById.get(hint.lessonLink.lessonId);
  const moduleId = lesson?.moduleId ?? "";
  const sectionAnchor = hint.lessonLink.sectionAnchor === undefined ? "" : `/${hint.lessonLink.sectionAnchor}`;
  return `#/learn/${moduleId}/${hint.lessonLink.lessonId}${sectionAnchor}`;
}

function Practice({
  interfaceLanguage,
  activeBank,
  activeScope,
  language,
  bankReady,
  now,
  onOpenLesson,
  preferences,
  progress,
  session,
  startPractice,
  onSessionChange,
  onProgressChange,
  onSetPreferences,
}: PracticeProps) {
  const [scopeKind, setScopeKind] = useState(() => controlsFromScope(activeScope, activeBank).scopeKind);
  const [categoryId, setCategoryId] = useState(() => controlsFromScope(activeScope, activeBank).categoryId);
  const [subsectionId, setSubsectionId] = useState(() => controlsFromScope(activeScope, activeBank).subsectionId);
  const [submittingPractice, setSubmittingPractice] = useState(false);
  const feedbackRef = useRef<HTMLDivElement>(null);
  const reviewRef = useRef<HTMLDivElement>(null);
  const [hintLevelsByQuestionId, setHintLevelsByQuestionId] = useState<ReadonlyMap<string, number>>(() => new Map());
  const [hintQualifiedQuestionIds, setHintQualifiedQuestionIds] = useState<ReadonlySet<string>>(() => new Set());
  const [answeredWithHelpQuestionIds, setAnsweredWithHelpQuestionIds] = useState<ReadonlySet<string>>(() => new Set());
  const currentItem = session?.items[session.currentIndex];
  const selectedSourceIndex = currentItem === undefined ? undefined : session?.selectedByQuestionId.get(currentItem.question.id);
  const currentHint = currentItem === undefined ? null : hintForQuestion(currentItem.question.id, activeBank.bankId);
  const currentHintVisibleLevel = currentItem === undefined ? 0 : hintLevelsByQuestionId.get(currentItem.question.id) ?? 0;
  const currentHintQualified = currentItem !== undefined && hintQualifiedQuestionIds.has(currentItem.question.id);
  const isAnswered = selectedSourceIndex !== undefined;
  const allAnswered = session !== null && session.items.every((item) => session.selectedByQuestionId.has(item.question.id));

  useEffect(() => {
    setHintLevelsByQuestionId(new Map());
    setHintQualifiedQuestionIds(new Set());
    setAnsweredWithHelpQuestionIds(new Set());
  }, [session?.instanceId]);

  useEffect(() => {
    if (session === null && bankReady) {
      startPractice(activeScope, preferences.practiceMode);
    }
  }, [bankReady]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    const controls = controlsFromScope(session?.scope ?? activeScope, activeBank);
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

  function revealHintLevel(questionId: string, level: 1 | 2): void {
    setHintLevelsByQuestionId((current) => {
      const next = new Map(current);
      next.set(questionId, Math.max(next.get(questionId) ?? 0, level));
      return next;
    });
  }

  function qualifyAnsweredWithHelp(questionId: string): void {
    setHintQualifiedQuestionIds((current) => {
      if (current.has(questionId)) {
        return current;
      }
      return new Set(current).add(questionId);
    });
  }

  function recordAnsweredWithHelp(questionId: string): void {
    setAnsweredWithHelpQuestionIds((current) => {
      if (current.has(questionId)) {
        return current;
      }
      return new Set(current).add(questionId);
    });
  }

  async function chooseAnswer(item: PracticeItem, displayIndex: number): Promise<void> {
    if (session === null || (session.mode === "immediate" && session.selectedByQuestionId.has(item.question.id))) {
      return;
    }
    const sourceIndex = item.choicePermutation[displayIndex]!;
    const answeredWithHelp = hintQualifiedQuestionIds.has(item.question.id);
    const selected = new Map(session.selectedByQuestionId);
    selected.set(item.question.id, sourceIndex);
    const nextSession = { ...session, selectedByQuestionId: selected };
    onSessionChange(nextSession);
    if (answeredWithHelp) {
      recordAnsweredWithHelp(item.question.id);
    }
    if (session.mode === "immediate") {
      const nextProgress = applyPracticeAnswer(progress, item.question.id, sourceIndex, now(), activeBank.bankId, answeredWithHelp);
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
          nextProgress = applyPracticeAnswer(nextProgress, item.question.id, sourceIndex, submittedAt, activeBank.bankId, answeredWithHelpQuestionIds.has(item.question.id));
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
              {activeBank.categories.map((category) => {
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
              {activeBank.subsections.map((subsection) => <option key={subsection.id} lang={englishTextLang(interfaceLanguage)} value={subsection.id}>{subsection.id}{colonSeparator(interfaceLanguage)}{subsectionTitle(subsection.id, activeBank)}</option>)}
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
              <span>{t(interfaceLanguage, "scopePrefix")} <ScopeValue activeBank={activeBank} interfaceLanguage={interfaceLanguage} scope={session.scope} /></span>
              <span>{t(interfaceLanguage, "modePrefix")} {session.mode === "immediate" ? t(interfaceLanguage, "feedbackImmediate") : t(interfaceLanguage, "feedbackReviewLater")}</span>
              <span>{t(interfaceLanguage, "seedPrefix")} {session.seed}</span>
            </div>
            <p>{t(interfaceLanguage, "answeredCount", session.selectedByQuestionId.size, session.items.length)}</p>
            <p>{t(interfaceLanguage, "currentSubsection")} <strong>{currentItem.question.subsectionId}</strong></p>
          </aside>
          <div className="practice-main">
            <ExamTools
              context="practice"
              hint={currentHint}
              hintAnsweredWithHelpQualified={currentHintQualified}
              hintLessonHref={currentHint === null ? undefined : hintLessonHref(currentHint)}
              hintVisibleLevel={currentHintVisibleLevel}
              interfaceLanguage={interfaceLanguage}
              key={session.instanceId}
              onHintVisibleLongEnough={() => {
                if (currentItem !== undefined) {
                  qualifyAnsweredWithHelp(currentItem.question.id);
                }
              }}
              onOpenHintLesson={onOpenLesson}
              onRevealHintLevel={(level) => {
                if (currentItem !== undefined) {
                  revealHintLevel(currentItem.question.id, level);
                }
              }}
              referenceSheetAvailable={activeBank.course === "basic"}
            >
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
            </ExamTools>
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

interface ExamToolsProps {
  readonly context: "practice" | "mock";
  readonly interfaceLanguage: InterfaceLanguage;
  readonly referenceSheetAvailable: boolean;
  readonly children: ReactNode;
  readonly hint?: QuestionHint | null;
  readonly hintAnsweredWithHelpQualified?: boolean;
  readonly hintLessonHref?: string;
  readonly hintVisibleLevel?: number;
  readonly onHintVisibleLongEnough?: () => void;
  readonly onOpenHintLesson?: (lessonId: string, sectionAnchor?: string) => void;
  readonly onRevealHintLevel?: (level: 1 | 2) => void;
}

function ExamTools({ context, interfaceLanguage, referenceSheetAvailable, children, hint = null, hintAnsweredWithHelpQualified = false, hintLessonHref, hintVisibleLevel = 0, onHintVisibleLongEnough, onOpenHintLesson, onRevealHintLevel }: ExamToolsProps) {
  const [activeTool, setActiveTool] = useState<ExamToolKind | null>(null);
  const [calculatorState, setCalculatorState] = useState<CalculatorState>(() => createCalculatorState({ locale: interfaceLanguage }));
  const calculatorButtonRef = useRef<HTMLButtonElement>(null);
  const referenceButtonRef = useRef<HTMLButtonElement>(null);
  const hintButtonRef = useRef<HTMLButtonElement>(null);
  const returnFocusRef = useRef<HTMLButtonElement | null>(null);
  const panelId = `exam-tools-${context}-panel`;
  const hintAvailable = context === "practice" && hint !== null && hintLessonHref !== undefined && onHintVisibleLongEnough !== undefined && onOpenHintLesson !== undefined && onRevealHintLevel !== undefined;

  useEffect(() => {
    setCalculatorState(createCalculatorState({ locale: interfaceLanguage }));
  }, [interfaceLanguage]);

  useEffect(() => {
    if (activeTool === null) {
      return;
    }
    window.setTimeout(() => {
      const panel = document.getElementById(panelId);
      const focusTarget = panel?.querySelector<HTMLElement>("[data-exam-tool-focus]") ?? panel;
      focusTarget?.focus({ preventScroll: true });
    }, 0);
  }, [activeTool, panelId]);

  function pressCalculatorKey(key: CalculatorKey): void {
    setCalculatorState((current) => applyCalculatorKey(current, key));
  }

  function openTool(tool: ExamToolKind, button: HTMLButtonElement | null): void {
    returnFocusRef.current = button;
    setActiveTool((current) => current === tool ? null : tool);
  }

  function closeTool(): void {
    const returnFocus = returnFocusRef.current;
    setActiveTool(null);
    window.setTimeout(() => returnFocus?.focus(), 0);
  }

  function handlePanelKeyDown(event: KeyboardEvent<HTMLElement>): void {
    if ((activeTool === "reference" || activeTool === "hint") && event.key === "Escape") {
      event.preventDefault();
      closeTool();
    }
  }

  function toolTitle(): string {
    if (activeTool === "calculator") {
      return t(interfaceLanguage, "calculatorTitle");
    }
    if (activeTool === "hint") {
      return t(interfaceLanguage, "hintToolTitle");
    }
    return t(interfaceLanguage, "referenceSheetTitle");
  }

  const shellClassName = [
    "exam-tools-shell",
    `exam-tools-shell--${context}`,
    activeTool === null ? "" : "exam-tools-shell--open",
  ].filter(Boolean).join(" ");

  return (
    <div className={shellClassName} data-testid={`${context}-exam-tools`}>
      <div className="exam-tools-toolbar" role="group" aria-label={t(interfaceLanguage, "examToolsToolbarAria")}>
        <button
          aria-controls={activeTool === "calculator" ? panelId : undefined}
          aria-expanded={activeTool === "calculator"}
          className="secondary-button"
          ref={calculatorButtonRef}
          type="button"
          onClick={() => openTool("calculator", calculatorButtonRef.current)}
        >{t(interfaceLanguage, "examToolCalculator")}</button>
        <button
          aria-controls={activeTool === "reference" ? panelId : undefined}
          aria-disabled={!referenceSheetAvailable}
          aria-expanded={activeTool === "reference"}
          className="secondary-button"
          disabled={!referenceSheetAvailable}
          ref={referenceButtonRef}
          type="button"
          onClick={() => openTool("reference", referenceButtonRef.current)}
        >{t(interfaceLanguage, "examToolReferenceSheet")}</button>
        {hintAvailable ? (
          <button
            aria-controls={activeTool === "hint" ? panelId : undefined}
            aria-expanded={activeTool === "hint"}
            className="secondary-button"
            ref={hintButtonRef}
            type="button"
            onClick={() => openTool("hint", hintButtonRef.current)}
          >{t(interfaceLanguage, "examToolHint")}</button>
        ) : null}
      </div>
      <div className="exam-tools-content">
        {children}
      </div>
      {activeTool === null ? null : (
        <aside className="exam-tool-panel" data-testid="exam-tool-panel" id={panelId} aria-labelledby={`${panelId}-title`} tabIndex={-1} onKeyDown={handlePanelKeyDown}>
          <div className="exam-tool-panel__header">
            <h3 id={`${panelId}-title`}>{toolTitle()}</h3>
            <button type="button" className="secondary-button" onClick={closeTool}>{t(interfaceLanguage, "closeExamTool")}</button>
          </div>
          {activeTool === "calculator" ? (
            <CalculatorTool
              calculatorState={calculatorState}
              interfaceLanguage={interfaceLanguage}
              onPressKey={pressCalculatorKey}
            />
          ) : null}
          {activeTool === "reference" ? <ReferenceSheetTool interfaceLanguage={interfaceLanguage} /> : null}
          {activeTool === "hint" && hintAvailable ? (
            <HintTool
              answeredWithHelpQualified={hintAnsweredWithHelpQualified}
              hint={hint}
              interfaceLanguage={interfaceLanguage}
              lessonHref={hintLessonHref}
              onHintVisibleLongEnough={onHintVisibleLongEnough}
              onOpenLesson={onOpenHintLesson}
              onRevealLevel={onRevealHintLevel}
              referenceSheetAvailable={referenceSheetAvailable}
              visibleLevel={hintVisibleLevel}
            />
          ) : null}
        </aside>
      )}
    </div>
  );
}

function CalculatorTool({ calculatorState, interfaceLanguage, onPressKey }: { readonly calculatorState: CalculatorState; readonly interfaceLanguage: InterfaceLanguage; readonly onPressKey: (key: CalculatorKey) => void }) {
  const spokenResult = calculatorState.displayValue.spoken[interfaceLanguage];

  function handleKeyDown(event: KeyboardEvent<HTMLElement>): void {
    if (event.target instanceof HTMLElement && event.target.closest("button") !== null && event.key === "Enter" && calculatorState.pendingOperator !== null && !calculatorState.awaitingOperand) {
      event.preventDefault();
      onPressKey("=");
      return;
    }
    const key = calculatorKeyFromKeyboardEvent(event);
    if (key === null) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    onPressKey(key);
  }

  return (
    <section className="calculator-tool" aria-label={t(interfaceLanguage, "calculatorTitle")} data-exam-tool-focus tabIndex={-1} onKeyDown={handleKeyDown}>
      <p className="calculator-help">{t(interfaceLanguage, "calculatorKeyboardHelp")}</p>
      <output className="calculator-display" aria-live="off" aria-label={t(interfaceLanguage, "calculatorDisplayAria", spokenResult)}>{calculatorState.display}</output>
      <div className="sr-only" aria-live="polite" data-testid="calculator-live-result">{t(interfaceLanguage, "calculatorResultAnnouncement", spokenResult)}</div>
      <div className="calculator-keypad" role="group" aria-label={t(interfaceLanguage, "calculatorKeypadAria")}>
        {calculatorKeyRows.map((row) => row.map((key) => (
          <button
            aria-label={calculatorKeyAriaLabel(interfaceLanguage, key)}
            className={key === "=" ? "primary-button" : "secondary-button"}
            key={key}
            type="button"
            onClick={() => onPressKey(key)}
            onKeyDown={handleKeyDown}
          >{calculatorKeyVisual(interfaceLanguage, key)}</button>
        )))}
      </div>
    </section>
  );
}

function firstMarkdownHeading(markdown: string): string | undefined {
  return /^#\s+(.+)$/m.exec(markdown)?.[1]?.trim();
}

function ReferenceSheetTool({ interfaceLanguage }: { readonly interfaceLanguage: InterfaceLanguage }) {
  const referenceSheetMarkdown = basicReferenceSheetMarkdownForWeb();
  return (
    <section className="reference-sheet-tool" aria-label={t(interfaceLanguage, "referenceSheetTitle")} data-exam-tool-focus tabIndex={-1}>
      {interfaceLanguage === "fr" ? <p className="reference-note" lang="fr-CA">{t(interfaceLanguage, "englishOnlyContentNotice")}</p> : null}
      <MarkdownContent markdown={referenceSheetMarkdown} title={firstMarkdownHeading(referenceSheetMarkdown)} tableLabel={t(interfaceLanguage, "referenceSheetTableAria")} interfaceLanguage={interfaceLanguage} contentLanguage="en" />
    </section>
  );
}

const calculatorKeyRows: readonly (readonly CalculatorKey[])[] = [
  ["AC", "C/CE", "backspace", "÷"],
  ["7", "8", "9", "×"],
  ["4", "5", "6", "-"],
  ["1", "2", "3", "+"],
  ["±", "0", ".", "="],
  ["%", "√", "x²", "1/x"],
];

function calculatorKeyFromKeyboardEvent(event: KeyboardEvent<HTMLElement>): CalculatorKey | null {
  if (event.ctrlKey || event.metaKey || event.altKey) {
    return null;
  }
  if (event.target instanceof HTMLElement && event.target.closest("button") !== null && (event.key === "Enter" || event.key === " ")) {
    return null;
  }
  if (/^[0-9]$/.test(event.key)) {
    return event.key as CalculatorKey;
  }
  if (event.key === "." || event.key === ",") {
    return ".";
  }
  if (event.key === "+") {
    return "+";
  }
  if (event.key === "-") {
    return "-";
  }
  if (event.key === "*" || event.key.toLowerCase() === "x") {
    return "×";
  }
  if (event.key === "/") {
    return "÷";
  }
  if (event.key === "Enter" || event.key === "=") {
    return "=";
  }
  if (event.key === "Backspace") {
    return "backspace";
  }
  if (event.key === "Escape") {
    return "C/CE";
  }
  if (event.key === "Delete") {
    return "AC";
  }
  return null;
}

function calculatorKeyVisual(interfaceLanguage: InterfaceLanguage, key: CalculatorKey): string {
  if (key === ".") {
    return interfaceLanguage === "fr" ? "," : ".";
  }
  if (key === "-") {
    return "−";
  }
  if (key === "backspace") {
    return "⌫";
  }
  return key;
}

function calculatorKeyAriaLabel(interfaceLanguage: InterfaceLanguage, key: CalculatorKey): string {
  if (/^[0-9]$/.test(key)) {
    return t(interfaceLanguage, "calculatorDigitKey", key);
  }
  switch (key) {
    case ".":
      return t(interfaceLanguage, "calculatorDecimalKey");
    case "+":
      return t(interfaceLanguage, "calculatorAddKey");
    case "-":
      return t(interfaceLanguage, "calculatorSubtractKey");
    case "×":
      return t(interfaceLanguage, "calculatorMultiplyKey");
    case "÷":
      return t(interfaceLanguage, "calculatorDivideKey");
    case "=":
      return t(interfaceLanguage, "calculatorEqualsKey");
    case "√":
      return t(interfaceLanguage, "calculatorSquareRootKey");
    case "x²":
      return t(interfaceLanguage, "calculatorSquareKey");
    case "1/x":
      return t(interfaceLanguage, "calculatorReciprocalKey");
    case "±":
      return t(interfaceLanguage, "calculatorSignKey");
    case "%":
      return t(interfaceLanguage, "calculatorPercentKey");
    case "C/CE":
      return t(interfaceLanguage, "calculatorClearEntryKey");
    case "AC":
      return t(interfaceLanguage, "calculatorAllClearKey");
    case "backspace":
      return t(interfaceLanguage, "calculatorBackspaceKey");
  }
  return key;
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
  readonly activeBank: BankData;
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

function MockExam({ activeBank, interfaceLanguage, exam, language, questions, preferences, now, seedFactory, onExamChange, onSubmitExam }: MockExamProps) {
  const [seed, setSeed] = useState("");
  const [timerEnabled, setTimerEnabled] = useState(preferences.examTimerEnabled);
  const [timerAnnouncement, setTimerAnnouncement] = useState("");
  const [submittingExam, setSubmittingExam] = useState(false);
  const examQuestionsById = useMemo(() => questions === null ? new Map<string, Question>() : questionsById(questions), [questions]);
  const confirmRef = useRef<HTMLElement>(null);
  const submitButtonRef = useRef<HTMLButtonElement>(null);
  const examInstanceRef = useRef(0);

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
    examInstanceRef.current += 1;
    onExamChange({
      instanceId: `mock-${examInstanceRef.current}`,
      seed: selectedSeed,
      startedAt: now(),
      timerEnabled,
      generatedItems: createMockExam(selectedSeed, questions, activeBank),
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
        <p>{activeBank.course === "advanced" ? t(interfaceLanguage, "advancedMockIntro", activeBank.mockExamQuestionCount) : t(interfaceLanguage, "mockIntro")}</p>
        <label>
          {t(interfaceLanguage, "seedOptional")}
          <input value={seed} onChange={(event) => setSeed(event.currentTarget.value)} placeholder={t(interfaceLanguage, "seedPlaceholder")} />
        </label>
        <label><input type="checkbox" checked={timerEnabled} onChange={(event) => setTimerEnabled(event.currentTarget.checked)} /> {t(interfaceLanguage, "timerEnable")}</label>
        <p id="timer-note">{t(interfaceLanguage, "timerNote")}</p>
        <p className="reference-note">{activeBank.course === "advanced" ? t(interfaceLanguage, "advancedNoReferenceSheetNote") : t(interfaceLanguage, "referenceSheetNote")}</p>
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
        bank: activeBank,
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
      <ExamTools
        context="mock"
        interfaceLanguage={interfaceLanguage}
        key={exam.instanceId}
        referenceSheetAvailable={activeBank.course === "basic"}
      >
        <div className="mock-exam-body">
          <div className="mock-question-stack">
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
        </div>
      </ExamTools>
    </section>
  );
}

function Results({ activeBank, attempt, interfaceLanguage, language, onStartPractice, questionsById }: { readonly activeBank: BankData; readonly attempt: ExamAttempt | null; readonly interfaceLanguage: InterfaceLanguage; readonly language: Language; readonly onStartPractice: (scope: PracticeScope) => void; readonly questionsById: ReadonlyMap<string, Question> }) {
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
      <p>{attempt.score.honours ? t(interfaceLanguage, "resultHonours") : attempt.score.passed ? t(interfaceLanguage, activeBank.course === "advanced" ? "advancedResultPass" : "resultPass") : t(interfaceLanguage, "resultBelowPass")}</p>
      <p>{activeBank.course === "advanced" ? t(interfaceLanguage, "advancedPassThresholdCopy") : t(interfaceLanguage, "passThresholdCopy")}</p>
      <h3>{t(interfaceLanguage, "categoryBreakdown")}</h3>
      <ul>
        {attempt.score.categoryBreakdown.map((entry) => (
          <li key={entry.categoryId}><CategoryNameText activeBank={activeBank} categoryId={entry.categoryId} interfaceLanguage={interfaceLanguage} />{colonSeparator(interfaceLanguage)}{entry.correct}/{entry.total} ({entry.percent.toFixed(0)}{interfaceLanguage === "fr" ? " %" : "%"})</li>
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

function About({ activeBank, interfaceLanguage }: { readonly activeBank: BankData; readonly interfaceLanguage: InterfaceLanguage }) {
  const legalLang = englishTextLang(interfaceLanguage);

  return (
    <section className="card about" aria-labelledby="about-title">
      <p className="eyebrow">{t(interfaceLanguage, "navAbout")}</p>
      <h2 id="about-title">{t(interfaceLanguage, "aboutTitle")}</h2>
      <p>{t(interfaceLanguage, "aboutIntro")}</p>

      <section aria-labelledby="about-bank-heading">
        <h3 id="about-bank-heading">{t(interfaceLanguage, "aboutBankHeading")}</h3>
        <p>{t(interfaceLanguage, "aboutBankVersion", activeBank.bankId, activeBank.manifest.effectiveDate)}</p>
        <p>{t(interfaceLanguage, "aboutQuestionBankCounts", activeBank.manifest.counts.questions, activeBank.manifest.counts.categories, activeBank.manifest.counts.subsections)}</p>
      </section>

      <section aria-labelledby="about-sources-heading">
        <h3 id="about-sources-heading">{t(interfaceLanguage, "aboutSourcesHeading")}</h3>
        <ul>
          <li>{t(interfaceLanguage, activeBank.course === "advanced" ? "aboutAdvancedQuestionBankSource" : "aboutQuestionBankSource", activeBank.manifest.effectiveDate, activeBank.manifest.source.url)}</li>
          <li>{t(interfaceLanguage, "aboutRbr4Source", rbr4CitationUrl)}</li>
          <li>{activeBank.course === "advanced" ? t(interfaceLanguage, "aboutAdvancedNoReferenceSheetSource") : t(interfaceLanguage, "aboutReferenceSheetSource")}</li>
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

const MORSE_PRACTICE_TEXT = "KMRSU PARIS";

function useMorsePlaybackCoordinator(): MorsePlaybackCoordinator {
  const stopHandlersRef = useRef(new Map<string, () => void>());
  return useMemo(() => ({
    register(ownerId, stop) {
      stopHandlersRef.current.set(ownerId, stop);
      return () => {
        if (stopHandlersRef.current.get(ownerId) === stop) {
          stopHandlersRef.current.delete(ownerId);
        }
      };
    },
    claim(ownerId) {
      for (const [registeredOwnerId, stop] of stopHandlersRef.current) {
        if (registeredOwnerId !== ownerId) {
          stop();
        }
      }
    },
  }), []);
}

function useMorsePlaybackRegistration(coordinator: MorsePlaybackCoordinator, ownerId: string, stop: () => void): void {
  const stopRef = useRef(stop);
  stopRef.current = stop;
  useEffect(() => coordinator.register(ownerId, () => stopRef.current()), [coordinator, ownerId]);
}

function MorseSection({ interfaceLanguage, preferences, onSetPreferences, store, now, seedFactory }: { readonly interfaceLanguage: InterfaceLanguage; readonly preferences: WebPreferences; readonly onSetPreferences: (preferences: PreferencesPatch) => Promise<boolean>; readonly store: ProgressStore; readonly now: () => string; readonly seedFactory: () => string }) {
  const playbackCoordinator = useMorsePlaybackCoordinator();
  return (
    <section className="card morse-section" aria-labelledby="morse-section-title">
      <p className="eyebrow">{t(interfaceLanguage, "morseEyebrow")}</p>
      <h2 id="morse-section-title">{t(interfaceLanguage, "morseSectionTitle")} <span className="preview-label">{t(interfaceLanguage, "previewLabel")}</span></h2>
      <p>{t(interfaceLanguage, "morseSectionIntro")}</p>
      <div className="morse-home-grid" role="group" aria-label={t(interfaceLanguage, "morseHomeEntriesAria")}>
        <div className="morse-home-card">
          <h3 id="morse-learn-title">{t(interfaceLanguage, "morseLearnTitle")}</h3>
          <p>{t(interfaceLanguage, "morseLearnPlaceholder")}</p>
        </div>
        <div className="morse-home-card">
          <h3 id="morse-copy-practice-title">{t(interfaceLanguage, "morseCopyPracticeTitle")}</h3>
          <p>{t(interfaceLanguage, "morsePracticePlaceholder")}</p>
        </div>
        <div className="morse-home-card">
          <h3 id="morse-exam-title">{t(interfaceLanguage, "morseExamTitle")}</h3>
          <p>{t(interfaceLanguage, "morseExamPlaceholder")}</p>
        </div>
        <div className="morse-home-card">
          <h3 id="morse-sending-home-title">{t(interfaceLanguage, "morseSendingTitle")}</h3>
          <p>{t(interfaceLanguage, "morseSendingPlaceholder")}</p>
        </div>
      </div>
      <MorseCoursePanel interfaceLanguage={interfaceLanguage} preferences={preferences} store={store} now={now} seedFactory={seedFactory} playbackCoordinator={playbackCoordinator} />
      <MorseCopyExamSection interfaceLanguage={interfaceLanguage} preferences={preferences} examSeedFactory={(profileName) => `web-${profileName}-${seedFactory()}`} playbackCoordinator={playbackCoordinator} />
      <MorseSendingPracticeSection interfaceLanguage={interfaceLanguage} preferences={preferences} examSeedFactory={(profileName) => `web-sending-${profileName}-${seedFactory()}`} playbackCoordinator={playbackCoordinator} />
      <MorseTrainerPreview interfaceLanguage={interfaceLanguage} preferences={preferences} playbackCoordinator={playbackCoordinator} />
      <MorseSettingsControls interfaceLanguage={interfaceLanguage} onSetPreferences={onSetPreferences} preferences={preferences} />
    </section>
  );
}

function MorseTrainerPreview({ interfaceLanguage, preferences, playbackCoordinator }: { readonly interfaceLanguage: InterfaceLanguage; readonly preferences: WebPreferences; readonly playbackCoordinator: MorsePlaybackCoordinator }) {
  const output = useWebMorseOutput(interfaceLanguage);
  const revealTimerRef = useRef<number | null>(null);
  const playbackGenerationRef = useRef(0);
  const playButtonRef = useRef<HTMLButtonElement>(null);
  const stopButtonRef = useRef<HTMLButtonElement>(null);
  const focusStopAfterStartRef = useRef(false);
  const focusPlayAfterStopRef = useRef(false);
  const [playing, setPlaying] = useState(false);
  const [revealed, setRevealed] = useState(false);
  const [status, setStatus] = useState("");
  const [liveStatus, setLiveStatus] = useState("");
  const morsePreferences = preferences.morse;
  const timingProfile = useMemo(() => morseTimingFromPreferences(morsePreferences), [morsePreferences]);
  const sequence = useMemo(() => textToTimedMorse(MORSE_PRACTICE_TEXT, timingProfile), [timingProfile]);
  const localeTag = interfaceLanguageTag(interfaceLanguage);
  const formattedDuration = useMemo(() => formatLocaleNumber(sequence.totalDurationSeconds, localeTag, 1), [localeTag, sequence.totalDurationSeconds]);
  const formattedCharacterWpm = useMemo(() => formatLocaleNumber(timingProfile.characterWpm, localeTag, 1), [localeTag, timingProfile.characterWpm]);
  const formattedEffectiveWpm = useMemo(() => formatLocaleNumber(timingProfile.effectiveWpm, localeTag, 1), [localeTag, timingProfile.effectiveWpm]);

  useEffect(() => () => {
    playbackGenerationRef.current += 1;
    void output.close();
    if (revealTimerRef.current !== null) {
      window.clearTimeout(revealTimerRef.current);
    }
  }, [output.close]);
  useMorsePlaybackRegistration(playbackCoordinator, "quick-listen", stopPlaying);

  useEffect(() => {
    if (playing && focusStopAfterStartRef.current) {
      focusStopAfterStartRef.current = false;
      window.setTimeout(() => stopButtonRef.current?.focus(), 0);
    }
    if (!playing && focusPlayAfterStopRef.current) {
      focusPlayAfterStopRef.current = false;
      window.setTimeout(() => playButtonRef.current?.focus(), 0);
    }
  }, [playing]);

  async function play(): Promise<void> {
    const generation = playbackGenerationRef.current + 1;
    playbackCoordinator.claim("quick-listen");
    playbackGenerationRef.current = generation;
    focusStopAfterStartRef.current = document.activeElement === playButtonRef.current;
    setRevealed(false);
    setPlaying(true);
    setStatus(t(interfaceLanguage, "morsePlaybackStarted"));
    setLiveStatus("");
    if (revealTimerRef.current !== null) {
      window.clearTimeout(revealTimerRef.current);
      revealTimerRef.current = null;
    }
    try {
      const handle = await output.playText(MORSE_PRACTICE_TEXT, morsePreferences);
      if (generation !== playbackGenerationRef.current) {
        handle.stop();
        return;
      }
      revealTimerRef.current = window.setTimeout(() => {
        if (generation !== playbackGenerationRef.current) {
          return;
        }
        setPlaying(false);
        setRevealed(true);
        focusPlayAfterStopRef.current = document.activeElement === stopButtonRef.current;
        const finishedStatus = t(interfaceLanguage, "morsePlaybackFinished");
        setStatus(finishedStatus);
        setLiveStatus(finishedStatus);
      }, Math.ceil(handle.durationSeconds * 1000) + 60);
    } catch (error) {
      if (generation !== playbackGenerationRef.current) {
        return;
      }
      setPlaying(false);
      focusPlayAfterStopRef.current = document.activeElement === stopButtonRef.current;
      const errorStatus = t(interfaceLanguage, "morsePlaybackError", formatError(error));
      setStatus(errorStatus);
      setLiveStatus(errorStatus);
    }
  }

  function stopPlaying(): void {
    if (!playing) {
      return;
    }
    playbackGenerationRef.current += 1;
    focusPlayAfterStopRef.current = document.activeElement === stopButtonRef.current;
    output.stop();
    if (revealTimerRef.current !== null) {
      window.clearTimeout(revealTimerRef.current);
      revealTimerRef.current = null;
    }
    setPlaying(false);
    const stoppedStatus = t(interfaceLanguage, "morsePlaybackStopped");
    setStatus(stoppedStatus);
    setLiveStatus(stoppedStatus);
  }

  function stop(): void {
    stopPlaying();
  }

  return (
    <section className="morse-trainer" aria-labelledby="morse-title">
      <h3 id="morse-title">{t(interfaceLanguage, "morseTitle")}</h3>
      <p>{t(interfaceLanguage, "morseIntro")}</p>
      <dl className="morse-settings-summary">
        <div><dt>{t(interfaceLanguage, "morseTone")}</dt><dd>{t(interfaceLanguage, "morseHertz", morsePreferences.toneHz)}</dd></div>
        <div><dt>{t(interfaceLanguage, "morseCharacterSpeed")}</dt><dd>{t(interfaceLanguage, "morseWpm", formattedCharacterWpm)}</dd></div>
        <div><dt>{t(interfaceLanguage, "morseEffectiveSpeed")}</dt><dd>{t(interfaceLanguage, "morseWpm", formattedEffectiveWpm)}</dd></div>
      </dl>
      <div className="action-row">
        <button type="button" className="primary-button" ref={playButtonRef} disabled={playing} onClick={() => void play()} aria-label={t(interfaceLanguage, "morsePlayPracticeAria")}>{t(interfaceLanguage, "morsePlay")}</button>
        <button type="button" ref={stopButtonRef} disabled={!playing} onClick={stop} aria-label={t(interfaceLanguage, "morseStopPracticeAria")}>{t(interfaceLanguage, "morseStop")}</button>
      </div>
      <p className="morse-duration">{t(interfaceLanguage, "morseDuration", formattedDuration)}</p>
      <MorseOutputView state={output.state} interfaceLanguage={interfaceLanguage} />
      <div className="morse-playback-status">{status ? <p>{status}</p> : null}</div>
      <div className="sr-only morse-live-status" role="status" aria-live="polite" aria-atomic="true">{liveStatus}</div>
      <section className="morse-copy-card" aria-labelledby="morse-copy-title">
        <h3 id="morse-copy-title">{t(interfaceLanguage, "morsePracticeTextTitle")}</h3>
        {revealed ? <p className="morse-copy" lang="en">{sequence.normalizedText}</p> : <p>{t(interfaceLanguage, "morseTextHidden")}</p>}
      </section>
    </section>
  );
}

interface MorseNumberDrafts {
  readonly toneHz: string;
  readonly characterWpm: string;
  readonly effectiveWpm: string;
}

function morseDraftsFromPreferences(preferences: WebPreferences["morse"]): MorseNumberDrafts {
  const normalized = normalizeMorsePreferences(preferences);
  return {
    toneHz: String(normalized.toneHz),
    characterWpm: String(normalized.characterWpm),
    effectiveWpm: String(normalized.effectiveWpm),
  };
}

function morseNumberInputValue(value: number): string {
  return Number.isInteger(value) ? String(value) : value.toFixed(1);
}

function morsePreferencesEqual(left: WebPreferences["morse"], right: WebPreferences["morse"]): boolean {
  return left.toneHz === right.toneHz &&
    left.characterWpm === right.characterWpm &&
    left.effectiveWpm === right.effectiveWpm &&
    left.timingProfile === right.timingProfile &&
    left.volume === right.volume &&
    left.outputMode === right.outputMode;
}

function morseNumberDraftBounds(field: keyof MorseNumberDrafts, preferences: WebPreferences["morse"]): { readonly minimum: number; readonly maximum: number } {
  const normalized = normalizeMorsePreferences(preferences);
  switch (field) {
    case "toneHz":
      return { minimum: 400, maximum: 900 };
    case "characterWpm":
      return { minimum: 12, maximum: 25 };
    case "effectiveWpm":
      return { minimum: 5, maximum: normalized.characterWpm };
  }
}

function isValidMorseNumberDraft(field: keyof MorseNumberDrafts, value: number, preferences: WebPreferences["morse"]): boolean {
  if (!Number.isFinite(value) || !Number.isInteger(value)) {
    return false;
  }
  const bounds = morseNumberDraftBounds(field, preferences);
  return value >= bounds.minimum && value <= bounds.maximum;
}

function MorseSettingsControls({ interfaceLanguage, preferences, onSetPreferences }: { readonly interfaceLanguage: InterfaceLanguage; readonly preferences: WebPreferences; readonly onSetPreferences: (preferences: PreferencesPatch) => Promise<boolean> }) {
  const [errors, setErrors] = useState<readonly string[]>([]);
  const [message, setMessage] = useState("");
  const [morseNumberDrafts, setMorseNumberDrafts] = useState(() => morseDraftsFromPreferences(preferences.morse));
  const morseTimingProfile = useMemo(() => morseTimingFromPreferences(preferences.morse), [preferences.morse]);
  const morseSpeedControlsDisabled = preferences.morse.timingProfile !== "general";
  const localeTag = interfaceLanguageTag(interfaceLanguage);
  const fixedCharacterWpm = useMemo(() => formatLocaleNumber(morseTimingProfile.characterWpm, localeTag, 1), [localeTag, morseTimingProfile.characterWpm]);
  const fixedEffectiveWpm = useMemo(() => formatLocaleNumber(morseTimingProfile.effectiveWpm, localeTag, 1), [localeTag, morseTimingProfile.effectiveWpm]);
  const characterWpmInputValue = morseSpeedControlsDisabled ? morseNumberInputValue(morseTimingProfile.characterWpm) : morseNumberDrafts.characterWpm;
  const effectiveWpmInputValue = morseSpeedControlsDisabled ? morseNumberInputValue(morseTimingProfile.effectiveWpm) : morseNumberDrafts.effectiveWpm;

  // Resync drafts only when the stored Morse preferences actually change. Skipping the
  // initial run avoids a redundant reset that could clobber a draft typed right after mount.
  const syncedMorsePreferences = useRef(preferences.morse);
  useEffect(() => {
    if (syncedMorsePreferences.current === preferences.morse) {
      return;
    }
    syncedMorsePreferences.current = preferences.morse;
    setMorseNumberDrafts(morseDraftsFromPreferences(preferences.morse));
  }, [preferences.morse]);

  async function saveMorsePreference(patch: Partial<WebPreferences["morse"]>): Promise<void> {
    try {
      const currentMorse = normalizeMorsePreferences(preferences.morse);
      const nextMorse = normalizeMorsePreferences({ ...preferences.morse, ...patch });
      if (morsePreferencesEqual(currentMorse, nextMorse)) {
        return;
      }
      const savedLatestRequest = await onSetPreferences({ morse: nextMorse });
      if (!savedLatestRequest) {
        return;
      }
      setErrors([]);
      setMessage(t(interfaceLanguage, "morseSettingsSaved"));
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorSavePreferences", formatError(error))]);
    }
  }

  function updateMorseNumberDraft(field: keyof MorseNumberDrafts, value: string): void {
    setMorseNumberDrafts((drafts) => ({ ...drafts, [field]: value }));
  }

  function handleMorseNumberKeyDown(event: KeyboardEvent<HTMLInputElement>, field: keyof MorseNumberDrafts): void {
    if (event.key === "Enter") {
      event.preventDefault();
      void commitMorseNumberDraft(field);
    }
  }

  async function commitMorseNumberDraft(field: keyof MorseNumberDrafts): Promise<void> {
    const draft = morseNumberDrafts[field].trim();
    const numericValue = Number(draft);
    if (draft === "" || !isValidMorseNumberDraft(field, numericValue, preferences.morse)) {
      const bounds = morseNumberDraftBounds(field, preferences.morse);
      const fieldLabel = field === "toneHz"
        ? t(interfaceLanguage, "morseTone")
        : field === "characterWpm"
          ? t(interfaceLanguage, "morseCharacterSpeed")
          : t(interfaceLanguage, "morseEffectiveSpeed");
      setMorseNumberDrafts(morseDraftsFromPreferences(preferences.morse));
      setMessage(t(
        interfaceLanguage,
        "morseNumberDraftReverted",
        fieldLabel,
        formatLocaleNumber(bounds.minimum, localeTag, 0),
        formatLocaleNumber(bounds.maximum, localeTag, 0),
      ));
      return;
    }
    const patch = { [field]: numericValue } as Partial<WebPreferences["morse"]>;
    const nextMorse = normalizeMorsePreferences({ ...preferences.morse, ...patch });
    setMorseNumberDrafts(morseDraftsFromPreferences(nextMorse));
    await saveMorsePreference(patch);
  }

  async function applyMorsePreset(): Promise<void> {
    try {
      const currentMorse = normalizeMorsePreferences(preferences.morse);
      const nextMorse = morseISEDExamPreset(preferences.morse);
      if (morsePreferencesEqual(currentMorse, nextMorse)) {
        return;
      }
      const savedLatestRequest = await onSetPreferences({ morse: nextMorse });
      if (!savedLatestRequest) {
        return;
      }
      setErrors([]);
      setMessage(t(interfaceLanguage, "morsePresetApplied"));
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorSavePreferences", formatError(error))]);
    }
  }

  return (
    <section className="settings-panel" aria-labelledby="morse-settings-title">
      <h3 id="morse-settings-title">{t(interfaceLanguage, "morseSettingsTitle")}</h3>
      <p>{t(interfaceLanguage, "morseSettingsIntro")}</p>
      <div className="settings-grid">
        <label className="stacked-control"><span>{t(interfaceLanguage, "morseTone")}</span><input type="number" min="400" max="900" step="1" value={morseNumberDrafts.toneHz} onChange={(event) => updateMorseNumberDraft("toneHz", event.currentTarget.value)} onBlur={() => void commitMorseNumberDraft("toneHz")} onKeyDown={(event) => handleMorseNumberKeyDown(event, "toneHz")} /></label>
        <label className="stacked-control"><span>{t(interfaceLanguage, "morseCharacterSpeed")}</span><input type="number" min="12" max="25" step="1" value={characterWpmInputValue} disabled={morseSpeedControlsDisabled} onChange={(event) => updateMorseNumberDraft("characterWpm", event.currentTarget.value)} onBlur={() => void commitMorseNumberDraft("characterWpm")} onKeyDown={(event) => handleMorseNumberKeyDown(event, "characterWpm")} /></label>
        <label className="stacked-control"><span>{t(interfaceLanguage, "morseEffectiveSpeed")}</span><input type="number" min="5" max={morseSpeedControlsDisabled ? characterWpmInputValue : preferences.morse.characterWpm} step="1" value={effectiveWpmInputValue} disabled={morseSpeedControlsDisabled} onChange={(event) => updateMorseNumberDraft("effectiveWpm", event.currentTarget.value)} onBlur={() => void commitMorseNumberDraft("effectiveWpm")} onKeyDown={(event) => handleMorseNumberKeyDown(event, "effectiveWpm")} /></label>
        <label className="stacked-control"><span>{t(interfaceLanguage, "morseVolume")}</span><input type="range" min="0" max="1" step="0.05" value={preferences.morse.volume} onChange={(event) => void saveMorsePreference({ volume: event.currentTarget.valueAsNumber })} /></label>
        <label className="stacked-control"><span>{t(interfaceLanguage, "morseOutputMode")}</span><select value={preferences.morse.outputMode} onChange={(event) => void saveMorsePreference({ outputMode: event.currentTarget.value as WebPreferences["morse"]["outputMode"] })}>
          <option value="audio">{t(interfaceLanguage, "morseOutputAudio")}</option>
          <option value="visualBeacon">{t(interfaceLanguage, "morseOutputVisualBeacon")}</option>
          <option value="visualTape">{t(interfaceLanguage, "morseOutputVisualTape")}</option>
        </select></label>
        <label className="stacked-control"><span>{t(interfaceLanguage, "morseTimingProfile")}</span><select value={preferences.morse.timingProfile} onChange={(event) => void saveMorsePreference({ timingProfile: event.currentTarget.value as WebMorseTimingProfileName })}>
          <option value="isedParis">{t(interfaceLanguage, "morseTimingISEDParis")}</option>
          <option value="ric1Literal">{t(interfaceLanguage, "morseTimingRIC1Literal")}</option>
          <option value="general">{t(interfaceLanguage, "morseTimingGeneral")}</option>
        </select></label>
      </div>
      {morseSpeedControlsDisabled ? <p>{t(interfaceLanguage, "morseFixedTimingDescription", fixedCharacterWpm, fixedEffectiveWpm)}</p> : null}
      <button type="button" onClick={() => void applyMorsePreset()}>{t(interfaceLanguage, "morseISEDExamPreset")}</button>
      <div role="status" aria-live="polite">{message ? <p>{message}</p> : null}</div>
      {errors.length > 0 ? <div role="alert"><ul>{errors.map((error) => <li key={error}>{error}</li>)}</ul></div> : null}
    </section>
  );
}

interface SettingsProps {
  readonly activeBank: BankData;
  readonly interfaceLanguage: InterfaceLanguage;
  readonly store: ProgressStore;
  readonly now: () => string;
  readonly preferences: WebPreferences;
  readonly statusMessage: string;
  readonly onProgressImported: (data: ProgressExportV1) => void;
  readonly onReset: () => void;
  readonly onSetPreferences: (preferences: PreferencesPatch) => Promise<boolean>;
}

function Settings({ activeBank, interfaceLanguage, store, now, preferences, statusMessage, onProgressImported, onReset, onSetPreferences }: SettingsProps) {
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
      const data = await store.exportData(now(), activeBank);
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
      const parsed = JSON.parse(await readFileText(file, interfaceLanguage)) as unknown;
      const result = validateProgressImport(parsed, activeBank);
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

  async function chooseLanguage(language: WebPreferences["language"]): Promise<void> {
    try {
      const savedLatestRequest = await onSetPreferences({ language });
      if (!savedLatestRequest) {
        return;
      }
      const resolvedLanguage = resolveLanguagePreference(language);
      setErrors([]);
      setMessage(t(resolvedLanguage, "languageSaved", languagePreferenceLabel(resolvedLanguage, language)));
    } catch (error) {
      setErrors([t(interfaceLanguage, "errorLanguageSave", formatError(error))]);
    }
  }

  return (
    <section className="card settings" aria-labelledby="settings-title">
      <h2 id="settings-title">{t(interfaceLanguage, "settingsTitle")}</h2>
      <p>{t(interfaceLanguage, "settingsPrivacyCopy")}</p>
      <p>{t(interfaceLanguage, "activeBank", activeBank.bankId, activeBank.manifest.effectiveDate)}</p>
      <fieldset className="segmented-control theme-toggle">
        <legend>{t(interfaceLanguage, "themeLegend")}</legend>
        <label><input type="radio" name="theme" checked={preferences.theme === "system"} onChange={() => void chooseTheme("system")} /> {t(interfaceLanguage, "themeSystem")}</label>
        <label><input type="radio" name="theme" checked={preferences.theme === "light"} onChange={() => void chooseTheme("light")} /> {t(interfaceLanguage, "themeLight")}</label>
        <label><input type="radio" name="theme" checked={preferences.theme === "dark"} onChange={() => void chooseTheme("dark")} /> {t(interfaceLanguage, "themeDark")}</label>
      </fieldset>
      <fieldset className="segmented-control language-setting-toggle">
        <legend>{t(interfaceLanguage, "languageSettingLegend")}</legend>
        <label><input type="radio" name="language-setting" checked={preferences.language === "system"} onChange={() => void chooseLanguage("system")} /> {t(interfaceLanguage, "languageSystemDefault")}</label>
        <label><input type="radio" name="language-setting" checked={preferences.language === "en"} onChange={() => void chooseLanguage("en")} /> <span lang={englishTextLang(interfaceLanguage)}>{t(interfaceLanguage, "languageEnglish")}</span></label>
        <label><input type="radio" name="language-setting" checked={preferences.language === "fr"} onChange={() => void chooseLanguage("fr")} /> <span lang="fr">{t(interfaceLanguage, "languageFrench")}</span></label>
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

function languagePreferenceLabel(interfaceLanguage: InterfaceLanguage, language: WebPreferences["language"]): string {
  switch (language) {
    case "system":
      return t(interfaceLanguage, "languageSystemDefault");
    case "fr":
      return t(interfaceLanguage, "languageFrench");
    case "en":
      return t(interfaceLanguage, "languageEnglish");
  }
}

function readFileText(file: File, interfaceLanguage: InterfaceLanguage): Promise<string> {
  if (typeof file.text === "function") {
    return file.text();
  }
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(reader.error ?? new Error(t(interfaceLanguage, "fileReadError")));
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

function formatLocaleNumber(value: number, locale: string, maximumFractionDigits: number): string {
  return new Intl.NumberFormat(locale, {
    maximumFractionDigits,
    minimumFractionDigits: Number.isInteger(value) ? 0 : maximumFractionDigits,
  }).format(value);
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

function controlsFromScope(scope: PracticeScope, bank: BankData): { scopeKind: string; categoryId: string; subsectionId: string } {
  return {
    scopeKind: scope.type,
    categoryId: scope.type === "category" ? scope.categoryId : bank.categories[0]?.id ?? "B-001",
    subsectionId: scope.type === "subsection" ? scope.subsectionId : bank.subsections[0]?.id ?? "B-001-001",
  };
}

function CategoryNameText({ activeBank, categoryId, interfaceLanguage }: { readonly activeBank: BankData; readonly categoryId: string; readonly interfaceLanguage: InterfaceLanguage }) {
  const name = categoryNameWithLanguage(categoryId, interfaceLanguage, activeBank);
  return <span lang={languageTag(name.language)}>{name.text}</span>;
}

function ScopeValue({ activeBank, interfaceLanguage, scope }: { readonly activeBank: BankData; readonly interfaceLanguage: InterfaceLanguage; readonly scope: PracticeScope }) {
  if (scope.type === "category") {
    return <CategoryNameText activeBank={activeBank} categoryId={scope.categoryId} interfaceLanguage={interfaceLanguage} />;
  }
  if (scope.type === "subsection") {
    return <>{scope.subsectionId}{colonSeparator(interfaceLanguage)}<span lang={englishTextLang(interfaceLanguage)}>{subsectionTitle(scope.subsectionId, activeBank)}</span></>;
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

function hasUnfinishedPracticeSession(session: PracticeSession | null): boolean {
  if (session === null || session.selectedByQuestionId.size === 0) {
    return false;
  }
  if (session.mode === "review-later") {
    return !session.submitted;
  }
  return session.selectedByQuestionId.size < session.items.length;
}

function buildReadiness(bank: BankData, progress: readonly QuestionProgressRecord[], attempts: readonly ExamAttempt[], now: string): ReadinessResult {
  return computeReadiness({
    bankId: bank.bankId,
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

function mergeBankProgress(current: readonly QuestionProgressRecord[], nextBankProgress: readonly QuestionProgressRecord[], bankId: string): readonly QuestionProgressRecord[] {
  return [...current.filter((record) => record.bankId !== bankId), ...nextBankProgress]
    .toSorted((a, b) => a.questionId.localeCompare(b.questionId));
}

function mergeBankExamAttempts(current: readonly ExamAttempt[], nextBankAttempts: readonly ExamAttempt[], bankId: string): readonly ExamAttempt[] {
  return [...current.filter((attempt) => attempt.bankId !== bankId), ...nextBankAttempts]
    .toSorted((a, b) => a.submittedAt.localeCompare(b.submittedAt));
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
