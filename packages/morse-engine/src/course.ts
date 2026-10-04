export type MorseLessonState = "locked" | "current" | "completed";

export interface MorseCourseUnit {
  readonly id: string;
  readonly unitNumber: number;
  readonly title: string;
  readonly lessonIds: readonly string[];
}

export interface MorseCourseLesson {
  readonly id: string;
  readonly unitId: string;
  readonly lessonNumber: number;
  readonly title: string;
  readonly newCharacters: readonly string[];
  readonly learnedCharacters: readonly string[];
}

export interface MorseCourse {
  readonly schemaVersion: 1;
  readonly kind: "morse-course";
  readonly courseId: string;
  readonly unlockAccuracy: number;
  readonly unitSize: number;
  readonly characterOrder: readonly string[];
  readonly units: readonly MorseCourseUnit[];
  readonly lessons: readonly MorseCourseLesson[];
}

export interface MorseLessonProgressRecord {
  readonly lessonId: string;
  readonly attempts: number;
  readonly bestAccuracy: number;
  readonly lastAccuracy: number;
  readonly lastAttemptedAt: string;
  readonly completedAt?: string;
}

export interface MorseCharacterStatRecord {
  readonly character: string;
  readonly attempts: number;
  readonly correctAttempts: number;
  readonly recentResults: readonly boolean[];
  readonly lastPracticedAt: string;
}

export interface MorseDailyActivityRecord {
  readonly date: string;
  readonly lessonsCompleted: number;
}

export interface MorseCourseProgressExport {
  readonly courseId: string;
  readonly lessonProgress: readonly MorseLessonProgressRecord[];
  readonly characterStats: readonly MorseCharacterStatRecord[];
  readonly dailyActivity: readonly MorseDailyActivityRecord[];
}

export type MorseCourseExercise =
  | { readonly kind: "meet"; readonly character: string }
  | { readonly kind: "choose"; readonly character: string; readonly options: readonly string[] }
  | { readonly kind: "type-character"; readonly character: string }
  | { readonly kind: "type-group"; readonly text: string };

export interface BuildMorseLessonExercisesInput {
  readonly lesson: MorseCourseLesson;
  readonly progress?: MorseCourseProgressExport;
  readonly seed: string;
  readonly scoredCount?: number;
}

const expectedOrder = Object.freeze("K M R S U A P T L O W I . N J E F 0 Y , V G 5 / Q 9 Z H 3 8 B ? 4 2 7 C 1 D 6 X -".split(" "));
const expectedCharacters = new Set(expectedOrder);
const confusableCharacters = new Map<string, readonly string[]>([
  ["K", ["R", "M", "A"]],
  ["M", ["O", "T", "K"]],
  ["R", ["K", "A", "S"]],
  ["S", ["U", "R", "I"]],
  ["U", ["S", "A", "V"]],
  ["A", ["R", "U", "W"]],
  ["P", ["T", "L", "J"]],
  ["T", ["M", "O", "P"]],
  ["L", ["P", "F", "R"]],
  ["O", ["M", "T", "0"]],
]);

