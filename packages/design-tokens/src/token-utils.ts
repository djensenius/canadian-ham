export interface TokenSet {
  readonly themes: Record<string, { readonly colors: Record<string, string> }>;
  readonly contrastPairs: readonly ContrastPair[];
}

export interface ContrastPair {
  readonly id: string;
  readonly theme: string;
  readonly foreground: string;
  readonly background: string;
  readonly kind: "body" | "large" | "ui";
}

export function hexToRgb(hex: string): readonly [number, number, number] {
  const normalized = hex.trim().replace(/^#/, "");
  if (!/^[0-9a-fA-F]{6}$/.test(normalized)) {
    throw new Error(`Invalid 6-digit hex colour: ${hex}`);
  }
  return [0, 2, 4].map((index) => Number.parseInt(normalized.slice(index, index + 2), 16)) as [number, number, number];
}

function linearize(channel: number): number {
  const value = channel / 255;
  return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
}

export function contrastRatio(foregroundHex: string, backgroundHex: string): number {
  const [fr, fg, fb] = hexToRgb(foregroundHex).map(linearize);
  const [br, bg, bb] = hexToRgb(backgroundHex).map(linearize);
  const foregroundLuminance = 0.2126 * fr + 0.7152 * fg + 0.0722 * fb;
  const backgroundLuminance = 0.2126 * br + 0.7152 * bg + 0.0722 * bb;
  const lighter = Math.max(foregroundLuminance, backgroundLuminance);
  const darker = Math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

export function minimumRatioForKind(kind: ContrastPair["kind"]): number {
  if (kind === "body") {
    return 4.5;
  }
  return 3;
}

export function contrastRows(tokens: TokenSet): readonly {
  readonly id: string;
  readonly theme: string;
  readonly foreground: string;
  readonly background: string;
  readonly kind: string;
  readonly ratio: number;
  readonly minimum: number;
}[] {
  return tokens.contrastPairs.map((pair) => {
    const theme = tokens.themes[pair.theme];
    if (theme === undefined) {
      throw new Error(`Unknown theme in contrast pair ${pair.id}: ${pair.theme}`);
    }
    const foreground = theme.colors[pair.foreground];
    const background = theme.colors[pair.background];
    if (foreground === undefined || background === undefined) {
      throw new Error(`Unknown colour token in contrast pair ${pair.id}`);
    }
    return {
      id: pair.id,
      theme: pair.theme,
      foreground: `${pair.foreground} ${foreground}`,
      background: `${pair.background} ${background}`,
      kind: pair.kind,
      ratio: contrastRatio(foreground, background),
      minimum: minimumRatioForKind(pair.kind),
    };
  });
}
