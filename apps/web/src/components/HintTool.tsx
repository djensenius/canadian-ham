import { useEffect, useRef, useState, type MouseEvent } from "react";

import type { Language } from "../data/bank";
import { referenceSheetSectionLabel, type QuestionHint } from "../data/hints";
import { t, type InterfaceLanguage } from "../lib/i18n";

export const hintVisibleQualificationMilliseconds = 500;

export interface HintToolProps {
  readonly hint: QuestionHint;
  readonly interfaceLanguage: InterfaceLanguage;
  readonly referenceSheetAvailable: boolean;
  readonly visibleLevel: number;
  readonly answeredWithHelpQualified: boolean;
  readonly onRevealLevel: (level: 1 | 2) => void;
  readonly onHintVisibleLongEnough: () => void;
  readonly onOpenLesson: (lessonId: string, sectionAnchor?: string) => void;
  readonly lessonHref: string;
}

export function HintTool({ hint, interfaceLanguage, referenceSheetAvailable, visibleLevel, answeredWithHelpQualified, onRevealLevel, onHintVisibleLongEnough, onOpenLesson, lessonHref }: HintToolProps) {
  const [liveMessage, setLiveMessage] = useState("");
  const revealedHintRef = useRef<HTMLElement | null>(null);
  const hintIsVisible = visibleLevel > 0;
  const lastAvailableLevel = hint.hints.length;
  const nextLevel = visibleLevel < lastAvailableLevel ? (visibleLevel + 1) as 1 | 2 : null;
  const visibleHints = hint.hints.filter((entry) => entry.level <= visibleLevel);
  const showLessonLink = visibleLevel >= lastAvailableLevel;
  const referenceSheetSection = hint.referenceSheetSection ?? null;

  useEffect(() => {
    if (!hintIsVisible || answeredWithHelpQualified) {
      return;
    }
    const timer = window.setTimeout(onHintVisibleLongEnough, hintVisibleQualificationMilliseconds);
    return () => window.clearTimeout(timer);
  }, [answeredWithHelpQualified, hint.questionId, hintIsVisible, onHintVisibleLongEnough]);

  useEffect(() => {
    if (visibleLevel === 0) {
      return;
    }
    window.setTimeout(() => revealedHintRef.current?.focus({ preventScroll: true }), 0);
  }, [hint.questionId, visibleLevel]);

  function reveal(level: 1 | 2): void {
    onRevealLevel(level);
    setLiveMessage(t(interfaceLanguage, "hintRevealedAnnouncement", level));
  }

  const lessonLink = hint.lessonLink;
  function handleLessonClick(event: MouseEvent<HTMLAnchorElement>): void {
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) {
      return;
    }
    event.preventDefault();
    onOpenLesson(lessonLink.lessonId, lessonLink.sectionAnchor);
  }

  return (
    <section className="hint-tool" aria-label={t(interfaceLanguage, "hintToolTitle")} data-exam-tool-focus tabIndex={-1}>
      <p className="hint-tool__intro">{t(interfaceLanguage, "hintToolIntro")}</p>
      <div className="sr-only" aria-live="polite" data-testid="hint-live-status">{liveMessage}{answeredWithHelpQualified ? ` ${t(interfaceLanguage, "hintAnsweredWithHelpAnnouncement")}` : ""}</div>
      {visibleHints.length === 0 ? <p className="hint-tool__empty">{t(interfaceLanguage, "hintNotOpenedYet")}</p> : null}
      {visibleHints.map((entry) => (
        <article className="hint-card" key={entry.level} ref={entry.level === visibleLevel ? revealedHintRef : undefined} tabIndex={-1} aria-labelledby={`hint-${hint.questionId}-${entry.level}-title`}>
          <h4 id={`hint-${hint.questionId}-${entry.level}-title`}>{t(interfaceLanguage, "hintLevelTitle", entry.level)}</h4>
          <p lang={languageTagForHint(interfaceLanguage)}>{entry[interfaceLanguage]}</p>
        </article>
      ))}
      {referenceSheetAvailable && referenceSheetSection !== null && visibleLevel > 0 ? (
        <p className="hint-reference-pointer"><strong>{t(interfaceLanguage, "hintReferenceSheetPointer")}</strong> {referenceSheetSectionLabel(referenceSheetSection, interfaceLanguage)}</p>
      ) : null}
      {showLessonLink ? (
        <p className="hint-lesson-link">
          <a href={lessonHref} onClick={handleLessonClick}>{t(interfaceLanguage, "hintReviewInLesson")}</a>
          {interfaceLanguage === "fr" ? <span className="reference-note"> {t(interfaceLanguage, "englishOnlyLessonNotice")}</span> : null}
        </p>
      ) : null}
      {nextLevel === null ? null : (
        <button type="button" className="primary-button" onClick={() => reveal(nextLevel)}>{t(interfaceLanguage, nextLevel === 1 ? "hintShowFirst" : "hintShowSecond")}</button>
      )}
    </section>
  );
}

function languageTagForHint(language: Language): string {
  return language === "fr" ? "fr-CA" : "en-CA";
}
