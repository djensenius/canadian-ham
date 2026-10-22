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
    assert.deepEqual(manifest.icons.map((icon) => icon.src), ["./pwa-icon-192.png", "./pwa-icon-512.png", "./pwa-maskable-icon-192.png", "./pwa-maskable-icon-512.png"]);
    assert.ok(manifest.icons.every((icon) => icon.type === "image/png"));
    assert.deepEqual(manifest.icons.map((icon) => icon.purpose), ["any", "any", "maskable", "maskable"]);
  });

  it("builds a precache list covering app shell, generated assets, icons, and question bank", () => {
    const precache = createPrecacheManifest([
      "assets/index-abc123.js",
      "assets/questions-def456.json",
      "assets/style.css.map",
    ]);

    assert.ok(precache.includes("./"));
    assert.ok(precache.includes("./index.html"));
    assert.ok(precache.includes("./manifest.webmanifest"));
    assert.ok(precache.includes("./favicon.svg"));
    assert.ok(precache.includes("./favicon-16.png"));
    assert.ok(precache.includes("./favicon-32.png"));
    assert.ok(precache.includes("./favicon-64.png"));
    assert.ok(precache.includes("./pwa-icon-192.png"));
    assert.ok(precache.includes("./pwa-maskable-icon-192.png"));
    assert.ok(precache.includes("./pwa-maskable-icon-512.png"));
    assert.ok(precache.includes("./assets/questions-def456.json"));
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

  it("serves an exact cached same-origin asset navigation instead of the app shell", async () => {
    const assetUrl = "https://example.test/assets/lesson.txt";
    const { response, fetchMock } = await dispatchFetch(
      createServiceWorkerSource(["./", "./index.html", "./assets/lesson.txt"], "assetnav"),
      navigationRequest(assetUrl),
      new Map([
        [assetUrl, new Response("Lesson bytes", { headers: { "content-type": "text/plain" } })],
        ["./index.html", new Response("<html>app shell</html>", { headers: { "content-type": "text/html" } })],
      ]),
    );

    assert.equal(await response.text(), "Lesson bytes");
    assert.equal(response.headers.get("content-type"), "text/plain");
    assert.equal(fetchMock.mock.calls.length, 0);
  });

  it("falls back to index.html only for app-shell navigations", async () => {
    const source = createServiceWorkerSource(["./", "./index.html"], "shellnav");
    const cachedEntries = new Map([["./index.html", new Response("<html>app shell</html>")]]);

    const shell = await dispatchFetch(source, navigationRequest("https://example.test/"), cachedEntries);
    assert.equal(await shell.response.text(), "<html>app shell</html>");
    assert.equal(shell.fetchMock.mock.calls.length, 0);

    const missingAsset = await dispatchFetch(source, navigationRequest("https://example.test/assets/missing.txt"), cachedEntries);
    assert.equal(await missingAsset.response.text(), "network:https://example.test/assets/missing.txt");
    assert.equal(missingAsset.fetchMock.mock.calls.length, 1);
  });

  it("rejects cross-origin requests without fetching or caching them", async () => {
    const result = await dispatchFetch(
      createServiceWorkerSource(["./", "./index.html"], "crossorigin"),
      new Request("https://ised-isde.canada.ca/site/example"),
      new Map(),
    );

    assert.equal(result.response.type, "error");
    assert.equal(result.response.status, 0);
    assert.equal(result.fetchMock.mock.calls.length, 0);
    assert.equal(result.cacheMatchMock.mock.calls.length, 0);
    assert.equal(result.cachePutMock.mock.calls.length, 0);
  });
});

function navigationRequest(url: string): Request {
  const request = new Request(url);
  Object.defineProperty(request, "mode", { configurable: true, value: "navigate" });
  return request;
}

type ServiceWorkerFetchHandler = (event: { readonly request: Request; readonly respondWith: (response: Promise<Response> | Response) => void }) => void;

async function dispatchFetch(source: string, request: Request, cachedEntries: Map<string, Response>): Promise<{ readonly response: Response; readonly fetchMock: ReturnType<typeof vi.fn>; readonly cacheMatchMock: ReturnType<typeof vi.fn>; readonly cachePutMock: ReturnType<typeof vi.fn> }> {
  let fetchHandler: ServiceWorkerFetchHandler = () => {
    throw new Error("Service worker fetch handler was not registered.");
  };
  const fetchMock = vi.fn(async (nextRequest: Request) => new Response(`network:${nextRequest.url}`));
  const cacheMatchMock = vi.fn(async (key: Request | string) => cachedEntries.get(cacheKey(key))?.clone());
  const cachePutMock = vi.fn(async (key: Request | string, response: Response) => {
    cachedEntries.set(cacheKey(key), response.clone());
  });
  const caches = {
    match: cacheMatchMock,
    keys: vi.fn(async () => ["canadian-ham-old"]),
    delete: vi.fn(async () => true),
    open: vi.fn(async () => ({
      addAll: vi.fn(async () => undefined),
      put: cachePutMock,
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
  return { response: await responsePromise, fetchMock, cacheMatchMock, cachePutMock };
}

function cacheKey(key: Request | string): string {
  return typeof key === "string" ? key : key.url;
}
