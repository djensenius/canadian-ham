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
    const startedAt = performance.now();
    const blocks = parseMarkdownBlocks(markdown);

    assert.ok(performance.now() - startedAt < 50);
    assert.ok(blocks.length > 0);
    assert.ok(blocks.some((block) => block.type === "unordered-list"));
    assert.ok(blocks.some((block) => block.type === "table"));
    assert.ok(blocks.some((block) => block.type === "paragraph" && block.text.includes("2 * 3")));
  }, 100);

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
