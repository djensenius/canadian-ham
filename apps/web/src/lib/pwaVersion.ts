import { createHash } from "node:crypto";

export interface PwaVersionFile {
  readonly fileName: string;
  readonly source: string | Uint8Array;
}

export interface PwaVersionInput {
  readonly bundleFiles: readonly PwaVersionFile[];
  readonly indexHtml: string | Uint8Array;
  readonly manifestJson: string | Uint8Array;
  readonly publicFiles: readonly PwaVersionFile[];
}

export function computePwaVersion({ bundleFiles, indexHtml, manifestJson, publicFiles }: PwaVersionInput): string {
  const versionHash = createHash("sha256");
  hashNamedSource(versionHash, "index.html", indexHtml);
  hashNamedSource(versionHash, "manifest.webmanifest", manifestJson);
  for (const entry of [...bundleFiles, ...publicFiles].sort((a, b) => a.fileName.localeCompare(b.fileName))) {
    hashNamedSource(versionHash, entry.fileName, entry.source);
  }
  return versionHash.digest("hex").slice(0, 16);
}

function hashNamedSource(hash: ReturnType<typeof createHash>, fileName: string, source: string | Uint8Array): void {
  hash.update(fileName);
  hash.update("\0");
  hash.update(source);
  hash.update("\0");
}
