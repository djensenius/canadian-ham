# Content licensing and attribution plan

This document defines how `canadian-ham` separates official ISED data from original project content and how it records permission, attribution, and disclaimers.

The ISED permission request has been drafted but not yet sent or granted. The requested scope covers the Basic 2025 question-bank TXT and PDF, the Basic 2025 English reference PDFs, the Advanced question bank, commercial use, future revisions, and structured app-data formats with shuffled choices. Written permission is tracked by task-1.1 and remains pending; no permission has been granted or recorded yet.

Until written permission is recorded, the GitHub repository `djensenius/canadian-ham` remains private. ISED's published terms allow reproduction for personal, non-commercial purposes without permission, including the [general terms and conditions](https://ised-isde.canada.ca/site/ised/en/terms-and-conditions) and [copyright written permission guidance](https://www.ised-isde.canada.ca/site/ised/en/copyright-written-permission). The owner has approved committing official ISED source artifacts for private, non-distributed development under the interim policy below as the owner's risk decision, not as legal advice. Public exposure or distribution does not fit that interim rationale and is blocked by the [public-release gate](#public-release-gate).

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
| Request status | Drafted (2026-09-28 owner decision); sent: pending; granted: pending |
| ISED reference number | Pending: fill in permission reference number |
| Permission date | Pending: fill in permission date |
| Permission scope | Pending: paste concise scope from written permission |
| Covered source artifacts | Pending scope: request includes 2025 Basic question bank delimited TXT; 2025 Basic question bank PDF; 2025 English Basic reference PDFs; Advanced question bank; commercial use; future revisions; structured app-data format with shuffled choices |
| Storage location for permission evidence | Pending: private owner records; do not commit private correspondence unless approved |
| Release review status | Blocked until reference number/date/scope are recorded and the scope explicitly covers the release artifacts |

Do not infer permission scope beyond the written clearance. T-007/task-1.1 records the permission reference number, date, scope, and explicit confirmation that the scope covers bundling verbatim question text as app data, including the Advanced bank already named in the request. The reference PDFs are retained only as source artifacts and are not shipped in the apps. Until permission is recorded, vendoring is allowed only for private, non-distributed development under the [interim private-development policy](#interim-private-development-policy); publication and distribution remain blocked by the [public-release gate](#public-release-gate).

## Interim private-development policy

While the repository is private and no outside collaborators are added, the project may commit official ISED artifacts needed for development under these versioned source directories:

- `content/sources/ised/basic-2025-07-15/` for:
  - the Basic 2025 delimited TXT;
  - `readme_basic.txt` and `lisezmoi_base.txt` from the Basic 2025 question-bank ZIP;
  - the Basic 2025 question-bank PDF;
  - the English Basic 2025 reference PDFs, either in the same directory or in a documented reference subfolder under that directory; these PDFs are not shipped in the apps.
- `content/sources/ised/advanced-<title-page-date>/` for verbatim Advanced question-bank source files from ISED, including the delimited TXT/ZIP companion files and English/French PDFs named in the permission request. Use the official title-page date once verified for the directory suffix, record the source URLs, and do not make an Advanced bank active in the apps until separate app support is implemented.

These files must be stored verbatim, with SHA-256 checksums recorded in the source manifest, and with the attribution and disclaimer in this document kept in place. The files must not be edited, reformatted, or mixed into original lesson or explanation content.

ISED's non-commercial reproduction conditions include:

- exercising due diligence in ensuring the accuracy of the materials reproduced;
- identifying ISED as the source department and identifying the source work by title;
- not representing the reproduction as an official version or as having been made in affiliation with or endorsed by the Government of Canada.

This interim policy is the owner's risk decision and is not legal advice. This policy does not allow making the repository public, deploying the web app publicly, distributing Apple builds, adding outside collaborators, or any other redistribution.

## Public-release gate

All of the following actions are blocked until T-007 records written ISED permission with the reference number, date, scope, and explicit confirmation that the scope covers bundling verbatim question text as app data. The reference PDFs remain source artifacts and are not shipped in the apps:

- making the GitHub repository public or adding outside collaborators;
- deploying the web app anywhere publicly reachable;
- TestFlight external testing or App Store submission;
- any other redistribution of ISED artifacts, normalized ISED data, or app bundles containing them.

Before any public exposure, the release review must verify that the repository history and release artifacts contain no ISED material outside the recorded permission scope.

If permission is refused or narrower than requested, recommended contingency is to publish from a fresh public repository with new history containing only files within the recorded permission scope, and to keep the current repository private or archive it privately. This avoids relying on history rewriting to make a previously private repository safe for public release.

Alternative contingency: use `git filter-repo` to purge already-committed out-of-scope ISED files from this repository history, then force-push rewritten branches and tags. History rewriting does not remove all risk: existing clones, worktrees, forks, and CI caches can retain the old objects, and GitHub may keep cached or unreachable commits and pull-request refs until GitHub Support purges them. Keep any still-needed out-of-scope official source files in a separate private repository or private submodule that is never included in public release history.

## Attribution text

Use this attribution near question-bank acknowledgements after T-007/task-1.1 records permission, adjusted only after legal/owner review:

> Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank and, where included, Advanced Qualification question bank, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page.

Short form for app settings or about page after T-007/task-1.1 records permission:

> ISED question-bank material reproduced with permission. Original lessons and explanations are by the canadian-ham project.

During private development before T-007 is complete, internal documentation and manifests must not claim that written permission has been granted.

TODO before public release: label any release About-page draft attribution as not in effect while the request status remains drafted; sent: pending; granted: pending, then replace it with the exact wording from the recorded ISED permission in T-007/task-1.1. Do not add a permission reference number, date, or scope here until the written permission record is available.

## Disclaimer

Use this disclaimer in the app/site about page, documentation, and any public release notes that mention ISED material:

> canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.

## Separation of content classes

The repository must keep ISED source data separate from original project content.

| Content class | Location | Rules |
|---|---|---|
| ISED official source artifacts | `content/sources/ised/basic-2025-07-15/`; `content/sources/ised/advanced-<title-page-date>/` | Store the Basic 2025 TXT, Basic 2025 question-bank PDF, English reference PDFs, and approved Advanced source files verbatim with checksums under the interim private-development policy while the repository remains private. Do not edit. Importer and CI jobs may run against the committed TXT files. The reference PDFs and Advanced PDFs are not shipped in the apps. Public release requires T-007/task-1.1 permission scope to cover included ISED app data. |
| Generated ISED question data | `content/generated/basic-2025-07-15/` | Generated from official source. Preserve text verbatim. Include source manifest. Private development may use it; public release requires T-007 permission scope to cover bundling verbatim question text as app data. |
| Category metadata | `content/categories.json` | Hand-maintained. English names from verified ISED/RAC materials. French names are ISED's official wording (CIR-3 §5.1 and the French Amateur Radio Exam Generator; see `docs/requirements.md`). |
| Original lessons | `content/lessons/` | Original writing by project. May cite ISED question IDs and RBR-4. Must not copy RAC/Coax study-guide text. |
| Original explanations | `content/explanations/` | Original writing by project. Separate from ISED records. Must not copy third-party study guides. |
| Reference material metadata/assets | `content/reference/` | Private development may track metadata and checksums for the English reference PDFs under the interim policy. The PDFs remain in `content/sources` for provenance and are not shipped in the apps. |

## Verbatim ISED question text

Rules:

- Keep ISED question text verbatim.
- Keep ISED answer text verbatim.
- Do not reword questions to make lessons easier.
- Do not correct perceived typos in official text without a documented source update.
- Do not translate English ISED questions into French.
- Use the official ISED French question and answer text from the delimited file.
- If French source text is missing in a future bank, block the import or mark the bank as not ready.

UI may wrap, style, and shuffle answers, but it must not alter official wording. Public release of structured app-data formats with verbatim question text and shuffled choices requires T-007 permission scope to cover that use.

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
- French UI may be translated by the project because it is original interface copy, not official ISED question text.
- Keep attribution, disclaimer, and other legal-review footer/About text English-only in the French UI with `lang="en"` / English accessibility-language tagging until T-007/task-1.1 and the release legal review approve localized legal copy. This avoids presenting unreviewed French drafts as legal wording.
- French category names are open until verified from an official source.
- French reference material has not yet been located; do not claim it exists.

## Reference material policy

The English reference material ZIP contains:

- `Reference Material for Amateur Radio Exam Basic EN 2025.pdf`, SHA-256 `e4e6a0ec35d9ccec2732b6c2a950b3ea721f826d44160b54b4e6298e86b93ae9`; not shipped in the apps.
- `Reference Material for Amateur Radio Training Basic EN 2025.pdf`, SHA-256 `2e0bf5e30a621852db0bf3c1e3954bbd60f906b19c531d97eab9b35c8f1a831e`; not shipped in the apps.

Rules:

- Label the training version as study aid material.
- Label the unlabelled exam version as reference material that may be used while writing the exam.
- Do not bundle these PDFs in web or Apple app artifacts; they are kept only as source artifacts under `content/sources`.
- Keep checksums in the source manifest.
- Do not recreate ISED diagrams unless permission scope explicitly allows derivative formats.

## Source update policy

When ISED updates the bank, follow the detailed [content update process](content-update-process.md) as well as the summary below:

1. Follow the re-verification procedure in [exam-facts.md](exam-facts.md).
2. Create a new versioned source directory rather than overwriting the active bank.
3. Confirm private-development handling or written permission scope covers the new source version before committing it.
4. Run importer validation and fixture updates in a dedicated worker branch.
5. Review all changed official text as source updates, not project edits.
6. Update app-visible bank version.
7. Keep legacy bank support out of scope unless separately approved.
8. Complete the [public-release gate](#public-release-gate) before any public exposure or distribution.

## Release checklist

Before any public release:

- Permission reference number, date, and scope are recorded above.
- Permission scope explicitly covers bundling verbatim question text as app data.
- Reference PDFs are not shipped in release artifacts.
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
- Confirm whether permission explicitly covers bundling verbatim question text as app data, including structured formats with shuffled choices.
- Confirm whether any future change to ship English reference PDFs in web or Apple apps has explicit permission before implementation; current app artifacts do not ship them.
- Verify official French category names before displaying French category headings.
- Locate French 2025 Basic reference material or document its absence in release notes.