export function parseMorseCourseFixture(value: unknown): MorseCourse {
  if (!isRecord(value)) throw new Error("Morse course fixture must be an object.");
  if (value.schemaVersion !== 1 || value.kind !== "morse-course") throw new Error("Unsupported Morse course fixture.");
  if (typeof value.courseId !== "string" || value.courseId.length === 0) throw new Error("Morse course courseId is required.");
  if (value.unlockAccuracy !== 0.9) throw new Error("Morse course unlockAccuracy must be 0.9.");
  if (value.unitSize !== 5) throw new Error("Morse course unitSize must be 5.");
  if (!arrayEquals(value.characterOrder, expectedOrder)) throw new Error("Morse course character order must match the approved G4FON/ISED order.");
  if (!Array.isArray(value.units) || value.units.length !== 8) throw new Error("Morse course must contain 8 units.");
  if (!Array.isArray(value.lessons) || value.lessons.length !== 40) throw new Error("Morse course must contain 40 lessons.");
  const units = value.units.map(parseUnit);
  const lessons = value.lessons.map(parseLesson);
  const lessonIds = new Set<string>();
  lessons.forEach((lesson, index) => {
    if (lesson.lessonNumber !== index + 1) throw new Error(`Morse lesson ${lesson.id} is out of order.`);
    if (!lessonIds.add(lesson.id)) throw new Error(`Duplicate Morse lesson id ${lesson.id}.`);
    const expectedLearned = expectedOrder.slice(0, index + 2);
    const expectedNew = index === 0 ? expectedOrder.slice(0, 2) : [expectedOrder[index + 1]!];
    if (!arrayEquals(lesson.learnedCharacters, expectedLearned) || !arrayEquals(lesson.newCharacters, expectedNew)) {
      throw new Error(`Morse lesson ${lesson.id} does not match the approved Koch progression.`);
    }
    if (lesson.unitId !== `unit-${String(Math.floor(index / 5) + 1).padStart(2, "0")}`) throw new Error(`Morse lesson ${lesson.id} has the wrong unit.`);
  });
  units.forEach((unit, index) => {
    const expectedUnitId = `unit-${String(index + 1).padStart(2, "0")}`;
    if (unit.unitNumber !== index + 1 || unit.id !== expectedUnitId) throw new Error(`Morse unit ${unit.id} is out of order.`);
    const expectedLessonIds = lessons.slice(index * 5, index * 5 + 5).map((lesson) => lesson.id);
    if (!arrayEquals(unit.lessonIds, expectedLessonIds)) throw new Error(`Morse unit ${unit.id} lesson IDs are out of order.`);
  });
  return Object.freeze({
    schemaVersion: 1,
    kind: "morse-course",
    courseId: value.courseId,
    unlockAccuracy: 0.9,
    unitSize: 5,
    characterOrder: expectedOrder,
    units: Object.freeze(units),
    lessons: Object.freeze(lessons),
  });
}

export function emptyMorseCourseProgress(courseId: string): MorseCourseProgressExport {
  return { courseId, lessonProgress: [], characterStats: [], dailyActivity: [] };
}

export function lessonState(course: MorseCourse, progress: MorseCourseProgressExport, lessonId: string): MorseLessonState {
  const index = course.lessons.findIndex((lesson) => lesson.id === lessonId);
  if (index < 0) throw new Error(`Unknown Morse lesson ${lessonId}.`);
  if (isLessonCompleted(course, progress, lessonId)) return "completed";
  if (index === 0 || isLessonCompleted(course, progress, course.lessons[index - 1]!.id)) return "current";
  return "locked";
}

export function isLessonCompleted(course: MorseCourse, progress: MorseCourseProgressExport, lessonId: string): boolean {
  const record = progress.lessonProgress.find((entry) => entry.lessonId === lessonId);
  return record !== undefined && record.bestAccuracy >= course.unlockAccuracy;
}

export function unlockedLessonCount(course: MorseCourse, progress: MorseCourseProgressExport): number {
  return course.lessons.filter((lesson) => lessonState(course, progress, lesson.id) !== "locked").length;
}

export function learnedCharactersForProgress(course: MorseCourse, progress: MorseCourseProgressExport): readonly string[] {
  const unlocked = Math.max(1, unlockedLessonCount(course, progress));
  return course.lessons[Math.min(unlocked - 1, course.lessons.length - 1)]!.learnedCharacters;
}

export function buildMorseLessonExercises(input: BuildMorseLessonExercisesInput): readonly MorseCourseExercise[] {
  const scoredCount = Math.max(15, Math.min(25, input.scoredCount ?? 20));
  const random = seededRandom(`${input.seed}:${input.lesson.id}`);
  const learned = input.lesson.learnedCharacters.filter((character) => expectedCharacters.has(character));
  const newCharacters = input.lesson.newCharacters.filter((character) => expectedCharacters.has(character));
  const weak = input.progress === undefined || input.lesson.lessonNumber === 1 ? [] : selectWeakestCharacters(input.progress.characterStats, learned, 6);
  const weighted = weightedPracticeCharacters(learned, newCharacters, weak);
  const exercises: MorseCourseExercise[] = newCharacters.map((character) => ({ kind: "meet", character }));

  for (let index = 0; index < scoredCount; index += 1) {
    const target = index < newCharacters.length ? newCharacters[index]! : drawWeighted(weighted, random);
    if (index % 5 === 4) {
      exercises.push({ kind: "type-group", text: buildKochGroup(weighted, random) });
    } else if (index % 2 === 0) {
      exercises.push({ kind: "choose", character: target, options: chooseOptions(target, learned, weak, random) });
    } else {
      exercises.push({ kind: "type-character", character: target });
    }
  }
  return Object.freeze(exercises);
}

