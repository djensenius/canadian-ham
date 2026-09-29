import { defineConfig } from "vitest/config";
import type { Plugin } from "vite";

function allowDevInlineStyles(): Plugin {
  return {
    name: "canadian-ham-dev-csp",
    apply: "serve",
    transformIndexHtml(html) {
      return html.replace("style-src 'self'", "style-src 'self' 'unsafe-inline'");
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
