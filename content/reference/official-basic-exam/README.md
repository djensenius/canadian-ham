# Official ISED Basic exam sheet reproduction (internal only)

Source: Innovation, Science and Economic Development Canada (ISED), **Reference Material for Amateur Radio Exam – Basic Qualification**, Version 1 (May 2025), in
`content/sources/ised/basic-2025-07-15/reference/Reference Material for Amateur Radio Exam Basic EN 2025.pdf`.
Source SHA-256: `e4e6a0ec35d9ccec2732b6c2a950b3ea721f826d44160b54b4e6298e86b93ae9`.

The five PNGs are full-page, unannotated raster reproductions at 144 dpi, not redrawn diagrams. Regenerate offline on macOS:

```sh
swift scripts/render-official-reference-sheet.swift \
  'content/sources/ised/basic-2025-07-15/reference/Reference Material for Amateur Radio Exam Basic EN 2025.pdf' \
  content/reference/official-basic-exam
```

`text-equivalent.md` transcribes the printed wording and formulas verbatim using linear fractions and Unicode subscripts. The original PDF's text layer omits its diagrams. Their spatial/symbol descriptions are therefore explicitly marked **project accessibility text, not ISED labels**, without supplying inferred block names/answers. The repeated header/footer is stated once and described as repeated on all pages. No French official sheet is available; French UI keeps the official content English.

Owner decision 2026-10-12 (2A) authorizes private development/internal TestFlight use under the interim risk policy, not public release. This reproduction is not an official version and Canadian Ham is not affiliated with or endorsed by the Government of Canada. See `docs/content-licensing.md`. Only the PNGs and transcript are copied by the opt-in build gate; neither this README nor the training PDF ships.

## SHA-256 of app assets
0389a8057e20080c51bcb36ddcedfd3bb703d684f145803b118331d57fb7055c  page-1.png
397ca428126befa7938b8a522461a3190896a083b3b3712752dd53111c9d8f0e  page-2.png
440fde861fcbb550fd33299fd3e41f44caebc8b888be4e5a84902cb3050134ae  page-3.png
98a9bce94a23cb182034148abea4bf710e903566c861fccfb810a0687b4415bc  page-4.png
f63a28f0ae447e78a14e2d77e24924d8db001a154d3a444e6f30eb93b407b840  page-5.png
e12733ce22d628646373d7310c016677c040b00394c364d2fe96be08f3fab57d  text-equivalent.md
