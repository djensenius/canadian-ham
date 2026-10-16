import type { ReactNode } from "react";

import { t, type InterfaceLanguage } from "../lib/i18n";

const figureSourceModules = import.meta.glob("../../../../content/figures/*.svg", {
  eager: true,
  query: "?raw",
  import: "default",
}) as Record<string, string>;

const figureSourcesById = new Map(
  Object.entries(figureSourceModules).map(([path, source]) => [path.split("/").pop()?.replace(/\.svg$/, "") ?? path, source]),
);

interface MarkdownContentProps {
  readonly markdown: string;
  readonly title?: string;
  readonly interfaceLanguage?: InterfaceLanguage;
  readonly contentLanguage?: "en" | "fr";
  readonly tableLabel?: string;
}

type MarkdownBlock =
  | { readonly type: "heading"; readonly depth: number; readonly text: string }
  | { readonly type: "paragraph"; readonly text: string }
  | { readonly type: "unordered-list"; readonly items: readonly string[] }
  | { readonly type: "ordered-list"; readonly items: readonly string[] }
  | { readonly type: "table"; readonly headers: readonly string[]; readonly rows: readonly (readonly string[])[] }
  | { readonly type: "code"; readonly language: string | null; readonly code: string }
  | { readonly type: "figure"; readonly id: string; readonly alt: string; readonly textEquivalent: readonly string[] }
  | { readonly type: "illustration"; readonly alt: string; readonly description: string };

export function MarkdownContent({ markdown, title, interfaceLanguage = "en", contentLanguage, tableLabel = t(interfaceLanguage, "markdownTableAria") }: MarkdownContentProps) {
  let tableIndex = 0;
  return <>{parseMarkdownBlocks(markdown, title).map((block, index) => {
    if (block.type === "table") {
      tableIndex += 1;
      return renderBlock(block, index, interfaceLanguage, contentLanguage, `${tableLabel} ${tableIndex}`);
    }
    return renderBlock(block, index, interfaceLanguage, contentLanguage, tableLabel);
  })}</>;
}

function renderBlock(block: MarkdownBlock, index: number, interfaceLanguage: InterfaceLanguage, contentLanguage: "en" | "fr" | undefined, tableLabel: string): ReactNode {
  if (block.type === "heading") {
    const Tag = `h${Math.min(block.depth + 1, 6)}` as "h2" | "h3" | "h4" | "h5" | "h6";
    return <Tag key={index} lang={contentLanguage}>{block.text}</Tag>;
  }
  if (block.type === "paragraph") {
    return <p key={index} lang={contentLanguage}>{block.text}</p>;
  }
  if (block.type === "unordered-list") {
    return <ul key={index} lang={contentLanguage}>{block.items.map((item, itemIndex) => <li key={`${itemIndex}-${item}`}>{item}</li>)}</ul>;
  }
  if (block.type === "ordered-list") {
    return <ol key={index} lang={contentLanguage}>{block.items.map((item, itemIndex) => <li key={`${itemIndex}-${item}`}>{item}</li>)}</ol>;
  }
  if (block.type === "table") {
    return (
      <div className="markdown-table-wrapper" key={index} role="region" aria-label={tableLabel} tabIndex={0}>
        <table lang={contentLanguage}>
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
        aria-label={block.language === null ? t(interfaceLanguage, "markdownCodeBlockAria") : t(interfaceLanguage, "markdownCodeBlockLanguageAria", block.language)}
        tabIndex={0}
      ><code lang={contentLanguage}>{block.code}</code></pre>
    );
  }
  if (block.type === "figure") {
    const source = figureSourcesById.get(block.id);
    return (
      <figure className="lesson-figure" data-figure-id={block.id} key={index}>
        <div
          className="lesson-figure__art"
          role="img"
          aria-label={block.alt}
          dangerouslySetInnerHTML={source === undefined ? undefined : { __html: source }}
        >{source === undefined ? block.alt : undefined}</div>
        {block.textEquivalent.length > 0 ? (
          <details className="lesson-figure__text-equivalent">
            <summary>{t(interfaceLanguage, "markdownFigureTextEquivalent")}</summary>
            <ul>
              {block.textEquivalent.map((item, itemIndex) => <li key={`${itemIndex}-${item}`}>{item}</li>)}
            </ul>
          </details>
        ) : null}
      </figure>
    );
  }
  return null;
}

