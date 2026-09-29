import { useMemo, useState } from "react";

import { LanguageToggle } from "./components/LanguageToggle";
import { allQuestionCount, categories, questionsForScope } from "./data/bank";
import type { Answer, Language, Question } from "./data/bank";
import { shuffleAnswers } from "./lib/tempShuffle";
import type { ShuffledAnswers } from "./lib/tempShuffle";

interface PracticePresentation {
  readonly question: Question;
  readonly shuffledAnswers: ShuffledAnswers<Answer>;
}

interface SessionTally {
  readonly answered: number;
  readonly correct: number;
}

interface Feedback {
  readonly selectedDisplayIndex: number;
  readonly isCorrect: boolean;
}

type View = "home" | "practice";

interface AppProps {
  readonly initialView?: View;
  readonly initialScopeId?: string;
  readonly random?: () => number;
}

function pickQuestion(scopeId: string, random: () => number): Question {
  const scopedQuestions = questionsForScope(scopeId);
  if (scopedQuestions.length === 0) {
    throw new Error(`No questions available for scope ${scopeId}`);
  }
  const selectedIndex = Math.floor(random() * scopedQuestions.length);
  return scopedQuestions[selectedIndex]!;
}

function createPresentation(scopeId: string, random: () => number): PracticePresentation {
  const question = pickQuestion(scopeId, random);
  return {
    question,
    shuffledAnswers: shuffleAnswers(question.answers, random),
  };
}

function scopeLabel(scopeId: string): string {
  if (scopeId === "all") {
    return "All questions";
  }
  return categories.find((category) => category.id === scopeId)?.name.en ?? scopeId;
}

export function App({ initialView = "home", initialScopeId = "all", random = Math.random }: AppProps) {
  const [view, setView] = useState<View>(initialView);
  const [language, setLanguage] = useState<Language>("en");
  const [scopeId, setScopeId] = useState(initialScopeId);
  const [presentation, setPresentation] = useState(() => createPresentation(initialScopeId, random));
  const [feedback, setFeedback] = useState<Feedback | null>(null);
  const [tally, setTally] = useState<SessionTally>({ answered: 0, correct: 0 });

  const visibleScopeLabel = useMemo(() => scopeLabel(scopeId), [scopeId]);

  function startPractice(nextScopeId: string): void {
    setScopeId(nextScopeId);
    setPresentation(createPresentation(nextScopeId, random));
    setFeedback(null);
    setTally({ answered: 0, correct: 0 });
    setView("practice");
  }

  function changeScope(nextScopeId: string): void {
    startPractice(nextScopeId);
  }

  function answerQuestion(selectedDisplayIndex: number): void {
    if (feedback !== null) {
      return;
    }
    const isCorrect = selectedDisplayIndex === presentation.shuffledAnswers.correctDisplayIndex;
    setFeedback({ selectedDisplayIndex, isCorrect });
    setTally((current) => ({
      answered: current.answered + 1,
      correct: current.correct + (isCorrect ? 1 : 0),
    }));
  }

  function nextQuestion(): void {
    setPresentation(createPresentation(scopeId, random));
    setFeedback(null);
  }

  return (
    <div className="app-shell">
      <header className="site-header">
        <div>
          <p className="eyebrow">Canadian Amateur Radio Basic</p>
          <h1>canadian-ham study app</h1>
        </div>
        <LanguageToggle language={language} onLanguageChange={setLanguage} />
      </header>

      <main>
        {view === "home" ? (
          <Home onStartPractice={startPractice} />
        ) : (
          <Practice
            feedback={feedback}
            language={language}
            onAnswer={answerQuestion}
            onBackHome={() => setView("home")}
            onNext={nextQuestion}
            onScopeChange={changeScope}
            presentation={presentation}
            scopeId={scopeId}
            scopeLabel={visibleScopeLabel}
            tally={tally}
          />
        )}
      </main>

      <Footer />
    </div>
  );
}

interface HomeProps {
  readonly onStartPractice: (scopeId: string) => void;
}

