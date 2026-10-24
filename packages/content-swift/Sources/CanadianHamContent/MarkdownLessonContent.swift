import Foundation

public enum MarkdownTableColumnAlignment: String, Equatable, Sendable {
    case none
    case left
    case center
    case right
}

public struct MarkdownTable: Equatable, Sendable {
    public let headers: [AttributedString]
    public let rows: [[AttributedString]]
    public let alignment: [MarkdownTableColumnAlignment]
    public let sourceLineNumber: Int

    public init(headers: [AttributedString], rows: [[AttributedString]], alignment: [MarkdownTableColumnAlignment], sourceLineNumber: Int) {
        self.headers = headers
        self.rows = rows
        self.alignment = alignment
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

public struct MarkdownFigure: Equatable, Sendable {
    public let id: String
    public let altText: String
    public let textEquivalent: [String]
    public let sourceLineNumber: Int

    public init(id: String, altText: String, textEquivalent: [String] = [], sourceLineNumber: Int) {
        self.id = id
        self.altText = altText
        self.textEquivalent = textEquivalent
        self.sourceLineNumber = sourceLineNumber
    }
}

public enum LessonBlock: Equatable, Sendable {
    case heading(level: Int, AttributedString)
    case paragraph(AttributedString)
    case tryIt(number: Int, prompt: AttributedString, answer: AttributedString)
    case list(ordered: Bool, items: [AttributedString])
    case code(language: String?, text: String)
    case table(MarkdownTable)
    case figure(MarkdownFigure)
    case illustrationBrief(MarkdownIllustrationBrief)
    case blockquote(AttributedString)
}

public struct RenderedLessonMarkdown: Equatable, Sendable {
    public let blocks: [LessonBlock]

    public init(blocks: [LessonBlock]) {
        self.blocks = blocks
    }

    public var tables: [MarkdownTable] {
        blocks.compactMap { block in
            if case let .table(table) = block {
                return table
            }
            return nil
        }
    }

    public var figures: [MarkdownFigure] {
        blocks.compactMap { block in
            if case let .figure(figure) = block {
                return figure
            }
            return nil
        }
    }

    public var illustrationBriefs: [MarkdownIllustrationBrief] {
        blocks.compactMap { block in
            if case let .illustrationBrief(brief) = block {
                return brief
            }
            return nil
        }
    }

    public var attributedString: AttributedString {
        var rendered = AttributedString()
        for block in blocks {
            let addition: AttributedString?
            switch block {
            case let .heading(_, text), let .paragraph(text), let .blockquote(text):
                addition = text
            case let .list(_, items):
                var listText = AttributedString()
                for (index, item) in items.enumerated() {
                    if index > 0 {
                        listText.append(AttributedString("\n"))
                    }
                    listText.append(item)
                }
                addition = listText
            case let .tryIt(_, prompt, _):
                addition = prompt // Hidden answers must not leak into the flattened lesson text.
            case let .code(_, text):
                addition = AttributedString(text)
            case .table, .figure, .illustrationBrief:
                addition = nil
            }
            guard let addition else {
                continue
            }
            if !rendered.characters.isEmpty {
                rendered.append(AttributedString("\n\n"))
            }
            rendered.append(addition)
        }
        return rendered
    }
}

public enum LessonMarkdownRenderer {
    public static func render(_ markdown: String) throws -> RenderedLessonMarkdown {
        RenderedLessonMarkdown(blocks: try parseBlocks(from: markdown))
    }

    public static func attributedString(for markdown: String) throws -> AttributedString {
        try inlineAttributedString(for: markdown)
    }

    public static func extractTables(from markdown: String) -> [MarkdownTable] {
        (try? parseBlocks(from: markdown).compactMap { block in
            if case let .table(table) = block {
                return table
            }
            return nil
        }) ?? []
    }

    public static func extractFigures(from markdown: String) -> [MarkdownFigure] {
        (try? parseBlocks(from: markdown).compactMap { block in
            if case let .figure(figure) = block {
                return figure
            }
            return nil
        }) ?? []
    }

    public static func extractIllustrationBriefs(from markdown: String) -> [MarkdownIllustrationBrief] {
        (try? parseBlocks(from: markdown).compactMap { block in
            if case let .illustrationBrief(brief) = block {
                return brief
            }
            return nil
        }) ?? []
    }

    private static func parseBlocks(from markdown: String) throws -> [LessonBlock] {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: "\n")
        var blocks: [LessonBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }

            if let fence = codeFenceOpening(line) {
                let parsed = parseCodeBlock(lines: lines, startIndex: index, fenceMarker: fence.marker)
                blocks.append(.code(language: fence.language, text: parsed.text))
                index = parsed.nextIndex
                continue
            }

            if let parsed = try parseFigure(lines: lines, startIndex: index) {
                blocks.append(parsed.block)
                index = parsed.nextIndex
                continue
            }

            if let heading = markdownHeading(line) {
                if heading.text.caseInsensitiveCompare("Illustration brief") == .orderedSame {
                    let parsed = parseIllustrationBrief(lines: lines, startIndex: index, headingLevel: heading.level)
                    if let brief = parsed.brief {
                        blocks.append(.illustrationBrief(brief))
                        index = parsed.nextIndex
                        continue
                    }
                }
                blocks.append(.heading(level: heading.level, try inlineAttributedString(for: heading.text)))
                index += 1
                continue
            }

            if let table = try parseTable(lines: lines, startIndex: index) {
                blocks.append(.table(table.model))
                index = table.nextIndex
                continue
            }

            if let item = try parseTryIt(lines: lines, startIndex: index) {
                blocks.append(item.block)
                index = item.nextIndex
                continue
            }

            if let list = try parseList(lines: lines, startIndex: index) {
                blocks.append(.list(ordered: list.ordered, items: list.items))
                index = list.nextIndex
                continue
            }

            if isBlockquoteLine(line) {
                let parsed = try parseBlockquote(lines: lines, startIndex: index)
                blocks.append(.blockquote(parsed.text))
                index = parsed.nextIndex
                continue
            }

            let parsed = try parseParagraph(lines: lines, startIndex: index)
            blocks.append(.paragraph(parsed.text))
            index = parsed.nextIndex
        }

        return blocks
    }

