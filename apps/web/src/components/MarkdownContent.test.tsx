import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import axe from "axe-core";
import { afterEach, describe, it } from "vitest";

import { lessonHeadingAnchorSlug, lessonHeadingAnchors, MarkdownContent, parseMarkdownBlocks } from "./MarkdownContent";

interface FigureDirectiveFixture {
  readonly name: string;
  readonly markdown: string;
  readonly expected: readonly Record<string, unknown>[];
}

interface LessonHeadingAnchorFixture {
  readonly slugCases: ReadonlyArray<{ readonly name: string; readonly headingText: string; readonly expectedSlug: string }>;
  readonly anchorCases: ReadonlyArray<{ readonly name: string; readonly title: string | null; readonly markdown: string; readonly expectedAnchors: readonly string[]; readonly rejectedAnchors: readonly string[] }>;
}

const moduleUrl = new URL(import.meta.url);
const modulePath = moduleUrl.protocol === "file:"
  ? fileURLToPath(moduleUrl)
  : join(process.cwd(), moduleUrl.pathname.replace(/^\/+/, ""));
const fixturesRoot = join(dirname(modulePath), "../../../../fixtures");
const figureDirectiveFixtures = JSON.parse(readFileSync(join(fixturesRoot, "markdown-figure-directives.json"), "utf8")) as FigureDirectiveFixture[];
const lessonHeadingAnchorFixture = JSON.parse(readFileSync(join(fixturesRoot, "lesson-heading-anchors.json"), "utf8")) as LessonHeadingAnchorFixture;

function simplifiedBlocks(markdown: string) {
  return parseMarkdownBlocks(markdown).map((block) => {
    if (block.type === "figure") {
      return { type: "figure", id: block.id, altText: block.alt, textEquivalent: block.textEquivalent };
    }
    if (block.type === "paragraph") {
      return { type: "paragraph", text: block.text };
    }
    if (block.type === "code") {
      return { type: "code", language: block.language, text: block.code };
    }
    if (block.type === "heading") {
      return { type: "heading", text: block.text };
    }
    return { type: block.type };
  });
}

afterEach(() => {
  cleanup();
  delete document.documentElement.dataset.theme;
});

const tryItMarkdown = "## Try it\n\n1. Find the current.\n\n:::answer\nThe current is 3 A.\n:::\n\n2. Name the path.\n\n:::answer\nThe audio path.\n:::";

for (const language of ["en", "fr"] as const) {
  for (const theme of ["light", "dark"] as const) {
    it(`reveals each Try-it independently with keyboard, announced state, retained focus and axe in ${language} ${theme}`, async () => {
      document.documentElement.dataset.theme = theme;
      const user = userEvent.setup();
      const { container } = render(<main><MarkdownContent markdown={tryItMarkdown} interfaceLanguage={language} contentLanguage="en" /></main>);
      const show = language === "en" ? "Show answer" : "Afficher la réponse";
      const hide = language === "en" ? "Hide answer" : "Masquer la réponse";
      const toggle = screen.getByRole("button", { name: `${show} 1` });
      const second = screen.getByRole("button", { name: `${show} 2` });
      assert.equal(toggle.getAttribute("aria-expanded"), "false");
      assert.equal(screen.queryByText("The current is 3 A."), null);
      assert.equal(document.getElementById(toggle.getAttribute("aria-controls")!)?.hidden, true);
      assert.deepEqual((await axe.run(container)).violations, []);

      await user.tab();
      assert.equal(document.activeElement, toggle);
      await user.keyboard("{Enter}");
      assert.equal(toggle.getAttribute("aria-expanded"), "true");
      assert.equal(toggle.textContent?.trim(), `${hide} 1`);
      assert.equal(document.activeElement, toggle);
      assert.equal(screen.getByText("The current is 3 A.").lang, "en");
      assert.match(container.querySelector('[aria-live="polite"]')!.textContent!, language === "en" ? /Answer 1 shown/ : /Réponse 1 affichée/);
      assert.equal(second.getAttribute("aria-expanded"), "false");
      assert.equal(screen.queryByText("The audio path."), null);
      assert.deepEqual((await axe.run(container)).violations, []);

      await user.keyboard(" ");
      assert.equal(toggle.getAttribute("aria-expanded"), "false");
      assert.equal(document.activeElement, toggle);
      assert.equal(screen.queryByText("The current is 3 A."), null);
      await user.tab();
      assert.equal(document.activeElement, second);
      await user.keyboard(" ");
      assert.ok(screen.getByText("The audio path."));
      assert.equal(screen.queryByText("The current is 3 A."), null);
      assert.deepEqual((await axe.run(container)).violations, []);
    });
  }
}

