# Pre-V2 SwiftData Progress.store fixture

`Progress.store` was generated for task-13.5 from the pre-V2 SwiftData model shape on commit `3a54632` (top-level `QuestionProgressEntity`, `ExamAttemptEntity`, `PreferencesEntity`, `CanadianHamProgressSchemaV1` with `Schema([QuestionProgressEntity.self, ExamAttemptEntity.self, PreferencesEntity.self])`).

Generation command used in this worktree:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift /tmp/generate-pre-v2-progress-fixture.swift "$PWD/fixtures/progress/pre-v2/Progress.store"
sqlite3 fixtures/progress/pre-v2/Progress.store 'PRAGMA wal_checkpoint(TRUNCATE);'
rm -f fixtures/progress/pre-v2/Progress.store-shm fixtures/progress/pre-v2/Progress.store-wal
```

The generator script was intentionally not committed; it copied the pre-V2 model declarations from `3a54632` and inserted one question-progress row, one mock-exam attempt row, and one preferences row with archived lesson progress. The committed fixture is used by migration tests so current V3 code proves it can open real pre-V2 stores with data intact.
