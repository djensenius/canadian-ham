import { useEffect, useRef, useState } from "react";

import { t, type InterfaceLanguage } from "../lib/i18n";

type OfflineState = "unsupported" | "installing" | "ready" | "error";

interface PwaStatusProps {
  readonly interfaceLanguage: InterfaceLanguage;
  readonly updateDisabled?: boolean;
}

export function PwaStatus({ interfaceLanguage, updateDisabled = false }: PwaStatusProps) {
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
          setMessage(t(interfaceLanguage, "pwaUpdateReady"));
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
        setMessage(t(interfaceLanguage, "pwaUpdateReady"));
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
  }, [interfaceLanguage, serviceWorkerAvailable]);

  const label = offlineState === "ready"
    ? t(interfaceLanguage, "pwaAvailableOffline")
    : offlineState === "unsupported"
      ? t(interfaceLanguage, "pwaOfflineUnavailable")
      : offlineState === "error"
        ? t(interfaceLanguage, "pwaOfflineAttention")
        : t(interfaceLanguage, "pwaCaching");

  return (
    <div className="pwa-status" aria-label={t(interfaceLanguage, "pwaOfflineAvailability")} aria-live="polite">
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
            setMessage(t(interfaceLanguage, "pwaUpdateApplying"));
          }}
        >{updateDisabled ? t(interfaceLanguage, "pwaFinishExamBeforeUpdating") : t(interfaceLanguage, "pwaReloadToUpdate")}</button>
      ) : null}
    </div>
  );
}