it("does not retain a revealed Try-it when the lesson content changes", async () => {
  const user = userEvent.setup();
  const { rerender } = render(<MarkdownContent markdown={tryItMarkdown} />);
  await user.click(screen.getByRole("button", { name: "Show answer 1" }));
  rerender(<MarkdownContent markdown={`## Another lesson\n\n${tryItMarkdown}`} />);
  assert.equal(screen.getByRole("button", { name: "Show answer 1" }).getAttribute("aria-expanded"), "false");
  assert.equal(screen.queryByText("The current is 3 A."), null);
  await user.click(screen.getByRole("button", { name: "Show answer 1" }));
  rerender(<MarkdownContent markdown={tryItMarkdown.replace("The current is 3 A.", "The current is 4 A.")} />);
  assert.equal(screen.getByRole("button", { name: "Show answer 1" }).getAttribute("aria-expanded"), "false");
  assert.equal(screen.queryByText("The current is 4 A."), null);
});

describe("MarkdownContent parser", () => {
  it("parses Try-it prompts and answers without changing numbering or later heading anchors", () => {
    const blocks = parseMarkdownBlocks(`${tryItMarkdown}\n\n## Radio connection\n\nKeep listening.`);
    assert.deepEqual(blocks.slice(1, 3), [
      { type: "try-it", number: 1, prompt: "Find the current.", answer: "The current is 3 A." },
      { type: "try-it", number: 2, prompt: "Name the path.", answer: "The audio path." },
    ]);
    assert.deepEqual(lessonHeadingAnchors(tryItMarkdown + "\n\n## Radio connection"), ["try-it", "radio-connection"]);
  });
  for (const fixture of figureDirectiveFixtures) {
    it(`matches shared figure-directive fixture: ${fixture.name}`, () => {
      assert.deepEqual(simplifiedBlocks(fixture.markdown), fixture.expected);
    });
  }

  for (const slugCase of lessonHeadingAnchorFixture.slugCases) {
    it(`matches shared heading slug fixture: ${slugCase.name}`, () => {
      assert.equal(lessonHeadingAnchorSlug(slugCase.headingText), slugCase.expectedSlug);
    });
  }

  for (const anchorCase of lessonHeadingAnchorFixture.anchorCases) {
    it(`matches shared rendered-heading anchor fixture: ${anchorCase.name}`, () => {
      const anchors = lessonHeadingAnchors(anchorCase.markdown, anchorCase.title ?? undefined);
      assert.deepEqual(anchors, anchorCase.expectedAnchors);
      for (const rejectedAnchor of anchorCase.rejectedAnchors) {
        assert.equal(anchors.includes(rejectedAnchor), false, rejectedAnchor);
      }
    });
  }

  it("renders shared heading ids on linkable headings and keeps duplicates unique", () => {
    render(<MarkdownContent markdown={"# Fixture Lesson\n\n## Shared setup\n\n## Shared setup"} title="Fixture Lesson" />);

    assert.equal(screen.queryByRole("heading", { name: "Fixture Lesson" }), null);
    const headings = screen.getAllByRole("heading", { name: "Shared setup" });
    assert.equal(headings[0]?.id, "shared-setup");
    assert.equal(headings[1]?.id, "shared-setup-1");
    assert.equal(headings[0]?.getAttribute("tabindex"), "-1");
  });

  it("updates rendered content when markdown and title props change", () => {
    const { rerender } = render(<MarkdownContent markdown={"# First Lesson\n\n## Shared setup\n\nInitial body"} title="First Lesson" />);

    assert.equal(screen.queryByRole("heading", { name: "First Lesson" }), null);
    assert.ok(screen.getByRole("heading", { name: "Shared setup" }));
    assert.ok(screen.getByText("Initial body"));

    rerender(<MarkdownContent markdown={"# Second Lesson\n\n## Updated setup\n\nUpdated body"} title="Second Lesson" />);

    assert.equal(screen.queryByText("Initial body"), null);
    assert.equal(screen.queryByRole("heading", { name: "Shared setup" }), null);
    assert.equal(screen.queryByRole("heading", { name: "Second Lesson" }), null);
    assert.ok(screen.getByRole("heading", { name: "Updated setup" }));
    assert.ok(screen.getByText("Updated body"));

    rerender(<MarkdownContent markdown={"# Second Lesson\n\n## Updated setup\n\nUpdated body"} title="Displayed Title" />);

    assert.ok(screen.getByRole("heading", { name: "Second Lesson" }));
  });

  it("handles dash, star, and plus unordered bullets", () => {
    const blocks = parseMarkdownBlocks("- dash\n* star\n+ plus");

    assert.deepEqual(blocks, [{ type: "unordered-list", items: ["dash", "star", "plus"] }]);
  });

  it("skips empty headings and continues parsing later content", () => {
    const blocks = parseMarkdownBlocks("# \n\n## Real heading\nText");

    assert.deepEqual(blocks, [
      { type: "heading", depth: 2, text: "Real heading" },
      { type: "paragraph", text: "Text" },
    ]);
  });

  it("always advances on pathological block delimiters", () => {
    const markdown = ["# ", "* item", "+ item", "- ", "#", "| a | b |", "| --- | --- |", "| c | d |", "2 * 3 remains math"].join("\n");
    const blocks = parseMarkdownBlocks(markdown);

    assert.ok(blocks.length > 0);
    assert.ok(blocks.some((block) => block.type === "unordered-list"));
    assert.ok(blocks.some((block) => block.type === "table"));
    assert.ok(blocks.some((block) => block.type === "paragraph" && block.text.includes("2 * 3")));
  });

  it("preserves underscores in formula-like text", () => {
    const blocks = parseMarkdownBlocks("R_1 and X_L stay formula-like, while _emphasis_ is plain text.");

    assert.deepEqual(blocks, [{ type: "paragraph", text: "R_1 and X_L stay formula-like, while emphasis is plain text." }]);
  });

  it("parses a fenced code block with a language without inline markdown processing", () => {
    const blocks = parseMarkdownBlocks("```text\n*not emphasized*\nR_1 stays formula-like\n```");

    assert.deepEqual(blocks, [{ type: "code", language: "text", code: "*not emphasized*\nR_1 stays formula-like" }]);
  });

  it("parses a fenced code block without a language", () => {
    const blocks = parseMarkdownBlocks("```\nvalue = 300 / f\n```");

    assert.deepEqual(blocks, [{ type: "code", language: null, code: "value = 300 / f" }]);
  });

  it("falls back to paragraph text for an unterminated fenced code block", () => {
    const blocks = parseMarkdownBlocks("```text\nvalue = 300 / f");

    assert.deepEqual(blocks, [{ type: "paragraph", text: "```text value = 300 / f" }]);
  });

  it("stops an illustration brief after its description without showing the author brief to learners", () => {
    const markdown = "## Illustration brief\n\nAlt text: Meter\n\nDescription: Draw a meter.\n\nThis paragraph stays separate.";
    const blocks = parseMarkdownBlocks(markdown);

    assert.equal(blocks[0]?.type, "illustration");
    assert.deepEqual(blocks[1], { type: "paragraph", text: "This paragraph stays separate." });

    render(<MarkdownContent markdown={markdown} />);
    assert.equal(screen.queryByText("Illustration placeholder"), null);
    assert.equal(screen.queryByText(/Draw a meter/u), null);
    assert.ok(screen.getByText("This paragraph stays separate."));
  });

  it("parses and renders figure directives with alt text and text equivalents", () => {
    const markdown = "::figure ohms-law-power-wheel\nAlt text: Ohm wheel alt.\nText equivalent:\n- To find P: I x E.\n::";
    const blocks = parseMarkdownBlocks(markdown);

    assert.deepEqual(blocks, [{ type: "figure", id: "ohms-law-power-wheel", alt: "Ohm wheel alt.", textEquivalent: ["To find P: I x E."] }]);

    render(<MarkdownContent markdown={markdown} />);
    assert.ok(screen.getByRole("img", { name: "Ohm wheel alt." }));
    assert.ok(screen.getByText("Figure text equivalent"));
    assert.ok(screen.getByText("To find P: I x E."));
  });

  it("renders parsed content without unsafe HTML injection", () => {
    render(<MarkdownContent markdown={"## Heading\n\n<script>alert(1)</script>\n\n* bullet"} />);

    assert.ok(screen.getByRole("heading", { name: "Heading" }));
    assert.ok(screen.getByText("<script>alert(1)</script>"));
    assert.ok(screen.getByText("bullet"));
  });
});
