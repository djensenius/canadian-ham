import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { ACTIVE_BANK_ID, ACTIVE_GENERATED_DIR } from "./active-bank.ts";
import { isMainModule } from "./cli.ts";
import { loadQuestionHints, referenceSheetSectionKeys, type LoadedQuestionHint, type QuestionHint, type ReferenceSheetSectionKey } from "./hints.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_HINT_ROOT = path.join(REPO_ROOT, "content/hints");
const DEFAULT_QUESTION_PATH = path.join(REPO_ROOT, ACTIVE_GENERATED_DIR, "questions.json");
const EXPECTED_BANK_ID = ACTIVE_BANK_ID;
const EXPECTED_LICENSE_CLASS = "original";
const HINT_ID_PREFIX = "HINT-";

// Leakage tuning: exact answer/option checks require a meaningful phrase, not just
// common numbers or units. Question-fragment checks compare six-token n-grams after
// dropping low-information tokens. Six tokens catches copied wording such as
// "keeps the signal stable during a long contact" while allowing normal repeated
// technical vocabulary and values like "12 V" or "2 A" in setup hints.
const QUESTION_FRAGMENT_GRAM_SIZE = 6;
const LOW_INFORMATION_TOKENS = new Set([
  "a", "an", "and", "are", "as", "at", "be", "by", "for", "from", "how", "in", "is", "it", "of", "on", "or", "the", "to", "what", "when", "where", "which", "why", "with",
  "de", "des", "du", "la", "le", "les", "un", "une", "et", "ou", "en", "dans", "pour", "par", "sur", "quel", "quelle", "quels", "quelles", "est", "sont", "au", "aux",
  "v", "volt", "volts", "a", "amp", "amps", "ampere", "amperes", "ohm", "ohms", "w", "watt", "watts", "hz", "khz", "mhz", "ghz", "db", "m", "mm", "cm", "km", "pf", "uf", "nf", "f",
]);
const REFERENCE_SHEET_WORDS = ["reference sheet", "reference material", "formula sheet", "feuille de référence", "document de référence"];

export type LocalizedText = {
  readonly en: string;
  readonly fr: string;
};

type AnswerRecord = {
  readonly sourceIndex: number;
  readonly isCorrect: boolean;
  readonly text: LocalizedText;
};

type QuestionRecord = {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly subsectionId: string;
  readonly text: LocalizedText;
  readonly answers: readonly AnswerRecord[];
};

export type HintCheckOptions = {
  readonly hintRoot?: string;
  readonly questionsPath?: string;
  readonly categoryId?: string;
  readonly subsectionId?: string;
  readonly requireComplete?: boolean;
};

export type HintCheckReport = {
  readonly hintFileCount: number;
  readonly hintQuestionCount: number;
  readonly checkedQuestionCount: number;
  readonly issues: readonly string[];
  readonly summaryLines: readonly string[];
};

export class HintCheckError extends Error {
  readonly report: HintCheckReport;

