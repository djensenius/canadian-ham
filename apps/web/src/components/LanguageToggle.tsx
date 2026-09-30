import type { Language } from "../data/bank";
import { t, type InterfaceLanguage } from "../lib/i18n";

interface LanguageToggleProps {
  readonly language: Language;
  readonly interfaceLanguage: InterfaceLanguage;
  readonly onLanguageChange: (language: Language) => void;
}

export function LanguageToggle({ language, interfaceLanguage, onLanguageChange }: LanguageToggleProps) {
  return (
    <fieldset className="language-toggle" aria-label={t(interfaceLanguage, "languageQuestionAria")}>
      <legend>{t(interfaceLanguage, "languageQuestionLegend")}</legend>
      <label>
        <input
          type="radio"
          name="language"
          value="en"
          checked={language === "en"}
          onChange={() => onLanguageChange("en")}
        />
        <span lang={interfaceLanguage === "fr" ? "en" : undefined}>{t(interfaceLanguage, "languageEnglish")}</span>
      </label>
      <label>
        <input
          type="radio"
          name="language"
          value="fr"
          checked={language === "fr"}
          onChange={() => onLanguageChange("fr")}
        />
        <span lang="fr">{t(interfaceLanguage, "languageFrench")}</span>
      </label>
    </fieldset>
  );
}
