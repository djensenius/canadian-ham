import { fileURLToPath } from "node:url";

import { checkAdvancedGeneratedFiles, writeAdvancedGeneratedFiles } from "./advanced-importer.ts";
import { isMainModule } from "./cli.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const checkMode = args.length === 1 && args[0] === "--check";
  if (args.length > 0 && !checkMode) {
    throw new Error("usage: node packages/content-tools/src/import-advanced.ts [--check]");
  }

  const files = checkMode
    ? await checkAdvancedGeneratedFiles(REPO_ROOT)
    : await writeAdvancedGeneratedFiles(REPO_ROOT);

  const verb = checkMode ? "verified" : "wrote";
  for (const file of files) {
    console.log(`${verb} ${file.path}`);
  }
}

if (isMainModule(import.meta)) {
  main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`import-advanced: ${message}`);
    process.exitCode = 1;
  });
}