    private static func parseTryIt(lines: [String], startIndex: Int) throws -> (block: LessonBlock, nextIndex: Int)? {
        let line = lines[startIndex]
        guard let range = line.range(of: #"^\d+\. "#, options: .regularExpression),
              let number = Int(line[range].dropLast(2)) else { return nil }
        let prompt = String(line[range.upperBound...])
        var opening = startIndex + 1
        while opening < lines.count, lines[opening].trimmingCharacters(in: .whitespaces).isEmpty {
            opening += 1
        }
        guard opening + 2 < lines.count, lines[opening] == ":::answer",
              !lines[opening + 1].trimmingCharacters(in: .whitespaces).isEmpty,
              lines[opening + 2] == ":::" else { return nil }
        return (
            .tryIt(number: number, prompt: try inlineAttributedString(for: prompt), answer: try inlineAttributedString(for: lines[opening + 1])),
            opening + 3
        )
    }

    private static func inlineAttributedString(for markdown: String) throws -> AttributedString {
        let sanitized = escapeRawHTMLOutsideCodeSpans(in: markdown)
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return try AttributedString(markdown: sanitized, options: options)
    }

    private static func parseCodeBlock(lines: [String], startIndex: Int, fenceMarker: String) -> (text: String, nextIndex: Int) {
        var codeLines: [String] = []
        var index = startIndex + 1
        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces).hasPrefix(fenceMarker) {
                return (codeLines.joined(separator: "\n"), index + 1)
            }
            codeLines.append(line)
            index += 1
        }
        return (codeLines.joined(separator: "\n"), index)
    }

    private static func figureDirectiveID(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let match = trimmed.range(of: #"^::figure\s+([a-z0-9][a-z0-9-]*)\s*$"#, options: .regularExpression) else {
            return nil
        }
        let matched = String(trimmed[match])
        guard let idRange = matched.range(of: #"[a-z0-9][a-z0-9-]*$"#, options: .regularExpression) else {
            return nil
        }
        return String(matched[idRange])
    }

    private static func parseFigure(lines: [String], startIndex: Int) throws -> (block: LessonBlock, nextIndex: Int)? {
        guard let id = figureDirectiveID(lines[startIndex]) else {
            let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
            guard trimmed.range(of: #"^::figure\b"#, options: .regularExpression) != nil else {
                return nil
            }
            let parsed = try parseInvalidFigureDirectiveFallback(lines: lines, startIndex: startIndex)
            return (.paragraph(parsed.text), parsed.nextIndex)
        }
        let sourceLineNumber = startIndex + 1
        var altText: String?
        var textEquivalent: [String] = []
        var fallbackLines = [lines[startIndex].trimmingCharacters(in: .whitespaces)]
        var readingTextEquivalent = false
        var index = startIndex + 1

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "::" {
                return (
                    .figure(MarkdownFigure(
                        id: id,
                        altText: altText?.isEmpty == false ? altText! : id,
                        textEquivalent: textEquivalent,
                        sourceLineNumber: sourceLineNumber
                    )),
                    index + 1
                )
            }
            if trimmed.isEmpty || markdownHeading(line) != nil {
                return (.paragraph(try inlineAttributedString(for: fallbackLines.joined(separator: " "))), index)
            }
            fallbackLines.append(trimmed)
            if trimmed.range(of: #"^Alt text:\s*"#, options: [.regularExpression, .caseInsensitive]) != nil {
                let value = trimmed.replacingOccurrences(of: #"^Alt text:\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
                altText = try plainInlineString(for: value)
                readingTextEquivalent = false
                index += 1
                continue
            }
            if trimmed.range(of: #"^Text equivalent:\s*$"#, options: [.regularExpression, .caseInsensitive]) != nil {
                readingTextEquivalent = true
                index += 1
                continue
            }
            if readingTextEquivalent, let item = try bulletText(trimmed) {
                textEquivalent.append(item)
            }
            index += 1
        }

        return (.paragraph(try inlineAttributedString(for: fallbackLines.joined(separator: " "))), index)
    }

    private static func parseInvalidFigureDirectiveFallback(lines: [String], startIndex: Int) throws -> (text: AttributedString, nextIndex: Int) {
        var fallbackLines = [lines[startIndex].trimmingCharacters(in: .whitespaces)]
        var index = startIndex + 1
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || markdownHeading(line) != nil {
                break
            }
            fallbackLines.append(trimmed)
            index += 1
        }
        return (try inlineAttributedString(for: fallbackLines.joined(separator: " ")), index)
    }

    private static func bulletText(_ trimmedLine: String) throws -> String? {
        guard let markerRange = trimmedLine.range(of: #"^[-*+]\s+"#, options: .regularExpression) else {
            return nil
        }
        return try plainInlineString(for: String(trimmedLine[markerRange.upperBound...]).trimmingCharacters(in: .whitespaces))
    }

    private static func plainInlineString(for markdown: String) throws -> String {
        String(try inlineAttributedString(for: markdown).characters)
    }

    private static func parseIllustrationBrief(lines: [String], startIndex: Int, headingLevel: Int) -> (brief: MarkdownIllustrationBrief?, nextIndex: Int) {
        let sourceLineNumber = startIndex + 1
        var altText: String?
        var descriptionLines: [String] = []
        var index = startIndex + 1

        while index < lines.count {
            let line = lines[index]
            if let nextHeading = markdownHeading(line), nextHeading.level <= headingLevel {
                break
            }
            if line.hasPrefix("Alt text:") {
                altText = String(line.dropFirst("Alt text:".count)).trimmingCharacters(in: .whitespaces)
                index += 1
                continue
            }
            if line.hasPrefix("Description:") {
                let firstLine = String(line.dropFirst("Description:".count)).trimmingCharacters(in: .whitespaces)
                if !firstLine.isEmpty {
                    descriptionLines.append(firstLine)
                }
                index += 1
                while index < lines.count {
                    let continuation = lines[index]
                    if markdownHeading(continuation) != nil || continuation.hasPrefix("Alt text:") || continuation.hasPrefix("Description:") {
                        break
                    }
                    let trimmed = continuation.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        descriptionLines.append(trimmed)
                    }
                    index += 1
                }
                continue
            }
            index += 1
        }

        guard let altText, !altText.isEmpty, !descriptionLines.isEmpty else {
            return (nil, startIndex + 1)
        }
        return (
            MarkdownIllustrationBrief(
                altText: altText,
                description: descriptionLines.joined(separator: "\n"),
                sourceLineNumber: sourceLineNumber
            ),
            index
        )
    }

    private static func parseTable(lines: [String], startIndex: Int) throws -> (model: MarkdownTable, nextIndex: Int)? {
        guard startIndex + 1 < lines.count,
              let headers = parseTableRow(lines[startIndex]),
              let alignment = parseTableDelimiter(lines[startIndex + 1], expectedColumnCount: headers.count) else {
            return nil
        }
        var rows: [[AttributedString]] = []
        var index = startIndex + 2
        while index < lines.count, let row = parseTableRow(lines[index]), row.count == headers.count {
            rows.append(try row.map { try inlineAttributedString(for: $0) })
            index += 1
        }
        return (
            MarkdownTable(
                headers: try headers.map { try inlineAttributedString(for: $0) },
                rows: rows,
                alignment: alignment,
                sourceLineNumber: startIndex + 1
            ),
            index
        )
    }

    private static func parseList(lines: [String], startIndex: Int) throws -> (ordered: Bool, items: [AttributedString], nextIndex: Int)? {
        guard let first = listItem(lines[startIndex]) else {
            return nil
        }
        let ordered = first.ordered
        var items = [try inlineAttributedString(for: first.text)]
        var index = startIndex + 1
        while index < lines.count, let item = listItem(lines[index]), item.ordered == ordered {
            items.append(try inlineAttributedString(for: item.text))
            index += 1
        }
        return (ordered, items, index)
    }

    private static func parseBlockquote(lines: [String], startIndex: Int) throws -> (text: AttributedString, nextIndex: Int) {
        var quoteLines: [String] = []
        var index = startIndex
        while index < lines.count, isBlockquoteLine(lines[index]) {
            let line = lines[index].trimmingCharacters(in: .whitespaces)
            var text = String(line.dropFirst())
            if text.hasPrefix(" ") {
                text.removeFirst()
            }
            quoteLines.append(text)
            index += 1
        }
        return (try inlineAttributedString(for: quoteLines.joined(separator: "\n")), index)
    }

    private static func parseParagraph(lines: [String], startIndex: Int) throws -> (text: AttributedString, nextIndex: Int) {
        var paragraphLines: [String] = []
        var index = startIndex
        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            }
            if codeFenceOpening(line) != nil || figureDirectiveID(line) != nil || markdownHeading(line) != nil || isBlockquoteLine(line) || listItem(line) != nil {
                break
            }
            if index + 1 < lines.count, parseTableRow(line) != nil, parseTableDelimiter(lines[index + 1], expectedColumnCount: parseTableRow(line)?.count ?? 0) != nil {
                break
            }
            paragraphLines.append(line)
            index += 1
        }
        if paragraphLines.isEmpty {
            paragraphLines.append(lines[startIndex])
            index = startIndex + 1
        }
        return (try inlineAttributedString(for: paragraphLines.joined(separator: "\n")), index)
    }

    private static func markdownHeading(_ line: String) -> (level: Int, text: String)? {
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
        var text = trimmed.dropFirst(count).trimmingCharacters(in: .whitespaces)
        while text.hasSuffix("#") {
            text = text.dropLast().trimmingCharacters(in: .whitespaces)
        }
        return (count, String(text))
    }

    private static func codeFenceOpening(_ line: String) -> (marker: String, language: String?)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```") else {
            return nil
        }
        var markerLength = 0
        for character in trimmed {
            if character == "`" {
                markerLength += 1
            } else {
                break
            }
        }
        guard markerLength >= 3 else {
            return nil
        }
        let marker = String(repeating: "`", count: markerLength)
        let language = trimmed.dropFirst(markerLength).trimmingCharacters(in: .whitespaces)
        return (marker, language.isEmpty ? nil : String(language))
    }

    private static func listItem(_ line: String) -> (ordered: Bool, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            return (false, String(trimmed.dropFirst(2)))
        }
        var digitCount = 0
        for scalar in trimmed.unicodeScalars {
            if CharacterSet.decimalDigits.contains(scalar) {
                digitCount += 1
            } else {
                break
            }
        }
        guard digitCount > 0 else {
            return nil
        }
        let dotIndex = trimmed.index(trimmed.startIndex, offsetBy: digitCount)
        guard dotIndex < trimmed.endIndex, trimmed[dotIndex] == "." else {
            return nil
        }
        let afterDot = trimmed.index(after: dotIndex)
        guard afterDot < trimmed.endIndex, trimmed[afterDot] == " " else {
            return nil
        }
        return (true, String(trimmed[trimmed.index(after: afterDot)...]))
    }

    private static func isBlockquoteLine(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix(">")
    }

    private static func parseTableRow(_ line: String) -> [String]? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|"), trimmed.hasSuffix("|") else {
            return nil
        }
        var cells: [String] = []
        var current = ""
        var escaped = false
        let inner = trimmed.dropFirst().dropLast()
        for character in inner {
            if escaped {
                current.append(character)
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "|" {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
        }
        if escaped {
            current.append("\\")
        }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells.count >= 2 ? cells : nil
    }

    private static func parseTableDelimiter(_ line: String, expectedColumnCount: Int) -> [MarkdownTableColumnAlignment]? {
        guard expectedColumnCount >= 2, let cells = parseTableRow(line), cells.count == expectedColumnCount else {
            return nil
        }
        var alignments: [MarkdownTableColumnAlignment] = []
        for cell in cells {
            var value = cell.trimmingCharacters(in: .whitespaces)
            let leftAligned = value.hasPrefix(":")
            let rightAligned = value.hasSuffix(":")
            if leftAligned {
                value.removeFirst()
            }
            if rightAligned {
                value.removeLast()
            }
            guard !value.isEmpty, value.allSatisfy({ $0 == "-" }) else {
                return nil
            }
            switch (leftAligned, rightAligned) {
            case (true, true):
                alignments.append(.center)
            case (true, false):
                alignments.append(.left)
            case (false, true):
                alignments.append(.right)
            case (false, false):
                alignments.append(.none)
            }
        }
        return alignments
    }

    private static func escapeRawHTMLOutsideCodeSpans(in markdown: String) -> String {
        var result = ""
        var index = markdown.startIndex
        while index < markdown.endIndex {
            if markdown[index] == "`" {
                let runStart = index
                var runEnd = index
                while runEnd < markdown.endIndex, markdown[runEnd] == "`" {
                    runEnd = markdown.index(after: runEnd)
                }
                let marker = String(markdown[runStart..<runEnd])
                result += marker
                index = runEnd
                if let close = markdown[index...].range(of: marker)?.lowerBound {
                    result += markdown[index..<close]
                    result += marker
                    index = markdown.index(close, offsetBy: marker.count)
                }
                continue
            }

            if markdown[index] == "<", let close = markdown[index...].firstIndex(of: ">") {
                let tag = String(markdown[markdown.index(after: index)..<close])
                if isMarkdownAutolink(tag) {
                    result += "<" + tag + ">"
                } else if isLikelyRawHTML(tag) {
                    result += "&lt;" + tag + "&gt;"
                } else {
                    result.append(markdown[index])
                    index = markdown.index(after: index)
                    continue
                }
                index = markdown.index(after: close)
                continue
            }

            result.append(markdown[index])
            index = markdown.index(after: index)
        }
        return result
    }

    private static func isMarkdownAutolink(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed == value else {
            return false
        }
        return trimmed.lowercased().hasPrefix("https://") || trimmed.lowercased().hasPrefix("http://") || trimmed.contains("@")
    }

    private static func isLikelyRawHTML(_ tag: String) -> Bool {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("!--") || trimmed.hasPrefix("?") || trimmed.hasPrefix("!") {
            return true
        }
        let withoutSlash = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        guard let first = withoutSlash.unicodeScalars.first, CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").contains(first) else {
            return false
        }
        return true
    }
}
