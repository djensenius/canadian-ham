import { generateMorseExamText, profileForName, textToTimedMorse, type MorseCopyDiff, type MorseProfileName } from "@canadian-ham/morse-engine";
import { useEffect, useMemo, useRef, useState } from "react";

import { WebMorsePlayer } from "../../lib/morseAudio";
import { interfaceLanguageTag, t, type InterfaceLanguage } from "../../lib/i18n";
import { morseTimingFromPreferences } from "../../lib/morseSettings";
import type { WebPreferences } from "../../lib/progressStore";
import { buildCopyDiff, containsDotDashNotation, copyPracticePassage, diffOperationLabel, type MorseCopyPassageLength } from "./copyExam";

interface MorseCopyExamSectionProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly preferences: WebPreferences;
  readonly reviewDurationSeconds?: number;
}

type CopyStage = "idle" | "playing" | "ready" | "graded";
type ExamStage = "idle" | "playing" | "review" | "graded";

interface CopyPassageState {
  readonly text: string;
  readonly title: string;
  readonly durationSeconds: number;
}

interface ExamPassageState {
  readonly text: string;
  readonly durationSeconds: number;
  readonly weightedCharacters: number;
}

const defaultExamReviewSeconds = 120;

export function MorseCopyExamSection({ interfaceLanguage, preferences, reviewDurationSeconds = defaultExamReviewSeconds }: MorseCopyExamSectionProps) {
  const locale = interfaceLanguageTag(interfaceLanguage);
  return (
    <div className="morse-copy-exam-grid">
      <MorseCopyPracticePanel interfaceLanguage={interfaceLanguage} locale={locale} preferences={preferences} />
      <MorseExamPanel interfaceLanguage={interfaceLanguage} locale={locale} preferences={preferences} reviewDurationSeconds={reviewDurationSeconds} />
    </div>
  );
}

