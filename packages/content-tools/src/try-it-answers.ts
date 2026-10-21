// Try-its use one numbered prompt followed by one plain-prose answer directive.
// Keep this grammar aligned with MarkdownContent and LessonMarkdownRenderer.
export function validateTryItAnswers(markdown: string): string[] {
  const lines = markdown.replace(/\r\n/gu, "\n").split("\n");
  const issues: string[] = [];
  let inTryIt = false;
  let nextNumber = 1;
  let itemCount = 0;
  const report = (index: number, message: string) => issues.push(`line ${index + 1}: ${message}`);
  const skipBlank = (index: number): number => {
    while (index < lines.length && lines[index]!.trim() === "") index += 1;
    return index;
  };
  const finishSection = (index: number) => {
    if (inTryIt && itemCount === 0) report(index, "Try it requires at least one numbered prompt and hidden answer");
  };

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index]!;
    if (/^## /u.test(line)) {
      finishSection(index);
      inTryIt = line === "## Try it";
      nextNumber = 1;
      itemCount = 0;
      continue;
    }
    if (!inTryIt) {
      if (/^:::answer\b|^:::$/u.test(line)) report(index, "answer directives belong only to numbered Try-it prompts");
      continue;
    }
    const prompt = /^(\d+)\. (.+)$/u.exec(line);
    if (prompt === null) {
      if (line.trim() !== "" && (itemCount > 0 || /^### |^:::|^[-*+] /u.test(line))) {
        report(index, "Try it allows only introductory prose, then numbered prompts with hidden answers");
      }
      continue;
    }
    itemCount += 1;
    if (Number(prompt[1]) !== nextNumber) report(index, `expected Try-it number ${nextNumber}`);
    nextNumber += 1;
    if (/\?\s+\S|\b(?:answer|solution):/iu.test(prompt[2]!)) report(index, "inline Try-it answers are not allowed; use :::answer");
    const opening = skipBlank(index + 1);
    if (lines[opening] !== ":::answer") {
      report(index, "each Try-it prompt requires a following :::answer block");
      continue;
    }
    const answer = lines[opening + 1];
    if (answer === undefined || answer.trim() === "" || /^(?:#|:::|\d+\. |[-*+] )/u.test(answer)) {
      report(opening, "answer must contain one nonempty line of plain prose");
    }
    if (lines[opening + 2] !== ":::") {
      report(opening, "answer must be one line of prose followed by ::: on its own line");
      continue;
    }
    index = opening + 2;
  }
  finishSection(lines.length - 1);
  return issues;
}
