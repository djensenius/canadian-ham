const CANONICAL_UTC_TIMESTAMP_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/u;

export function requireCanonicalUtcTimestamp(value: string, fieldName: string): void {
  if (!CANONICAL_UTC_TIMESTAMP_PATTERN.test(value) || Number.isNaN(Date.parse(value)) || new Date(Date.parse(value)).toISOString() !== value) {
    throw new Error(`${fieldName} must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS.sssZ`);
  }
}

export function parseCanonicalUtcTimestamp(value: string, fieldName: string): number {
  requireCanonicalUtcTimestamp(value, fieldName);
  return Date.parse(value);
}
