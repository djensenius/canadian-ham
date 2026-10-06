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
  readonly examTextFactory?: (profileName: MorseProfileName) => string;
  readonly examDurationSeconds?: number;
  readonly nowMilliseconds?: () => number;
}

type SendingMode = "practice" | "exam";

type ActiveKey = "straight";

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

const noopPlaybackCoordinator: MorsePlaybackCoordinator = {
  register: () => () => {},
  claim: () => {},
};

export function MorseSendingPracticeSection({ interfaceLanguage, preferences, playbackCoordinator = noopPlaybackCoordinator, examSeedFactory = defaultExamSeedFactory, examTextFactory, examDurationSeconds = defaultExamDurationSeconds, nowMilliseconds = () => performance.now() }: MorseSendingPracticeSectionProps) {
  const keyboardHelpId = useId();
  const playerRef = useRef<WebMorsePlayer | null>(null);
  const toneGenerationRef = useRef(0);
  const activeKeyRef = useRef<KeyDownState | null>(null);
  const finalizeTimerRef = useRef<number | null>(null);
  const paddleTimerRef = useRef<number | null>(null);
  const pressedPaddlesRef = useRef<Set<MorseKeyElement>>(new Set());
  const nextIambicElementRef = useRef<MorseKeyElement>(".");
  const examIntervalRef = useRef<number | null>(null);
  const pendingSamplesRef = useRef<readonly MorseKeyTimingSample[]>([]);
  const decodedTextRef = useRef("");
  const examTextRef = useRef("");
  const examRunningRef = useRef(false);
  const profileRef = useRef(morseTimingFromPreferences(preferences.morse));
  const lastPaddleElementRef = useRef<MorseKeyElement | null>(null);
  const [mode, setMode] = useState<SendingMode>("practice");
  const [pendingSamples, setPendingSamplesState] = useState<readonly MorseKeyTimingSample[]>([]);
  const [decodedText, setDecodedTextState] = useState("");
  const [lastFeedback, setLastFeedback] = useState<MorseCharacterTimingFeedback | null>(null);
  const [status, setStatus] = useState("");
  const [liveStatus, setLiveStatus] = useState("");
  const [examText, setExamTextState] = useState("");
  const [examRemaining, setExamRemaining] = useState(examDurationSeconds);
  const [examRunning, setExamRunningState] = useState(false);
  const [examRun, setExamRun] = useState(0);
  const [examScore, setExamScore] = useState<MorseSendingScore | null>(null);
  const [gradedText, setGradedText] = useState("");
  const [straightPressed, setStraightPressed] = useState(false);
  const profile = useMemo(() => morseTimingFromPreferences(preferences.morse), [preferences.morse]);
  profileRef.current = profile;
  const locale = interfaceLanguageTag(interfaceLanguage);

  useEffect(() => () => {
    releaseAllKeys({ finalizeStraight: false });
    clearFinalizeTimer();
    clearExamInterval();
    void playerRef.current?.close();
  }, []);

  useEffect(() => playbackCoordinator.register("sending-practice", () => {
    releaseAllKeys({ finalizeStraight: true });
  }), [playbackCoordinator]);

  useEffect(() => {
    function releaseForPageExit(): void {
      releaseAllKeys({ finalizeStraight: true });
    }
    function releaseForVisibility(): void {
      if (document.visibilityState !== "visible") releaseForPageExit();
    }
    window.addEventListener("blur", releaseForPageExit);
    document.addEventListener("visibilitychange", releaseForVisibility);
    return () => {
      window.removeEventListener("blur", releaseForPageExit);
      document.removeEventListener("visibilitychange", releaseForVisibility);
    };
  }, []);

  useEffect(() => {
    if (!examRunning) return;
    clearExamInterval();
    // Derive the countdown from a deadline, not from tick counts: browsers throttle
    // intervals in background tabs, which would otherwise let an exam run past 3:00.
    const deadline = Date.now() + examRemaining * 1000;
    function syncRemaining(): void {
      setExamRemaining(Math.max(0, Math.ceil((deadline - Date.now()) / 1000)));
    }
    function syncOnVisible(): void {
      if (document.visibilityState === "visible") syncRemaining();
    }
    examIntervalRef.current = window.setInterval(syncRemaining, 1000);
    document.addEventListener("visibilitychange", syncOnVisible);
    return () => {
      clearExamInterval();
      document.removeEventListener("visibilitychange", syncOnVisible);
    };
  }, [examRunning, examRun]);

  useEffect(() => {
    if (examRunning && examRemaining === 0) {
      gradeExam(false);
    }
  }, [examRemaining, examRunning]);

  function setPendingSamples(samples: readonly MorseKeyTimingSample[]): void {
    pendingSamplesRef.current = samples;
    setPendingSamplesState(samples);
  }

  function setDecodedText(text: string): void {
    decodedTextRef.current = text;
    setDecodedTextState(text);
  }

  function setExamText(text: string): void {
    examTextRef.current = text;
    setExamTextState(text);
  }

  function setExamRunning(running: boolean): void {
    examRunningRef.current = running;
    setExamRunningState(running);
  }

  function clearFinalizeTimer(): void {
    if (finalizeTimerRef.current !== null) {
      window.clearTimeout(finalizeTimerRef.current);
      finalizeTimerRef.current = null;
    }
  }

  function clearPaddleTimer(): void {
    if (paddleTimerRef.current !== null) {
      window.clearTimeout(paddleTimerRef.current);
      paddleTimerRef.current = null;
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
    setStraightPressed(false);
  }

  function releaseAllKeys({ finalizeStraight }: { readonly finalizeStraight: boolean }): void {
    const active = activeKeyRef.current;
    if (active?.key === "straight" && finalizeStraight) {
      const durationSeconds = Math.max(0.001, (nowMilliseconds() - active.startedAtMilliseconds) / 1000);
      appendSample(classifyMorseKeyDown(durationSeconds, profileRef.current));
    }
    stopTone();
    clearPaddleTimer();
    pressedPaddlesRef.current.clear();
  }

  function resetSending(nextMode: SendingMode = mode): void {
    releaseAllKeys({ finalizeStraight: false });
    clearFinalizeTimer();
    clearExamInterval();
    setPendingSamples([]);
    setDecodedText("");
    setLastFeedback(null);
    setStatus("");
    setLiveStatus("");
    setExamScore(null);
    setGradedText("");
    if (nextMode === "practice") {
      setExamRunning(false);
    } else if (examTextRef.current !== "") {
      setExamRemaining(examDurationSeconds);
      setExamRunning(true);
      setExamRun((run) => run + 1);
    }
    setMode(nextMode);
  }

  async function beginStraightKey(source: "keyboard" | "touch"): Promise<void> {
    if (activeKeyRef.current !== null) return;
    clearFinalizeTimer();
    playbackCoordinator.claim("sending-practice");
    const generation = toneGenerationRef.current + 1;
    toneGenerationRef.current = generation;
    activeKeyRef.current = { key: "straight", startedAtMilliseconds: nowMilliseconds() };
    setStraightPressed(true);
    playerRef.current ??= new WebMorsePlayer();
    try {
      await playerRef.current.startTone(preferences.morse);
    } catch (error) {
      if (generation === toneGenerationRef.current) {
        const message = t(interfaceLanguage, "morseSendingToneError", formatError(error));
        setStatus(message);
        setLiveStatus(message);
        activeKeyRef.current = null;
        setStraightPressed(false);
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
    appendSample(classifyMorseKeyDown(durationSeconds, profileRef.current));
  }

  function appendSample(sample: MorseKeyTimingSample, finalizeAfterElementSeconds = 0): void {
    const next = [...pendingSamplesRef.current, sample];
    setPendingSamples(next);
    scheduleFinalizeCharacter(next, finalizeAfterElementSeconds);
  }

  function scheduleFinalizeCharacter(samples: readonly MorseKeyTimingSample[], finalizeAfterElementSeconds = 0): void {
    clearFinalizeTimer();
    finalizeTimerRef.current = window.setTimeout(() => {
      finalizeCharacter(samples);
    }, Math.ceil((finalizeAfterElementSeconds + profileRef.current.interCharacterGapSeconds) * 1000) + 20);
  }

  function finalizePendingCharacter(): string {
    return finalizeCharacter(pendingSamplesRef.current);
  }

  function finalizeCharacter(samples: readonly MorseKeyTimingSample[]): string {
    clearFinalizeTimer();
    if (samples.length === 0) return decodedTextRef.current;
    const feedback = morseCharacterTimingFeedback(samples);
    const nextText = applyMorseDecodedCharacter(decodedTextRef.current, feedback.decoded);
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
    return nextText;
  }

  function emitPaddleElement(element: MorseKeyElement): void {
    clearFinalizeTimer();
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
    const timing = profileRef.current;
    const durationSeconds = element === "." ? timing.dotSeconds : timing.dashSeconds;
    appendSample({ element, durationSeconds, expectedSeconds: durationSeconds, ratioToExpected: 1 }, durationSeconds);
  }

  function beginPaddle(element: MorseKeyElement): void {
    pressedPaddlesRef.current.add(element);
    if (paddleTimerRef.current === null) {
      emitAndScheduleNextPaddleElement(element);
    }
  }

  function endPaddle(element: MorseKeyElement): void {
    pressedPaddlesRef.current.delete(element);
    if (pressedPaddlesRef.current.size === 0) {
      clearPaddleTimer();
      playerRef.current?.stop();
    }
  }

  function emitAndScheduleNextPaddleElement(preferredElement?: MorseKeyElement): void {
    const pressed = pressedPaddlesRef.current;
    if (pressed.size === 0) {
      clearPaddleTimer();
      return;
    }
    let element: MorseKeyElement;
    if (pressed.has(".") && pressed.has("-")) {
      element = lastPaddleElementRef.current === null ? nextIambicElementRef.current : oppositeElement(lastPaddleElementRef.current);
      nextIambicElementRef.current = oppositeElement(element);
    } else {
      element = preferredElement ?? (pressed.has(".") ? "." : "-");
      nextIambicElementRef.current = oppositeElement(element);
    }
    lastPaddleElementRef.current = element;
    emitPaddleElement(element);
    const timing = profileRef.current;
    const durationSeconds = element === "." ? timing.dotSeconds : timing.dashSeconds;
    const repeatMilliseconds = Math.max(40, Math.round((durationSeconds + timing.intraCharacterGapSeconds) * 1000));
    clearPaddleTimer();
    paddleTimerRef.current = window.setTimeout(() => emitAndScheduleNextPaddleElement(), repeatMilliseconds);
  }

  function handleKeyDown(event: KeyboardEvent<HTMLElement>): void {
    if (isInteractiveKeyboardTarget(event.target, event.currentTarget)) return;
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
    if (isInteractiveKeyboardTarget(event.target, event.currentTarget)) return;
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
    event.currentTarget.setPointerCapture?.(event.pointerId);
    void beginStraightKey("touch");
  }

  function endPointerStraight(event: PointerEvent<HTMLButtonElement>): void {
    if (event.currentTarget.hasPointerCapture?.(event.pointerId)) {
      event.currentTarget.releasePointerCapture?.(event.pointerId);
    }
    endStraightKey();
  }

  function beginPointerPaddle(event: PointerEvent<HTMLButtonElement>, element: MorseKeyElement): void {
    event.currentTarget.setPointerCapture?.(event.pointerId);
    beginPaddle(element);
  }

  function endPointerPaddle(event: PointerEvent<HTMLButtonElement>, element: MorseKeyElement): void {
    if (event.currentTarget.hasPointerCapture?.(event.pointerId)) {
      event.currentTarget.releasePointerCapture?.(event.pointerId);
    }
    endPaddle(element);
  }

  function startExam(): void {
    resetSending("exam");
    const generatedText = examTextFactory?.("isedParis") ?? generateMorseExamText({ profile: profileForName("isedParis"), seed: examSeedFactory("isedParis"), minDurationSeconds: 0 }).text;
    setExamText(generatedText);
    setExamRemaining(examDurationSeconds);
    setExamScore(null);
    setGradedText("");
    setExamRunning(true);
    setExamRun((run) => run + 1);
    setStatus(t(interfaceLanguage, "morseSendingExamStarted"));
  }

  function gradeExam(completedWithinTime = examRemaining > 0): void {
    if (examTextRef.current === "" || !examRunningRef.current && examScore !== null) return;
    const sentText = finalizePendingCharacter();
    const score = scoreMorseSending(examTextRef.current, sentText, completedWithinTime);
    setExamRunning(false);
    clearExamInterval();
    setGradedText(sentText);
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
    <section className="morse-sending-panel" aria-labelledby="morse-sending-title" tabIndex={0} onKeyDown={handleKeyDown} onKeyUp={handleKeyUp} onBlur={(event) => { if (!event.currentTarget.contains(event.relatedTarget)) releaseAllKeys({ finalizeStraight: true }); }} aria-describedby={keyboardHelpId}>
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
            <button type="button" onClick={startExam}>{t(interfaceLanguage, "morseSendingStartExam")}</button>
            <button type="button" disabled={examText === "" || examScore !== null} onClick={() => gradeExam()}>{t(interfaceLanguage, "morseSendingGradeExam")}</button>
          </div>
        </div>
      ) : null}
      <div className="morse-keyer-grid">
        <section aria-labelledby="morse-straight-key-heading">
          <h4 id="morse-straight-key-heading">{t(interfaceLanguage, "morseStraightKeyTitle")}</h4>
          <button
            type="button"
            className={`morse-key-button${straightPressed ? " active" : ""}`}
            aria-label={t(interfaceLanguage, "morseStraightKeyButtonAria")}
            aria-pressed={straightPressed}
            onPointerDown={beginPointerStraight}
            onPointerUp={endPointerStraight}
            onPointerCancel={endPointerStraight}
            onLostPointerCapture={endStraightKey}
          >
            {t(interfaceLanguage, "morseStraightKeyButton")}
          </button>
        </section>
        <section aria-labelledby="morse-paddle-heading">
          <h4 id="morse-paddle-heading">{t(interfaceLanguage, "morsePaddleTitle")}</h4>
          <div className="morse-paddle-row">
            <button type="button" className="morse-key-button" aria-label={t(interfaceLanguage, "morseDotPaddleAria")} onPointerDown={(event) => beginPointerPaddle(event, ".")} onPointerUp={(event) => endPointerPaddle(event, ".")} onPointerCancel={(event) => endPointerPaddle(event, ".")} onLostPointerCapture={() => endPaddle(".")}>{t(interfaceLanguage, "morseDotPaddle")}</button>
            <button type="button" className="morse-key-button" aria-label={t(interfaceLanguage, "morseDashPaddleAria")} onPointerDown={(event) => beginPointerPaddle(event, "-")} onPointerUp={(event) => endPointerPaddle(event, "-")} onPointerCancel={(event) => endPointerPaddle(event, "-")} onLostPointerCapture={() => endPaddle("-")}>{t(interfaceLanguage, "morseDashPaddle")}</button>
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
      {examScore !== null ? <SendingExamResults interfaceLanguage={interfaceLanguage} score={examScore} decodedText={gradedText} /> : null}
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

function oppositeElement(element: MorseKeyElement): MorseKeyElement {
  return element === "." ? "-" : ".";
}

function isInteractiveKeyboardTarget(target: EventTarget | null, container: HTMLElement): boolean {
  if (!(target instanceof HTMLElement) || target === container) return false;
  return target.closest("button,input,select,textarea,a,[role='button']") !== null;
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
