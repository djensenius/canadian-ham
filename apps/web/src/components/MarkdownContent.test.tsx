import assert from "node:assert/strict";
import { render, screen } from "@testing-library/react";
import { describe, it } from "vitest";

import { MarkdownContent, parseMarkdownBlocks } from "./MarkdownContent";

describe("MarkdownContent parser", () => {
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

  it("stops an illustration brief after its description", () => {
    const blocks = parseMarkdownBlocks("## Illustration brief\n\nAlt text: Meter\n\nDescription: Draw a meter.\n\nThis paragraph stays separate.");

    assert.equal(blocks[0]?.type, "illustration");
    assert.deepEqual(blocks[1], { type: "paragraph", text: "This paragraph stays separate." });
  });

  it("renders parsed content without unsafe HTML injection", () => {
    render(<MarkdownContent markdown={"## Heading\n\n<script>alert(1)</script>\n\n* bullet"} />);

    assert.ok(screen.getByRole("heading", { name: "Heading" }));
    assert.ok(screen.getByText("<script>alert(1)</script>"));
    assert.ok(screen.getByText("bullet"));
  });
});
