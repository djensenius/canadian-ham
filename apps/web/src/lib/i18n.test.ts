import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { enMessages, frMessages } from "./i18n";

describe("interface message catalogue", () => {
  it("keeps English and French message keys in parity", () => {
    assert.deepEqual(Object.keys(frMessages).sort(), Object.keys(enMessages).sort());
  });
});