function MorseCopyPracticePanel({ interfaceLanguage, locale, preferences }: { readonly interfaceLanguage: InterfaceLanguage; readonly locale: string; readonly preferences: WebPreferences }) {
  const playerRef = useRef<WebMorsePlayer | null>(null);
  const finishTimerRef = useRef<number | null>(null);
  const generationRef = useRef(0);
  const passageIndexRef = useRef(0);
  const [length, setLength] = useState<MorseCopyPassageLength>("short");
  const [stage, setStage] = useState<CopyStage>("idle");
  const [passage, setPassage] = useState<CopyPassageState | null>(null);
  const [copy, setCopy] = useState("");
  const [diff, setDiff] = useState<MorseCopyDiff | null>(null);
  const [status, setStatus] = useState("");
  const [liveStatus, setLiveStatus] = useState("");

  useEffect(() => () => {
    generationRef.current += 1;
    clearWindowTimer(finishTimerRef.current);
    void playerRef.current?.close();
  }, []);

  async function start(): Promise<void> {
    const selected = copyPracticePassage(length, passageIndexRef.current);
    passageIndexRef.current += 1;
    const timing = morseTimingFromPreferences(preferences.morse);
    const durationSeconds = textToTimedMorse(selected.text, timing).totalDurationSeconds;
    const generation = generationRef.current + 1;
    generationRef.current = generation;
    clearWindowTimer(finishTimerRef.current);
    playerRef.current ??= new WebMorsePlayer();
    setPassage({ text: selected.text, title: selected.title, durationSeconds });
    setCopy("");
    setDiff(null);
    setStage("playing");
    setStatus(t(interfaceLanguage, "morseCopyPracticeStarted"));
    setLiveStatus("");
    try {
      const handle = await playerRef.current.playText(selected.text, preferences.morse);
      if (generation !== generationRef.current) {
        handle.stop();
        return;
      }
      finishTimerRef.current = window.setTimeout(() => {
        if (generation !== generationRef.current) {
          return;
        }
        setStage("ready");
        const message = t(interfaceLanguage, "morseCopyPracticeReady");
        setStatus(message);
        setLiveStatus(message);
      }, Math.ceil(handle.durationSeconds * 1000) + 60);
    } catch (error) {
      if (generation !== generationRef.current) {
        return;
      }
      setStage("idle");
      const message = t(interfaceLanguage, "morsePlaybackError", formatError(error));
      setStatus(message);
      setLiveStatus(message);
    }
  }

  function stop(): void {
    generationRef.current += 1;
    clearWindowTimer(finishTimerRef.current);
    playerRef.current?.stop();
    setStage(passage === null ? "idle" : "ready");
    const message = t(interfaceLanguage, "morsePlaybackStopped");
    setStatus(message);
    setLiveStatus(message);
  }

  function grade(): void {
    if (passage === null) {
      return;
    }
    const nextDiff = buildCopyDiff(passage.text, copy);
    setDiff(nextDiff);
    setStage("graded");
    const message = t(interfaceLanguage, "morseCopyPracticeChecked", String(nextDiff.score.errors));
    setStatus(message);
    setLiveStatus(message);
  }

  const formattedDuration = passage === null ? null : formatSeconds(passage.durationSeconds, locale);
  return (
    <section className="morse-copy-panel" aria-labelledby="morse-copy-practice-heading">
      <h3 id="morse-copy-practice-heading">{t(interfaceLanguage, "morseCopyPracticeTitle")}</h3>
      <p>{t(interfaceLanguage, "morseCopyPracticeIntro")}</p>
      <div className="settings-grid">
        <label className="stacked-control">
          <span>{t(interfaceLanguage, "morseCopyLength")}</span>
          <select value={length} disabled={stage === "playing"} onChange={(event) => setLength(event.currentTarget.value as MorseCopyPassageLength)}>
            <option value="short">{t(interfaceLanguage, "morseCopyLengthShort")}</option>
            <option value="medium">{t(interfaceLanguage, "morseCopyLengthMedium")}</option>
            <option value="long">{t(interfaceLanguage, "morseCopyLengthLong")}</option>
          </select>
        </label>
      </div>
      <div className="action-row">
        <button type="button" className="primary-button" disabled={stage === "playing"} onClick={() => void start()}>{t(interfaceLanguage, "morseCopyStart")}</button>
        <button type="button" disabled={stage !== "playing"} onClick={stop}>{t(interfaceLanguage, "morseStop")}</button>
        <button type="button" disabled={passage === null || stage === "playing"} onClick={grade}>{t(interfaceLanguage, "morseCopyCheck")}</button>
      </div>
      {formattedDuration ? <p className="morse-duration">{t(interfaceLanguage, "morseDuration", formattedDuration)}</p> : null}
      <label className="stacked-control morse-copy-input">
        <span>{t(interfaceLanguage, "morseCopyYourCopy")}</span>
        <textarea value={copy} disabled={passage === null} rows={5} onChange={(event) => setCopy(event.currentTarget.value)} />
      </label>
      {containsDotDashNotation(copy) ? <p className="warning-text" role="alert">{t(interfaceLanguage, "morseDotDashWarning")}</p> : null}
      <div className="morse-copy-status">{status ? <p>{status}</p> : null}</div>
      <div className="sr-only" role="status" aria-live="polite" aria-atomic="true">{liveStatus}</div>
      {diff ? <MorseDiffView diff={diff} interfaceLanguage={interfaceLanguage} expectedText={passage?.text ?? ""} /> : null}
    </section>
  );
}

