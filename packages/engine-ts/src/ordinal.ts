const utf8Encoder = new TextEncoder();

export function compareOrdinal(a: string, b: string): number {
  const left = utf8Encoder.encode(a);
  const right = utf8Encoder.encode(b);
  const length = Math.min(left.length, right.length);
  for (let index = 0; index < length; index += 1) {
    const delta = left[index] - right[index];
    if (delta !== 0) {
      return delta < 0 ? -1 : 1;
    }
  }
  return left.length < right.length ? -1 : left.length > right.length ? 1 : 0;
}
