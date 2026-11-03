import Accessibility
import Foundation

struct TVAboutCardText {
    let title: AttributedString
    let paragraphs: [AttributedString]

    init(title: String, paragraphs: [String], interfaceLanguage: String, bodyLanguage: String? = nil) {
        var attributedTitle = AttributedString(title)
        attributedTitle.languageIdentifier = interfaceLanguage
        self.title = attributedTitle
        self.paragraphs = paragraphs.map { paragraph in
            var text = AttributedString(paragraph)
            text.languageIdentifier = bodyLanguage ?? interfaceLanguage
            return text
        }
    }

    var accessibilityLabel: AttributedString {
        // Heading and language metadata belong to runs, not the whole focusable card.
        var label = title
        label.accessibilityHeadingLevel = .h2
        for paragraph in paragraphs {
            label += AttributedString("\n\n")
            label += paragraph
        }
        return label
    }
}
