# task-38.1 figure evidence

The `web/` images are generated from `content/figures/*.svg`; the `ios/` images are generated from the synced Apple asset-catalog SVGs. The real app screenshots live in `app/`. Figure art sits on paper-inset (`#EFE3CB` light and `#181410` dark) with ink (`#1F1A14` light and `#F3E8D2` dark), matching the app surface used behind the SVGs and giving approximately 13.6:1 in light and 15.1:1 in dark.

The `qlmanage-ios/` PNGs are Quick Look thumbnail renders produced with `qlmanage -t -s 800` from the Apple-asset evidence SVGs for visual review at a small fixed width. The iOS UI-test result bundles for the light/dark figure audits also attach screenshots named `task38-1-ios-<theme>-<figure-id>` when those tests are run.
