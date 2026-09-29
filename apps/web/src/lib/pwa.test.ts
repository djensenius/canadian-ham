import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { createPrecacheManifest, createServiceWorkerSource, createWebAppManifest, isSameOriginCacheableRequest } from "./pwa";

describe("PWA manifest and service worker assets", () => {
  it("generates a standalone web app manifest with local icons", () => {
    const manifest = createWebAppManifest();

    assert.equal(manifest.name, "Canadian Ham Basic Study");
    assert.equal(manifest.display, "standalone");
    assert.equal(manifest.theme_color, "#F6EEDC");
    assert.deepEqual(manifest.icons.map((icon) => icon.src), ["./pwa-icon-192.png", "./pwa-icon-512.png", "./pwa-icon-512.png"]);
    assert.ok(manifest.icons.every((icon) => icon.type === "image/png"));
  });

  it("builds a precache list covering app shell, generated assets, icons, question bank and reference PDFs", () => {
    const precache = createPrecacheManifest([
      "assets/index-abc123.js",
      "assets/questions-def456.json",
      "assets/Reference Material for Amateur Radio Exam Basic EN 2025-aaa.pdf",
      "assets/Reference Material for Amateur Radio Training Basic EN 2025-bbb.pdf",
      "assets/style.css.map",
    ]);

    assert.ok(precache.includes("./"));
    assert.ok(precache.includes("./index.html"));
    assert.ok(precache.includes("./manifest.webmanifest"));
    assert.ok(precache.includes("./pwa-icon-192.png"));
    assert.ok(precache.includes("./assets/questions-def456.json"));
    assert.ok(precache.some((entry) => /Reference Material.*Exam.*\.pdf/.test(entry)));
    assert.ok(precache.some((entry) => /Reference Material.*Training.*\.pdf/.test(entry)));
    assert.ok(precache.every((entry) => !entry.endsWith(".map")));
  });

  it("generates cache-first same-origin service worker logic without auto skipWaiting", () => {
    const source = createServiceWorkerSource(["./", "./index.html", "./assets/index.js"], "testversion");

    assert.match(source, /CACHE_NAME = "canadian-ham-testversion"/);
    assert.match(source, /cacheFirst\(request\)/);
    assert.match(source, /url\.origin !== self\.location\.origin/);
    assert.match(source, /SKIP_WAITING/);
    assert.doesNotMatch(source, /self\.skipWaiting\(\);\s*\}\);\s*self\.addEventListener\("install"/);
    assert.equal(isSameOriginCacheableRequest("/assets/index.js", "https://example.test"), true);
    assert.equal(isSameOriginCacheableRequest("https://other.example/assets/index.js", "https://example.test"), false);
  });
});
