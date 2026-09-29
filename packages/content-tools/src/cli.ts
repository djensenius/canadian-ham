import { realpathSync } from "node:fs";
import { pathToFileURL } from "node:url";

export function isMainModule(meta: ImportMeta, argv = process.argv): boolean {
  const metaWithMain = meta as ImportMeta & { readonly main?: unknown };
  if ("main" in metaWithMain) {
    return metaWithMain.main === true;
  }
  const invokedScript = argv[1];
  if (invokedScript === undefined) {
    return false;
  }
  try {
    return meta.url === pathToFileURL(realpathSync(invokedScript)).href;
  } catch {
    return false;
  }
}
