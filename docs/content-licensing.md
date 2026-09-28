# Content licensing and attribution plan

This document defines how `canadian-ham` separates official ISED data from original project content and how it records permission, attribution, and disclaimers.

The owner states that written Crown copyright clearance from ISED has been granted. The project must still record permission details before release.

Related documents:

- [exam facts](exam-facts.md)
- [requirements](requirements.md)
- [architecture](architecture.md)
- [privacy](privacy.md)

## Permission record

Record the written permission here when available in project records.

| Field | Value |
|---|---|
| Permission holder | Owner / project maintainer |
| ISED reference number | Pending: fill in permission reference number |
| Permission date | Pending: fill in permission date |
| Permission scope | Pending: paste concise scope from written permission |
| Covered source artifacts | 2025 Basic question bank delimited TXT; 2025 Basic question bank PDF; 2025 English Basic reference material, if included in permission scope |
| Storage location for permission evidence | Pending: private owner records; do not commit private correspondence unless approved |
| Release review status | Blocked until reference number/date/scope are recorded |

Do not infer permission scope beyond the written clearance. T-101 must not commit ISED source artifacts until the permission reference record exists. If the permission does not clearly cover an artifact, commit only its canonical URL and checksum until clarified; do not vendor or bundle the artifact itself.

## Attribution text

Use this attribution near question-bank and reference-material acknowledgements, adjusted only after legal/owner review:

> Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank and related reference material, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page.

Short form for app settings or about page:

> ISED Basic question-bank material reproduced with permission. Original lessons and explanations are by the canadian-ham project.

## Disclaimer

Use this disclaimer in the app/site about page, documentation, and any public release notes that mention ISED material:

> canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.

## Separation of content classes

The repository must keep ISED source data separate from original project content.

| Content class | Location | Rules |
|---|---|---|
| ISED official source artifacts | `content/sources/ised/basic-2025-07-15/` | Store verbatim files and checksums only after the permission record is filed and scope covers the artifact. Do not edit. For artifacts not clearly in scope, store only URL and checksum metadata. |
| Normalized ISED question data | `content/normalized/basic-2025-07-15/` | Generated from official source. Preserve text verbatim. Include source manifest. |
| Category metadata | `content/categories.json` | Hand-maintained. English names from verified ISED/RAC materials. French names pending official verification. |
| Original lessons | `content/lessons/` | Original writing by project. May cite ISED question IDs and RBR-4. Must not copy RAC/Coax study-guide text. |
| Original explanations | `content/explanations/` | Original writing by project. Separate from ISED records. Must not copy third-party study guides. |
| Reference material metadata/assets | `content/reference/` | Include only artifacts covered by permission and tracked checksums. |

## Verbatim ISED question text

Rules:

- Keep ISED question text verbatim.
- Keep ISED answer text verbatim.
- Do not reword questions to make lessons easier.
- Do not correct perceived typos in official text without a documented source update.
- Do not translate English ISED questions into French.
- Use the official ISED French question and answer text from the delimited file.
- If French source text is missing in a future bank, block the import or mark the bank as not ready.

UI may wrap, style, and shuffle answers, but it must not alter official wording.

## Original lessons and explanations

Original content may:

- Explain concepts in plain language.
- Cite official question IDs.
- Cite RBR-4 and other verified source URLs from [exam-facts.md](exam-facts.md).
- Explain how to use formulas and block diagrams.
- Give original examples that are not copied from third-party study guides.

Original content must not:

- Copy RAC study-guide text.
- Copy Coax Publications study-guide text.
- Copy any third-party study-guide prose, diagrams, examples, or tables without explicit permission.
- Paraphrase third-party study guides so closely that the structure and expression are still derived from them.
- Invent regulatory facts not present in verified sources.

## French content policy

- Use official ISED French question and answer text from the delimited file.
- Do not create project translations of ISED question text.
- French UI is planned later and may be translated by the project because it is original interface copy, not official ISED question text.
- French category names are open until verified from an official source.
- French reference material has not yet been located; do not claim it exists.

## Reference material policy

The English reference material ZIP contains:

- `Reference Material for Amateur Radio Exam Basic EN 2025.pdf`, SHA-256 `e4e6a0ec35d9ccec2732b6c2a950b3ea721f826d44160b54b4e6298e86b93ae9`.
- `Reference Material for Amateur Radio Training Basic EN 2025.pdf`, SHA-256 `2e0bf5e30a621852db0bf3c1e3954bbd60f906b19c531d97eab9b35c8f1a831e`.

Rules:

- Label the training version as study aid material.
- Label the unlabelled exam version as reference material that may be used while writing the exam.
- Bundle only if permission scope covers bundling.
- Keep checksums in the source manifest.
- Do not recreate ISED diagrams unless permission scope explicitly allows derivative formats.
- If a native viewer renders PDF pages, it must not send the PDF to a remote service.

## Source update policy

When ISED updates the bank:

1. Follow the re-verification procedure in [exam-facts.md](exam-facts.md).
2. Create a new versioned source directory rather than overwriting the active bank.
3. Confirm permission scope covers the new source version.
4. Run importer validation and fixture updates in a dedicated worker branch.
5. Review all changed official text as source updates, not project edits.
6. Update app-visible bank version.
7. Keep legacy bank support out of scope unless separately approved.

## Release checklist

Before any public release:

- Permission reference number, date, and scope are recorded above.
- Attribution text appears in web and Apple about/settings surfaces.
- Disclaimer appears in web and Apple about/settings surfaces.
- Source URLs and checksums are recorded.
- Official ISED question text is traceable from normalized JSON back to source records.
- Original lessons and explanations are stored separately from ISED data.
- Review confirms no RAC/Coax study-guide text was copied.
- French question text comes from ISED official source.
- Open licensing questions are either resolved or clearly documented as release blockers.

## Open licensing questions

- Fill in ISED permission reference number.
- Fill in ISED permission date.
- Confirm whether permission explicitly covers bundling the English reference PDFs in both web and Apple apps.
- Confirm whether permission covers generated normalized JSON derived from the delimited TXT.
- Verify official French category names before displaying French category headings.
- Locate French 2025 Basic reference material or document its absence in release notes.