function Home({ onStartPractice }: HomeProps) {
  return (
    <section className="card home" aria-labelledby="home-title">
      <h2 id="home-title">Start studying</h2>
      <p>
        Practice with the committed 2025-07-15 Basic question bank. Pick a category, or use all questions for a mixed session.
      </p>
      <div className="category-grid" aria-label="Practice categories">
        <button className="category-card all-questions" type="button" onClick={() => onStartPractice("all")}>
          <span>All questions</span>
          <strong>{allQuestionCount}</strong>
          <small>Mixed across all categories</small>
        </button>
        {categories.map((category) => (
          <button className="category-card" type="button" key={category.id} onClick={() => onStartPractice(category.id)}>
            <span>{category.name.en}</span>
            <strong>{category.questionCount}</strong>
            <small>{category.subsectionCount} subsections</small>
          </button>
        ))}
      </div>
    </section>
  );
}

interface PracticeProps {
  readonly feedback: Feedback | null;
  readonly language: Language;
  readonly onAnswer: (selectedDisplayIndex: number) => void;
  readonly onBackHome: () => void;
  readonly onNext: () => void;
  readonly onScopeChange: (scopeId: string) => void;
  readonly presentation: PracticePresentation;
  readonly scopeId: string;
  readonly scopeLabel: string;
  readonly tally: SessionTally;
}

function Practice({
  feedback,
  language,
  onAnswer,
  onBackHome,
  onNext,
  onScopeChange,
  presentation,
  scopeId,
  scopeLabel,
  tally,
}: PracticeProps) {
  const correctAnswer = presentation.shuffledAnswers.answers[presentation.shuffledAnswers.correctDisplayIndex]!;

  return (
    <section className="card practice" aria-labelledby="practice-title">
      <div className="practice-topline">
        <button className="secondary" type="button" onClick={onBackHome}>
          Back to categories
        </button>
        <label>
          Practice set
          <select value={scopeId} onChange={(event) => onScopeChange(event.currentTarget.value)}>
            <option value="all">All questions ({allQuestionCount})</option>
            {categories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name.en} ({category.questionCount})
              </option>
            ))}
          </select>
        </label>
      </div>

      <div className="session-summary" aria-label="Session tally">
        <span>{scopeLabel}</span>
        <span>
          Score: {tally.correct} correct / {tally.answered} answered
        </span>
      </div>

      <article className="question-panel">
        <p className="question-meta">
          {presentation.question.id} · {presentation.question.categoryId} · {presentation.question.subsectionId}
        </p>
        <h2 id="practice-title">Practice question</h2>
        <p className="question-text">{presentation.question.text[language]}</p>

        <div className="answers" role="group" aria-label="Answer choices">
          {presentation.shuffledAnswers.answers.map((answer, displayIndex) => {
            const selected = feedback?.selectedDisplayIndex === displayIndex;
            const correct = displayIndex === presentation.shuffledAnswers.correctDisplayIndex;
            const className = [
              "answer-button",
              feedback !== null && correct ? "is-correct" : "",
              feedback !== null && selected && !correct ? "is-incorrect" : "",
            ].filter(Boolean).join(" ");
            return (
              <button
                className={className}
                data-testid="answer-choice"
                disabled={feedback !== null}
                key={answer.sourceIndex}
                type="button"
                onClick={() => onAnswer(displayIndex)}
              >
                <span className="answer-label">{String.fromCharCode(65 + displayIndex)}</span>
                <span>{answer.text[language]}</span>
                {feedback !== null && correct ? <strong>Correct answer</strong> : null}
                {feedback !== null && selected && !correct ? <strong>Your answer</strong> : null}
              </button>
            );
          })}
        </div>
      </article>

      <div className="feedback" role="status" aria-live="polite">
        {feedback === null ? (
          <p>Choose an answer to see immediate feedback.</p>
        ) : feedback.isCorrect ? (
          <p>
            Correct. The correct answer is: <strong>{correctAnswer.text[language]}</strong>
          </p>
        ) : (
          <p>
            Incorrect. The correct answer is: <strong>{correctAnswer.text[language]}</strong>
          </p>
        )}
      </div>

      <button className="next-button" disabled={feedback === null} type="button" onClick={onNext}>
        Next question
      </button>
    </section>
  );
}

function Footer() {
  return (
    <footer className="site-footer">
      <p>
        Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank and related reference material. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page. Written permission is pending; this private-development build is not for public release.
      </p>
      <p>
        canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.
      </p>
    </footer>
  );
}
