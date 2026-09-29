import assert from "node:assert/strict";
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, it } from "vitest";

import { App } from "./App";

describe("Practice", () => {
  it("shows a question and gives immediate feedback", () => {
    render(<App initialView="practice" initialScopeId="B-001" random={() => 0} />);

    assert.match(screen.getByRole("heading", { name: "Practice question" }).textContent ?? "", /Practice question/);
    const choices = screen.getAllByTestId("answer-choice");
    assert.equal(choices.length, 4);

    fireEvent.click(choices[0]!);

    const feedback = screen.getByRole("status").textContent ?? "";
    assert.match(feedback, /Correct\.|Incorrect\./);
    assert.match(feedback, /The correct answer is:/);
  });
});
