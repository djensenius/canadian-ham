import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { enMessages, frMessages, INTERFACE_LANGUAGE_STORAGE_KEY, readStoredInterfaceLanguage, t } from "./i18n";

describe("interface message catalogue", () => {
  it("keeps English and French message keys in parity", () => {
    assert.deepEqual(Object.keys(frMessages).sort(), Object.keys(enMessages).sort());
  });

  it("reads stored interface language before navigator defaults", () => {
    const values = new Map<string, string>();
    Object.defineProperty(window, "localStorage", {
      configurable: true,
      value: {
        getItem: (key: string) => values.get(key) ?? null,
        removeItem: (key: string) => { values.delete(key); },
        setItem: (key: string, value: string) => { values.set(key, value); },
      },
    });
    window.localStorage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "en");
    assert.equal(readStoredInterfaceLanguage(), "en");
    assert.equal(t("fr", "navSettings"), "Réglages");
  });
});
