import { useEffect, useMemo, useRef, useState } from "react";
import {
  MORSE_CODE_TABLE,
  buildMorseLessonExercises,
  dailyStreak,
  emptyMorseCourseProgress,
  learnedCharactersForProgress,
  lessonState,
  parseMorseCourseFixture,
  recordMorseCharacterResults,
  recordMorseLessonAttempt,
  selectWeakestCharacters,
  type MorseCourseExercise as Exercise,
  type MorseCourseLesson,
  type MorseCourseProgressExport,
} from "@canadian-ham/morse-engine";

import courseFixture from "../../../../../fixtures/morse/course.json";
import { MorseOutputView, useWebMorseOutput } from "../../lib/morseOutput";
import type { InterfaceLanguage } from "../../lib/i18n";
import { t } from "../../lib/i18n";
import type { ProgressStore, WebPreferences } from "../../lib/progressStore";
import type { MorsePlaybackCoordinator } from "../copyExam/MorseCopyExamSection";

const course = parseMorseCourseFixture(courseFixture);

const noopPlaybackCoordinator: MorsePlaybackCoordinator = {
  register: () => () => {},
  claim: () => {},
};

export interface SessionState {
  readonly mode: "lesson" | "review";
  readonly lesson: MorseCourseLesson | null;
  readonly exercises: readonly Exercise[];
  readonly index: number;
  readonly correct: number;
  readonly total: number;
  readonly characterResults: readonly { readonly character: string; readonly correct: boolean }[];
  readonly feedback: string;
  readonly done: boolean;
}

