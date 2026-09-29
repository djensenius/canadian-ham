import type { ReactNode } from "react";

interface MarkdownContentProps {
  readonly markdown: string;
  readonly title?: string;
}

type MarkdownBlock =
  | { readonly type: "heading"; readonly depth: number; readonly text: string }
  | { readonly type: "paragraph"; readonly text: string }
  | { readonly type: "unordered-list"; readonly items: readonly string[] }
  | { readonly type: "ordered-list"; readonly items: readonly string[] }
  | { readonly type: "table"; readonly headers: readonly string[]; readonly rows: readonly (readonly string[])[] }
  | { readonly type: "code"; readonly language: string | null; readonly code: string }
  | { readonly type: "illustration"; readonly alt: string; readonly description: string };

export function MarkdownContent({ markdown, title }: MarkdownContentProps) {
  return <>{parseMarkdownBlocks(markdown, title).map((block, index) => renderBlock(block, index))}</>;
}

function renderBlock(block: MarkdownBlock, index: number): ReactNode {
  if (block.type === "heading") {
    const Tag = `h${Math.min(block.depth + 1, 6)}` as "h2" | "h3" | "h4" | "h5" | "h6";
    return <Tag key={index}>{block.text}</Tag>;
  }
  if (block.type === "paragraph") {
    return <p key={index}>{block.text}</p>;
  }
  if (block.type === "unordered-list") {
    return <ul key={index}>{block.items.map((item) => <li key={item}>{item}</li>)}</ul>;
  }
  if (block.type === "ordered-list") {
    return <ol key={index}>{block.items.map((item) => <li key={item}>{item}</li>)}</ol>;
  }
  if (block.type === "table") {
    return (
      <div className="markdown-table-wrapper" key={index} role="region" aria-label="Lesson table" tabIndex={0}>
        <table>
          <thead>
            <tr>{block.headers.map((header) => <th key={header} scope="col">{header}</th>)}</tr>
          </thead>
          <tbody>
            {block.rows.map((row, rowIndex) => (
              <tr key={rowIndex}>{row.map((cell, cellIndex) => <td key={`${rowIndex}-${cellIndex}`}>{cell}</td>)}</tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }
  if (block.type === "code") {
    return (
      <pre
        className="markdown-code-block"
        key={index}
        role="group"
        aria-label={block.language === null ? "Lesson code block" : `Lesson code block (${block.language})`}
        tabIndex={0}
      ><code>{block.code}</code></pre>
    );
  }
  return (
    <figure className="illustration-placeholder" key={index}>
      <div className="illustration-placeholder__art" role="img" aria-label={block.alt}>
        Illustration placeholder
      </div>
      <figcaption>
        <strong>Illustration brief:</strong> {block.description}
      </figcaption>
    </figure>
  );
}

export function parseMarkdownBlocks(markdown: string, title?: string): MarkdownBlock[] {
  const normalized = markdown.replace(/\r\n/g, "\n");
  const lines = normalized.split("\n");
  const blocks: MarkdownBlock[] = [];
  let index = 0;

  while (index < lines.length) {
    const previousIndex = index;
    const line = lines[index] ?? "";
    if (line.trim() === "") {
      index += 1;
      assertParserProgress(previousIndex, index);
      continue;
    }

    const fencedCode = parseFencedCode(lines, index);
    if (fencedCode !== null) {
      blocks.push(fencedCode.block);
      index = fencedCode.nextIndex;
      assertParserProgress(previousIndex, index);
      continue;
    }

    const heading = /^(#{1,6})(?:\s+(.*))?$/.exec(line);
    if (heading !== null) {
      const text = stripInlineMarkdown((heading[2] ?? "").trim());
      const depth = heading[1]!.length;
      if (text.length === 0) {
        index += 1;
        assertParserProgress(previousIndex, index);
        continue;
      }
      if (/^illustration brief$/i.test(text)) {
        const { block, nextIndex } = parseIllustration(lines, index + 1);
        blocks.push(block);
        index = nextIndex;
        assertParserProgress(previousIndex, index);
        continue;
      }
      if (!(depth === 1 && title !== undefined && text === title)) {
        blocks.push({ type: "heading", depth: Math.max(depth, 2), text });
      }
      index += 1;
      assertParserProgress(previousIndex, index);
      continue;
    }

    if (isTableStart(lines, index)) {
      const { block, nextIndex } = parseTable(lines, index);
      blocks.push(block);
      index = nextIndex;
      assertParserProgress(previousIndex, index);
      continue;
    }

    if (/^\s*[-*+]\s+/.test(line)) {
      const items: string[] = [];
      while (index < lines.length && /^\s*[-*+]\s+/.test(lines[index] ?? "")) {
        items.push(stripInlineMarkdown((lines[index] ?? "").replace(/^\s*[-*+]\s+/, "").trim()));
        index += 1;
      }
      blocks.push({ type: "unordered-list", items });
      assertParserProgress(previousIndex, index);
      continue;
    }

    if (/^\s*\d+\.\s+/.test(line)) {
      const items: string[] = [];
      while (index < lines.length && /^\s*\d+\.\s+/.test(lines[index] ?? "")) {
        items.push(stripInlineMarkdown((lines[index] ?? "").replace(/^\s*\d+\.\s+/, "").trim()));
        index += 1;
      }
      blocks.push({ type: "ordered-list", items });
      assertParserProgress(previousIndex, index);
      continue;
    }

    const paragraphLines: string[] = [];
    while (index < lines.length) {
      const paragraphLine = lines[index] ?? "";
      if (paragraphLine.trim() === "" || /^(#{1,6})(?:\s|$)/.test(paragraphLine) || /^\s*[-*+]\s+/.test(paragraphLine) || /^\s*\d+\.\s+/.test(paragraphLine) || isTableStart(lines, index) || parseFencedCode(lines, index) !== null) {
        break;
      }
      paragraphLines.push(paragraphLine.trim());
      index += 1;
    }
    if (paragraphLines.length === 0) {
      index += 1;
      assertParserProgress(previousIndex, index);
      continue;
    }
    blocks.push({ type: "paragraph", text: stripInlineMarkdown(paragraphLines.join(" ")) });
    assertParserProgress(previousIndex, index);
  }

  return blocks;
}

function parseFencedCode(lines: readonly string[], startIndex: number): { readonly block: MarkdownBlock; readonly nextIndex: number } | null {
  const language = parseFenceOpening(lines[startIndex] ?? "");
  if (language === undefined) {
    return null;
  }
  const codeLines: string[] = [];
  let index = startIndex + 1;
  while (index < lines.length) {
    const line = lines[index] ?? "";
    if (isFenceClosing(line)) {
      return { block: { type: "code", language, code: codeLines.join("\n") }, nextIndex: index + 1 };
    }
    codeLines.push(line);
    index += 1;
  }
  return null;
}

function parseFenceOpening(line: string): string | null | undefined {
  const match = /^ {0,3}```(?:[ \t]*([^`\s]+))?[ \t]*$/.exec(line);
  if (match === null) {
    return undefined;
  }
  return match[1] ?? null;
}

function isFenceClosing(line: string): boolean {
  return /^ {0,3}```[ \t]*$/.test(line);
}

function assertParserProgress(previousIndex: number, nextIndex: number): void {
  if (nextIndex <= previousIndex) {
    throw new Error(`Markdown parser failed to advance at line ${previousIndex + 1}.`);
  }
}

function parseIllustration(lines: readonly string[], startIndex: number): { readonly block: MarkdownBlock; readonly nextIndex: number } {
  let index = startIndex;
  const content: string[] = [];
  while (index < lines.length) {
    const line = lines[index] ?? "";
    if (/^(#{1,6})(?:\s|$)/.test(line)) {
      break;
    }
    if (line.trim() === "" && content.some((entry) => /^Description:/i.test(entry))) {
      break;
    }
    if (line.trim() !== "") {
      content.push(line.trim());
    }
    index += 1;
  }
  const joined = content.join("\n");
  const alt = /Alt text:\s*([^\n]+)/i.exec(joined)?.[1]?.trim() ?? "Planned lesson illustration";
  const description = /Description:\s*([\s\S]+)/i.exec(joined)?.[1]?.replace(/\n+/g, " ").trim() ?? "An original accessible illustration will be added here.";
  return { block: { type: "illustration", alt: stripInlineMarkdown(alt), description: stripInlineMarkdown(description) }, nextIndex: index };
}

function isTableStart(lines: readonly string[], index: number): boolean {
  const current = lines[index] ?? "";
  const separator = lines[index + 1] ?? "";
  return current.includes("|") && /^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$/.test(separator);
}

function parseTable(lines: readonly string[], startIndex: number): { readonly block: MarkdownBlock; readonly nextIndex: number } {
  const headers = splitTableRow(lines[startIndex] ?? "");
  let index = startIndex + 2;
  const rows: string[][] = [];
  while (index < lines.length && (lines[index] ?? "").includes("|")) {
    rows.push(splitTableRow(lines[index] ?? ""));
    index += 1;
  }
  return { block: { type: "table", headers, rows }, nextIndex: index };
}

function splitTableRow(line: string): string[] {
  return line.replace(/^\s*\|?/, "").replace(/\|?\s*$/, "").split("|").map((cell) => stripInlineMarkdown(cell.trim()));
}

function stripInlineMarkdown(value: string): string {
  return value
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/__([^_]+)__/g, "$1")
    .replace(/\*([^\s*](?:[^*]*[^\s*])?)\*/g, "$1")
    .replace(/(^|[^\w])_([^\s_](?:[^\s_]*[^\s_])?)_(?=$|[^\w])/g, "$1$2")
    .replace(/\\([\\`*_[\]{}()#+\-.!|])/g, "$1");
}
