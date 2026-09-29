import assert from "node:assert/strict";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, it } from "vitest";

import { App } from "./App";

afterEach(() => cleanup());

describe("Practice", () => {
  it("renders deterministic feedback, tally, language, and focus behavior", async () => {
    render(<App initialView="practice" initialScopeId="B-001" random={() => 0} />);

    const heading = screen.getByRole("heading", { name: "Practice question" });
    assert.match(heading.textContent ?? "", /Practice question/);
    assert.equal(heading.closest("article")?.hasAttribute("lang"), false);
    assert.equal(document.querySelector(".question-text")?.getAttribute("lang"), "en");

    fireEvent.click(screen.getByLabelText("Français"));
    assert.equal(heading.closest("article")?.hasAttribute("lang"), false);
    assert.equal(document.querySelector(".question-text")?.getAttribute("lang"), "fr");
    assert.ok(screen.getAllByTestId("answer-choice").every((choice) => choice.querySelectorAll("span")[1]?.getAttribute("lang") === "fr"));
    fireEvent.click(screen.getByLabelText("English"));
    assert.equal(document.querySelector(".question-text")?.getAttribute("lang"), "en");

    const choices = screen.getAllByTestId("answer-choice");
    assert.equal(choices.length, 4);

    fireEvent.click(choices[0]!);

    const feedback = screen.getByRole("status").textContent ?? "";
    assert.match(feedback, /Incorrect\./);
    assert.match(feedback, /The correct answer is:/);
    assert.match(feedback, /The Radiocommunication Act/);
    assert.equal(screen.getByRole("status").querySelector("strong")?.getAttribute("lang"), "en");
    assert.match(screen.getByLabelText("Session tally").textContent ?? "", /Score: 0 correct \/ 1 answered/);

    const nextButton = screen.getByRole("button", { name: "Next question" });
    await waitFor(() => assert.equal(document.activeElement, nextButton));

    fireEvent.click(nextButton);
    await waitFor(() => assert.equal(document.activeElement, heading));
    assert.doesNotMatch(document.querySelector(".question-meta")?.textContent ?? "", /B-001-001-001/);
  });

  it("reports correct feedback when the deterministic correct answer is chosen", () => {
    render(<App initialView="practice" initialScopeId="B-001" random={() => 0} />);

    const choices = screen.getAllByTestId("answer-choice");
    fireEvent.click(choices[3]!);

    const feedback = screen.getByRole("status").textContent ?? "";
    assert.match(feedback, /Correct\./);
    assert.match(feedback, /The correct answer is:/);
    assert.match(feedback, /The Radiocommunication Act/);
    assert.match(screen.getByLabelText("Session tally").textContent ?? "", /Score: 1 correct \/ 1 answered/);
  });
});
