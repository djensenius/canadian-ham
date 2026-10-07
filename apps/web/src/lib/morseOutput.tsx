import { useCallback, useId, useMemo, useRef, useState } from "react";
import {
  MORSE_BEACON_AREA_CSS_PIXELS,
  MORSE_DARK_ACCENT_RGB,
  MORSE_DARK_PAPER_INSET_RGB,
  MORSE_LIGHT_ACCENT_RGB,
  MORSE_LIGHT_PAPER_INSET_RGB,
  evaluateMorseBeaconFlashSafety,
  maxMorseFlashesPerSecond,
  morseBeaconPalette,
  morseSignalEvents,
  morseTapeTokens,
  textToTimedMorse,
} from "@canadian-ham/morse-engine";

import { interfaceLanguageTag, t, type InterfaceLanguage } from "./i18n";
import { WebMorsePlayer, type MorsePlaybackHandle } from "./morseAudio";
import { morseTimingFromPreferences, normalizeMorsePreferences, type WebMorsePreferences } from "./morseSettings";

export interface WebMorseOutputState {
  readonly mode: "idle" | "visualBeacon" | "visualTape";
  readonly beaconActive: boolean;
  readonly tape: string;
  readonly safetyNote: string;
}

const idleOutputState: WebMorseOutputState = Object.freeze({ mode: "idle", beaconActive: false, tape: "", safetyNote: "" });

interface WebMorseOutputController {
  readonly state: WebMorseOutputState;
  playText(text: string, preferences: WebMorsePreferences): Promise<MorsePlaybackHandle>;
  stop(): void;
  close(): Promise<void>;
}

export function useWebMorseOutput(interfaceLanguage: InterfaceLanguage): WebMorseOutputController {
  const playerRef = useRef<WebMorsePlayer | null>(null);
  const timersRef = useRef<number[]>([]);
  const activeStopRef = useRef<(() => void) | null>(null);
  const [state, setState] = useState<WebMorseOutputState>(idleOutputState);

  const clearVisualTimers = useCallback(() => {
    for (const timer of timersRef.current) {
      window.clearTimeout(timer);
    }
    timersRef.current = [];
  }, []);

  const stop = useCallback(() => {
    clearVisualTimers();
    activeStopRef.current?.();
    activeStopRef.current = null;
    playerRef.current?.stop();
    setState(idleOutputState);
  }, [clearVisualTimers]);

  const playText = useCallback(async (text: string, preferences: WebMorsePreferences): Promise<MorsePlaybackHandle> => {
    stop();
    const normalized = normalizeMorsePreferences(preferences);
    if (normalized.outputMode === "audio") {
      playerRef.current ??= new WebMorsePlayer();
      const handle = await playerRef.current.playText(text, normalized);
      activeStopRef.current = handle.stop;
      return handle;
    }

    const sequence = textToTimedMorse(text, morseTimingFromPreferences(normalized));
    const reduceMotion = prefersReducedMotion();
    const signalEvents = morseSignalEvents(sequence);
    const flashesPerSecond = maxMorseFlashesPerSecond(signalEvents);
    const safety = evaluateMorseBeaconFlashSafety({ palette: currentWebBeaconPalette(), flashesPerSecond });
    const useTape = normalized.outputMode === "visualTape" || reduceMotion || !safety.safe;
    const safetyNote = reduceMotion
      ? t(interfaceLanguage, "morseOutputReducedMotionTape")
      : !safety.safe
        ? t(interfaceLanguage, "morseOutputSafetyFallback")
        : t(interfaceLanguage, "morseOutputBeaconSafety", formatLocaleNumber(MORSE_BEACON_AREA_CSS_PIXELS, interfaceLanguage, 0), formatLocaleNumber(safety.maxAreaCssPixels, interfaceLanguage, 0), formatLocaleNumber(flashesPerSecond, interfaceLanguage, 0));

    if (useTape) {
      setState({ mode: "visualTape", beaconActive: false, tape: "", safetyNote });
      const tokens = morseTapeTokens(sequence);
      let tape = "";
      for (const token of tokens) {
        timersRef.current.push(window.setTimeout(() => {
          tape += token.token;
          setState({ mode: "visualTape", beaconActive: false, tape, safetyNote });
        }, Math.max(0, Math.round(token.revealAtSeconds * 1000))));
      }
    } else {
      setState({ mode: "visualBeacon", beaconActive: false, tape: "", safetyNote });
      for (const event of signalEvents) {
        timersRef.current.push(window.setTimeout(() => {
          setState({ mode: "visualBeacon", beaconActive: event.kind === "on", tape: "", safetyNote });
        }, Math.max(0, Math.round(event.atSeconds * 1000))));
      }
    }

    const finishTimer = window.setTimeout(() => {
      setState((current) => ({ ...current, beaconActive: false }));
      activeStopRef.current = null;
    }, Math.ceil(sequence.totalDurationSeconds * 1000) + 60);
    timersRef.current.push(finishTimer);

    const handle: MorsePlaybackHandle = {
      durationSeconds: sequence.totalDurationSeconds,
      startedAtSeconds: performance.now() / 1000,
      stop,
    };
    activeStopRef.current = () => {
      clearVisualTimers();
      setState(idleOutputState);
    };
    return handle;
  }, [clearVisualTimers, interfaceLanguage, stop]);

  const close = useCallback(async () => {
    stop();
    await playerRef.current?.close();
    playerRef.current = null;
  }, [stop]);

  return useMemo(() => ({ state, playText, stop, close }), [close, playText, state, stop]);
}

export function MorseOutputView({ state, interfaceLanguage }: { readonly state: WebMorseOutputState; readonly interfaceLanguage: InterfaceLanguage }) {
  const generatedLabelId = useId();
  if (state.mode === "idle") {
    return null;
  }
  const labelId = state.mode === "visualTape" ? generatedLabelId : undefined;
  return (
    <div className="morse-output-view" aria-live="off">
      {state.mode === "visualBeacon" ? <div className={`morse-beacon-lamp${state.beaconActive ? " active" : ""}`} aria-label={t(interfaceLanguage, "morseOutputVisualBeaconName")} role="img" /> : null}
      {state.mode === "visualTape" ? <div role="region" aria-labelledby={labelId}>
        <p id={labelId} className="sr-only">{t(interfaceLanguage, "morseOutputVisualTapeName")}</p>
        <output className="morse-visual-tape" aria-live="off">{state.tape || "·"}</output>
      </div> : null}
      <p className="help-text">{state.safetyNote}</p>
    </div>
  );
}

function currentWebBeaconPalette() {
  const dark = document.documentElement.dataset.theme === "dark"
    || (document.documentElement.dataset.theme !== "light" && (globalThis.matchMedia?.("(prefers-color-scheme: dark)").matches ?? false));
  return dark
    ? morseBeaconPalette({ accent: MORSE_DARK_ACCENT_RGB, background: MORSE_DARK_PAPER_INSET_RGB })
    : morseBeaconPalette({ accent: MORSE_LIGHT_ACCENT_RGB, background: MORSE_LIGHT_PAPER_INSET_RGB });
}

function formatLocaleNumber(value: number, interfaceLanguage: InterfaceLanguage, maximumFractionDigits: number): string {
  return new Intl.NumberFormat(interfaceLanguageTag(interfaceLanguage), { maximumFractionDigits, minimumFractionDigits: maximumFractionDigits }).format(value);
}

function prefersReducedMotion(): boolean {
  return globalThis.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
}
