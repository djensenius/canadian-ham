import assert from "node:assert/strict";
import { describe, it } from "vitest";
import { officialReferenceSheetEnabled } from "./officialReferenceSheetPlugin";

describe("official reference sheet build gate", () => {
  it("defaults on only for local development", () => {
    assert.equal(officialReferenceSheetEnabled("serve", {}), true);
    assert.equal(officialReferenceSheetEnabled("build", {}), false);
  });
  it("requires an explicit internal build opt-in and supports removal", () => {
    assert.equal(officialReferenceSheetEnabled("build", { OFFICIAL_REFERENCE_SHEET: "YES" }), true);
    assert.equal(officialReferenceSheetEnabled("serve", { OFFICIAL_REFERENCE_SHEET: "NO" }), false);
    assert.equal(officialReferenceSheetEnabled("build", { OFFICIAL_REFERENCE_SHEET: "true" }), false);
  });
});
