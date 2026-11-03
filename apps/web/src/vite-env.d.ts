/// <reference types="vite/client" />


declare module "virtual:official-reference-sheet" {
  const sheet: { readonly markdown: string; readonly pages: readonly string[] } | null;
  export default sheet;
}
