import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { languageForPreferredLocales, resolveLanguagePreference } from "./languagePreference";

describe("language preference resolution", () => {
  it("uses French for primary fr locales and English otherwise", () => {
    assert.equal(languageForPreferredLocales(["fr-CA", "en-CA"]), "fr");
    assert.equal(languageForPreferredLocales(["fr", "en-CA"]), "fr");
    assert.equal(languageForPreferredLocales(["en-CA", "fr-CA"]), "en");
    assert.equal(languageForPreferredLocales(["de-DE"]), "en");
    assert.equal(languageForPreferredLocales([]), "en");
  });

  it("honours explicit overrides before system locales", () => {
    assert.equal(resolveLanguagePreference("system", ["fr-CA"]), "fr");
    assert.equal(resolveLanguagePreference("en", ["fr-CA"]), "en");
    assert.equal(resolveLanguagePreference("fr", ["en-CA"]), "fr");
  });
});
