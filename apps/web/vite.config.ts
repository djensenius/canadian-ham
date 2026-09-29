import { defineConfig } from "vitest/config";
import type { Plugin } from "vite";

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

export default defineConfig({
  base: "./",
  plugins: [allowDevInlineStyles()],
  test: {
    environment: "jsdom",
    globals: true,
  },
});
