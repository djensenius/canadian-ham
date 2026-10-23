import assert from "node:assert/strict";
import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import axe from "axe-core";
import { afterEach, describe, it, vi } from "vitest";
import { t } from "../lib/i18n";
import { ReferenceSheetTool } from "./ReferenceSheetTool";

afterEach(cleanup);

describe("ReferenceSheetTool official English exam sheet", () => {
  for (const language of ["en", "fr"] as const) {
    for (const theme of ["light", "dark"] as const) {
      it(`supports pages, zoom, accessible text and study fallback in ${language}, ${theme}`, async () => {
        document.documentElement.lang = language;
        document.documentElement.dataset.theme = theme;
        const user = userEvent.setup();
        const { container } = render(<main><ReferenceSheetTool interfaceLanguage={language} /></main>);
        const image = screen.getByRole("img");
        assert.match(image.getAttribute("src") ?? "", /page-1.png/);
        await user.click(screen.getByRole("button", { name: t(language, "sheetZoomIn") }));
        assert.ok(container.querySelector(".sheet-zoom-150"));
        for (let page = 1; page < 5; page++) {
          await user.selectOptions(screen.getByRole("combobox", { name: t(language, "sheetPage") }), String(page));
          assert.match(image.getAttribute("src") ?? "", new RegExp(`page-${page + 1}.png`));
        }
        const checkAxe = async () => {
          const results = await axe.run(container);
          assert.deepEqual(results.violations, []);
        };
        // Keep the default axe rules, matching the app integration audits.
        await checkAxe();
        await user.click(screen.getByRole("checkbox", { name: t(language, "sheetTextEquivalent") }));
        assert.ok(screen.getByText("L = 142 / F"));
        assert.ok(screen.getByText("L = 71 / F"));
        assert.equal(screen.getByText("L = 306 / F").closest("ul")?.lang, "en");
        assert.ok(screen.getByRole("heading", { name: "Page 5" }));
        assert.ok(screen.getByText(/The switch arm points to the middle contact/));
        await checkAxe();
        await user.selectOptions(screen.getByRole("combobox", { name: t(language, "referenceSheetVersion") }), "study");
        assert.ok(screen.getByRole("heading", { name: "Ohm's law" }));
        assert.equal(screen.queryByRole("img"), null);
        await checkAxe();
      }, 10_000);
    }
  }

  it("offers only the original sheet when the build gate excludes official content", async () => {
    vi.resetModules();
    vi.doMock("virtual:official-reference-sheet", () => ({ default: null }));
    const { ReferenceSheetTool: FallbackTool } = await import("./ReferenceSheetTool");
    render(<FallbackTool interfaceLanguage="en" />);
    assert.ok(screen.getByRole("heading", { name: "Ohm's law" }));
    assert.equal(screen.queryByRole("combobox"), null);
    vi.doUnmock("virtual:official-reference-sheet");
  });
});
