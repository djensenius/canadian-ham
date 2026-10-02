import { BASIC_BANK_ID, contentRulesForBankId } from "./banks.ts";

export const ACTIVE_BANK_ID = BASIC_BANK_ID;
export const ACTIVE_BANK_RULES = contentRulesForBankId(ACTIVE_BANK_ID);
export const ACTIVE_GENERATED_DIR = `content/generated/${ACTIVE_BANK_ID}`;
export const ACTIVE_SOURCE_DIR = `content/sources/ised/${ACTIVE_BANK_ID}`;
