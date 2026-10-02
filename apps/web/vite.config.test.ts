import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { resolveWebBase } from "./vite.config";

describe("Vite base path", () => {
  it("defaults to relative paths for local development and preview builds", () => {
    assert.equal(resolveWebBase({}), "./");
    assert.equal(resolveWebBase({ CANADIAN_HAM_WEB_BASE_PATH: "" }), "./");
  });

  it("accepts the GitHub Pages project-site base path", () => {
    assert.equal(resolveWebBase({ CANADIAN_HAM_WEB_BASE_PATH: "/canadian-ham/" }), "/canadian-ham/");
  });

  it("rejects URL-like or non-normalized base paths", () => {
    assert.throws(() => resolveWebBase({ CANADIAN_HAM_WEB_BASE_PATH: "canadian-ham" }), /starts and ends with '\/'/);
    assert.throws(() => resolveWebBase({ CANADIAN_HAM_WEB_BASE_PATH: "https://example.com/canadian-ham/" }), /starts and ends with '\/'/);
    assert.throws(() => resolveWebBase({ CANADIAN_HAM_WEB_BASE_PATH: "/canadian-ham//" }), /empty path segments/);
    assert.throws(() => resolveWebBase({ CANADIAN_HAM_WEB_BASE_PATH: "/../canadian-ham/" }), /'\.\.'/);
  });
});
