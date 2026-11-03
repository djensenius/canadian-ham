import { useState } from "react";
import officialSheet from "virtual:official-reference-sheet";

import { basicReferenceSheetMarkdownForWeb } from "../data/referenceSheet";
import { t, type InterfaceLanguage } from "../lib/i18n";
import { MarkdownContent } from "./MarkdownContent";

export function ReferenceSheetTool({ interfaceLanguage }: { readonly interfaceLanguage: InterfaceLanguage }) {
  const [showOfficial, setShowOfficial] = useState(officialSheet !== null);
  const [textEquivalent, setTextEquivalent] = useState(false);
  const [page, setPage] = useState(0);
  const [zoom, setZoom] = useState(100);
  const original = basicReferenceSheetMarkdownForWeb();
  return (
    <section className="reference-sheet-tool" aria-label={t(interfaceLanguage, "referenceSheetTitle")} data-exam-tool-focus tabIndex={-1}>
      {officialSheet !== null ? (
        <label>{t(interfaceLanguage, "referenceSheetVersion")}
          <select value={showOfficial ? "official" : "study"} onChange={(event) => setShowOfficial(event.target.value === "official")}>
            <option value="official">{t(interfaceLanguage, "officialSheet")}</option>
            <option value="study">{t(interfaceLanguage, "studySheet")}</option>
          </select>
        </label>
      ) : null}
      {interfaceLanguage === "fr" ? <p className="reference-note" lang="fr-CA">{t(interfaceLanguage, "englishOnlyContentNotice")}</p> : null}
      {showOfficial && officialSheet !== null ? (
        <>
          <p lang="en">Source: Innovation, Science and Economic Development Canada (ISED), Reference Material for Amateur Radio Exam – Basic Qualification, Version 1 (May 2025). Reproduced for internal use; this reproduction is not an official version. Canadian Ham is not affiliated with or endorsed by the Government of Canada.</p>
          <label><input type="checkbox" checked={textEquivalent} onChange={(event) => setTextEquivalent(event.target.checked)} /> {t(interfaceLanguage, "sheetTextEquivalent")}</label>
          {textEquivalent ? <MarkdownContent markdown={officialSheet.markdown} interfaceLanguage={interfaceLanguage} contentLanguage="en" /> : (
            <>
              <label>{t(interfaceLanguage, "sheetPage")}
                <select value={page} onChange={(event) => setPage(Number(event.target.value))}>
                  {officialSheet.pages.map((_, index) => <option value={index} key={index}>{index + 1} / 5</option>)}
                </select>
              </label>
              <div className="sheet-zoom-controls">
                <button type="button" disabled={zoom <= 100} onClick={() => setZoom(zoom - 50)}>{t(interfaceLanguage, "sheetZoomOut")}</button>
                <output aria-label={t(interfaceLanguage, "sheetZoom")}>{zoom}%</output>
                <button type="button" disabled={zoom >= 300} onClick={() => setZoom(zoom + 50)}>{t(interfaceLanguage, "sheetZoomIn")}</button>
              </div>
              <div className={`official-sheet-viewport sheet-zoom-${zoom}`} role="region" aria-label={t(interfaceLanguage, "officialSheet")} tabIndex={0}>
                <img src={officialSheet.pages[page]} alt={t(interfaceLanguage, "sheetPageAlt", page + 1)} />
              </div>
            </>
          )}
        </>
      ) : <MarkdownContent markdown={original} title="Original Basic formula and reference study aid" tableLabel={t(interfaceLanguage, "referenceSheetTableAria")} interfaceLanguage={interfaceLanguage} contentLanguage="en" />}
    </section>
  );
}
