import type { Language } from "../data/bank";
import type { LanguagePreference } from "./progressStore";

export function languageForPreferredLocales(preferredLocales: readonly string[] | undefined): Language {
  const primaryLocale = preferredLocales?.find((locale) => locale.trim().length > 0) ?? "";
  return primaryLocale.toLowerCase().startsWith("fr") ? "fr" : "en";
}

export function navigatorPreferredLocales(navigatorLike: Pick<Navigator, "languages" | "language"> | undefined = globalThis.navigator): readonly string[] {
  if (navigatorLike === undefined) {
    return [];
  }
  return navigatorLike.languages.length > 0 ? navigatorLike.languages : [navigatorLike.language];
}

export function resolveLanguagePreference(preference: LanguagePreference, preferredLocales: readonly string[] = navigatorPreferredLocales()): Language {
  return preference === "system" ? languageForPreferredLocales(preferredLocales) : preference;
}
