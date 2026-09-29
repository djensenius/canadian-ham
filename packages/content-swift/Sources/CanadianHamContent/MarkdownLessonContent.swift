import Foundation

public struct MarkdownTable: Equatable, Sendable {
    public let headers: [String]
    public let rows: [[String]]
    public let sourceLineNumber: Int

    public init(headers: [String], rows: [[String]], sourceLineNumber: Int) {
        self.headers = headers
        self.rows = rows
        self.sourceLineNumber = sourceLineNumber
    }
}

public struct MarkdownIllustrationBrief: Equatable, Sendable {
    public let altText: String
    public let description: String
    public let sourceLineNumber: Int

    public init(altText: String, description: String, sourceLineNumber: Int) {
        self.altText = altText
        self.description = description
        self.sourceLineNumber = sourceLineNumber
    }
}

public struct RenderedLessonMarkdown: Equatable, Sendable {
    public let attributedString: AttributedString
    public let tables: [MarkdownTable]
    public let illustrationBriefs: [MarkdownIllustrationBrief]

    public init(attributedString: AttributedString, tables: [MarkdownTable], illustrationBriefs: [MarkdownIllustrationBrief]) {
        self.attributedString = attributedString
        self.tables = tables
        self.illustrationBriefs = illustrationBriefs
    }
}

public enum LessonMarkdownRenderer {
    public static func render(_ markdown: String) throws -> RenderedLessonMarkdown {
        RenderedLessonMarkdown(
            attributedString: try attributedString(for: markdown),
            tables: extractTables(from: markdown),
            illustrationBriefs: extractIllustrationBriefs(from: markdown)
        )
    }

    public static func attributedString(for markdown: String) throws -> AttributedString {
        let sanitized = escapeRawHTMLTags(in: markdown)
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return try AttributedString(markdown: sanitized, options: options)
    }

    public static func extractTables(from markdown: String) -> [MarkdownTable] {
        let lines = markdown.components(separatedBy: "\n")
        var tables: [MarkdownTable] = []
        var index = 0
        while index + 1 < lines.count {
            let headerLine = lines[index]
            let delimiterLine = lines[index + 1]
            let headers = parseTableRow(headerLine)
            if headers.count >= 2, isTableDelimiter(delimiterLine, expectedColumnCount: headers.count) {
                var rows: [[String]] = []
                var rowIndex = index + 2
                while rowIndex < lines.count, let row = parseTableDataRow(lines[rowIndex], expectedColumnCount: headers.count) {
                    rows.append(row)
                    rowIndex += 1
                }
                tables.append(MarkdownTable(headers: headers, rows: rows, sourceLineNumber: index + 1))
                index = max(rowIndex, index + 1)
            } else {
                index += 1
            }
        }
        return tables
    }

    public static func extractIllustrationBriefs(from markdown: String) -> [MarkdownIllustrationBrief] {
        let lines = markdown.components(separatedBy: "\n")
        var briefs: [MarkdownIllustrationBrief] = []
        var index = 0
        while index < lines.count {
            guard let headingLevel = illustrationBriefHeadingLevel(lines[index]) else {
                index += 1
                continue
            }
            let sourceLineNumber = index + 1
            var altText: String?
            var descriptionLines: [String] = []
            index += 1
            while index < lines.count {
                let line = lines[index]
                if let nextLevel = markdownHeadingLevel(line), nextLevel <= headingLevel {
                    break
                }
                if line.hasPrefix("Alt text:") {
                    altText = String(line.dropFirst("Alt text:".count)).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("Description:") {
                    let firstDescription = String(line.dropFirst("Description:".count)).trimmingCharacters(in: .whitespaces)
                    if !firstDescription.isEmpty {
                        descriptionLines.append(firstDescription)
                    }
                    var continuationIndex = index + 1
                    while continuationIndex < lines.count {
                        let continuation = lines[continuationIndex]
                        if markdownHeadingLevel(continuation) != nil || continuation.hasPrefix("Alt text:") || continuation.hasPrefix("Description:") {
                            break
                        }
                        if !continuation.trimmingCharacters(in: .whitespaces).isEmpty {
                            descriptionLines.append(continuation.trimmingCharacters(in: .whitespaces))
                        }
                        continuationIndex += 1
                    }
                }
                index += 1
            }
            if let altText, !altText.isEmpty, !descriptionLines.isEmpty {
                briefs.append(MarkdownIllustrationBrief(
                    altText: altText,
                    description: descriptionLines.joined(separator: "\n"),
                    sourceLineNumber: sourceLineNumber
                ))
            }
        }
        return briefs
    }

    private static func parseTableDataRow(_ line: String, expectedColumnCount: Int) -> [String]? {
        let row = parseTableRow(line)
        return row.count == expectedColumnCount ? row : nil
    }

    private static func parseTableRow(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|"), trimmed.hasSuffix("|") else {
            return []
        }
        let inner = trimmed.dropFirst().dropLast()
        return inner.split(separator: "|", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
    }

    private static func isTableDelimiter(_ line: String, expectedColumnCount: Int) -> Bool {
        let cells = parseTableRow(line)
        guard cells.count == expectedColumnCount else {
            return false
        }
        return cells.allSatisfy { cell in
            var value = cell.trimmingCharacters(in: .whitespaces)
            if value.hasPrefix(":") {
                value.removeFirst()
            }
            if value.hasSuffix(":") {
                value.removeLast()
            }
            return value.count >= 3 && value.allSatisfy { $0 == "-" }
        }
    }

    private static func markdownHeadingLevel(_ line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var count = 0
        for character in trimmed {
            if character == "#" {
                count += 1
            } else {
                break
            }
        }
        guard (1...6).contains(count), trimmed.dropFirst(count).hasPrefix(" ") else {
            return nil
        }
        return count
    }

    private static func illustrationBriefHeadingLevel(_ line: String) -> Int? {
        guard let level = markdownHeadingLevel(line) else {
            return nil
        }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let title = trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces)
        return title.caseInsensitiveCompare("Illustration brief") == .orderedSame ? level : nil
    }

    private static func escapeRawHTMLTags(in markdown: String) -> String {
        var result = ""
        var index = markdown.startIndex
        while index < markdown.endIndex {
            if markdown[index] == "<", let close = markdown[index...].firstIndex(of: ">") {
                let tag = String(markdown[markdown.index(after: index)..<close])
                if isLikelyRawHTMLTag(tag) {
                    result += "&lt;" + tag + "&gt;"
                    index = markdown.index(after: close)
                    continue
                }
            }
            result.append(markdown[index])
            index = markdown.index(after: index)
        }
        return result
    }

    private static func isLikelyRawHTMLTag(_ tag: String) -> Bool {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutSlash = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        guard let first = withoutSlash.unicodeScalars.first, CharacterSet.letters.contains(first) else {
            return false
        }
        return !withoutSlash.contains("\n")
    }
}
