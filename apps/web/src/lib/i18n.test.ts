import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { enMessages, frMessages, INTERFACE_LANGUAGE_STORAGE_KEY, readStoredInterfaceLanguage, t } from "./i18n";

function setNavigatorLanguages(language: string, languages: readonly string[]): () => void {
  const originalLanguage = navigator.language;
  const originalLanguages = navigator.languages;
  Object.defineProperty(navigator, "language", { value: language, configurable: true });
  Object.defineProperty(navigator, "languages", { value: languages, configurable: true });
  return () => {
    Object.defineProperty(navigator, "language", { value: originalLanguage, configurable: true });
    Object.defineProperty(navigator, "languages", { value: originalLanguages, configurable: true });
  };
}

function useMemoryLocalStorage(): Storage {
  const values = new Map<string, string>();
  const storage = {
    get length() {
      return values.size;
    },
    clear: () => values.clear(),
    getItem: (key: string) => values.get(key) ?? null,
    key: (index: number) => [...values.keys()][index] ?? null,
    removeItem: (key: string) => { values.delete(key); },
    setItem: (key: string, value: string) => { values.set(key, value); },
  };
  Object.defineProperty(window, "localStorage", { configurable: true, value: storage });
  return storage;
}

describe("interface message catalogue", () => {
  it("keeps English and French message keys in parity", () => {
    assert.deepEqual(Object.keys(frMessages).sort(), Object.keys(enMessages).sort());
  });

  it("reads stored interface language before navigator defaults", () => {
    const restoreNavigator = setNavigatorLanguages("fr-CA", ["fr-CA", "en-CA"]);
    const storage = useMemoryLocalStorage();
    try {
      storage.setItem(INTERFACE_LANGUAGE_STORAGE_KEY, "en");
      assert.equal(readStoredInterfaceLanguage(), "en");
      assert.equal(t("fr", "navSettings"), "Réglages");
    } finally {
      restoreNavigator();
    }
  });

  it("defaults to English when the first navigator language is English", () => {
    const restoreNavigator = setNavigatorLanguages("en-CA", ["en-CA", "fr-CA"]);
    const storage = useMemoryLocalStorage();
    try {
      storage.removeItem(INTERFACE_LANGUAGE_STORAGE_KEY);
      assert.equal(readStoredInterfaceLanguage(), "en");
    } finally {
      restoreNavigator();
    }
  });
});
