import { realpathSync } from "node:fs";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { contrastRows, type TokenSet } from "./token-utils.ts";

interface Tokens extends TokenSet {
  readonly themes: Record<string, { readonly colors: Record<string, string> }>;
  readonly typography: {
    readonly families: Record<string, string>;
    readonly scale: Record<string, { readonly rem: number; readonly lineHeight: number; readonly appleTextStyle: string }>;
  };
  readonly spacing: Record<string, number>;
  readonly radii: Record<string, number>;
  readonly motion: {
    readonly durations: Record<string, number>;
    readonly easing: Record<string, string>;
  };
}

const PACKAGE_ROOT = fileURLToPath(new URL("../", import.meta.url));
const REPO_ROOT = path.resolve(PACKAGE_ROOT, "../..");
const TOKENS_PATH = path.join(PACKAGE_ROOT, "tokens.json");
const CSS_PATH = path.join(REPO_ROOT, "apps/web/src/styles/tokens.css");
const SWIFT_PATH = path.join(REPO_ROOT, "apps/apple/CanadianHam/Design/Tokens.swift");
const DESIGN_DOC_PATH = path.join(REPO_ROOT, "docs/design.md");
const CHECK_MODE = process.argv.includes("--check");
const CONTRAST_START = "<!-- contrast-table:start -->";
const CONTRAST_END = "<!-- contrast-table:end -->";

function cssName(name: string): string {
  return name.replace(/[A-Z]/g, (match) => `-${match.toLowerCase()}`);
}

function swiftName(name: string): string {
  return name.replace(/[^a-zA-Z0-9_]/g, "_");
}