function MorseExamPanel({ interfaceLanguage, locale, preferences, reviewDurationSeconds }: { readonly interfaceLanguage: InterfaceLanguage; readonly locale: string; readonly preferences: WebPreferences; readonly reviewDurationSeconds: number }) {
  const playerRef = useRef<WebMorsePlayer | null>(null);
  const playbackTimerRef = useRef<number | null>(null);
  const reviewIntervalRef = useRef<number | null>(null);
  const reviewFinishTimerRef = useRef<number | null>(null);
  const generationRef = useRef(0);
  const [profileName, setProfileName] = useState<MorseProfileName>("isedParis");
  const [stage, setStage] = useState<ExamStage>("idle");
  const [exam, setExam] = useState<ExamPassageState | null>(null);
  const [copy, setCopy] = useState("");
  const [diff, setDiff] = useState<MorseCopyDiff | null>(null);
  const [reviewRemaining, setReviewRemaining] = useState(reviewDurationSeconds);
  const [status, setStatus] = useState("");
  const [liveStatus, setLiveStatus] = useState("");

  useEffect(() => () => {
    generationRef.current += 1;
    clearWindowTimer(playbackTimerRef.current);
    clearWindowTimer(reviewIntervalRef.current);
    clearWindowTimer(reviewFinishTimerRef.current);
    void playerRef.current?.close();
  }, []);

  async function start(): Promise<void> {
    const generation = generationRef.current + 1;
    generationRef.current = generation;
    clearWindowTimer(playbackTimerRef.current);
    clearWindowTimer(reviewIntervalRef.current);
    clearWindowTimer(reviewFinishTimerRef.current);
    const profile = profileForName(profileName);
    const generated = generateMorseExamText({ profile, seed: `web-${profileName}-${Date.now().toString(36)}` });
    const examPreferences = { ...preferences.morse, timingProfile: profileName, characterWpm: 12, effectiveWpm: 5 } as const;
    playerRef.current ??= new WebMorsePlayer();
    setExam({ text: generated.text, durationSeconds: generated.durationSeconds, weightedCharacters: generated.weightedCharacters });
    setCopy("");
    setDiff(null);
    setReviewRemaining(reviewDurationSeconds);
    setStage("playing");
    setStatus(t(interfaceLanguage, "morseExamPlaybackStarted"));
    setLiveStatus("");
    try {
      const handle = await playerRef.current.playText(generated.text, examPreferences);
      if (generation !== generationRef.current) {
        handle.stop();
        return;
      }
      playbackTimerRef.current = window.setTimeout(() => {
        if (generation !== generationRef.current) {
          return;
        }
        startReviewTimer(generation, generated.text);
      }, Math.ceil(handle.durationSeconds * 1000) + 60);
    } catch (error) {
      if (generation !== generationRef.current) {
        return;
      }
      setStage("idle");
      const message = t(interfaceLanguage, "morsePlaybackError", formatError(error));
      setStatus(message);
      setLiveStatus(message);
    }
  }

  function startReviewTimer(generation: number, expected: string): void {
    setStage("review");
    setReviewRemaining(reviewDurationSeconds);
    const message = t(interfaceLanguage, "morseExamReviewStarted", formatWholeSeconds(reviewDurationSeconds, locale));
    setStatus(message);
    setLiveStatus(message);
    reviewIntervalRef.current = window.setInterval(() => {
      setReviewRemaining((remaining) => Math.max(0, remaining - 1));
    }, 1000);
    reviewFinishTimerRef.current = window.setTimeout(() => {
      if (generation !== generationRef.current) {
        return;
      }
      clearWindowTimer(reviewIntervalRef.current);
      const nextDiff = buildCopyDiff(expected, copyRef.current);
      setDiff(nextDiff);
      setStage("graded");
      const gradedMessage = nextDiff.score.passed
        ? t(interfaceLanguage, "morseExamPassed", String(nextDiff.score.errors))
        : t(interfaceLanguage, "morseExamFailed", String(nextDiff.score.errors), String(nextDiff.score.markPercent));
      setStatus(gradedMessage);
      setLiveStatus(gradedMessage);
    }, reviewDurationSeconds * 1000);
  }

  const copyRef = useRef(copy);
  useEffect(() => {
    copyRef.current = copy;
  }, [copy]);

  const formattedDuration = exam === null ? null : formatSeconds(exam.durationSeconds, locale);
  const formattedWeighted = exam === null ? null : formatLocaleNumber(exam.weightedCharacters, locale, 0);
  const reviewText = formatWholeSeconds(reviewRemaining, locale);
  return (
    <section className="morse-exam-panel" aria-labelledby="morse-exam-heading">
      <h3 id="morse-exam-heading">{t(interfaceLanguage, "morseExamTitle")}</h3>
      <p>{t(interfaceLanguage, "morseExamIntro")}</p>
      <div className="settings-grid">
        <label className="stacked-control">
          <span>{t(interfaceLanguage, "morseExamProfile")}</span>
          <select value={profileName} disabled={stage === "playing" || stage === "review"} onChange={(event) => setProfileName(event.currentTarget.value as MorseProfileName)}>
            <option value="isedParis">{t(interfaceLanguage, "morseTimingISEDParis")}</option>
            <option value="ric1Literal">{t(interfaceLanguage, "morseTimingRIC1Literal")}</option>
          </select>
        </label>
      </div>
      <div className="action-row">
        <button type="button" className="primary-button" disabled={stage === "playing" || stage === "review"} onClick={() => void start()}>{t(interfaceLanguage, "morseExamStart")}</button>
      </div>
      {formattedDuration && formattedWeighted ? <p className="morse-duration">{t(interfaceLanguage, "morseExamGeneratedSummary", formattedWeighted, formattedDuration)}</p> : null}
      {stage === "review" ? <p className="timer-pill" role="timer" aria-live="off">{t(interfaceLanguage, "morseExamReviewRemaining", reviewText)}</p> : null}
      <label className="stacked-control morse-copy-input">
        <span>{t(interfaceLanguage, "morseCopyYourCopy")}</span>
        <textarea value={copy} disabled={exam === null || stage === "graded"} rows={6} onChange={(event) => setCopy(event.currentTarget.value)} />
      </label>
      {containsDotDashNotation(copy) ? <p className="warning-text" role="alert">{t(interfaceLanguage, "morseDotDashWarning")}</p> : null}
      <div className="morse-copy-status">{status ? <p>{status}</p> : null}</div>
      <div className="sr-only" role="status" aria-live="polite" aria-atomic="true">{liveStatus}</div>
      {diff ? <MorseDiffView diff={diff} interfaceLanguage={interfaceLanguage} expectedText={exam?.text ?? ""} /> : null}
    </section>
  );
}

