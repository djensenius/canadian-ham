import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { computePwaVersion } from "./pwaVersion";

const baseInput = {
  bundleFiles: [{ fileName: "assets/app.js", source: "console.log('app');" }],
  indexHtml: "<html><head><title>Canadian Ham</title></head><body><div id=\"root\"></div></body></html>",
  manifestJson: JSON.stringify({ name: "Canadian Ham Basic Study", start_url: "./" }),
  publicFiles: [{ fileName: "pwa-icon-192.png", source: new Uint8Array([1, 2, 3]) }],
};

describe("computePwaVersion", () => {
  it("changes when only index.html changes", () => {
    const original = computePwaVersion(baseInput);
    const changed = computePwaVersion({ ...baseInput, indexHtml: baseInput.indexHtml.replace("</head>", "<meta name=\"theme-color\" content=\"#000000\"></head>") });

    assert.notEqual(changed, original);
  });

  it("changes when only the manifest content changes", () => {
    const original = computePwaVersion(baseInput);
    const changed = computePwaVersion({ ...baseInput, manifestJson: JSON.stringify({ name: "Canadian Ham Basic Study", start_url: "./", display: "standalone" }) });

    assert.notEqual(changed, original);
  });
});
