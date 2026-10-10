# App Store submission notes

Status: draft for `task-1.9`. These notes are for App Store Connect preparation only; do not submit or publish anything until the release gates in [`../release-checklist.md`](../release-checklist.md) are complete.

## Category

- Primary category: **Education**.
- Secondary category: **Reference**.
- Rationale: the v1 app is an offline amateur-radio study and reference-practice tool with lessons, quizzes, practice by topic, mock exams and Morse training.

## Age rating questionnaire draft

Expected rating after the questionnaire: **4+**, subject to App Store Connect's final calculated result.

| Area | Draft answer | Evidence / rationale |
|---|---|---|
| Cartoon or fantasy violence | None | No combat or violence features. |
| Realistic violence | None | No realistic violence content. |
| Sexual content or nudity | None | No sexual or nudity content. |
| Profanity or crude humour | None | Educational radio-study content only. |
| Alcohol, tobacco, drug use or references | None | No such content in app features. |
| Mature or suggestive themes | None | Educational radio-study content only. |
| Medical or treatment information | None | Not a medical app. |
| Horror or fear themes | None | No horror content. |
| Gambling, contests or loot boxes | None | No gambling, contests, purchases or chance-based rewards. |
| User-generated content | No | No accounts, posting, chat, uploads or moderation surface. |
| Unrestricted web access | No | No in-app browser or remote content feed; source/citation URLs are user-initiated references and the app does not load remote web content. |
| Kids category | No | The app is for general amateur-radio learners, not declared in the Kids category. |

## App Privacy answers

Use [`../privacy-label-evidence.md`](../privacy-label-evidence.md) and [`../../privacy.md`](../../privacy.md) as the source of truth at submission time. Re-run the release evidence before submitting.

Recommended App Store Connect answer: **Data Not Collected**.

| App Privacy area | Draft answer |
|---|---|
| Data collection gate | Data Not Collected. |
| Contact Info | Not collected. |
| Health and Fitness | Not collected. |
| Financial Info | Not collected. |
| Location | Not collected. |
| Sensitive Info | Not collected. |
| Contacts | Not collected. |
| User Content | Not collected. |
| Browsing History | Not collected. |
| Search History | Not collected. |
| Identifiers | Not collected. |
| Purchases | Not collected. |
| Usage Data | Not collected. |
| Diagnostics | Not collected. |
| Body / surroundings categories for visionOS, if shown | Not collected. |
| Other Data | Not collected. |
| Tracking | No tracking. |
| Third-party SDK data collection | None. |

Rationale: v1 has no accounts, analytics, telemetry, ads, tracking, remote config, third-party runtime SDKs or Apple-app networking features. On iPhone, iPad and Mac, progress remains local unless the user exports it. Apple TV and Vision Pro keep practice sessions only while the app is open.

## Support and marketing URL plan

No URL may be made public until the release gates allow it.

- Support URL: use a public support page on the same static site prepared by [`../web-deploy.md`](../web-deploy.md). The page must identify the app, state the no-data/offline privacy summary, provide a support contact path chosen by the owner, and link to the privacy page. Do not use the private GitHub repository or private issue tracker as the public support URL.
- Marketing URL: use the public static web app / project landing page after deployment is approved. The marketing page must not imply ISED endorsement, a guaranteed exam outcome or public-source availability before the repository-public gate is complete.
- Privacy policy URL: use the public version of [`../../privacy.md`](../../privacy.md) or an equivalent public privacy page generated from it after deployment is approved.

## ISED attribution and disclaimer wording

The ISED attribution is a **draft pending `task-1.1`**. Do not paste it into App Store Connect until the permission reference number, date and exact scope are recorded in [`../../content-licensing.md`](../../content-licensing.md), and then adjust only to match the recorded permission.

Draft attribution for the listing after permission is recorded:

> Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page.

Short listing form, if space is needed after permission is recorded:

> ISED Basic question-bank material reproduced with permission. Original lessons and explanations are by the canadian-ham project.

Required non-endorsement disclaimer for listing text or review notes that mention ISED material:

> canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.

fr-CA listing note: keep legal attribution and disclaimer wording in English unless `task-1.1` / owner legal review approves localized legal copy. The fr-CA marketing copy in [`fr-CA.md`](fr-CA.md) therefore describes features without translating the draft legal attribution.
