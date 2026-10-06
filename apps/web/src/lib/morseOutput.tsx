import { useCallback, useMemo, useRef, useState } from "react";
import {
  MORSE_BEACON_AREA_CSS_PIXELS,
  MORSE_BEACON_DARKER_RELATIVE_LUMINANCE,
  MORSE_BEACON_LIGHTER_RELATIVE_LUMINANCE,
  evaluateMorseFlashSafety,
  maxMorseFlashesPerSecond,
  morseSignalEvents,
  morseTapeTokens,
  textToTimedMorse,
} from "@canadian-ham/morse-engine";

import { t, type InterfaceLanguage } from "./i18n";
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
    const safety = evaluateMorseFlashSafety({
      flashAreaCssPixels: MORSE_BEACON_AREA_CSS_PIXELS,
      flashesPerSecond,
      darkerRelativeLuminance: MORSE_BEACON_DARKER_RELATIVE_LUMINANCE,
      lighterRelativeLuminance: MORSE_BEACON_LIGHTER_RELATIVE_LUMINANCE,
      usesSaturatedRed: false,
    });
    const useTape = normalized.outputMode === "visualTape" || reduceMotion || !safety.safe;
    const safetyNote = reduceMotion
      ? t(interfaceLanguage, "morseOutputReducedMotionTape")
      : !safety.safe
        ? t(interfaceLanguage, "morseOutputSafetyFallback")
        : t(interfaceLanguage, "morseOutputBeaconSafety", MORSE_BEACON_AREA_CSS_PIXELS.toLocaleString(), safety.luminanceDelta.toFixed(2), String(flashesPerSecond));

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

export function MorseOutputView({ state }: { readonly state: WebMorseOutputState }) {
  if (state.mode === "idle") {
    return null;
  }
  return (
    <div className="morse-output-view" aria-live="off">
      {state.mode === "visualBeacon" ? <div className={`morse-beacon-lamp${state.beaconActive ? " active" : ""}`} aria-label="Morse visual beacon" role="img" /> : null}
      {state.mode === "visualTape" ? <p className="morse-visual-tape" aria-label="Morse tape output">{state.tape || "·"}</p> : null}
      <p className="help-text">{state.safetyNote}</p>
    </div>
  );
}

function prefersReducedMotion(): boolean {
  return globalThis.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
}
