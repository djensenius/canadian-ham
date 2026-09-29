import { useEffect, useState } from "react";

type OfflineState = "unsupported" | "installing" | "ready" | "error";

export function PwaStatus() {
  const [offlineState, setOfflineState] = useState<OfflineState>(() => typeof navigator === "undefined" || !("serviceWorker" in navigator) ? "unsupported" : "installing");
  const [updateWorker, setUpdateWorker] = useState<ServiceWorker | null>(null);
  const [message, setMessage] = useState("");

  useEffect(() => {
    if (!("serviceWorker" in navigator)) {
      return undefined;
    }
    let cancelled = false;
    let registration: ServiceWorkerRegistration | null = null;

    function watchInstalling(worker: ServiceWorker | null): void {
      if (worker === null) {
        return;
      }
      worker.addEventListener("statechange", () => {
        if (cancelled) {
          return;
        }
        if (worker.state === "installed" && navigator.serviceWorker.controller !== null) {
          setUpdateWorker(worker);
          setMessage("An offline update is ready. Apply it when you are not in the middle of an exam.");
        }
        if (worker.state === "activated") {
          setOfflineState("ready");
        }
      });
    }

    void navigator.serviceWorker.register("./sw.js").then(async (nextRegistration) => {
      if (cancelled) {
        return;
      }
      registration = nextRegistration;
      watchInstalling(registration.installing);
      if (registration.waiting !== null && navigator.serviceWorker.controller !== null) {
        setUpdateWorker(registration.waiting);
        setMessage("An offline update is ready. Apply it when you are not in the middle of an exam.");
      }
      registration.addEventListener("updatefound", () => watchInstalling(registration?.installing ?? null));
      await navigator.serviceWorker.ready;
      if (!cancelled) {
        setOfflineState("ready");
      }
    }).catch((error: unknown) => {
      if (!cancelled) {
        setOfflineState("error");
        setMessage(error instanceof Error ? error.message : String(error));
      }
    });

    return () => {
      cancelled = true;
    };
  }, []);

  const label = offlineState === "ready"
    ? "Available offline"
    : offlineState === "unsupported"
      ? "Offline install unavailable"
      : offlineState === "error"
        ? "Offline cache needs attention"
        : "Caching for offline use";

  return (
    <div className="pwa-status" aria-label="Offline availability" aria-live="polite">
      <span aria-hidden="true">{offlineState === "ready" ? "✓" : "•"}</span>
      <span>{label}</span>
      {message ? <span className="pwa-status__message">{message}</span> : null}
      {updateWorker !== null ? (
        <button
          type="button"
          onClick={() => {
            updateWorker.postMessage({ type: "SKIP_WAITING" });
            setUpdateWorker(null);
            setMessage("Offline update applied. Finish current work before refreshing.");
          }}
        >Apply offline update</button>
      ) : null}
    </div>
  );
}
