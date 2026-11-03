import Foundation

#if canImport(Darwin)
// AttributedString Markdown parsing is only available in Apple Foundation.

public enum LessonHeadingAnchors {
    public static func slug(for headingText: String) -> String {
        let stripped = stripInlineMarkdown(headingText)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .lowercased()
        let allowed = stripped.unicodeScalars.filter { scalar in
            isJavaScriptLetterOrNumber(scalar)
                || CharacterSet.whitespacesAndNewlines.contains(scalar)
                || scalar == UnicodeScalar("-")
        }
        return String(String.UnicodeScalarView(allowed))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .map { character in character.isWhitespace ? "-" : String(character) }
            .joined()
    }

    public static func anchors(for markdown: String, title: String? = nil) throws -> [String] {
        try anchorEntries(for: markdown, title: title).compactMap { $0 }
    }

    public static func anchorEntries(for markdown: String, title: String? = nil) throws -> [String?] {
        let rendered = try LessonMarkdownRenderer.render(markdown)
        return anchorEntries(for: rendered, title: title)
    }

    public static func anchorEntries(for rendered: RenderedLessonMarkdown, title: String? = nil) -> [String?] {
        var seen: [String: Int] = [:]
        var anchors: [String?] = []

        for block in rendered.blocks {
            guard case let .heading(level, text) = block else { continue }
            let plainText = String(text.characters)
            if level == 1, let title, plainText == title {
                continue
            }
            let baseSlug = slug(for: plainText)
            guard !baseSlug.isEmpty else {
                anchors.append(nil)
                continue
            }
            let previousCount = seen[baseSlug] ?? 0
            seen[baseSlug] = previousCount + 1
            anchors.append(previousCount == 0 ? baseSlug : "\(baseSlug)-\(previousCount)")
        }

        return anchors
    }

    private static func isJavaScriptLetterOrNumber(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
             .decimalNumber, .letterNumber, .otherNumber:
            true
        default:
            false
        }
    }

    private static func stripInlineMarkdown(_ value: String) -> String {
        var result = value
        result = replacing(result, pattern: #"\[([^\]]+)\]\(([^)]+)\)"#, template: "$1")
        result = replacing(result, pattern: #"`([^`]+)`"#, template: "$1")
        result = replacing(result, pattern: #"\*\*([^*]+)\*\*"#, template: "$1")
        result = replacing(result, pattern: #"__([^_]+)__"#, template: "$1")
        result = replacing(result, pattern: #"\*([^\s*](?:[^*]*[^\s*])?)\*"#, template: "$1")
        result = replacing(result, pattern: #"(^|[^\w])_([^\s_](?:[^\s_]*[^\s_])?)_(?=$|[^\w])"#, template: "$1$2")
        result = replacing(result, pattern: #"\\([\\`*_\[\]{}()#+\-.!|])"#, template: "$1")
        return result
    }

    private static func replacing(_ value: String, pattern: String, template: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return value }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return expression.stringByReplacingMatches(in: value, range: range, withTemplate: template)
    }
}
#endif