export function selectWeakestCharacters(
  stats: readonly MorseCharacterStatRecord[],
  learnedCharacters: readonly string[],
  limit = 5,
): readonly string[] {
  const byCharacter = new Map(stats.map((stat) => [stat.character, stat]));
  return learnedCharacters
    .filter((character) => expectedCharacters.has(character))
    .map((character, order) => ({ character, order, score: recentAccuracy(byCharacter.get(character)) }))
    .toSorted((left, right) => left.score - right.score || left.order - right.order)
    .slice(0, Math.max(0, limit))
    .map((entry) => entry.character);
}

export function recordMorseLessonAttempt(input: {
  readonly course: MorseCourse;
  readonly progress: MorseCourseProgressExport;
  readonly lessonId: string;
  readonly correct: number;
  readonly total: number;
  readonly characterResults: readonly { readonly character: string; readonly correct: boolean }[];
  readonly attemptedAt: string;
  readonly activityDate?: string;
}): MorseCourseProgressExport {
  if (input.total <= 0 || input.correct < 0 || input.correct > input.total) throw new Error("Invalid Morse lesson score.");
  const accuracy = input.correct / input.total;
  const existing = input.progress.lessonProgress.find((entry) => entry.lessonId === input.lessonId);
  const completedAt = accuracy >= input.course.unlockAccuracy ? (existing?.completedAt ?? input.attemptedAt) : existing?.completedAt;
  const lessonRecord: MorseLessonProgressRecord = {
    lessonId: input.lessonId,
    attempts: (existing?.attempts ?? 0) + 1,
    bestAccuracy: Math.max(existing?.bestAccuracy ?? 0, accuracy),
    lastAccuracy: accuracy,
    lastAttemptedAt: input.attemptedAt,
    ...(completedAt === undefined ? {} : { completedAt }),
  };
  const lessonProgress = [
    ...input.progress.lessonProgress.filter((entry) => entry.lessonId !== input.lessonId),
    lessonRecord,
  ].toSorted((a, b) => a.lessonId.localeCompare(b.lessonId));
  const characterStats = updatedCharacterStats(input.progress.characterStats, input.characterResults, input.attemptedAt);
  const dailyActivity = accuracy >= input.course.unlockAccuracy
    ? updatedDailyActivity(input.progress.dailyActivity, input.activityDate ?? isoDate(input.attemptedAt))
    : input.progress.dailyActivity;
  return { courseId: input.course.courseId, lessonProgress, characterStats, dailyActivity };
}

export function recordMorseCharacterResults(progress: MorseCourseProgressExport, results: readonly { readonly character: string; readonly correct: boolean }[], attemptedAt: string): MorseCourseProgressExport {
  return { ...progress, characterStats: updatedCharacterStats(progress.characterStats, results, attemptedAt) };
}

export function dailyStreak(activity: readonly MorseDailyActivityRecord[], todayIso: string): number {
  const completedDates = new Set(activity.filter((entry) => entry.lessonsCompleted > 0).map((entry) => entry.date));
  const today = isoDate(todayIso);
  let cursor = completedDates.has(today) ? today : shiftIsoDate(today, -1);
  let streak = 0;
  while (completedDates.has(cursor)) {
    streak += 1;
    cursor = shiftIsoDate(cursor, -1);
  }
  return streak;
}

function chooseOptions(target: string, learned: readonly string[], weak: readonly string[], random: () => number): readonly string[] {
  const learnedSet = new Set(learned);
  const distractors = unique([
    ...weak,
    ...(confusableCharacters.get(target) ?? []),
    ...[...learned.slice(-8)].reverse(),
    ...learned,
  ]).filter((character) => character !== target && expectedCharacters.has(character) && learnedSet.has(character));
  return shuffle([target, ...distractors.slice(0, 3)], random);
}

function weightedPracticeCharacters(learned: readonly string[], newCharacters: readonly string[], weak: readonly string[]): readonly string[] {
  const weighted: string[] = [];
  const pushWeighted = (characters: readonly string[], weight: number) => {
    for (const character of characters) {
      if (!expectedCharacters.has(character)) continue;
      for (let index = 0; index < weight; index += 1) weighted.push(character);
    }
  };
  pushWeighted(learned, 1);
  pushWeighted(learned.slice(-6), 1);
  pushWeighted(weak, 2);
  pushWeighted(newCharacters, 4);
  return weighted.length === 0 ? ["K"] : Object.freeze(weighted);
}

