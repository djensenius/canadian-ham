import { useEffect, useMemo, useRef, useState } from "react";
import {
  MORSE_CODE_TABLE,
  dailyStreak,
  emptyMorseCourseProgress,
  learnedCharactersForProgress,
  lessonState,
  parseMorseCourseFixture,
  recordMorseCharacterResults,
  recordMorseLessonAttempt,
  selectWeakestCharacters,
  type MorseCourseLesson,
  type MorseCourseProgressExport,
} from "@canadian-ham/morse-engine";

import courseFixture from "../../../../../fixtures/morse/course.json";
import { WebMorsePlayer } from "../../lib/morseAudio";
import type { InterfaceLanguage } from "../../lib/i18n";
import { t } from "../../lib/i18n";
import type { ProgressStore, WebPreferences } from "../../lib/progressStore";

const course = parseMorseCourseFixture(courseFixture);

type Exercise =
  | { readonly kind: "meet"; readonly character: string }
  | { readonly kind: "choose"; readonly character: string; readonly options: readonly string[] }
  | { readonly kind: "type-character"; readonly character: string }
  | { readonly kind: "type-group"; readonly text: string };

interface SessionState {
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

export function MorseCoursePanel({ interfaceLanguage, preferences, store, now }: {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly preferences: WebPreferences;
  readonly store: ProgressStore;
  readonly now: () => string;
}) {
  const [progress, setProgress] = useState<MorseCourseProgressExport>(() => emptyMorseCourseProgress(course.courseId));
  const [loadError, setLoadError] = useState<string | null>(null);
  const [session, setSession] = useState<SessionState | null>(null);
  const [typedAnswer, setTypedAnswer] = useState("");
  const [liveMessage, setLiveMessage] = useState("");
  const playerRef = useRef<WebMorsePlayer | null>(null);

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
    return () => { cancelled = true; playerRef.current?.stop(); };
  }, [store]);

  const learned = useMemo(() => learnedCharactersForProgress(course, progress), [progress]);
  const weakest = useMemo(() => selectWeakestCharacters(progress.characterStats, learned, 5), [learned, progress.characterStats]);
  const lessonsCompleted = progress.lessonProgress.filter((record) => record.bestAccuracy >= course.unlockAccuracy).length;
  const streak = dailyStreak(progress.dailyActivity, now());

  async function play(text: string): Promise<void> {
    playerRef.current ??= new WebMorsePlayer();
    await playerRef.current.playText(text, preferences.morse);
  }

  function startLesson(lesson: MorseCourseLesson): void {
    if (lessonState(course, progress, lesson.id) === "locked") return;
    const focus = lesson.newCharacters.at(-1) ?? lesson.learnedCharacters.at(-1) ?? "K";
    const group = lesson.learnedCharacters.slice(-5).join("").padEnd(5, focus).slice(0, 5);
    setTypedAnswer("");
    setSession({
      mode: "lesson",
      lesson,
      exercises: [
        { kind: "meet", character: focus },
        { kind: "choose", character: focus, options: lesson.learnedCharacters.slice(0, 4).includes(focus) ? lesson.learnedCharacters.slice(0, 4) : [...lesson.learnedCharacters.slice(0, 3), focus] },
        { kind: "type-character", character: focus },
        { kind: "type-group", text: group },
      ],
      index: 0,
      correct: 0,
      total: 0,
      characterResults: [],
      feedback: "",
      done: false,
    });
  }

  function startReview(): void {
    const reviewCharacters = weakest.length > 0 ? weakest : learned.slice(0, 5);
    setTypedAnswer("");
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
  }

  async function saveSession(next: SessionState): Promise<void> {
    const attemptedAt = now();
    const nextProgress = next.mode === "lesson" && next.lesson !== null
      ? recordMorseLessonAttempt({ course, progress, lessonId: next.lesson.id, correct: next.correct, total: Math.max(1, next.total), characterResults: next.characterResults, attemptedAt })
      : recordMorseCharacterResults(progress, next.characterResults, attemptedAt);
    await store.putMorseCourseProgress(nextProgress);
    setProgress(nextProgress);
  }

  function answer(correct: boolean, results: readonly { readonly character: string; readonly correct: boolean }[]): void {
    if (session === null) return;
    const scored = session.exercises[session.index]?.kind !== "meet";
    const nextTotal = session.total + (scored ? 1 : 0);
    const nextCorrect = session.correct + (scored && correct ? 1 : 0);
    const isLast = session.index >= session.exercises.length - 1;
    const feedback = scored ? (correct ? t(interfaceLanguage, "morseCourseFeedbackCorrect") : t(interfaceLanguage, "morseCourseFeedbackIncorrect")) : t(interfaceLanguage, "morseCourseMeetComplete");
    const nextSession = {
      ...session,
      index: isLast ? session.index : session.index + 1,
      correct: nextCorrect,
      total: nextTotal,
      characterResults: [...session.characterResults, ...results],
      feedback,
      done: isLast,
    };
    setSession(nextSession);
    setTypedAnswer("");
    setLiveMessage(feedback);
    if (isLast) void saveSession(nextSession);
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
                <button type="button" className={`morse-lesson-node ${state}`} disabled={state === "locked"} aria-current={state === "current" ? "step" : undefined} onClick={() => startLesson(lesson)}>
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
        <section className="morse-session" aria-labelledby="morse-session-title">
          <h4 id="morse-session-title">{session.mode === "lesson" && session.lesson !== null ? t(interfaceLanguage, "morseCourseSessionLesson", session.lesson.lessonNumber) : t(interfaceLanguage, "morseCourseReviewTitle")}</h4>
          <p>{t(interfaceLanguage, "morseCourseSessionProgress", session.index + 1, session.exercises.length)}</p>
          {renderExercise(currentExercise, play, typedAnswer, setTypedAnswer, answer, interfaceLanguage)}
          {session.feedback ? <p role="status">{session.feedback}</p> : null}
          {session.done ? <LessonSummary interfaceLanguage={interfaceLanguage} session={session} /> : null}
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

function LessonSummary({ interfaceLanguage, session }: { readonly interfaceLanguage: InterfaceLanguage; readonly session: SessionState }) {
  const percent = session.total === 0 ? 100 : Math.round((session.correct / session.total) * 100);
  return <section className="morse-summary" aria-labelledby="morse-summary-title"><h5 id="morse-summary-title">{t(interfaceLanguage, "morseCourseSummary")}</h5><p>{t(interfaceLanguage, "morseCourseAccuracy", percent)}</p><p>{percent >= 90 ? t(interfaceLanguage, "morseCourseUnlocked") : t(interfaceLanguage, "morseCourseTryAgain")}</p></section>;
}

function stateLabel(interfaceLanguage: InterfaceLanguage, state: "locked" | "current" | "completed"): string {
  switch (state) {
    case "locked": return t(interfaceLanguage, "morseCourseStateLocked");
    case "current": return t(interfaceLanguage, "morseCourseStateCurrent");
    case "completed": return t(interfaceLanguage, "morseCourseStateCompleted");
  }
}