export function MorseCoursePanel({ interfaceLanguage, preferences, store, now, seedFactory, playbackCoordinator = noopPlaybackCoordinator }: {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly preferences: WebPreferences;
  readonly store: ProgressStore;
  readonly now: () => string;
  readonly seedFactory: () => string;
  readonly playbackCoordinator?: MorsePlaybackCoordinator;
}) {
  const [progress, setProgress] = useState<MorseCourseProgressExport>(() => emptyMorseCourseProgress(course.courseId));
  const [loadError, setLoadError] = useState<string | null>(null);
  const [session, setSession] = useState<SessionState | null>(null);
  const [sessionFocusRequest, setSessionFocusRequest] = useState(0);
  const [typedAnswer, setTypedAnswer] = useState("");
  const [liveMessage, setLiveMessage] = useState("");
  const [actionError, setActionError] = useState<string | null>(null);
  const [saveState, setSaveState] = useState<"idle" | "saving" | "saved" | "failed">("idle");
  const output = useWebMorseOutput(interfaceLanguage);
  // Bumped on every play and every stop so a cancelled start is ignored, not reported as an error.
  const playbackGenerationRef = useRef(0);
  const sessionRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    let cancelled = false;
    store.getMorseCourseProgress()
      .then((stored) => {
        if (!cancelled && stored !== undefined && stored.courseId === course.courseId) {
          setProgress(stored);
        }
      })
      .catch((error: unknown) => {
        if (!cancelled) setLoadError(error instanceof Error ? error.message : String(error));
      });
    const unregister = playbackCoordinator.register("course", () => {
      playbackGenerationRef.current += 1;
      output.stop();
    });
    return () => {
      cancelled = true;
      unregister();
      playbackGenerationRef.current += 1;
      void output.close();
    };
  }, [output.close, output.stop, playbackCoordinator, store]);

  useEffect(() => {
    if (session !== null && !session.done) {
      const reduceMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
      sessionRef.current?.scrollIntoView?.({ block: "start", behavior: reduceMotion ? "auto" : "smooth" });
      sessionRef.current?.focus({ preventScroll: true });
    }
  }, [sessionFocusRequest]);

  const learned = useMemo(() => learnedCharactersForProgress(course, progress), [progress]);
  const weakest = useMemo(() => selectWeakestCharacters(progress.characterStats, learned, 5), [learned, progress.characterStats]);
  const lessonsCompleted = progress.lessonProgress.filter((record) => record.bestAccuracy >= course.unlockAccuracy).length;
  const todayLocalDate = localDateString(now());
  const streak = dailyStreak(progress.dailyActivity, todayLocalDate);

  async function play(text: string): Promise<void> {
    playbackCoordinator.claim("course");
    const generation = playbackGenerationRef.current + 1;
    playbackGenerationRef.current = generation;
    try {
      const handle = await output.playText(text, preferences.morse);
      if (generation !== playbackGenerationRef.current) {
        handle.stop();
        return;
      }
      setActionError(null);
    } catch (error) {
      if (generation !== playbackGenerationRef.current) return;
      const message = t(interfaceLanguage, "morsePlaybackError", formatError(error));
      setActionError(message);
      setLiveMessage(message);
    }
  }

  function startLesson(lesson: MorseCourseLesson): void {
    if (lessonState(course, progress, lesson.id) === "locked") return;
    const exercises = buildMorseLessonExercises({ lesson, progress, seed: seedFactory() });
    resetSessionFeedback();
    setSession({
      mode: "lesson",
      lesson,
      exercises,
      index: 0,
      correct: 0,
      total: 0,
      characterResults: [],
      feedback: "",
      done: false,
    });
    setSessionFocusRequest((value) => value + 1);
  }

  function startReview(): void {
    const reviewCharacters = weakest.length > 0 ? weakest : learned.slice(0, 5);
    resetSessionFeedback();
    setSession({
      mode: "review",
      lesson: null,
      exercises: reviewCharacters.map((character) => ({ kind: "type-character", character })),
      index: 0,
      correct: 0,
      total: 0,
      characterResults: [],
      feedback: "",
      done: false,
    });
    setSessionFocusRequest((value) => value + 1);
  }

  function resetSessionFeedback(): void {
    setTypedAnswer("");
    setLiveMessage("");
    setActionError(null);
    setSaveState("idle");
  }

  async function saveSession(next: SessionState): Promise<void> {
    const attemptedAt = now();
    const nextProgress = next.mode === "lesson" && next.lesson !== null
      ? recordMorseLessonAttempt({ course, progress, lessonId: next.lesson.id, correct: next.correct, total: Math.max(1, next.total), characterResults: next.characterResults, attemptedAt, activityDate: localDateString(attemptedAt) })
      : recordMorseCharacterResults(progress, next.characterResults, attemptedAt);
    setSaveState("saving");
    setActionError(null);
    try {
      await store.putMorseCourseProgress(nextProgress);
      setProgress(nextProgress);
      setSaveState("saved");
    } catch (error) {
      const message = t(interfaceLanguage, "morseCourseSaveError", formatError(error));
      setSaveState("failed");
      setActionError(message);
      setLiveMessage(message);
    }
  }

  function answer(correct: boolean, results: readonly { readonly character: string; readonly correct: boolean }[]): void {
    if (session === null) return;
    const nextSession = answerMorseCourseSession(session, correct, results, interfaceLanguage);
    if (nextSession === session) return;
    setSession(nextSession);
    setTypedAnswer("");
    setLiveMessage(nextSession.feedback);
    if (nextSession.done) void saveSession(nextSession);
  }

  const currentExercise = session?.exercises[session.index];

  return (
    <section className="morse-course" aria-labelledby="morse-course-title">
      <div className="morse-course-header">
        <div>
          <p className="eyebrow">{t(interfaceLanguage, "morseCourseEyebrow")}</p>
          <h3 id="morse-course-title">{t(interfaceLanguage, "morseCourseTitle")}</h3>
          <p>{t(interfaceLanguage, "morseCourseIntro")}</p>
        </div>
        <dl className="morse-course-stats">
          <div><dt>{t(interfaceLanguage, "morseCourseStreak")}</dt><dd>{t(interfaceLanguage, "morseCourseStreakDays", streak)}</dd></div>
          <div><dt>{t(interfaceLanguage, "morseCourseLessonsCompleted")}</dt><dd>{t(interfaceLanguage, "morseCourseLessonsCompletedValue", lessonsCompleted, course.lessons.length)}</dd></div>
        </dl>
      </div>
      {loadError !== null ? <p role="alert">{t(interfaceLanguage, "morseCourseLoadError", loadError)}</p> : null}
      {actionError !== null ? <p role="alert">{actionError}</p> : null}
      <div className="action-row">
        <button type="button" onClick={startReview}>{t(interfaceLanguage, "morseCourseReviewWeak")}</button>
        <p>{t(interfaceLanguage, "morseCourseWeakest", weakest.join(" ") || learned.join(" "))}</p>
      </div>
      <div className="morse-unit-path" aria-label={t(interfaceLanguage, "morseCoursePathAria")}>{course.units.map((unit) => (
        <section className="morse-unit" aria-labelledby={`${unit.id}-title`} key={unit.id}>
          <h4 id={`${unit.id}-title`}>{t(interfaceLanguage, "morseCourseUnit", unit.unitNumber)}</h4>
          <ol>
            {unit.lessonIds.map((lessonId) => {
              const lesson = course.lessons.find((entry) => entry.id === lessonId)!;
              const state = lessonState(course, progress, lesson.id);
              return <li key={lesson.id}>
                <button type="button" className={`morse-lesson-node ${state}`} disabled={state === "locked"} aria-label={t(interfaceLanguage, "morseCourseLessonAccessibleLabel", lesson.lessonNumber, lesson.newCharacters.join(" "), stateLabel(interfaceLanguage, state))} aria-current={state === "current" ? "step" : undefined} onClick={() => startLesson(lesson)}>
                  <span>{t(interfaceLanguage, "morseCourseLessonLabel", lesson.lessonNumber)}</span>
                  <strong>{lesson.newCharacters.join(" ")}</strong>
                  <small>{stateLabel(interfaceLanguage, state)}</small>
                </button>
              </li>;
            })}
          </ol>
        </section>
      ))}</div>
      {session !== null && currentExercise !== undefined ? (
        <section className="morse-session" aria-labelledby="morse-session-title" ref={sessionRef} tabIndex={-1}>
          <h4 id="morse-session-title">{session.mode === "lesson" && session.lesson !== null ? t(interfaceLanguage, "morseCourseSessionLesson", session.lesson.lessonNumber) : t(interfaceLanguage, "morseCourseReviewTitle")}</h4>
          <p>{t(interfaceLanguage, "morseCourseSessionProgress", session.index + 1, session.exercises.length)}</p>
          {!session.done ? renderExercise(currentExercise, play, typedAnswer, setTypedAnswer, answer, interfaceLanguage) : null}
          <MorseOutputView state={output.state} interfaceLanguage={interfaceLanguage} />
          {session.feedback ? <p>{session.feedback}</p> : null}
          {session.done ? <LessonSummary interfaceLanguage={interfaceLanguage} saveState={saveState} session={session} /> : null}
          <div className="sr-only" aria-live="polite" aria-atomic="true">{liveMessage}</div>
        </section>
      ) : null}
    </section>
  );
}

