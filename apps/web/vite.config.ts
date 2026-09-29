import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { defineConfig } from "vitest/config";
import type { Plugin } from "vite";

import { createPrecacheManifest, createServiceWorkerSource, createWebAppManifest } from "./src/lib/pwa";

function allowDevInlineStyles(): Plugin {
  return {
    name: "canadian-ham-dev-csp",
    apply: "serve",
    transformIndexHtml(html) {
      let foundStyleSrc = false;
      const nextHtml = html.replace(/(^|;\s*)style-src(?![-\w])([^;"]*)/m, (match, prefix: string, sources: string) => {
        foundStyleSrc = true;
        return sources.includes("'unsafe-inline'") ? match : `${prefix}style-src${sources} 'unsafe-inline'`;
      });
      if (!foundStyleSrc) {
        throw new Error("Unable to locate style-src directive in index.html CSP for dev inline styles.");
      }
      return nextHtml;
    },
  };
}

function canadianHamPwa(): Plugin {
  let root = process.cwd();
  return {
    name: "canadian-ham-pwa",
    configResolved(config) {
      root = config.root;
    },
    generateBundle(_options, bundle) {
      const emittedEntries = Object.values(bundle)
        .filter((entry) => entry.fileName !== "sw.js" && entry.fileName !== "manifest.webmanifest")
        .map((entry) => ({ fileName: entry.fileName, source: bundleEntrySource(entry) }));
      const precacheEntries = createPrecacheManifest(emittedEntries.map((entry) => entry.fileName));
      const versionHash = createHash("sha256");
      for (const entry of [...emittedEntries, ...publicAssetEntries(root)].sort((a, b) => a.fileName.localeCompare(b.fileName))) {
        versionHash.update(entry.fileName);
        versionHash.update("\0");
        versionHash.update(entry.source);
        versionHash.update("\0");
      }
      const version = versionHash.digest("hex").slice(0, 16);
      this.emitFile({
        type: "asset",
        fileName: "manifest.webmanifest",
        source: `${JSON.stringify(createWebAppManifest(), null, 2)}\n`,
      });
      this.emitFile({
        type: "asset",
        fileName: "sw.js",
        source: createServiceWorkerSource(precacheEntries, version),
      });
    },
  };
}

function bundleEntrySource(entry: { readonly type: string; readonly code?: string; readonly source?: string | Uint8Array }): string | Uint8Array {
  if (entry.type === "chunk") {
    return entry.code ?? "";
  }
  return entry.source ?? "";
}

function publicAssetEntries(root: string): readonly { readonly fileName: string; readonly source: string | Uint8Array }[] {
  const publicDir = join(root, "public");
  try {
    return walkPublicDir(publicDir).map((path) => ({ fileName: relative(publicDir, path).replace(/\\/g, "/"), source: readFileSync(path) }));
  } catch (error) {
    if ((error as { readonly code?: string }).code === "ENOENT") {
      return [];
    }
    throw error;
  }
}

function walkPublicDir(directory: string): string[] {
  return readdirSync(directory).flatMap((entry) => {
    const path = join(directory, entry);
    const stats = statSync(path);
    return stats.isDirectory() ? walkPublicDir(path) : [path];
  });
}

export default defineConfig({
  base: "./",
  plugins: [allowDevInlineStyles(), canadianHamPwa()],
  test: {
    environment: "jsdom",
    globals: true,
  },
});
