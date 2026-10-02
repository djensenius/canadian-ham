export const BASIC_BANK_ID = "basic-2025-07-15";
export const SYNTHETIC_ADVANCED_BANK_ID = "advanced-synthetic";

export interface ContentBankCategoryRules {
  readonly id: string;
  readonly questionCount: number;
  readonly subsectionCount: number;
  readonly examQuestionCount: number;
}

export interface ContentBankRules {
  readonly bankId: string;
  readonly certificate: "canadian-amateur-basic" | "canadian-amateur-advanced";
  readonly questionIdPrefix: "B" | "A";
  readonly effectiveDate: string | null;
  readonly questionCount: number;
  readonly subsectionCount: number;
  readonly categoryCount: number;
  readonly examQuestionCount: number;
  readonly passPercent: number;
  readonly hasHonours: boolean;
  readonly honoursPercent: number | null;
  readonly categoryRules: readonly ContentBankCategoryRules[];
}

export const BASIC_BANK_RULES: ContentBankRules = {
  bankId: BASIC_BANK_ID,
  certificate: "canadian-amateur-basic",
  questionIdPrefix: "B",
  effectiveDate: "2025-07-15",
  questionCount: 984,
  subsectionCount: 100,
  categoryCount: 8,
  examQuestionCount: 100,
  passPercent: 70,
  hasHonours: true,
  honoursPercent: 80,
  categoryRules: [
    { id: "B-001", questionCount: 199, subsectionCount: 25, examQuestionCount: 25 },
    { id: "B-002", questionCount: 99, subsectionCount: 9, examQuestionCount: 9 },
    { id: "B-003", questionCount: 199, subsectionCount: 21, examQuestionCount: 21 },
    { id: "B-004", questionCount: 63, subsectionCount: 6, examQuestionCount: 6 },
    { id: "B-005", questionCount: 142, subsectionCount: 13, examQuestionCount: 13 },
    { id: "B-006", questionCount: 140, subsectionCount: 13, examQuestionCount: 13 },
    { id: "B-007", questionCount: 87, subsectionCount: 8, examQuestionCount: 8 },
    { id: "B-008", questionCount: 55, subsectionCount: 5, examQuestionCount: 5 },
  ],
};

export const ADVANCED_BANK_RULES: ContentBankRules = {
  bankId: SYNTHETIC_ADVANCED_BANK_ID,
  certificate: "canadian-amateur-advanced",
  questionIdPrefix: "A",
  effectiveDate: null,
  questionCount: 549,
  subsectionCount: 50,
  categoryCount: 7,
  examQuestionCount: 50,
  passPercent: 70,
  hasHonours: false,
  honoursPercent: null,
  categoryRules: [
    { id: "A-001", questionCount: 54, subsectionCount: 5, examQuestionCount: 5 },
    { id: "A-002", questionCount: 132, subsectionCount: 12, examQuestionCount: 12 },
    { id: "A-003", questionCount: 66, subsectionCount: 6, examQuestionCount: 6 },
    { id: "A-004", questionCount: 44, subsectionCount: 4, examQuestionCount: 4 },
    { id: "A-005", questionCount: 99, subsectionCount: 9, examQuestionCount: 9 },
    { id: "A-006", questionCount: 55, subsectionCount: 5, examQuestionCount: 5 },
    { id: "A-007", questionCount: 99, subsectionCount: 9, examQuestionCount: 9 },
  ],
};

// Matches packages/schemas/common.schema.json: the whole id, not just the prefix.
const ADVANCED_BANK_ID_PATTERN = /^advanced-[a-z0-9-]+$/u;

export function contentRulesForBankId(bankId: string = BASIC_BANK_ID): ContentBankRules {
  if (bankId === BASIC_BANK_ID) {
    return BASIC_BANK_RULES;
  }
  if (bankId === SYNTHETIC_ADVANCED_BANK_ID || ADVANCED_BANK_ID_PATTERN.test(bankId)) {
    return { ...ADVANCED_BANK_RULES, bankId };
  }
  throw new Error(`unsupported bankId ${bankId}`);
}
