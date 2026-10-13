export const PWA_PUBLIC_ASSETS = [
  "./favicon.svg",
  "./favicon-16.png",
  "./favicon-32.png",
  "./favicon-64.png",
  "./apple-touch-icon-180.png",
  "./pwa-icon-192.png",
  "./pwa-icon-512.png",
  "./pwa-maskable-icon-192.png",
  "./pwa-maskable-icon-512.png",
  "./manifest.webmanifest",
] as const;

export interface WebAppManifestIcon {
  readonly src: string;
  readonly sizes: string;
  readonly type: string;
  readonly purpose?: string;
}

export interface WebAppManifest {
  readonly name: string;
  readonly short_name: string;
  readonly description: string;
  readonly start_url: string;
  readonly scope: string;
  readonly display: "standalone";
  readonly background_color: string;
  readonly theme_color: string;
  readonly icons: readonly WebAppManifestIcon[];
}

export function createWebAppManifest(): WebAppManifest {
  return {
    name: "Canadian Ham Basic Study",
    short_name: "Canadian Ham",
    description: "Offline-first Canadian Amateur Radio Basic qualification study tool.",
    start_url: "./",
    scope: "./",
    display: "standalone",
    background_color: "#F6EEDC",
    theme_color: "#F6EEDC",
    icons: [
      { src: "./pwa-icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "./pwa-icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "./pwa-maskable-icon-192.png", sizes: "192x192", type: "image/png", purpose: "maskable" },
      { src: "./pwa-maskable-icon-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}

export function normalizePrecacheEntry(fileName: string): string {
  if (fileName === "") {
    return "./";
  }
  if (fileName.startsWith("./")) {
    return fileName;
  }
  if (fileName.startsWith("/")) {
    return `.${fileName}`;
  }
  return `./${fileName}`;
}

export function createPrecacheManifest(fileNames: readonly string[]): readonly string[] {
  return [...new Set(["./", "./index.html", ...PWA_PUBLIC_ASSETS, ...fileNames.map(normalizePrecacheEntry)])]
    .filter((entry) => !entry.endsWith(".map"))
    .sort();
}

export function createServiceWorkerSource(precacheEntries: readonly string[], cacheVersion: string): string {
  const manifestJson = JSON.stringify(precacheEntries, null, 2);
  const versionJson = JSON.stringify(cacheVersion);
  return `const CACHE_NAME = "canadian-ham-${cacheVersion}";
const PRECACHE_URLS = ${manifestJson};

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS.map((url) => new Request(url, { cache: "reload" })))));
});

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((name) => name.startsWith("canadian-ham-") && name !== CACHE_NAME).map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener("message", (event) => {
  if (event.data && event.data.type === "SKIP_WAITING") {
    self.skipWaiting();
  }
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") {
    return;
  }
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) {
    event.respondWith(Response.error());
    return;
  }
  if (request.mode === "navigate") {
    event.respondWith(navigationResponse(request));
    return;
  }
  event.respondWith(cacheFirst(request));
});

async function navigationResponse(request) {
  const cachedExact = await caches.match(request);
  if (cachedExact) {
    return cachedExact;
  }
  if (isAppShellNavigation(request)) {
    const cachedShell = await caches.match("./index.html");
    return cachedShell || fetch(request);
  }
  return fetch(request);
}

function isAppShellNavigation(request) {
  const requestUrl = new URL(request.url);
  const scopePath = new URL(self.registration.scope).pathname;
  const relativePath = requestUrl.pathname.slice(scopePath.length).replace(/^\\/+/, "");
  return relativePath === "" || relativePath === "index.html";
}

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }
  const response = await fetch(request);
  if (response.ok && new URL(request.url).origin === self.location.origin) {
    const cache = await caches.open(CACHE_NAME);
    await cache.put(request, response.clone());
  }
  return response;
}

self.__CANADIAN_HAM_PRECACHE_VERSION__ = ${versionJson};
`;
}

export function isSameOriginCacheableRequest(requestUrl: string, serviceWorkerOrigin: string): boolean {
  return new URL(requestUrl, serviceWorkerOrigin).origin === serviceWorkerOrigin;
}
