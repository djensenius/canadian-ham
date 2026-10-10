# task-38.1 figure evidence

The `web/` images are generated from `content/figures/*.svg`; the `ios/` images are generated from the synced Apple asset-catalog SVGs. Light uses raised paper `#FFF8EA` with ink `#1F1A14`; dark uses raised paper `#2A241D` with ink `#F3E8D2`, matching design-token contrast pairs (text and strokes are 16.34:1 light and 12.63:1 dark on raised paper).

The UI-test result bundles for the iOS light/dark figure audits also attach screenshots named `task38-1-ios-<theme>-<figure-id>` when those tests are run.