  constructor(report: HintCheckReport) {
    super("hint check failed");
    this.report = report;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function hasLocalizedText(value: unknown): value is LocalizedText {
  return isRecord(value) && isNonEmptyString(value.en) && isNonEmptyString(value.fr);
}

async function loadQuestions(questionsPath: string): Promise<Map<string, QuestionRecord>> {
  const raw: unknown = JSON.parse(await readFile(questionsPath, "utf8"));
  if (!Array.isArray(raw)) {
    throw new Error(`${questionsPath}: expected an array of question records`);
  }
  const questions = new Map<string, QuestionRecord>();
  for (const [index, item] of raw.entries()) {
    if (!isRecord(item) || !isNonEmptyString(item.id) || !isNonEmptyString(item.bankId) || !isNonEmptyString(item.categoryId) || !isNonEmptyString(item.subsectionId) || !hasLocalizedText(item.text) || !Array.isArray(item.answers)) {
      throw new Error(`${questionsPath}: question record ${index} has an invalid shape`);
    }
    const answers: AnswerRecord[] = [];
    for (const [answerIndex, answer] of item.answers.entries()) {
      if (!isRecord(answer) || typeof answer.sourceIndex !== "number" || !Number.isInteger(answer.sourceIndex) || typeof answer.isCorrect !== "boolean" || !hasLocalizedText(answer.text)) {
        throw new Error(`${questionsPath}: ${item.id} answer ${answerIndex} has an invalid shape`);
      }
      answers.push({ sourceIndex: answer.sourceIndex, isCorrect: answer.isCorrect, text: answer.text });
    }
    questions.set(item.id, { id: item.id, bankId: item.bankId, categoryId: item.categoryId, subsectionId: item.subsectionId, text: item.text, answers });
  }
  return questions;
}

function normalizeText(value: string): string {
  return value
    .normalize("NFKD")
    .replace(/\p{Diacritic}/gu, "")
    .replace(/[’‘`]/g, "'")
    .replace(/[×]/g, "x")
    .toLowerCase();
}

function tokens(value: string): string[] {
  return normalizeText(value).match(/[\p{L}\p{N}]+/gu) ?? [];
}

function significantTokens(value: string): string[] {
  return tokens(value).filter((token) => !isLowInformationToken(token));
}

function isLowInformationToken(token: string): boolean {
  return /^\d+(?:\.\d+)?$/u.test(token) || token.length <= 1 || LOW_INFORMATION_TOKENS.has(token);
}

function containsTokenPhrase(haystackTokens: readonly string[], needleTokens: readonly string[]): boolean {
  if (needleTokens.length === 0 || haystackTokens.length < needleTokens.length) {
    return false;
  }
  for (let start = 0; start <= haystackTokens.length - needleTokens.length; start += 1) {
    let matches = true;
    for (let offset = 0; offset < needleTokens.length; offset += 1) {
      if (haystackTokens[start + offset] !== needleTokens[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return true;
    }
  }
  return false;
}

function shouldCheckOfficialPhrase(officialText: string): boolean {
  const officialTokens = tokens(officialText);
  const meaningfulTokens = officialTokens.filter((token) => !isLowInformationToken(token));
  if (officialTokens.length >= 4 && meaningfulTokens.length >= 1) {
    return true;
  }
  if (officialTokens.length >= 2 && meaningfulTokens.join("").length >= 8) {
    return true;
  }
  return officialTokens.length === 1 && meaningfulTokens.length === 1 && meaningfulTokens[0]!.length >= 5;
}

function checkOfficialPhraseLeakage(hintText: string, officialText: string): boolean {
  if (!shouldCheckOfficialPhrase(officialText)) {
    return false;
  }
  return containsTokenPhrase(tokens(hintText), tokens(officialText));
}

function ngrams(values: readonly string[], size: number): string[] {
  if (values.length < size) {
    return [];
  }
  const result: string[] = [];
  for (let index = 0; index <= values.length - size; index += 1) {
    result.push(values.slice(index, index + size).join(" "));
  }
  return result;
}

function findQuestionFragmentLeakage(hintText: string, questionText: string): string | null {
  const hintGrams = new Set(ngrams(significantTokens(hintText), QUESTION_FRAGMENT_GRAM_SIZE));
  if (hintGrams.size === 0) {
    return null;
  }
  for (const gram of ngrams(significantTokens(questionText), QUESTION_FRAGMENT_GRAM_SIZE)) {
    if (hintGrams.has(gram)) {
      return gram;
    }
  }
  return null;
}

function validateHintShape(hint: LoadedQuestionHint, relativePath: string, issues: string[]): void {
  if (!isNonEmptyString(hint.id)) {
    issues.push(`${relativePath}: id must be a non-empty string`);
  }
  if (!isNonEmptyString(hint.questionId)) {
    issues.push(`${relativePath}: questionId must be a non-empty string`);
  }
  if (hint.id !== `${HINT_ID_PREFIX}${hint.questionId}`) {
    issues.push(`${relativePath}: id must be ${HINT_ID_PREFIX}${hint.questionId}`);
  }
  if (hint.bankId !== EXPECTED_BANK_ID) {
    issues.push(`${relativePath}: bankId must be ${EXPECTED_BANK_ID}`);
  }
  if (!isNonEmptyString(hint.status)) {
    issues.push(`${relativePath}: status must be a non-empty string`);
  }
  if (hint.licenseClass !== EXPECTED_LICENSE_CLASS) {
    issues.push(`${relativePath}: licenseClass must be ${EXPECTED_LICENSE_CLASS}`);
  }
  if (!Array.isArray(hint.hints) || hint.hints.length !== 2) {
    issues.push(`${relativePath}: hints must contain exactly two entries`);
    return;
  }
  for (const [index, step] of hint.hints.entries()) {
    const expectedLevel = index + 1;
    const label = `${relativePath}: hints[${index}]`;
    if (!isRecord(step)) {
      issues.push(`${label} must be an object`);
      continue;
    }
    if (step.level !== expectedLevel) {
      issues.push(`${label}.level must be ${expectedLevel}`);
    }
    if (!isNonEmptyString(step.en)) {
      issues.push(`${label}.en must be non-empty`);
    }
    if (!isNonEmptyString(step.fr)) {
      issues.push(`${label}.fr must be non-empty`);
    }
  }
  if (hint.referenceSheetSection !== undefined && hint.referenceSheetSection !== null && !(referenceSheetSectionKeys as readonly string[]).includes(hint.referenceSheetSection)) {
    issues.push(`${relativePath}: referenceSheetSection must be one of ${referenceSheetSectionKeys.join(", ")} or null`);
  }
}

function validateHintLocation(hint: LoadedQuestionHint, relativePath: string, question: QuestionRecord | undefined, issues: string[]): void {
  if (question === undefined) {
    return;
  }
  const expectedCategory = question.categoryId.toLowerCase();
  const expectedFile = path.join(expectedCategory, `${hint.questionId.toLowerCase()}.json`).split(path.sep).join("/");
  const normalizedPath = relativePath.split(path.sep).join("/");
  if (!normalizedPath.endsWith(expectedFile)) {
    issues.push(`${relativePath}: expected location to end with ${expectedFile}`);
  }
}

function validateHintLeakage(hint: LoadedQuestionHint, relativePath: string, question: QuestionRecord, issues: string[]): void {
  for (const step of hint.hints) {
    for (const language of ["en", "fr"] as const) {
      const hintText = step[language];
      const label = `${relativePath}: level ${step.level} ${language}`;
      if (REFERENCE_SHEET_WORDS.some((word) => normalizeText(hintText).includes(normalizeText(word)))) {
        issues.push(`${label}: reference-sheet pointer text belongs in UI metadata, not hint prose`);
      }
      const questionFragment = findQuestionFragmentLeakage(hintText, question.text[language]);
      if (questionFragment !== null) {
        issues.push(`${label}: copies a long question fragment (${JSON.stringify(questionFragment)})`);
      }
      for (const answer of question.answers) {
        const answerText = answer.text[language];
        if (checkOfficialPhraseLeakage(hintText, answerText)) {
          const kind = answer.isCorrect ? "correct answer" : `answer option sourceIndex ${answer.sourceIndex}`;
          issues.push(`${label}: contains ${kind} text ${JSON.stringify(answerText)}`);
        }
      }
    }
  }
}

function filteredQuestions(questions: Iterable<QuestionRecord>, options: HintCheckOptions): QuestionRecord[] {
  return [...questions]
    .filter((question) => options.categoryId === undefined || question.categoryId === options.categoryId)
    .filter((question) => options.subsectionId === undefined || question.subsectionId === options.subsectionId)
    .sort((a, b) => a.id.localeCompare(b.id));
}

function filteredHints(hints: readonly LoadedQuestionHint[], questionsById: ReadonlyMap<string, QuestionRecord>, options: HintCheckOptions): LoadedQuestionHint[] {
  return hints.filter((hint) => {
    const question = questionsById.get(hint.questionId);
    if (question === undefined) {
      return true;
    }
    if (options.categoryId !== undefined && question.categoryId !== options.categoryId) {
      return false;
    }
    return !(options.subsectionId !== undefined && question.subsectionId !== options.subsectionId);
  });
}

export async function checkHints(options: HintCheckOptions = {}): Promise<HintCheckReport> {
  const hintRoot = options.hintRoot ?? DEFAULT_HINT_ROOT;
  const questionsPath = options.questionsPath ?? DEFAULT_QUESTION_PATH;
  const issues: string[] = [];
  const questionsById = await loadQuestions(questionsPath);
  const selectedQuestions = filteredQuestions(questionsById.values(), options);
  const selectedQuestionIds = new Set(selectedQuestions.map((question) => question.id));
  const allHints = await loadQuestionHints({ hintRoot });
  const hints = filteredHints(allHints, questionsById, options);
  const hintsByQuestionId = new Map<string, LoadedQuestionHint>();

  for (const hint of hints) {
    const relativePath = path.relative(hintRoot, hint.filePath).split(path.sep).join("/");
    validateHintShape(hint, relativePath, issues);
    const previous = hintsByQuestionId.get(hint.questionId);
    if (previous !== undefined) {
      issues.push(`${relativePath}: duplicate hint for ${hint.questionId}; first seen in ${path.relative(hintRoot, previous.filePath).split(path.sep).join("/")}`);
    } else {
      hintsByQuestionId.set(hint.questionId, hint);
    }
    const question = questionsById.get(hint.questionId);
    if (question === undefined) {
      issues.push(`${relativePath}: questionId ${hint.questionId} is not in the active question bank`);
      continue;
    }
    if (!selectedQuestionIds.has(question.id)) {
      continue;
    }
    validateHintLocation(hint, relativePath, question, issues);
    validateHintLeakage(hint, relativePath, question, issues);
  }

  if (options.requireComplete === true) {
    for (const question of selectedQuestions) {
      if (!hintsByQuestionId.has(question.id)) {
        issues.push(`${question.id}: missing hint file`);
      }
    }
  }

  const report: HintCheckReport = {
    hintFileCount: hints.length,
    hintQuestionCount: hintsByQuestionId.size,
    checkedQuestionCount: selectedQuestions.length,
    issues,
    summaryLines: [
      `check-hints: checked ${hints.length} hint file(s) for ${selectedQuestions.length} active Basic question(s)`,
      options.requireComplete === true ? "check-hints: completeness requirement enabled" : "check-hints: completeness requirement disabled",
    ],
  };
  if (issues.length > 0) {
    throw new HintCheckError(report);
  }
  return report;
}

type MutableHintCheckOptions = {
  hintRoot?: string;
  questionsPath?: string;
  categoryId?: string;
  subsectionId?: string;
  requireComplete?: boolean;
};

function parseArgs(argv: readonly string[]): HintCheckOptions & { readonly selfTest: boolean } {
  const options: MutableHintCheckOptions & { selfTest: boolean } = { selfTest: false };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index]!;
    if (arg === "--self-test") {
      options.selfTest = true;
    } else if (arg === "--category") {
      options.categoryId = requireValue(argv, ++index, arg);
    } else if (arg === "--subsection") {
      options.subsectionId = requireValue(argv, ++index, arg);
    } else if (arg === "--require-complete") {
      options.requireComplete = true;
    } else if (arg === "--hint-root") {
      options.hintRoot = path.resolve(process.cwd(), requireValue(argv, ++index, arg));
    } else if (arg === "--questions") {
      options.questionsPath = path.resolve(process.cwd(), requireValue(argv, ++index, arg));
    } else {
      throw new Error(`unknown argument ${arg}`);
    }
  }
  return { selfTest: options.selfTest, hintRoot: options.hintRoot, questionsPath: options.questionsPath, categoryId: options.categoryId, subsectionId: options.subsectionId, requireComplete: options.requireComplete };
}

function requireValue(argv: readonly string[], index: number, flag: string): string {
  const value = argv[index];
  if (value === undefined || value.startsWith("--")) {
    throw new Error(`${flag} requires a value`);
  }
  return value;
}

function question(overrides: Partial<QuestionRecord> = {}): QuestionRecord {
  return {
    id: "B-001-001-001",
    bankId: EXPECTED_BANK_ID,
    categoryId: "B-001",
    subsectionId: "B-001-001",
    text: {
      en: "Which part of a fixture station keeps the signal stable during a long contact?",
      fr: "Quelle partie d'une station fictive garde le signal stable pendant un long contact?",
    },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Stable oscillator", fr: "Oscillateur stable" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Loose antenna", fr: "Antenne desserrée" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Bright display", fr: "Afficheur lumineux" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Long power cord", fr: "Long cordon d'alimentation" } },
    ],
    ...overrides,
  };
}

function hint(overrides: Partial<QuestionHint> = {}): QuestionHint {
  return {
    id: "HINT-B-001-001-001",
    questionId: "B-001-001-001",
    bankId: EXPECTED_BANK_ID,
    status: "draft",
    hints: [
      {
        level: 1,
        en: "Think about the circuit block that sets a steady radio-frequency rhythm.",
        fr: "Pensez au bloc de circuit qui fixe un rythme radiofréquence régulier.",
      },
      {
        level: 2,
        en: "Ignore cables and displays; choose the block that controls frequency stability.",
        fr: "Ignorez les câbles et les afficheurs; choisissez le bloc qui contrôle la stabilité de fréquence.",
      },
    ],
    referenceSheetSection: null,
    licenseClass: "original",
    ...overrides,
  };
}

async function withSelfTestFixture(name: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-hints-${name}-`));
  try {
    await mkdir(path.join(root, "content/hints/b-001"), { recursive: true });
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await run(root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

async function writeSelfTestFixture(root: string, hintRecord: QuestionHint, questions: readonly QuestionRecord[] = [question()]): Promise<void> {
  await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), `${JSON.stringify(questions, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "content/hints/b-001/b-001-001-001.json"), `${JSON.stringify(hintRecord, null, 2)}\n`, "utf8");
}

async function assertSelfTestRejects(name: string, hintRecord: QuestionHint, expectedIssue: string, questions: readonly QuestionRecord[] = [question()]): Promise<void> {
  await withSelfTestFixture(name, async (root) => {
    await writeSelfTestFixture(root, hintRecord, questions);
    try {
      await checkHints({
        hintRoot: path.join(root, "content/hints"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
        requireComplete: true,
      });
    } catch (error: unknown) {
      if (error instanceof HintCheckError && error.report.issues.some((issue) => issue.includes(expectedIssue))) {
        return;
      }
      throw error;
    }
    throw new Error(`${name}: expected hint check to reject ${expectedIssue}`);
  });
}

export async function runHintCheckerSelfTest(): Promise<void> {
  await withSelfTestFixture("valid", async (root) => {
    await writeSelfTestFixture(root, hint());
    await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      requireComplete: true,
    });
  });

  await assertSelfTestRejects("correct-answer", hint({ hints: [
    { level: 1, en: "Think about a stable oscillator before answering.", fr: "Pensez à un bloc de fréquence régulier avant de répondre." },
    { level: 2, en: "Choose the block that holds frequency steady.", fr: "Choisissez le bloc qui garde la fréquence stable." },
  ] }), "correct answer text");

  await assertSelfTestRejects("option", hint({ hints: [
    { level: 1, en: "Eliminate a loose antenna before choosing.", fr: "Écartez une antenne desserrée avant de choisir." },
    { level: 2, en: "Focus on frequency control, not station wiring.", fr: "Concentrez-vous sur le contrôle de fréquence, pas sur le câblage." },
  ] }), "answer option sourceIndex 1");

  await assertSelfTestRejects("question-fragment", hint({ hints: [
    { level: 1, en: "Ask what keeps the signal stable during a long contact.", fr: "Demandez-vous ce qui garde le signal stable pendant un long contact." },
    { level: 2, en: "Focus on frequency control.", fr: "Concentrez-vous sur le contrôle de fréquence." },
  ] }), "copies a long question fragment");

  await assertSelfTestRejects("missing-fr", hint({ hints: [
    { level: 1, en: "Think about the frequency-control block.", fr: "" },
    { level: 2, en: "Focus on the part that sets the rhythm.", fr: "Concentrez-vous sur la partie qui fixe le rythme." },
  ] }), "hints[0].fr must be non-empty");

  await assertSelfTestRejects("bad-reference", hint({ referenceSheetSection: "bad-section" as ReferenceSheetSectionKey }), "referenceSheetSection must be one of");

  await withSelfTestFixture("common-numbers-units", async (root) => {
    const numericQuestion = question({
      text: { en: "Fixture calculation question?", fr: "Question de calcul fictive?" },
      answers: [
        { sourceIndex: 0, isCorrect: true, text: { en: "12 V", fr: "12 V" } },
        { sourceIndex: 1, isCorrect: false, text: { en: "2 A", fr: "2 A" } },
        { sourceIndex: 2, isCorrect: false, text: { en: "5 W", fr: "5 W" } },
        { sourceIndex: 3, isCorrect: false, text: { en: "50 ohms", fr: "50 ohms" } },
      ],
    });
    await writeSelfTestFixture(root, hint({ hints: [
      { level: 1, en: "Use the formula with 12 V and 2 A after converting units.", fr: "Utilisez la formule avec 12 V et 2 A après les conversions d'unités." },
      { level: 2, en: "Set the known values into the relationship, then solve without rounding early.", fr: "Placez les valeurs connues dans la relation, puis calculez sans arrondir trop tôt." },
    ] }), [numericQuestion]);
    await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      requireComplete: true,
    });
  });
}

async function main(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  if (options.selfTest) {
    await runHintCheckerSelfTest();
    console.log("check-hints self-test: passed");
    return;
  }
  const report = await checkHints(options);
  for (const line of report.summaryLines) {
    console.log(line);
  }
}

if (isMainModule(import.meta)) {
  main().catch((error: unknown) => {
    if (error instanceof HintCheckError) {
      console.error(`check-hints failed with ${error.report.issues.length} issue(s):`);
      for (const issue of error.report.issues.slice(0, 100)) {
        console.error(`- ${issue}`);
      }
      if (error.report.issues.length > 100) {
        console.error(`... ${error.report.issues.length - 100} more issue(s) omitted.`);
      }
    } else {
      const message = error instanceof Error ? error.message : String(error);
      console.error(message);
    }
    process.exitCode = 1;
  });
}
