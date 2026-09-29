import { StrictMode, Suspense, lazy } from "react";
import { createRoot } from "react-dom/client";

import "./styles.css";

const App = lazy(async () => {
  const module = await import("./App");
  return { default: module.App };
});

const rootElement = document.getElementById("root");
if (rootElement === null) {
  throw new Error("Root element not found");
}

createRoot(rootElement).render(
  <StrictMode>
    <Suspense fallback={<main className="app-loading" aria-busy="true">Preparing the offline study desk…</main>}>
      <App />
    </Suspense>
  </StrictMode>,
);