function renderExercise(
  exercise: Exercise,
  play: (text: string) => Promise<void>,
  typedAnswer: string,
  setTypedAnswer: (value: string) => void,
  answer: (correct: boolean, results: readonly { readonly character: string; readonly correct: boolean }[]) => void,
  interfaceLanguage: InterfaceLanguage,
) {
  if (exercise.kind === "meet") {
    const code = MORSE_CODE_TABLE[exercise.character as keyof typeof MORSE_CODE_TABLE];
    return <div className="morse-exercise"><p>{t(interfaceLanguage, "morseCourseMeet", exercise.character)}</p><p className="morse-code-visual" aria-label={t(interfaceLanguage, "morseCourseCodeFor", exercise.character, code)}>{code}</p><button type="button" onClick={() => void play(exercise.character)}>{t(interfaceLanguage, "morseCoursePlayCharacter")}</button><button type="button" className="primary-button" onClick={() => answer(true, [])}>{t(interfaceLanguage, "next")}</button></div>;
  }
  if (exercise.kind === "choose") {
    return <div className="morse-exercise"><p>{t(interfaceLanguage, "morseCourseChoose")}</p><button type="button" onClick={() => void play(exercise.character)}>{t(interfaceLanguage, "morsePlay")}</button><div className="morse-choice-grid">{exercise.options.map((option) => <button type="button" key={option} onClick={() => answer(option === exercise.character, [{ character: exercise.character, correct: option === exercise.character }])}>{option}</button>)}</div></div>;
  }
  const expected = exercise.kind === "type-character" ? exercise.character : exercise.text;
  return <form className="morse-exercise" onSubmit={(event) => { event.preventDefault(); const normalized = typedAnswer.trim().toUpperCase(); const correct = normalized === expected; answer(correct, Array.from(expected).map((character, index) => ({ character, correct: normalized[index] === character }))); }}><p>{exercise.kind === "type-character" ? t(interfaceLanguage, "morseCourseTypeCharacter") : t(interfaceLanguage, "morseCourseTypeGroup")}</p><button type="button" onClick={() => void play(expected)}>{t(interfaceLanguage, "morsePlay")}</button><label className="stacked-control"><span>{t(interfaceLanguage, "morseCourseYourCopy")}</span><input value={typedAnswer} autoCapitalize="characters" onChange={(event) => setTypedAnswer(event.currentTarget.value)} /></label><button type="submit" className="primary-button">{t(interfaceLanguage, "morseCourseCheck")}</button></form>;
}

