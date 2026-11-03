import { slugForHeadingText } from "./check-links.ts";

type HintLessonLink = { lessonId: string; sectionAnchor?: string };

// M1 rounds are authored once for both readers; hints remain the teaching-section authority.
export function quizRoundIssues(
  rounds: unknown,
  lessonId: string,
  officialQuestionIds: readonly string[],
  conceptCheckCount: number,
  markdown: string,
  hintLinks: ReadonlyMap<string, HintLessonLink>,
): string[] {
  const issues: string[] = [];
  if (!Array.isArray(rounds) || rounds.length === 0) return ["M1 quizzes require nonempty rounds"];
  if (conceptCheckCount !== 0) issues.push("M1 rounds require official-only quizzes");
  const headings = [...markdown.matchAll(/^## (.+)$/gm)].map((match) => ({ title: match[1]!, anchor: slugForHeadingText(match[1]!) }));
  let previousHeadingIndex = -1;
  const mappedIds: string[] = [];
  for (const [index, round] of rounds.entries()) {
    const prefix = `rounds[${index}]`;
    if (round === null || typeof round !== "object" || Array.isArray(round)) {
      issues.push(`${prefix} must be an object`);
      continue;
    }
    const headingIndex = headings.findIndex((heading) => heading.anchor === round.sectionAnchor);
    if (headingIndex === -1 || headingIndex <= previousHeadingIndex) issues.push(`${prefix} must name a unique teaching section in lesson heading order`);
    previousHeadingIndex = Math.max(previousHeadingIndex, headingIndex);
    const heading = headings[headingIndex];
    if (round.title?.en !== heading?.title || typeof round.title?.fr !== "string" || !round.title.fr.trim()) {
      issues.push(`${prefix} title must match its lesson heading and have a French translation`);
    }
    if (!Array.isArray(round.officialQuestionIds) || round.officialQuestionIds.length === 0) {
      issues.push(`${prefix} requires nonempty officialQuestionIds`);
      continue;
    }
    for (const id of round.officialQuestionIds) {
      mappedIds.push(id);
      const link = hintLinks.get(id);
      if (link?.lessonId !== lessonId || link.sectionAnchor !== round.sectionAnchor) issues.push(`${prefix} ${id} must match its hint teaching section`);
    }
  }
  if (mappedIds.length !== officialQuestionIds.length || new Set(mappedIds).size !== mappedIds.length
      || officialQuestionIds.some((id) => !mappedIds.includes(id)) || mappedIds.some((id) => !officialQuestionIds.includes(id))) {
    issues.push("rounds must map every official question exactly once, with no extra items");
  }
  return issues;
}