function buildKochGroup(weightedCharacters: readonly string[], random: () => number): string {
  return Array.from({ length: 5 }, () => drawWeighted(weightedCharacters, random)).join("");
}

function drawWeighted(characters: readonly string[], random: () => number): string {
  return characters[Math.floor(random() * characters.length)] ?? characters[0] ?? "K";
}

function unique(values: readonly string[]): readonly string[] {
  return [...new Set(values)];
}

function shuffle<T>(values: readonly T[], random: () => number): readonly T[] {
  const shuffled = [...values];
  for (let index = shuffled.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(random() * (index + 1));
    [shuffled[index], shuffled[swapIndex]] = [shuffled[swapIndex]!, shuffled[index]!];
  }
  return Object.freeze(shuffled);
}

function seededRandom(seed: string): () => number {
  let state = 2166136261;
  for (let index = 0; index < seed.length; index += 1) {
    state ^= seed.charCodeAt(index);
    state = Math.imul(state, 16777619);
  }
  return () => {
    state += 0x6D2B79F5;
    let value = state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
}

function updatedCharacterStats(stats: readonly MorseCharacterStatRecord[], results: readonly { readonly character: string; readonly correct: boolean }[], attemptedAt: string): readonly MorseCharacterStatRecord[] {
  const byCharacter = new Map(stats.map((stat) => [stat.character, stat]));
  for (const result of results) {
    if (!expectedCharacters.has(result.character)) continue;
    const current = byCharacter.get(result.character);
    byCharacter.set(result.character, {
      character: result.character,
      attempts: (current?.attempts ?? 0) + 1,
      correctAttempts: (current?.correctAttempts ?? 0) + (result.correct ? 1 : 0),
      recentResults: [...(current?.recentResults ?? []), result.correct].slice(-20),
      lastPracticedAt: attemptedAt,
    });
  }
  return [...byCharacter.values()].toSorted((a, b) => expectedOrder.indexOf(a.character) - expectedOrder.indexOf(b.character));
}

function updatedDailyActivity(activity: readonly MorseDailyActivityRecord[], date: string): readonly MorseDailyActivityRecord[] {
  const current = activity.find((entry) => entry.date === date);
  return [
    ...activity.filter((entry) => entry.date !== date),
    { date, lessonsCompleted: (current?.lessonsCompleted ?? 0) + 1 },
  ].toSorted((a, b) => a.date.localeCompare(b.date));
}

function recentAccuracy(stat: MorseCharacterStatRecord | undefined): number {
  if (stat === undefined || stat.recentResults.length === 0) return -1;
  return stat.recentResults.filter(Boolean).length / stat.recentResults.length;
}

function parseUnit(value: unknown): MorseCourseUnit {
  if (!isRecord(value) || typeof value.id !== "string" || typeof value.unitNumber !== "number" || typeof value.title !== "string" || !Array.isArray(value.lessonIds) || !value.lessonIds.every((id) => typeof id === "string")) throw new Error("Invalid Morse course unit.");
  return Object.freeze({ id: value.id, unitNumber: value.unitNumber, title: value.title, lessonIds: Object.freeze([...value.lessonIds]) });
}

function parseLesson(value: unknown): MorseCourseLesson {
  if (!isRecord(value) || typeof value.id !== "string" || typeof value.unitId !== "string" || typeof value.lessonNumber !== "number" || typeof value.title !== "string" || !isCharacterArray(value.newCharacters) || !isCharacterArray(value.learnedCharacters)) throw new Error("Invalid Morse course lesson.");
  return Object.freeze({ id: value.id, unitId: value.unitId, lessonNumber: value.lessonNumber, title: value.title, newCharacters: Object.freeze([...value.newCharacters]), learnedCharacters: Object.freeze([...value.learnedCharacters]) });
}

function isCharacterArray(value: unknown): value is string[] {
  return Array.isArray(value) && value.every((entry) => typeof entry === "string" && expectedCharacters.has(entry));
}

function arrayEquals(left: unknown, right: readonly string[]): boolean {
  return Array.isArray(left) && left.length === right.length && left.every((entry, index) => entry === right[index]);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isoDate(value: string): string {
  return value.slice(0, 10);
}

function shiftIsoDate(value: string, days: number): string {
  const date = new Date(`${value}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}
