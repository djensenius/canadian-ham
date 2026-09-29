# content/sources/ised

Purpose: verbatim ISED source artifacts for private, non-distributed development.

Belongs here:

- Official ISED source files exactly as downloaded or extracted for the active bank.
- Versioned source directories such as `basic-2025-07-15/` once T-101 vendors the files.
- Checksum manifests that verify byte identity.

Must not go here:

- Hand-edited TXT, PDF, ZIP, or derived files.
- Normalized JSON output; use [`../../generated/`](../../generated/).
- Original lessons, explanations, or app code.

Git handling: [`.gitattributes`](../../../.gitattributes) marks `content/sources/**` as binary so Git does not normalize line endings or generate text diffs. This preserves CRLF TXT files and PDFs byte-for-byte so recorded SHA-256 checksums remain valid.

Relevant docs: [`../../../docs/content-licensing.md`](../../../docs/content-licensing.md), [`../../../docs/exam-facts.md`](../../../docs/exam-facts.md), [`../../../docs/architecture.md`](../../../docs/architecture.md).
