import assert from "node:assert/strict";
import vm from "node:vm";
import { describe, it, vi } from "vitest";

import { createPrecacheManifest, createServiceWorkerSource, createWebAppManifest, isSameOriginCacheableRequest } from "./pwa";

describe("PWA manifest and service worker assets", () => {
  it("generates a standalone web app manifest with local icons", () => {
    const manifest = createWebAppManifest();

    assert.equal(manifest.name, "Canadian Ham Basic Study");
    assert.equal(manifest.display, "standalone");
    assert.equal(manifest.theme_color, "#F6EEDC");
    assert.deepEqual(manifest.icons.map((icon) => icon.src), ["./pwa-icon-192.png", "./pwa-icon-512.png"]);
    assert.ok(manifest.icons.every((icon) => icon.type === "image/png"));
    assert.ok(manifest.icons.every((icon) => icon.purpose === undefined));
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
    assert.match(source, /navigationResponse\(request\)/);
    assert.match(source, /cache: "reload"/);
    assert.match(source, /url\.origin !== self\.location\.origin/);
    assert.match(source, /SKIP_WAITING/);
    assert.doesNotMatch(source, /self\.skipWaiting\(\);\s*\}\);\s*self\.addEventListener\("install"/);
    assert.equal(isSameOriginCacheableRequest("/assets/index.js", "https://example.test"), true);
    assert.equal(isSameOriginCacheableRequest("https://other.example/assets/index.js", "https://example.test"), false);
  });

  it("serves an exact cached PDF navigation instead of the app shell", async () => {
    const pdfUrl = "https://example.test/assets/reference.pdf";
    const { response, fetchMock } = await dispatchFetch(
      createServiceWorkerSource(["./", "./index.html", "./assets/reference.pdf"], "pdfnav"),
      navigationRequest(pdfUrl),
      new Map([
        [pdfUrl, new Response("PDF bytes", { headers: { "content-type": "application/pdf" } })],
        ["./index.html", new Response("<html>app shell</html>", { headers: { "content-type": "text/html" } })],
      ]),
    );

    assert.equal(await response.text(), "PDF bytes");
    assert.equal(response.headers.get("content-type"), "application/pdf");
    assert.equal(fetchMock.mock.calls.length, 0);
  });

  it("falls back to index.html only for app-shell navigations", async () => {
    const source = createServiceWorkerSource(["./", "./index.html"], "shellnav");
    const cachedEntries = new Map([["./index.html", new Response("<html>app shell</html>")]]);

    const shell = await dispatchFetch(source, navigationRequest("https://example.test/"), cachedEntries);
    assert.equal(await shell.response.text(), "<html>app shell</html>");
    assert.equal(shell.fetchMock.mock.calls.length, 0);

    const missingPdf = await dispatchFetch(source, navigationRequest("https://example.test/assets/missing.pdf"), cachedEntries);
    assert.equal(await missingPdf.response.text(), "network:https://example.test/assets/missing.pdf");
    assert.equal(missingPdf.fetchMock.mock.calls.length, 1);
  });
});

function navigationRequest(url: string): Request {
  const request = new Request(url);
  Object.defineProperty(request, "mode", { configurable: true, value: "navigate" });
  return request;
}

type ServiceWorkerFetchHandler = (event: { readonly request: Request; readonly respondWith: (response: Promise<Response> | Response) => void }) => void;

async function dispatchFetch(source: string, request: Request, cachedEntries: Map<string, Response>): Promise<{ readonly response: Response; readonly fetchMock: ReturnType<typeof vi.fn> }> {
  let fetchHandler: ServiceWorkerFetchHandler = () => {
    throw new Error("Service worker fetch handler was not registered.");
  };
  const fetchMock = vi.fn(async (nextRequest: Request) => new Response(`network:${nextRequest.url}`));
  const caches = {
    match: vi.fn(async (key: Request | string) => cachedEntries.get(cacheKey(key))?.clone()),
    keys: vi.fn(async () => ["canadian-ham-old"]),
    delete: vi.fn(async () => true),
    open: vi.fn(async () => ({
      addAll: vi.fn(async () => undefined),
      put: vi.fn(async (key: Request | string, response: Response) => {
        cachedEntries.set(cacheKey(key), response.clone());
      }),
    })),
  };
  const self = {
    location: { origin: "https://example.test" },
    registration: { scope: "https://example.test/" },
    clients: { claim: vi.fn(async () => undefined) },
    skipWaiting: vi.fn(),
    addEventListener: vi.fn((type: string, handler: unknown) => {
      if (type === "fetch") {
        fetchHandler = handler as ServiceWorkerFetchHandler;
      }
    }),
  };
  vm.runInNewContext(source, { self, caches, Request, Response, URL, fetch: fetchMock });
  let responsePromise: Promise<Response> | null = null;
  fetchHandler({
    request,
    respondWith: (response: Promise<Response> | Response) => {
      responsePromise = Promise.resolve(response);
    },
  });
  assert.ok(responsePromise);
  return { response: await responsePromise, fetchMock };
}

function cacheKey(key: Request | string): string {
  return typeof key === "string" ? key : key.url;
}
