import { resolve } from "node:path";
import type { Plugin } from "vite";

export function officialReferenceSheetEnabled(command: "build" | "serve", env: NodeJS.ProcessEnv = process.env): boolean {
  return env.OFFICIAL_REFERENCE_SHEET === "YES" || (command === "serve" && env.OFFICIAL_REFERENCE_SHEET !== "NO");
}

// An off build never resolves the source imports, so official content is absent
// from the output and its offline cache, not merely hidden in the interface.
export function officialReferenceSheetPlugin(): Plugin {
  const moduleId = "virtual:official-reference-sheet";
  let enabled = false;
  return {
    name: "official-reference-sheet",
    configResolved(config) { enabled = officialReferenceSheetEnabled(config.command); },
    resolveId(id) { if (id === moduleId) return `\0${moduleId}`; },
    load(id) {
      if (id !== `\0${moduleId}`) return;
      if (!enabled) return "export default null;";
      const directory = resolve(import.meta.dirname, "../../content/reference/official-basic-exam");
      return [
        `import markdown from ${JSON.stringify(`${directory}/text-equivalent.md?raw`)};`,
        ...Array.from({ length: 5 }, (_, index) => `import page${index + 1} from ${JSON.stringify(`${directory}/page-${index + 1}.png`)};`),
        "export default { markdown, pages: [page1, page2, page3, page4, page5] };",
      ].join("\n");
    },
  };
}
