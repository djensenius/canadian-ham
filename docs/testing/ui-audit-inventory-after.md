# UI accessibility audit inventory after task-31 consolidation

Generated after task-31 UI-suite consolidation. Each row is one `performAccessibilityAudit` call path present in the consolidated UI suites. `lowerHalf` is `true` only for audits that intentionally scroll lower content/details into view before auditing.

| platform | testName | screenState | appearance | lowerHalf |
| --- | --- | --- | --- | --- |
| iOS | testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice | French home | light | false |
| iOS | testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice | French practice question | light | false |
| iOS | testAccessibilityAuditMorseBeaconOutputLightAndDark | Morse visual beacon during playback | light | false |
| iOS | testAccessibilityAuditMorseBeaconOutputLightAndDark | Morse visual beacon after playback | light | false |
| iOS | testAccessibilityAuditMorseBeaconOutputLightAndDark | Morse visual beacon during playback | dark | false |
| iOS | testAccessibilityAuditMorseBeaconOutputLightAndDark | Morse visual beacon after playback | dark | false |
| iOS | testAccessibilityAuditMorseTapeOutputLightAndDark | Morse visual tape during playback | light | false |
| iOS | testAccessibilityAuditMorseTapeOutputLightAndDark | Morse visual tape after playback | light | false |
| iOS | testAccessibilityAuditMorseTapeOutputLightAndDark | Morse visual tape during playback | dark | false |
| iOS | testAccessibilityAuditMorseTapeOutputLightAndDark | Morse visual tape after playback | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse home top | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse home lower content | light | true |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse course home top | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse course home lower units | light | true |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse course unit | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse lesson session | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse lesson summary | light | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse home top | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse home lower content | dark | true |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse course home top | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse course home lower units | dark | true |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse course unit | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse lesson session | dark | false |
| iOS | testAccessibilityAuditMorseCourseLessonAndSummaryLightAndDark | Morse lesson summary | dark | false |
| iOS | testMorseSendingMainScreenLight | Morse sending main screen | light | false |
| iOS | testMorseSendingMainScreenLight | Morse sending main screen lower half | light | true |
| iOS | testMorseSendingMainScreenDark | Morse sending main screen | dark | false |
| iOS | testMorseSendingMainScreenDark | Morse sending main screen lower half | dark | true |
| iOS | testMorseSendingResultsLight | Morse sending results | light | false |
| iOS | testMorseSendingResultsDark | Morse sending results | dark | false |
| iOS | testMorseExamGradedDiffLight | Morse exam graded diff result iteration 1 | light | false |
| iOS | testMorseExamGradedDiffLight | Morse exam graded diff result iteration 2 | light | false |
| iOS | testMorseExamGradedDiffLight | Morse exam graded diff result iteration 3 | light | false |
| iOS | testMorseExamGradedDiffDark | Morse exam graded diff result iteration 1 | dark | false |
| iOS | testMorseExamGradedDiffDark | Morse exam graded diff result iteration 2 | dark | false |
| iOS | testMorseExamGradedDiffDark | Morse exam graded diff result iteration 3 | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Compact root list | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Home | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Practice hub | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Mock exam start | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Learn module list | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Settings | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Morse | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | About | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Store recovery | light | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Compact root list | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Home | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Practice hub | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Mock exam start | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Learn module list | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Settings | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Morse | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | About | dark | false |
| iOS | testAccessibilityAuditCoreScreensLightAndDark | Store recovery | dark | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Unanswered practice | light | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Incorrect answered practice | light | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Correct answered practice | light | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Practice review | light | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Practice review feedback | light | true |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Unanswered practice | dark | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Incorrect answered practice | dark | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Correct answered practice | dark | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Practice review | dark | false |
| iOS | testAccessibilityAuditPracticeSessionLightAndDark | Practice review feedback | dark | true |
| iOS | testAccessibilityAuditLearnFlowLightAndDark | Learn module list | light | false |
| iOS | testAccessibilityAuditLearnFlowLightAndDark | Lesson reader top | light | false |
| iOS | testAccessibilityAuditLearnFlowLightAndDark | Lesson quiz answered | light | false |
| iOS | testAccessibilityAuditLearnFlowLightAndDark | Learn module list | dark | false |
| iOS | testAccessibilityAuditLearnFlowLightAndDark | Lesson reader top | dark | false |
| iOS | testAccessibilityAuditLearnFlowLightAndDark | Lesson quiz answered | dark | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam question timer | light | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam question navigator timer | light | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam answered flagged question | light | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam question navigator answered flagged | light | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam results | light | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam results details | light | true |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam question timer | dark | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam question navigator timer | dark | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam answered flagged question | dark | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam question navigator answered flagged | dark | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam results | dark | false |
| iOS | testAccessibilityAuditMockExamFlowLightAndDark | Mock exam results details | dark | true |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced course picker | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced lessons coming | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced practice hub | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced practice question | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced mock start | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced mock question | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced mock results | light | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced course picker | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced lessons coming | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced practice hub | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced practice question | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced mock start | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced mock question | dark | false |
| iOS | testAccessibilityAuditAdvancedCourseScreensLightAndDark | Advanced mock results | dark | false |
| iOS | testCourseSwitchConfirmationKeepsMockExamWhenCancelledLightAndDark | Course switch confirmation | light | false |
| iOS | testCourseSwitchConfirmationKeepsMockExamWhenCancelledLightAndDark | Course switch confirmation | dark | false |
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
