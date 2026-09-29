import { createHash } from "node:crypto";
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
  return {
    name: "canadian-ham-pwa",
    generateBundle(_options, bundle) {
      const emittedFiles = Object.values(bundle)
        .map((entry) => entry.fileName)
        .filter((fileName) => fileName !== "sw.js" && fileName !== "manifest.webmanifest");
      const precacheEntries = createPrecacheManifest(emittedFiles);
      const version = createHash("sha256").update(precacheEntries.join("\n")).digest("hex").slice(0, 16);
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

export default defineConfig({
  base: "./",
  plugins: [allowDevInlineStyles(), canadianHamPwa()],
  test: {
    environment: "jsdom",
    globals: true,
  },
});
