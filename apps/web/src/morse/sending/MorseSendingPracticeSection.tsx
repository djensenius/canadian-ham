import {
  applyMorseDecodedCharacter,
  classifyMorseKeyDown,
  generateMorseExamText,
  morseCharacterTimingFeedback,
  profileForName,
  scoreMorseSending,
  type MorseCharacterTimingFeedback,
  type MorseKeyElement,
  type MorseKeyTimingSample,
  type MorseProfileName,
  type MorseSendingScore,
} from "@canadian-ham/morse-engine";
import { useEffect, useId, useMemo, useRef, useState, type KeyboardEvent, type PointerEvent } from "react";

import { WebMorsePlayer } from "../../lib/morseAudio";
import { interfaceLanguageTag, t, type InterfaceLanguage } from "../../lib/i18n";
import { morseTimingFromPreferences } from "../../lib/morseSettings";
import type { WebPreferences } from "../../lib/progressStore";
import type { MorsePlaybackCoordinator } from "../copyExam/MorseCopyExamSection";

interface MorseSendingPracticeSectionProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly preferences: WebPreferences;
  readonly playbackCoordinator: MorsePlaybackCoordinator;
  readonly examSeedFactory?: (profileName: MorseProfileName) => string;
  readonly examDurationSeconds?: number;
  readonly nowMilliseconds?: () => number;
}

type SendingMode = "practice" | "exam";

type ActiveKey = "straight" | "dot" | "dash";

interface KeyDownState {
  readonly key: ActiveKey;
  readonly startedAtMilliseconds: number;
}

const defaultExamSeedFactory = (profileName: MorseProfileName) => `web-sending-${profileName}-${Date.now().toString(36)}`;
const defaultExamDurationSeconds = 180;
const paddleKeyboardMap: Readonly<Record<string, MorseKeyElement>> = Object.freeze({
  j: ".",
  ".": ".",
  k: "-",
  "-": "-",
});

