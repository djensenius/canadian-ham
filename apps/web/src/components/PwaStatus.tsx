import { useEffect, useRef, useState } from "react";

type OfflineState = "unsupported" | "installing" | "ready" | "error";

interface PwaStatusProps {
  readonly updateDisabled?: boolean;
}

export function PwaStatus({ updateDisabled = false }: PwaStatusProps) {
  const serviceWorkerAvailable = typeof navigator !== "undefined" && "serviceWorker" in navigator && import.meta.env.PROD;
  const [offlineState, setOfflineState] = useState<OfflineState>(() => serviceWorkerAvailable ? "installing" : "unsupported");
  const [updateWorker, setUpdateWorker] = useState<ServiceWorker | null>(null);
  const [message, setMessage] = useState("");
  const applyingUpdateRef = useRef(false);

  useEffect(() => {
    if (!serviceWorkerAvailable) {
      return undefined;
    }
    let cancelled = false;
    let registration: ServiceWorkerRegistration | null = null;

    function onControllerChange(): void {
      if (applyingUpdateRef.current) {
        window.location.reload();
      }
    }

    navigator.serviceWorker.addEventListener("controllerchange", onControllerChange);

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
      navigator.serviceWorker.removeEventListener("controllerchange", onControllerChange);
    };
  }, [serviceWorkerAvailable]);

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
          disabled={updateDisabled}
          onClick={() => {
            applyingUpdateRef.current = true;
            updateWorker.postMessage({ type: "SKIP_WAITING" });
            setUpdateWorker(null);
            setMessage("Offline update is applying. The app will reload to finish installing it.");
          }}
        >{updateDisabled ? "Finish mock exam before updating" : "Reload to apply offline update"}</button>
      ) : null}
    </div>
  );
}
