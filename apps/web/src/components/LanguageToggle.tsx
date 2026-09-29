import type { Language } from "../data/bank";

interface LanguageToggleProps {
  readonly language: Language;
  readonly onLanguageChange: (language: Language) => void;
}

export function LanguageToggle({ language, onLanguageChange }: LanguageToggleProps) {
  return (
    <fieldset className="language-toggle" aria-label="Question language">
      <legend>Question language</legend>
      <label>
        <input
          type="radio"
          name="language"
          value="en"
          checked={language === "en"}
          onChange={() => onLanguageChange("en")}
        />
        English
      </label>
      <label>
        <input
          type="radio"
          name="language"
          value="fr"
          checked={language === "fr"}
          onChange={() => onLanguageChange("fr")}
        />
        Français
      </label>
    </fieldset>
  );
}
