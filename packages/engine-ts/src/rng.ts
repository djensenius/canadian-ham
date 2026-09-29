const MASK_32 = 0xffffffffn;
const MASK_64 = 0xffffffffffffffffn;
const TWO_32 = 0x1_0000_0000n;
const PCG32_MULTIPLIER = 0x5851f42d4c957f2dn;
const DEFAULT_INITSEQ = 0x14057b7ef767814fn;
const FNV1A64_OFFSET = 0xcbf29ce484222325n;
const FNV1A64_PRIME = 0x00000100000001b3n;

export const RNG_ALGORITHM = "fnv1a64-pcg32-xsh-rr";

export interface RngVector {
  readonly seed: string;
  readonly first8Uint32: readonly number[];
}

export function fnv1a64Utf8(seed: string): bigint {
  let hash = FNV1A64_OFFSET;
  const bytes = new TextEncoder().encode(seed);
  for (const byte of bytes) {
    hash ^= BigInt(byte);
    hash = (hash * FNV1A64_PRIME) & MASK_64;
  }
  return hash;
}

export class Pcg32 {
  #state = 0n;
  #inc = 0n;

  constructor(initstate: bigint, initseq: bigint = DEFAULT_INITSEQ) {
    this.srandom(initstate, initseq);
  }

  static fromSeedString(seed: string): Pcg32 {
    return new Pcg32(fnv1a64Utf8(seed), DEFAULT_INITSEQ);
  }

  srandom(initstate: bigint, initseq: bigint): void {
    this.#state = 0n;
    this.#inc = ((initseq << 1n) | 1n) & MASK_64;
    this.nextUint32();
    this.#state = (this.#state + initstate) & MASK_64;
    this.nextUint32();
  }

  nextUint32(): number {
    const oldstate = this.#state;
    this.#state = (oldstate * PCG32_MULTIPLIER + this.#inc) & MASK_64;
    const xorshifted = Number((((oldstate >> 18n) ^ oldstate) >> 27n) & MASK_32);
    const rot = Number(oldstate >> 59n) & 31;
    return ((xorshifted >>> rot) | (xorshifted << ((-rot) & 31))) >>> 0;
  }

  bounded(n: number): number {
    if (!Number.isInteger(n) || n < 1 || n > 0x1_0000_0000) {
      throw new RangeError(`bounded(n) requires an integer where 1 <= n <= 2^32; received ${n}`);
    }

    const divisor = BigInt(n);
    const threshold = Number((TWO_32 - divisor) % divisor);
    for (;;) {
      const r = this.nextUint32();
      if (r >= threshold) {
        return r % n;
      }
    }
  }
}

export function firstUint32Values(seed: string, count: number): number[] {
  if (!Number.isInteger(count) || count < 0) {
    throw new RangeError(`count must be a non-negative integer; received ${count}`);
  }
  const rng = Pcg32.fromSeedString(seed);
  return Array.from({ length: count }, () => rng.nextUint32());
}

export function pcg32DemoValues(): number[] {
  const rng = new Pcg32(42n, 54n);
  return Array.from({ length: 6 }, () => rng.nextUint32());
}

export function shuffled<T>(values: readonly T[], rng: Pcg32): T[] {
  const output = [...values];
  for (let i = output.length - 1; i >= 1; i -= 1) {
    const j = rng.bounded(i + 1);
    [output[i], output[j]] = [output[j], output[i]];
  }
  return output;
}
