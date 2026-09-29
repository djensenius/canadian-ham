import { checkGeneratedFiles, writeGeneratedFiles } from "./basic-importer.ts";

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const checkMode = args.length === 1 && args[0] === "--check";
  if (args.length > 0 && !checkMode) {
    throw new Error("usage: node packages/content-tools/src/import-basic.ts [--check]");
  }

  const files = checkMode
    ? await checkGeneratedFiles(process.cwd())
    : await writeGeneratedFiles(process.cwd());

  const verb = checkMode ? "verified" : "wrote";
  for (const file of files) {
    console.log(`${verb} ${file.path}`);
  }
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`import-basic: ${message}`);
  process.exitCode = 1;
});
