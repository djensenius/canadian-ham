import assert from "node:assert/strict";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState } from "react";
import { describe, it, vi } from "vitest";

import { hintForQuestion, type QuestionHint } from "../data/hints";
import { HintTool } from "./HintTool";

function requiredHint(questionId: string): QuestionHint {
  const hint = hintForQuestion(questionId, "basic-2025-07-15");
  assert.ok(hint);
  return hint;
}

function HintHarness({ hint, interfaceLanguage = "en", referenceSheetAvailable = true, onQualified = () => undefined }: {
  readonly hint: QuestionHint;
  readonly interfaceLanguage?: "en" | "fr";
  readonly referenceSheetAvailable?: boolean;
  readonly onQualified?: () => void;
}) {
  const [visibleLevel, setVisibleLevel] = useState(0);
  return (
    <HintTool
      answeredWithHelpQualified={false}
      canRecordHelp={true}
      hint={hint}
      interfaceLanguage={interfaceLanguage}
      lessonHref={`#/learn/M5/${hint.lessonLink.lessonId}`}
      onHintVisibleLongEnough={onQualified}
      onOpenLesson={() => undefined}
      onRevealLevel={(_questionId, level) => setVisibleLevel(level)}
      referenceSheetAvailable={referenceSheetAvailable}
      visibleLevel={visibleLevel}
    />
  );
}

describe("HintTool", () => {
  it("supports the two-level ladder from the keyboard and gates reference-sheet labels on availability", async () => {
    const hint = requiredHint("B-005-004-002");
    const user = userEvent.setup();
    render(<HintHarness hint={hint} />);

    const firstButton = screen.getByRole("button", { name: "Show Hint 1" });
    firstButton.focus();
    await user.keyboard("{Enter}");
    assert.ok(screen.getByRole("heading", { name: "Hint 1" }));
    assert.ok(screen.getByText("Ohm's law"));
    assert.equal(screen.getByTestId("hint-live-status").textContent?.includes("Hint 1 shown."), true);

    const secondButton = screen.getByRole("button", { name: "Show Hint 2" });
    secondButton.focus();
    await user.keyboard(" ");
    assert.ok(screen.getByRole("heading", { name: "Hint 2" }));
    assert.ok(screen.getByRole("link", { name: "Review in lesson" }));
  });

  it("shows one-level French hints without a broken second-hint affordance or unavailable sheet pointer", async () => {
    const hint = requiredHint("B-005-001-006");
    const user = userEvent.setup();
    render(<HintHarness hint={hint} interfaceLanguage="fr" referenceSheetAvailable={false} />);

    await user.click(screen.getByRole("button", { name: "Afficher l’indice 1" }));

    assert.ok(screen.getByRole("heading", { name: "Indice 1" }));
    assert.match(screen.getByText(hint.hints[0]!.fr).textContent ?? "", /préfixe/u);
    assert.equal(screen.queryByRole("button", { name: "Afficher l’indice 2" }), null);
    assert.equal(screen.queryByText(/Feuille de référence/u), null);
    assert.ok(screen.getByRole("link", { name: "Revoir dans la leçon" }));
    assert.ok(screen.getByText(/Leçon offerte en anglais seulement/u));
  });

  it("qualifies answered-with-help only after the hint has been visible for 0.5 seconds", async () => {
    vi.useFakeTimers();
    try {
      const hint = requiredHint("B-001-001-001");
      const qualified = vi.fn();
      render(<HintHarness hint={hint} onQualified={qualified} />);

      screen.getByRole("button", { name: "Show Hint 1" }).click();
      await vi.advanceTimersByTimeAsync(499);
      assert.equal(qualified.mock.calls.length, 0);
      await vi.advanceTimersByTimeAsync(1);
      assert.equal(qualified.mock.calls.length, 1);
    } finally {
      vi.useRealTimers();
    }
  });
});