function hexToRgbUnit(hex: string): readonly [string, string, string] {
  const normalized = hex.replace(/^#/, "");
  const values = [0, 2, 4].map((index) => Number.parseInt(normalized.slice(index, index + 2), 16) / 255);
  return values.map((value) => value.toFixed(6)) as [string, string, string];
}

function assertEqualKeys(label: string, left: Record<string, unknown>, right: Record<string, unknown>): void {
  const leftKeys = Object.keys(left).sort();
  const rightKeys = Object.keys(right).sort();
  const missingRight = leftKeys.filter((key) => !rightKeys.includes(key));
  const missingLeft = rightKeys.filter((key) => !leftKeys.includes(key));
  if (missingRight.length > 0 || missingLeft.length > 0) {
    throw new Error(`${label} keys differ. Missing from dark: ${missingRight.join(", ") || "none"}; missing from light: ${missingLeft.join(", ") || "none"}.`);
  }
}

function validateTokens(tokens: Tokens): void {
  if (tokens.themes.light === undefined || tokens.themes.dark === undefined) {
    throw new Error("Tokens must define light and dark themes.");
  }
  assertEqualKeys("Theme colour", tokens.themes.light.colors, tokens.themes.dark.colors);
  const seenPairIds = new Set<string>();
  for (const [name, step] of Object.entries(tokens.typography.scale)) {
    if (typeof step.appleTextStyle !== "string" || step.appleTextStyle.length === 0) {
      throw new Error(`Typography token ${name} must define appleTextStyle.`);
    }
  }
  for (const pair of tokens.contrastPairs) {
    if (seenPairIds.has(pair.id)) {
      throw new Error(`Duplicate contrast pair id: ${pair.id}`);
    }
    seenPairIds.add(pair.id);
    const theme = tokens.themes[pair.theme];
    if (theme === undefined) {
      throw new Error(`Unknown theme in contrast pair ${pair.id}: ${pair.theme}`);
    }
    if (theme.colors[pair.foreground] === undefined || theme.colors[pair.background] === undefined) {
      throw new Error(`Unknown colour token in contrast pair ${pair.id}.`);
    }
  }
  if (seenPairIds.size === 0) {
    throw new Error("At least one contrast pair must be declared.");
  }
}

function generateCss(tokens: Tokens): string {
  const light = tokens.themes.light.colors;
  const dark = tokens.themes.dark.colors;
  const colourLines = Object.keys(light).map((name) => `  --ch-color-${cssName(name)}: ${light[name]};`).join("\n");
  const darkLines = Object.keys(dark).map((name) => `    --ch-color-${cssName(name)}: ${dark[name]};`).join("\n");
  const typographyLines = Object.entries(tokens.typography.scale).flatMap(([name, value]) => [
    `  --ch-type-${cssName(name)}-size: ${value.rem}rem;`,
    `  --ch-type-${cssName(name)}-line-height: ${value.lineHeight};`,
  ]).join("\n");
  const familyLines = Object.entries(tokens.typography.families)
    .map(([name, value]) => `  --ch-font-${cssName(name)}: ${value};`)
    .join("\n");
  const spacingLines = Object.entries(tokens.spacing)
    .map(([name, value]) => `  --ch-space-${cssName(name)}: ${value / 16}rem;`)
    .join("\n");
  const radiiLines = Object.entries(tokens.radii)
    .map(([name, value]) => `  --ch-radius-${cssName(name)}: ${value === 999 ? "999px" : `${value / 16}rem`};`)
    .join("\n");
  const durationLines = Object.entries(tokens.motion.durations)
    .map(([name, value]) => `  --ch-motion-${cssName(name)}: ${value}ms;`)
    .join("\n");
  const easingLines = Object.entries(tokens.motion.easing)
    .map(([name, value]) => `  --ch-ease-${cssName(name)}: ${value};`)
    .join("\n");

  return `/* Generated by packages/design-tokens/src/generate.ts. Do not edit by hand. */\n:root {\n${colourLines}\n${familyLines}\n${typographyLines}\n${spacingLines}\n${radiiLines}\n${durationLines}\n${easingLines}\n  color-scheme: light dark;\n}\n\n@media (prefers-color-scheme: dark) {\n  :root {\n${darkLines}\n  }\n}\n\n[data-theme=\"light\"] {\n${colourLines}\n  color-scheme: light;\n}\n\n[data-theme=\"dark\"] {\n${Object.keys(dark).map((name) => `  --ch-color-${cssName(name)}: ${dark[name]};`).join("\n")}\n  color-scheme: dark;\n}\n\n@media (prefers-reduced-motion: reduce) {\n  :root {\n${Object.keys(tokens.motion.durations).map((name) => `    --ch-motion-${cssName(name)}: 0ms;`).join("\n")}\n  }\n}\n`;
}

function generateSwift(tokens: Tokens): string {
  const colorNames = Object.keys(tokens.themes.light.colors);
  const colors = colorNames.map((name) => {
    const [lr, lg, lb] = hexToRgbUnit(tokens.themes.light.colors[name]);
    const [dr, dg, db] = hexToRgbUnit(tokens.themes.dark.colors[name]);
    return `        public static let ${swiftName(name)} = Color.dynamicToken(light: DesignTokens.RGB(red: ${lr}, green: ${lg}, blue: ${lb}), dark: DesignTokens.RGB(red: ${dr}, green: ${dg}, blue: ${db}))`;
  }).join("\n");
  const spacing = Object.entries(tokens.spacing)
    .map(([name, value]) => `        public static let ${swiftName(name)}: CGFloat = ${value}`)
    .join("\n");
  const radii = Object.entries(tokens.radii)
    .map(([name, value]) => `        public static let ${swiftName(name)}: CGFloat = ${value}`)
    .join("\n");
  const typeScale = Object.entries(tokens.typography.scale).map(([name, step]) => {
    const style = `.${step.appleTextStyle}`;
    const design = name === "title" || name === "headline" || name === "display" ? ".serif" : ".default";
    return `        public static let ${swiftName(name)} = Font.system(${style}, design: ${design})`;
  }).join("\n");
  const durations = Object.entries(tokens.motion.durations)
    .map(([name, value]) => `        public static let ${swiftName(name)}: Double = ${value / 1000}`)
    .join("\n");

  return `// Generated by packages/design-tokens/src/generate.ts. Do not edit by hand.\nimport SwiftUI\n\n#if os(macOS)\nimport AppKit\n#else\nimport UIKit\n#endif\n\npublic enum DesignTokens {\n    public struct RGB: Sendable {\n        public let red: Double\n        public let green: Double\n        public let blue: Double\n\n        public init(red: Double, green: Double, blue: Double) {\n            self.red = red\n            self.green = green\n            self.blue = blue\n        }\n    }\n\n    public enum Colors {\n${colors}\n    }\n\n    public enum FontScale {\n${typeScale}\n    }\n\n    public enum Spacing {\n${spacing}\n    }\n\n    public enum Radius {\n${radii}\n    }\n\n    public enum Motion {\n${durations}\n    }\n}\n\nprivate extension Color {\n    static func dynamicToken(light: DesignTokens.RGB, dark: DesignTokens.RGB) -> Color {\n        #if os(macOS)\n        return Color(NSColor(name: nil) { appearance in\n            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])\n            let color = bestMatch == .darkAqua ? dark : light\n            return NSColor(red: color.red, green: color.green, blue: color.blue, alpha: 1)\n        })\n        #else\n        return Color(UIColor { traits in\n            let color = traits.userInterfaceStyle == .dark ? dark : light\n            return UIColor(red: color.red, green: color.green, blue: color.blue, alpha: 1)\n        })\n        #endif\n    }\n}\n`;
}

function generateContrastTable(tokens: Tokens): string {
  const rows = contrastRows(tokens).map((row) => (
    `| ${row.id} | ${row.theme} | ${row.kind} | ${row.foreground} | ${row.background} | ${row.ratio.toFixed(2)} | ${row.minimum.toFixed(1)} |`
  )).join("\n");
  return `${CONTRAST_START}\n| Pair | Theme | Kind | Foreground | Background | Ratio | Min |\n|---|---|---|---|---|---:|---:|\n${rows}\n${CONTRAST_END}`;
}

function replaceContrastTable(document: string, tokens: Tokens): string {
  const table = generateContrastTable(tokens);
  if (document.includes(CONTRAST_START) && document.includes(CONTRAST_END)) {
    const start = document.indexOf(CONTRAST_START);
    const end = document.indexOf(CONTRAST_END) + CONTRAST_END.length;
    return `${document.slice(0, start)}${table}${document.slice(end)}`;
  }

  const heading = "## Contrast table";
  const nextHeading = "\n## Typography";
  const start = document.indexOf(heading);
  const end = document.indexOf(nextHeading, start);
  if (start === -1 || end === -1) {
    throw new Error("Could not locate Contrast table section in docs/design.md.");
  }
  const section = `${heading}\n\nThe design-token test computes these WCAG 2.2 ratios for every declared foreground/background pair. Body text requires at least 4.5:1; large text and UI boundaries/focus rings require at least 3:1. The table below is generated from \`packages/design-tokens/tokens.json\`; run \`node packages/design-tokens/src/generate.ts\` after token changes.\n\n${table}\n`;
  return `${document.slice(0, start)}${section}${document.slice(end)}`;
}

async function writeOrCheck(filePath: string, content: string): Promise<void> {
  if (CHECK_MODE) {
    const existing = await readFile(filePath, "utf8");
    if (existing !== content) {
      throw new Error(`${path.relative(REPO_ROOT, filePath)} is out of date. Run node packages/design-tokens/src/generate.ts.`);
    }
    return;
  }
  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, content, "utf8");
}

async function main(): Promise<void> {
  const tokens = JSON.parse(await readFile(TOKENS_PATH, "utf8")) as Tokens;
  validateTokens(tokens);
  await writeOrCheck(CSS_PATH, generateCss(tokens));
  await writeOrCheck(SWIFT_PATH, generateSwift(tokens));
  const designDoc = await readFile(DESIGN_DOC_PATH, "utf8");
  await writeOrCheck(DESIGN_DOC_PATH, replaceContrastTable(designDoc, tokens));
  console.log(CHECK_MODE ? "Design token generated files and docs are current." : "Generated design token outputs and docs.");
}

function isMainModule(): boolean {
  const metaWithMain = import.meta as ImportMeta & { readonly main?: unknown };
  if ("main" in metaWithMain) {
    return metaWithMain.main === true;
  }
  if (process.argv[1] === undefined) {
    return false;
  }
  try {
    return import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href;
  } catch {
    return false;
  }
}

if (isMainModule()) {
  await main();
}