export function MorseSendingPracticeSection({ interfaceLanguage, preferences, playbackCoordinator, examSeedFactory = defaultExamSeedFactory, examDurationSeconds = defaultExamDurationSeconds, nowMilliseconds = () => performance.now() }: MorseSendingPracticeSectionProps) {
  const keyboardHelpId = useId();
  const playerRef = useRef<WebMorsePlayer | null>(null);
  const toneGenerationRef = useRef(0);
  const activeKeyRef = useRef<KeyDownState | null>(null);
  const finalizeTimerRef = useRef<number | null>(null);
  const paddleIntervalRef = useRef<number | null>(null);
  const pressedPaddlesRef = useRef<Set<MorseKeyElement>>(new Set());
  const nextIambicElementRef = useRef<MorseKeyElement>(".");
  const examIntervalRef = useRef<number | null>(null);
  const [mode, setMode] = useState<SendingMode>("practice");
  const [pendingSamples, setPendingSamples] = useState<readonly MorseKeyTimingSample[]>([]);
  const [decodedText, setDecodedText] = useState("");
  const [lastFeedback, setLastFeedback] = useState<MorseCharacterTimingFeedback | null>(null);
  const [status, setStatus] = useState("");
  const [liveStatus, setLiveStatus] = useState("");
  const [examText, setExamText] = useState("");
  const [examRemaining, setExamRemaining] = useState(examDurationSeconds);
  const [examRunning, setExamRunning] = useState(false);
  const [examScore, setExamScore] = useState<MorseSendingScore | null>(null);
  const profile = useMemo(() => morseTimingFromPreferences(preferences.morse), [preferences.morse]);
  const locale = interfaceLanguageTag(interfaceLanguage);
  const keyButtonPressed = activeKeyRef.current?.key === "straight";

  useEffect(() => () => {
    stopTone();
    clearFinalizeTimer();
    clearPaddleInterval();
    clearExamInterval();
    void playerRef.current?.close();
  }, []);

  useEffect(() => {
    if (!examRunning) return;
    clearExamInterval();
    examIntervalRef.current = window.setInterval(() => {
      setExamRemaining((remaining) => {
        if (remaining <= 1) {
          clearExamInterval();
          setExamRunning(false);
          gradeExam(false);
          return 0;
        }
        return remaining - 1;
      });
    }, 1000);
    return clearExamInterval;
  }, [examRunning]);

  function clearFinalizeTimer(): void {
    if (finalizeTimerRef.current !== null) {
      window.clearTimeout(finalizeTimerRef.current);
      finalizeTimerRef.current = null;
    }
  }

  function clearPaddleInterval(): void {
    if (paddleIntervalRef.current !== null) {
      window.clearInterval(paddleIntervalRef.current);
      paddleIntervalRef.current = null;
    }
  }

  function clearExamInterval(): void {
    if (examIntervalRef.current !== null) {
      window.clearInterval(examIntervalRef.current);
      examIntervalRef.current = null;
    }
  }

  function stopTone(): void {
    toneGenerationRef.current += 1;
    playerRef.current?.stop();
    activeKeyRef.current = null;
  }

  function resetSending(nextMode: SendingMode = mode): void {
    stopTone();
    clearFinalizeTimer();
    clearPaddleInterval();
    pressedPaddlesRef.current.clear();
    setPendingSamples([]);
    setDecodedText("");
    setLastFeedback(null);
    setStatus("");
    setLiveStatus("");
    setMode(nextMode);
  }

  async function beginStraightKey(source: "keyboard" | "touch"): Promise<void> {
    if (activeKeyRef.current !== null) return;
    playbackCoordinator.claim("sending-practice");
    const generation = toneGenerationRef.current + 1;
    toneGenerationRef.current = generation;
    activeKeyRef.current = { key: "straight", startedAtMilliseconds: nowMilliseconds() };
    playerRef.current ??= new WebMorsePlayer();
    try {
      await playerRef.current.startTone(preferences.morse);
    } catch (error) {
      if (generation === toneGenerationRef.current) {
        const message = t(interfaceLanguage, "morseSendingToneError", formatError(error));
        setStatus(message);
        setLiveStatus(message);
        activeKeyRef.current = null;
      }
      return;
    }
    if (source === "keyboard") {
      setStatus(t(interfaceLanguage, "morseSendingKeyDownKeyboard"));
    }
  }

  function endStraightKey(): void {
    const active = activeKeyRef.current;
    if (active?.key !== "straight") return;
    const durationSeconds = Math.max(0.001, (nowMilliseconds() - active.startedAtMilliseconds) / 1000);
    stopTone();
    appendSample(classifyMorseKeyDown(durationSeconds, profile));
  }

  function appendSample(sample: MorseKeyTimingSample): void {
    setPendingSamples((samples) => {
      const next = [...samples, sample];
      scheduleFinalizeCharacter(next);
      return next;
    });
  }

  function scheduleFinalizeCharacter(samples: readonly MorseKeyTimingSample[]): void {
    clearFinalizeTimer();
    finalizeTimerRef.current = window.setTimeout(() => finalizeCharacter(samples), Math.ceil(profile.interCharacterGapSeconds * 1000) + 20);
  }

  function finalizeCharacter(samples: readonly MorseKeyTimingSample[]): void {
    clearFinalizeTimer();
    if (samples.length === 0) return;
    const feedback = morseCharacterTimingFeedback(samples);
    const nextText = applyMorseDecodedCharacter(decodedText, feedback.decoded);
    setPendingSamples([]);
    setLastFeedback(feedback);
    setDecodedText(nextText);
    const message = feedback.decoded.kind === "errorSignal"
      ? t(interfaceLanguage, "morseSendingErrorSignal")
      : feedback.decoded.kind === "character" && feedback.decoded.character !== undefined
        ? t(interfaceLanguage, "morseSendingDecodedCharacter", feedback.decoded.character)
        : t(interfaceLanguage, "morseSendingUnknownCharacter", feedback.elements);
    setStatus(message);
    setLiveStatus(message);
  }

  function emitPaddleElement(element: MorseKeyElement): void {
    playbackCoordinator.claim("sending-practice");
    const text = element === "." ? "E" : "T";
    void (async () => {
      playerRef.current ??= new WebMorsePlayer();
      try {
        await playerRef.current.playText(text, preferences.morse);
      } catch {
        // The timing sample still records even if the optional side-tone cannot start.
      }
    })();
    appendSample({
      element,
      durationSeconds: element === "." ? profile.dotSeconds : profile.dashSeconds,
      expectedSeconds: element === "." ? profile.dotSeconds : profile.dashSeconds,
      ratioToExpected: 1,
    });
  }

  function beginPaddle(element: MorseKeyElement): void {
    pressedPaddlesRef.current.add(element);
    emitPaddleElement(element);
    restartPaddleInterval();
  }

  function endPaddle(element: MorseKeyElement): void {
    pressedPaddlesRef.current.delete(element);
    restartPaddleInterval();
  }

  function restartPaddleInterval(): void {
    clearPaddleInterval();
    if (pressedPaddlesRef.current.size === 0) return;
    const repeatMilliseconds = Math.max(40, Math.round((profile.dotSeconds + profile.intraCharacterGapSeconds) * 1000));
    paddleIntervalRef.current = window.setInterval(() => {
      const pressed = pressedPaddlesRef.current;
      if (pressed.size === 0) return;
      let element: MorseKeyElement;
      if (pressed.has(".") && pressed.has("-")) {
        element = nextIambicElementRef.current;
        nextIambicElementRef.current = element === "." ? "-" : ".";
      } else {
        element = pressed.has(".") ? "." : "-";
      }
      emitPaddleElement(element);
    }, repeatMilliseconds);
  }

  function handleKeyDown(event: KeyboardEvent<HTMLElement>): void {
    const key = event.key.toLowerCase();
    if (event.repeat) return;
    if (key === " ") {
      event.preventDefault();
      void beginStraightKey("keyboard");
      return;
    }
    const paddle = paddleKeyboardMap[key];
    if (paddle !== undefined) {
      event.preventDefault();
      beginPaddle(paddle);
    }
  }

  function handleKeyUp(event: KeyboardEvent<HTMLElement>): void {
    const key = event.key.toLowerCase();
    if (key === " ") {
      event.preventDefault();
      endStraightKey();
      return;
    }
    const paddle = paddleKeyboardMap[key];
    if (paddle !== undefined) {
      event.preventDefault();
      endPaddle(paddle);
    }
  }

  function beginPointerStraight(event: PointerEvent<HTMLButtonElement>): void {
    event.currentTarget.setPointerCapture(event.pointerId);
    void beginStraightKey("touch");
  }

  function endPointerStraight(event: PointerEvent<HTMLButtonElement>): void {
    event.currentTarget.releasePointerCapture(event.pointerId);
    endStraightKey();
  }

  function beginPointerPaddle(event: PointerEvent<HTMLButtonElement>, element: MorseKeyElement): void {
    event.currentTarget.setPointerCapture(event.pointerId);
    beginPaddle(element);
  }

  function endPointerPaddle(event: PointerEvent<HTMLButtonElement>, element: MorseKeyElement): void {
    event.currentTarget.releasePointerCapture(event.pointerId);
    endPaddle(element);
  }

  function startExam(): void {
    resetSending("exam");
    const generated = generateMorseExamText({ profile: profileForName("isedParis"), seed: examSeedFactory("isedParis"), minDurationSeconds: 0 });
    setExamText(generated.text);
    setExamRemaining(examDurationSeconds);
    setExamScore(null);
    setExamRunning(true);
    setStatus(t(interfaceLanguage, "morseSendingExamStarted"));
  }

  function gradeExam(completedWithinTime = examRemaining > 0): void {
    if (examText === "") return;
    finalizeCharacter(pendingSamples);
    const score = scoreMorseSending(examText, decodedText, completedWithinTime);
    setExamRunning(false);
    clearExamInterval();
    setExamScore(score);
    const message = score.passed
      ? t(interfaceLanguage, "morseSendingExamPassed", String(score.diff.score.errors))
      : t(interfaceLanguage, "morseSendingExamFailed", String(score.diff.score.errors), String(score.markPercent));
    setStatus(message);
    setLiveStatus(message);
  }

  const pendingElements = pendingSamples.map((sample) => sample.element).join("");
  const feedbackSummary = lastFeedback === null ? null : timingFeedbackSummary(lastFeedback, interfaceLanguage, locale);
  const timerLabel = formatTimer(examRemaining);

  return (
    <section className="morse-sending-panel" aria-labelledby="morse-sending-title" tabIndex={0} onKeyDown={handleKeyDown} onKeyUp={handleKeyUp} aria-describedby={keyboardHelpId}>
      <div className="morse-sending-header">
        <div>
          <h3 id="morse-sending-title">{t(interfaceLanguage, "morseSendingTitle")}</h3>
          <p>{t(interfaceLanguage, "morseSendingIntro")}</p>
        </div>
        <div className="action-row">
          <button type="button" className={mode === "practice" ? "primary-button" : undefined} onClick={() => resetSending("practice")}>{t(interfaceLanguage, "morseSendingPracticeMode")}</button>
          <button type="button" className={mode === "exam" ? "primary-button" : undefined} onClick={startExam}>{t(interfaceLanguage, "morseSendingExamMode")}</button>
        </div>
      </div>
      <p id={keyboardHelpId} className="help-text">{t(interfaceLanguage, "morseSendingKeyboardHelp")}</p>
      {mode === "exam" ? (
        <div className="morse-sending-exam" aria-labelledby="morse-sending-exam-heading">
          <h4 id="morse-sending-exam-heading">{t(interfaceLanguage, "morseSendingExamHeading")}</h4>
          {examText === "" ? <p>{t(interfaceLanguage, "morseSendingExamNotStarted")}</p> : <p className="morse-copy" lang="en">{examText}</p>}
          <p className="morse-timer" aria-live="off">{t(interfaceLanguage, "morseSendingTimer", timerLabel)}</p>
          <div className="action-row">
            <button type="button" disabled={examRunning} onClick={startExam}>{t(interfaceLanguage, "morseSendingStartExam")}</button>
            <button type="button" disabled={examText === "" || examScore !== null} onClick={() => gradeExam()}>{t(interfaceLanguage, "morseSendingGradeExam")}</button>
          </div>
        </div>
      ) : null}
      <div className="morse-keyer-grid">
        <section aria-labelledby="morse-straight-key-heading">
          <h4 id="morse-straight-key-heading">{t(interfaceLanguage, "morseStraightKeyTitle")}</h4>
          <button
            type="button"
            className={`morse-key-button${keyButtonPressed ? " active" : ""}`}
            aria-label={t(interfaceLanguage, "morseStraightKeyButtonAria")}
            aria-pressed={keyButtonPressed}
            onPointerDown={beginPointerStraight}
            onPointerUp={endPointerStraight}
            onPointerCancel={endPointerStraight}
          >
            {t(interfaceLanguage, "morseStraightKeyButton")}
          </button>
        </section>
        <section aria-labelledby="morse-paddle-heading">
          <h4 id="morse-paddle-heading">{t(interfaceLanguage, "morsePaddleTitle")}</h4>
          <div className="morse-paddle-row">
            <button type="button" className="morse-key-button" aria-label={t(interfaceLanguage, "morseDotPaddleAria")} onPointerDown={(event) => beginPointerPaddle(event, ".")} onPointerUp={(event) => endPointerPaddle(event, ".")} onPointerCancel={(event) => endPointerPaddle(event, ".")}>{t(interfaceLanguage, "morseDotPaddle")}</button>
            <button type="button" className="morse-key-button" aria-label={t(interfaceLanguage, "morseDashPaddleAria")} onPointerDown={(event) => beginPointerPaddle(event, "-")} onPointerUp={(event) => endPointerPaddle(event, "-")} onPointerCancel={(event) => endPointerPaddle(event, "-")}>{t(interfaceLanguage, "morseDashPaddle")}</button>
          </div>
        </section>
      </div>
      <dl className="morse-sending-feedback">
        <div><dt>{t(interfaceLanguage, "morseSendingPendingElements")}</dt><dd>{pendingElements || "—"}</dd></div>
        <div><dt>{t(interfaceLanguage, "morseSendingDecodedText")}</dt><dd className="morse-copy" lang="en">{decodedText || "—"}</dd></div>
        <div><dt>{t(interfaceLanguage, "morseSendingLastFeedback")}</dt><dd>{feedbackSummary ?? t(interfaceLanguage, "morseSendingNoFeedback")}</dd></div>
      </dl>
      <div className="action-row">
        <button type="button" onClick={() => resetSending(mode)}>{t(interfaceLanguage, "morseSendingClear")}</button>
      </div>
      {status ? <p className="morse-copy-status">{status}</p> : null}
      <div className="sr-only" role="status" aria-live="polite" aria-atomic="true">{liveStatus}</div>
      {examScore !== null ? <SendingExamResults interfaceLanguage={interfaceLanguage} score={examScore} decodedText={decodedText} /> : null}
    </section>
  );
}