function MorseDiffView({ diff, expectedText, interfaceLanguage }: { readonly diff: MorseCopyDiff; readonly expectedText: string; readonly interfaceLanguage: InterfaceLanguage }) {
  const summary = t(
    interfaceLanguage,
    "morseDiffSummary",
    String(diff.score.errors),
    String(diff.score.wrong),
    String(diff.score.missing),
    String(diff.score.inserted),
  );
  return (
    <section className="morse-diff" aria-labelledby="morse-diff-heading">
      <h4 id="morse-diff-heading">{t(interfaceLanguage, "morseDiffTitle")}</h4>
      <p role="status">{summary}</p>
      <p>{diff.score.passed ? t(interfaceLanguage, "morseDiffPassMark", String(diff.score.markPercent)) : t(interfaceLanguage, "morseDiffFailMark", String(diff.score.markPercent))}</p>
      <details>
        <summary>{t(interfaceLanguage, "morseExpectedTranscript")}</summary>
        <p className="morse-copy" lang="en">{expectedText}</p>
      </details>
      <ol className="morse-diff-list" aria-label={summary}>
        {diff.operations.map((operation, index) => (
          <li key={`${operation.kind}-${index}`} className={`morse-diff-token morse-diff-${operation.kind}`} aria-label={diffOperationLabel(operation)}>
            <span className="morse-diff-token-label">{visibleDiffLabel(operation)}</span>
          </li>
        ))}
      </ol>
    </section>
  );
}

function visibleDiffLabel(operation: { readonly kind: string; readonly expected?: string; readonly received?: string }): string {
  switch (operation.kind) {
    case "match":
      return operation.expected ?? "";
    case "wrong":
      return `✕ ${operation.expected ?? ""}/${operation.received ?? ""}`;
    case "missing":
      return `− ${operation.expected ?? ""}`;
    case "inserted":
      return `+ ${operation.received ?? ""}`;
    default:
      return "";
  }
}

function clearWindowTimer(timer: number | null): void {
  if (timer !== null) {
    window.clearTimeout(timer);
    window.clearInterval(timer);
  }
}

function formatSeconds(value: number, locale: string): string {
  return formatLocaleNumber(value, locale, 1);
}

function formatWholeSeconds(value: number, locale: string): string {
  return formatLocaleNumber(value, locale, 0);
}

function formatLocaleNumber(value: number, locale: string, maximumFractionDigits: number): string {
  return new Intl.NumberFormat(locale, { maximumFractionDigits, minimumFractionDigits: maximumFractionDigits }).format(value);
}

function formatError(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
