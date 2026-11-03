import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { enMessages, frMessages } from "./i18n";

describe("interface message catalogue", () => {
  it("keeps English and French message keys in parity", () => {
    assert.deepEqual(Object.keys(frMessages).sort(), Object.keys(enMessages).sort());
  });

  it("uses points and traits consistently in French Morse copy", () => {
    assert.equal(frMessages.morseDotPaddle, "Point");
    assert.equal(frMessages.morseDashPaddle, "Trait");
    assert.equal(frMessages.morseDotPaddleAria, "Palette de points. Maintenez pour répéter les points.");
    assert.equal(frMessages.morseDashPaddleAria, "Palette de traits. Maintenez pour répéter les traits.");
    assert.equal(frMessages.morseCourseMeet("A"), "Découvrez A. Écoutez, puis observez ses points et traits.");
    assert.equal(frMessages.morseDotDashWarning, "Entrez les caractères entendus, et non la notation en points et traits.");
    assert.equal(frMessages.morseStraightKeyButtonAria, "Clé droite. Maintenez pour envoyer la tonalité, puis relâchez pour classer le point ou le trait.");
    assert.equal(frMessages.morseSendingNoFeedback, "Envoyez un caractère pour voir le ratio point/trait et la constance du minutage.");
    assert.equal(frMessages.morseSendingFeedbackSummary("A", "3", "100"), "A : ratio point/trait 3, constance du minutage 100 %.");
    assert.equal(frMessages.morseSendingRatioUnavailable, "pas assez de points et de traits");
    assert.ok(frMessages.morseSendingIntro.includes("J/point et K/trait"));
    // The hyphen key is still a typographic trait d’union, not a Morse element.
    assert.equal(frMessages.morseSendingKeyboardHelp, "Clavier : placez d’abord le foyer dans la zone des clés, puis maintenez Espace pour la clé droite; maintenez J ou point pour la palette de points; maintenez K ou trait d’union pour la palette de traits.");
    for (const [key, message] of Object.entries(frMessages)) {
      if (key.startsWith("morse") && typeof message === "string") {
        assert.doesNotMatch(message, /\btirets?\b/i, key);
      }
    }
  });
});
