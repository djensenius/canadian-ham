import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { defineConfig } from "vitest/config";
import type { Plugin } from "vite";

import { createPrecacheManifest, createServiceWorkerSource, createWebAppManifest } from "./src/lib/pwa.ts";
import { officialReferenceSheetPlugin } from "./officialReferenceSheetPlugin.ts";
import { computePwaVersion } from "./src/lib/pwaVersion.ts";

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

export function resolveWebBase(env: NodeJS.ProcessEnv = process.env): string {
  const configuredBase = env.CANADIAN_HAM_WEB_BASE_PATH;
  if (configuredBase === undefined || configuredBase.trim() === "") {
    return "./";
  }

  if (configuredBase === "./") {
    return configuredBase;
  }
  if (!configuredBase.startsWith("/") || !configuredBase.endsWith("/")) {
    throw new Error("CANADIAN_HAM_WEB_BASE_PATH must be './' or an absolute path that starts and ends with '/'.");
  }
  if (configuredBase.includes("//") || configuredBase.includes("..")) {
    throw new Error("CANADIAN_HAM_WEB_BASE_PATH must not contain empty path segments or '..'.");
  }
  return configuredBase;
}

function canadianHamPwa(): Plugin {
  let root = process.cwd();
  return {
    name: "canadian-ham-pwa",
    configResolved(config) {
      root = config.root;
    },
    generateBundle: {
      order: "post",
      handler(_options, bundle) {
        const emittedEntries = Object.values(bundle)
          .filter((entry) => entry.fileName !== "sw.js" && entry.fileName !== "manifest.webmanifest")
          .map((entry) => ({ fileName: entry.fileName, source: bundleEntrySource(entry) }));
        const indexEntry = emittedEntries.find((entry) => entry.fileName === "index.html");
        const bundleFiles = emittedEntries.filter((entry) => entry.fileName !== "index.html");
        const publicFiles = publicAssetEntries(root);
        const manifestJson = `${JSON.stringify(createWebAppManifest(), null, 2)}\n`;
        const precacheEntries = createPrecacheManifest(emittedEntries.map((entry) => entry.fileName));
        const version = computePwaVersion({
          bundleFiles,
          indexHtml: indexEntry?.source ?? readFileSync(join(root, "index.html")),
          manifestJson,
          publicFiles,
        });
        this.emitFile({
          type: "asset",
          fileName: "manifest.webmanifest",
          source: manifestJson,
        });
        this.emitFile({
          type: "asset",
          fileName: "sw.js",
          source: createServiceWorkerSource(precacheEntries, version),
        });
      },
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
  base: resolveWebBase(),
  plugins: [allowDevInlineStyles(), officialReferenceSheetPlugin(), canadianHamPwa()],
  test: {
    environment: "jsdom",
    globals: true,
  },
});
