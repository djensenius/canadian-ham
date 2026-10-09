export const BASIC_BANK_ID = "basic-2025-07-15";
export const ADVANCED_BANK_ID = "advanced-2025-02-04";
export const SYNTHETIC_ADVANCED_BANK_ID = "advanced-synthetic";

export interface BankRules {
  readonly bankId: string;
  readonly categoryIds: readonly string[];
  readonly mockExamQuestionCount: number;
  readonly subsectionCount: number;
  readonly passPercent: number;
  readonly hasHonours: boolean;
  readonly honoursPercent: number | null;
}

export const BASIC_BANK_RULES: BankRules = {
  bankId: BASIC_BANK_ID,
  categoryIds: ["B-001", "B-002", "B-003", "B-004", "B-005", "B-006", "B-007", "B-008"],
  mockExamQuestionCount: 100,
  subsectionCount: 100,
  passPercent: 70,
  hasHonours: true,
  honoursPercent: 80,
};

export const ADVANCED_BANK_RULES: BankRules = {
  bankId: ADVANCED_BANK_ID,
  categoryIds: ["A-001", "A-002", "A-003", "A-004", "A-005", "A-006", "A-007"],
  mockExamQuestionCount: 50,
  subsectionCount: 50,
  passPercent: 70,
  hasHonours: false,
  honoursPercent: null,
};

// Matches packages/schemas/common.schema.json: the whole id, not just the prefix.
const BASIC_BANK_ID_PATTERN = /^basic-\d{4}-\d{2}-\d{2}$/u;
const ADVANCED_BANK_ID_PATTERN = /^advanced-[a-z0-9-]+$/u;

export function rulesForBankId(bankId: string = BASIC_BANK_ID): BankRules {
  if (BASIC_BANK_ID_PATTERN.test(bankId)) {
    return { ...BASIC_BANK_RULES, bankId };
  }
  if (bankId === SYNTHETIC_ADVANCED_BANK_ID || ADVANCED_BANK_ID_PATTERN.test(bankId)) {
    return { ...ADVANCED_BANK_RULES, bankId };
  }
  throw new Error(`unsupported bankId ${bankId}`);
}