function SendingExamResults({ interfaceLanguage, score, decodedText }: { readonly interfaceLanguage: InterfaceLanguage; readonly score: MorseSendingScore; readonly decodedText: string }) {
  const heading = score.passed
    ? t(interfaceLanguage, "morseSendingExamPassed", String(score.diff.score.errors))
    : t(interfaceLanguage, "morseSendingExamFailed", String(score.diff.score.errors), String(score.markPercent));
  return (
    <section className="morse-sending-results" aria-labelledby="morse-sending-results-heading">
      <h4 id="morse-sending-results-heading">{t(interfaceLanguage, "morseSendingResultsTitle")}</h4>
      <p>{heading}</p>
      <p>{t(interfaceLanguage, "morseSendingResultsRule")}</p>
      <p>{t(interfaceLanguage, "morseDiffSummary", String(score.diff.score.errors), String(score.diff.score.wrong), String(score.diff.score.missing), String(score.diff.score.inserted))}</p>
      <h5>{t(interfaceLanguage, "morseSendingDecodedText")}</h5>
      <p className="morse-copy" lang="en">{decodedText || t(interfaceLanguage, "morseSendingNoSentText")}</p>
    </section>
  );
}

function timingFeedbackSummary(feedback: MorseCharacterTimingFeedback, interfaceLanguage: InterfaceLanguage, locale: string): string {
  const ratio = feedback.dotDashRatio === null ? t(interfaceLanguage, "morseSendingRatioUnavailable") : formatLocaleNumber(feedback.dotDashRatio, locale, 2);
  return t(interfaceLanguage, "morseSendingFeedbackSummary", feedback.elements, ratio, String(feedback.timingConsistencyPercent));
}

function formatTimer(seconds: number): string {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, "0")}`;
}

function formatLocaleNumber(value: number, locale: string, maximumFractionDigits: number): string {
  return new Intl.NumberFormat(locale, { maximumFractionDigits, minimumFractionDigits: maximumFractionDigits }).format(value);
}

function formatError(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
