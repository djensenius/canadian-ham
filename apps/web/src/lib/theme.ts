import type { ThemePreference } from "./progressStore";

export const THEME_STORAGE_KEY = "canadian-ham.theme-preference";

export const THEME_COLORS: Record<"light" | "dark", string> = {
  light: "#F6EEDC",
  dark: "#201B16",
};

export function readStoredThemePreference(): ThemePreference {
  try {
    const storedTheme = globalThis.localStorage?.getItem(THEME_STORAGE_KEY);
    return isThemePreference(storedTheme) ? storedTheme : "system";
  } catch {
    return "system";
  }
}

export function mirrorThemePreference(theme: ThemePreference): void {
  try {
    if (theme === "system") {
      globalThis.localStorage?.removeItem(THEME_STORAGE_KEY);
    } else {
      globalThis.localStorage?.setItem(THEME_STORAGE_KEY, theme);
    }
  } catch {
    // LocalStorage can be unavailable in private or hardened browser modes.
  }
}

export function applyThemePreference(theme: ThemePreference): void {
  if (theme === "system") {
    delete document.documentElement.dataset.theme;
  } else {
    document.documentElement.dataset.theme = theme;
  }
  setThemeColor(resolvedTheme(theme));
}

export function resolvedTheme(theme: ThemePreference): "light" | "dark" {
  if (theme !== "system") {
    return theme;
  }
  return globalThis.matchMedia?.("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function setThemeColor(theme: "light" | "dark"): void {
  const themeColorMeta = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]');
  themeColorMeta?.setAttribute("content", THEME_COLORS[theme]);
}

function isThemePreference(value: string | null | undefined): value is ThemePreference {
  return value === "system" || value === "light" || value === "dark";
}