export function lessonHeadingAnchorSlug(headingText: string): string {
  return headingText
    .trim()
    .replace(/`([^`]+)`/g, "$1")
    .replace(/<[^>]+>/g, "")
    .toLowerCase()
    .replace(/[^\p{Letter}\p{Number}\s-]/gu, "")
    .trim()
    .replace(/\s/g, "-");
}

export function lessonHeadingAnchors(markdown: string, title?: string): string[] {
  const seen = new Map<string, number>();
  const anchors: string[] = [];
  for (const block of parseMarkdownBlocks(markdown, title)) {
    if (block.type !== "heading") {
      continue;
    }
    const baseSlug = lessonHeadingAnchorSlug(block.text);
    if (baseSlug.length === 0) {
      continue;
    }
    const previousCount = seen.get(baseSlug) ?? 0;
    seen.set(baseSlug, previousCount + 1);
    anchors.push(previousCount === 0 ? baseSlug : `${baseSlug}-${previousCount}`);
  }
  return anchors;
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

    const figure = parseFigure(lines, index);
    if (figure !== null) {
      blocks.push(figure.block);
      index = figure.nextIndex;
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
      if (paragraphLine.trim() === "" || /^(#{1,6})(?:\s|$)/.test(paragraphLine) || /^\s*[-*+]\s+/.test(paragraphLine) || /^\s*\d+\.\s+/.test(paragraphLine) || figureDirectiveId(paragraphLine) !== null || isTableStart(lines, index) || parseFencedCode(lines, index) !== null) {
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

function figureDirectiveId(line: string): string | null {
  return /^::figure\s+([a-z0-9][a-z0-9-]*)\s*$/.exec(line.trim())?.[1] ?? null;
}

function parseFigure(lines: readonly string[], startIndex: number): { readonly block: MarkdownBlock; readonly nextIndex: number } | null {
  const id = figureDirectiveId(lines[startIndex] ?? "");
  if (id === null) {
    return null;
  }

  let index = startIndex + 1;
  let alt = "";
  const textEquivalent: string[] = [];
  const fallbackLines = [lines[startIndex]?.trim() ?? ""];
  let readingTextEquivalent = false;

  while (index < lines.length) {
    const line = lines[index] ?? "";
    const trimmed = line.trim();
    if (trimmed === "::") {
      return {
        block: {
          type: "figure",
          id,
          alt: stripInlineMarkdown(alt.length > 0 ? alt : id),
          textEquivalent,
        },
        nextIndex: index + 1,
      };
    }
    if (trimmed === "" || /^(#{1,6})(?:\s|$)/.test(line)) {
      return {
        block: { type: "paragraph", text: stripInlineMarkdown(fallbackLines.join(" ")) },
        nextIndex: index,
      };
    }
    fallbackLines.push(trimmed);

    const altMatch = /^Alt text:\s*(.+)$/i.exec(trimmed);
    if (altMatch !== null) {
      alt = altMatch[1].trim();
      readingTextEquivalent = false;
      index += 1;
      continue;
    }
    if (/^Text equivalent:\s*$/i.test(trimmed)) {
      readingTextEquivalent = true;
      index += 1;
      continue;
    }
    if (readingTextEquivalent && /^[-*+]\s+/.test(trimmed)) {
      textEquivalent.push(stripInlineMarkdown(trimmed.replace(/^[-*+]\s+/, "").trim()));
    }
    index += 1;
  }

  return {
    block: { type: "paragraph", text: stripInlineMarkdown(fallbackLines.join(" ")) },
    nextIndex: index,
  };
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
