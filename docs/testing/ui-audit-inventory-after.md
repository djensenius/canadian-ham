# UI accessibility audit inventory after the task-31 UI-suite changes

Generated after the task-31 UI-suite changes (scroll-settling and teardown; launch consolidation was backed out and is task-33). Each row is one `performAccessibilityAudit` call path present in the final UI suites. `lowerHalf` is `true` only for audits that intentionally scroll lower content/details into view before auditing.

Task-44.3 exam-tool exception: at the compact iPhone medium detent only, `CanadianHamExamToolsUITests` may ignore and log XCTest's nil-element Dynamic Type text-clipping audit issue (`textClipped`, raw audit type `131072`, “Text of this SwiftUI.AccessibilityNode may be clipped at larger Dynamic Type sizes”) while the calculator sheet is open. The nil-element `textClipped` exception is used only inside the medium-detent exam-tool audit helper, capped at five ignored issues per audit, and paired with a compensating pre-audit check that visible tool-panel static text and buttons have non-empty frames and are hittable or within the panel's visible bounds. Every other medium-detent audit issue fails, including any `textClipped` issue with an attached element. The large-detent and iPad inspector calculator audits run the full default audit with no handler. The Apple reference-sheet tool is hidden for task-44.3 and follows in TASK-44.4.

| platform | testName | screenState | appearance | lowerHalf |
| --- | --- | --- | --- | --- |
| iOS | testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice | French home | light | false |
| iOS | testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice | French practice question | light | false |
| iOS | testAccessibilityAuditMorseBeaconOutputLight | Morse visual beacon during playback | light | false |
| iOS | testAccessibilityAuditMorseBeaconOutputLight | Morse visual beacon after playback | light | false |
| iOS | testAccessibilityAuditMorseBeaconOutputDark | Morse visual beacon during playback | dark | false |
| iOS | testAccessibilityAuditMorseBeaconOutputDark | Morse visual beacon after playback | dark | false |
| iOS | testAccessibilityAuditMorseTapeOutputLight | Morse visual tape during playback | light | false |
| iOS | testAccessibilityAuditMorseTapeOutputLight | Morse visual tape after playback | light | false |
| iOS | testAccessibilityAuditMorseTapeOutputDark | Morse visual tape during playback | dark | false |
| iOS | testAccessibilityAuditMorseTapeOutputDark | Morse visual tape after playback | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLight | Morse home top | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLight | Morse home lower content | light | true |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLight | Morse course home top | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLight | Morse course home lower units | light | true |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLight | Morse course unit | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLight | Morse lesson session | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLight | Morse lesson summary | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryDark | Morse home top | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryDark | Morse home lower content | dark | true |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryDark | Morse course home top | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryDark | Morse course home lower units | dark | true |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryDark | Morse course unit | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryDark | Morse lesson session | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryDark | Morse lesson summary | dark | false |
| iOS | testAccessibilityAuditMorseSendingMainScreenLight | Morse sending main screen | light | false |
| iOS | testAccessibilityAuditMorseSendingMainScreenLight | Morse sending main screen lower half | light | true |
| iOS | testAccessibilityAuditMorseSendingMainScreenDark | Morse sending main screen | dark | false |
| iOS | testAccessibilityAuditMorseSendingMainScreenDark | Morse sending main screen lower half | dark | true |
| iOS | testAccessibilityAuditMorseSendingResultsLight | Morse sending results | light | false |
| iOS | testAccessibilityAuditMorseSendingResultsDark | Morse sending results | dark | false |
| iOS | testAccessibilityAuditMorseExamGradedDiffLight | Morse exam graded diff result iteration 1 | light | false |
| iOS | testAccessibilityAuditMorseExamGradedDiffLight | Morse exam graded diff result iteration 2 | light | false |
| iOS | testAccessibilityAuditMorseExamGradedDiffLight | Morse exam graded diff result iteration 3 | light | false |
| iOS | testAccessibilityAuditMorseExamGradedDiffDark | Morse exam graded diff result iteration 1 | dark | false |
| iOS | testAccessibilityAuditMorseExamGradedDiffDark | Morse exam graded diff result iteration 2 | dark | false |
| iOS | testAccessibilityAuditMorseExamGradedDiffDark | Morse exam graded diff result iteration 3 | dark | false |
| iOS | testAccessibilityAuditCoreScreensLight | Compact root list | light | false |
| iOS | testAccessibilityAuditCoreScreensLight | Home | light | false |
| iOS | testAccessibilityAuditCoreScreensLight | Practice hub | light | false |
| iOS | testAccessibilityAuditCoreScreensLight | Mock exam start | light | false |
| iOS | testAccessibilityAuditCoreScreensLight | Learn module list | light | false |
| iOS | testAccessibilityAuditCoreScreensLight | Settings | light | false |
| iOS | testAccessibilityAuditCoreScreensLight | Morse | light | false |
| iOS | testAccessibilityAuditCoreScreensLight | About | light | false |
| iOS | testAccessibilityAuditCoreScreensLight | Store recovery | light | false |
| iOS | testAccessibilityAuditCoreScreensDark | Compact root list | dark | false |
| iOS | testAccessibilityAuditCoreScreensDark | Home | dark | false |
| iOS | testAccessibilityAuditCoreScreensDark | Practice hub | dark | false |
| iOS | testAccessibilityAuditCoreScreensDark | Mock exam start | dark | false |
| iOS | testAccessibilityAuditCoreScreensDark | Learn module list | dark | false |
| iOS | testAccessibilityAuditCoreScreensDark | Settings | dark | false |
| iOS | testAccessibilityAuditCoreScreensDark | Morse | dark | false |
| iOS | testAccessibilityAuditCoreScreensDark | About | dark | false |
| iOS | testAccessibilityAuditCoreScreensDark | Store recovery | dark | false |
| iOS | testAccessibilityAuditPracticeSessionLight | Unanswered practice | light | false |
| iOS | testAccessibilityAuditPracticeSessionLight | Incorrect answered practice | light | false |
| iOS | testAccessibilityAuditPracticeSessionLight | Correct answered practice | light | false |
| iOS | testAccessibilityAuditPracticeSessionLight | Practice review | light | false |
| iOS | testAccessibilityAuditPracticeSessionLight | Practice review feedback | light | true |
| iOS | testAccessibilityAuditPracticeSessionDark | Unanswered practice | dark | false |
| iOS | testAccessibilityAuditPracticeSessionDark | Incorrect answered practice | dark | false |
| iOS | testAccessibilityAuditPracticeSessionDark | Correct answered practice | dark | false |
| iOS | testAccessibilityAuditPracticeSessionDark | Practice review | dark | false |
| iOS | testAccessibilityAuditPracticeSessionDark | Practice review feedback | dark | true |
| iOS | testAccessibilityAuditLearnFlowLight | Learn module list | light | false |
| iOS | testAccessibilityAuditLearnFlowLight | Lesson reader top | light | false |
| iOS | testAccessibilityAuditLearnFlowLight | Lesson quiz answered | light | false |
| iOS | testAccessibilityAuditLearnFlowDark | Learn module list | dark | false |
| iOS | testAccessibilityAuditLearnFlowDark | Lesson reader top | dark | false |
| iOS | testAccessibilityAuditLearnFlowDark | Lesson quiz answered | dark | false |
| iOS | testOhmsLawLessonFiguresAndAccessibilityLight | Ohm's law lesson inline figures, enlarged figures, and expanded figure text equivalent | light | true |
| iOS | testOhmsLawLessonFiguresAndAccessibilityDark | Ohm's law lesson inline figures, enlarged figures, and expanded figure text equivalent | dark | true |
| iOS | testAccessibilityAuditMockExamFlowLight | Mock exam question timer | light | false |
| iOS | testAccessibilityAuditMockExamFlowLight | Mock exam question navigator timer | light | false |
| iOS | testAccessibilityAuditMockExamFlowLight | Mock exam answered flagged question | light | false |
| iOS | testAccessibilityAuditMockExamFlowLight | Mock exam question navigator answered flagged | light | false |
| iOS | testAccessibilityAuditMockExamFlowLight | Mock exam results | light | false |
| iOS | testAccessibilityAuditMockExamFlowLight | Mock exam results details | light | true |
| iOS | testAccessibilityAuditMockExamFlowDark | Mock exam question timer | dark | false |
| iOS | testAccessibilityAuditMockExamFlowDark | Mock exam question navigator timer | dark | false |
| iOS | testAccessibilityAuditMockExamFlowDark | Mock exam answered flagged question | dark | false |
| iOS | testAccessibilityAuditMockExamFlowDark | Mock exam question navigator answered flagged | dark | false |
| iOS | testAccessibilityAuditMockExamFlowDark | Mock exam results | dark | false |
| iOS | testAccessibilityAuditMockExamFlowDark | Mock exam results details | dark | true |
| iOS | testAccessibilityAuditAdvancedCourseScreensLight | Advanced course picker | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLight | Advanced lessons coming | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLight | Advanced practice hub | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLight | Advanced practice question | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLight | Advanced mock start | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLight | Advanced mock question | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLight | Advanced mock results | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensDark | Advanced course picker | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensDark | Advanced lessons coming | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensDark | Advanced practice hub | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensDark | Advanced practice question | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensDark | Advanced mock start | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensDark | Advanced mock question | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensDark | Advanced mock results | dark | false |
| iOS | testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight | Course switch confirmation | light | false |
| iOS | testCourseSwitchConfirmationAuditsDark | Course switch confirmation | dark | false |
| tvOS | testCategoryGridAccessibilityAuditLightAndDark | Categories | light | false |
| tvOS | testCategoryGridAccessibilityAuditLightAndDark | Categories | dark | false |
| tvOS | testPracticeAccessibilityAuditLightAndDark | Practice | light | false |
| tvOS | testPracticeAccessibilityAuditLightAndDark | Answered practice | light | false |
| tvOS | testPracticeAccessibilityAuditLightAndDark | Practice | dark | false |
| tvOS | testPracticeAccessibilityAuditLightAndDark | Answered practice | dark | false |
| tvOS | testAboutAccessibilityAuditLightAndDark | About | light | false |
| tvOS | testAboutAccessibilityAuditLightAndDark | About | dark | false |
| tvOS | testMorseAccessibilityAuditLightAndDark | Morse | light | false |
| tvOS | testMorseAccessibilityAuditLightAndDark | Morse | dark | false |
| visionOS | testCategoryGridAccessibilityAuditLightAndDark | Categories | light | false |
| visionOS | testCategoryGridAccessibilityAuditLightAndDark | Categories | dark | false |
| visionOS | testPracticeAccessibilityAuditLightAndDark | Practice | light | false |
| visionOS | testPracticeAccessibilityAuditLightAndDark | Answered practice | light | false |
| visionOS | testPracticeAccessibilityAuditLightAndDark | Practice | dark | false |
| visionOS | testPracticeAccessibilityAuditLightAndDark | Answered practice | dark | false |
| visionOS | testAboutAccessibilityAuditLightAndDark | About | light | false |
| visionOS | testAboutAccessibilityAuditLightAndDark | About | dark | false |
| visionOS | testMorseAccessibilityAuditLightAndDark | Morse | light | false |
| visionOS | testMorseAccessibilityAuditLightAndDark | Morse | dark | false |

## Approved audit exceptions reflected after task-38.1

- `testOhmsLawLessonFiguresAndAccessibilityLight` and `testOhmsLawLessonFiguresAndAccessibilityDark` use the owner-approved 2026-10-12 false-positive rule only for inline lesson scroll content under an opaque navigation bar: the handler may ignore contrast issues only when the failing element is inside the lesson scroll view and its frame is not fully contained in the visible scroll area below the bar. Navigation-bar elements fail, elements outside the scroll view fail, issues without an element fail, fully visible contrast issues fail, and every non-contrast issue fails. Enlarged figure sheets run the plain audit without this handler.
- Task-42's Morse settings description exception and task-44.3's exam-tool medium-detent clipping exception remain separately approved and are tracked in `AGENTS.md`.