export function answerMorseCourseSession(
  session: SessionState,
  correct: boolean,
  results: readonly { readonly character: string; readonly correct: boolean }[],
  interfaceLanguage: InterfaceLanguage,
): SessionState {
  if (session.done) return session;
  const scored = session.exercises[session.index]?.kind !== "meet";
  const nextTotal = session.total + (scored ? 1 : 0);
  const nextCorrect = session.correct + (scored && correct ? 1 : 0);
  const isLast = session.index >= session.exercises.length - 1;
  const expected = expectedAnswer(session.exercises[session.index]);
  const feedback = scored ? (correct ? t(interfaceLanguage, "morseCourseFeedbackCorrect") : t(interfaceLanguage, "morseCourseFeedbackIncorrect", expected)) : t(interfaceLanguage, "morseCourseMeetComplete");
  return {
    ...session,
    index: isLast ? session.index : session.index + 1,
    correct: nextCorrect,
    total: nextTotal,
    characterResults: [...session.characterResults, ...results],
    feedback,
    done: isLast,
  };
}

function expectedAnswer(exercise: Exercise | undefined): string {
  if (exercise === undefined) return "";
  switch (exercise.kind) {
    case "meet": return exercise.character;
    case "choose": return exercise.character;
    case "type-character": return exercise.character;
    case "type-group": return exercise.text;
  }
}

function localDateString(value: string): string {
  const date = new Date(value);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function LessonSummary({ interfaceLanguage, saveState, session }: { readonly interfaceLanguage: InterfaceLanguage; readonly saveState: "idle" | "saving" | "saved" | "failed"; readonly session: SessionState }) {
  const percent = session.total === 0 ? 100 : Math.round((session.correct / session.total) * 100);
  const savedMessage = morseCourseSummaryMessage(interfaceLanguage, session, percent, course.lessons.length);
  const progressMessage = saveState === "saving"
    ? t(interfaceLanguage, "morseCourseSavingProgress")
    : saveState === "failed"
      ? t(interfaceLanguage, "morseCourseProgressNotSaved")
      : savedMessage;
  return <section className="morse-summary" aria-labelledby="morse-summary-title"><h5 id="morse-summary-title">{t(interfaceLanguage, "morseCourseSummary")}</h5><p>{t(interfaceLanguage, "morseCourseAccuracy", percent)}</p><p>{progressMessage}</p></section>;
}

export function morseCourseSummaryMessage(interfaceLanguage: InterfaceLanguage, session: SessionState, percent: number, lessonCount: number): string {
  if (session.mode === "review") {
    return t(interfaceLanguage, "morseCourseReviewComplete");
  }
  const isFinalLesson = session.lesson !== null && session.lesson.lessonNumber >= lessonCount;
  if (percent >= 90) {
    return isFinalLesson ? t(interfaceLanguage, "morseCourseComplete") : t(interfaceLanguage, "morseCourseUnlocked");
  }
  return isFinalLesson ? t(interfaceLanguage, "morseCourseTryFinalAgain") : t(interfaceLanguage, "morseCourseTryAgain");
}

function formatError(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function stateLabel(interfaceLanguage: InterfaceLanguage, state: "locked" | "current" | "completed"): string {
  switch (state) {
    case "locked": return t(interfaceLanguage, "morseCourseStateLocked");
    case "current": return t(interfaceLanguage, "morseCourseStateCurrent");
    case "completed": return t(interfaceLanguage, "morseCourseStateCompleted");
  }
}
