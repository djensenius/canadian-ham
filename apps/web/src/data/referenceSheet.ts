import basicReferenceSheetMarkdown from "../../../../content/reference-sheet/basic.md?raw";

export type ReferenceSheetId = "basic-original-study-aid";

interface ReferenceSheetSource {
  readonly id: ReferenceSheetId;
  readonly markdown: string;
}

const basicReferenceSheetSource: ReferenceSheetSource = {
  id: "basic-original-study-aid",
  markdown: basicReferenceSheetMarkdown,
};

export function basicReferenceSheetMarkdownForWeb(): string {
  return basicReferenceSheetSource.markdown;
}
