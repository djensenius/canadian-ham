import Foundation

public enum ContentLanguage: String, Codable, Equatable, Sendable {
    case en
    case fr
}

public struct ParsedDistractorNote: Equatable, Sendable {
    public let sourceIndex: Int
    public let quotedChoice: String
    public let note: String
    public let lineNumber: Int

    public init(sourceIndex: Int, quotedChoice: String, note: String, lineNumber: Int) {
        self.sourceIndex = sourceIndex
        self.quotedChoice = quotedChoice
        self.note = note
        self.lineNumber = lineNumber
    }
}

public struct ParsedExplanationBody: Equatable, Sendable {
    public let correctAnswerParagraph: String
    public let distractorNotes: [ParsedDistractorNote]

    public init(correctAnswerParagraph: String, distractorNotes: [ParsedDistractorNote]) {
        self.correctAnswerParagraph = correctAnswerParagraph
        self.distractorNotes = distractorNotes
    }

    public var distractorNotesBySourceIndex: [Int: ParsedDistractorNote] {
        var lookup: [Int: ParsedDistractorNote] = [:]
        for note in distractorNotes where lookup[note.sourceIndex] == nil {
            lookup[note.sourceIndex] = note
        }
        return lookup
    }
}

public enum ExplanationBodyParser {
    public static let distractorHeader = "Why the distractors are wrong:"
    private static let correctAnswerPrefix = "Why the correct answer is right:"

    public static func parse(_ body: String) throws -> ParsedExplanationBody {
        guard let headerRange = body.range(of: distractorHeader) else {
            throw ContentError("explanation body is missing \(String(reflecting: distractorHeader))")
        }
        let correctSection = String(body[..<headerRange.lowerBound])
        let notesSection = String(body[headerRange.upperBound...])
        let correctParagraph = normalizedCorrectAnswerParagraph(correctSection)
        if correctParagraph.isEmpty {
            throw ContentError("explanation body is missing the correct-answer paragraph")
        }
        let notes = try parseDistractorNotes(notesSection, startingLineNumber: lineNumber(in: body, at: headerRange.upperBound))
        if notes.isEmpty {
            throw ContentError("explanation body is missing per-choice sourceIndex notes")
        }
        return ParsedExplanationBody(correctAnswerParagraph: correctParagraph, distractorNotes: notes)
    }

    public static func parse(_ explanation: Explanation, language: ContentLanguage = .en) throws -> ParsedExplanationBody {
        let body = language == .fr ? (explanation.body.fr ?? explanation.body.en) : explanation.body.en
        return try parse(body)
    }

    public static func parse(_ explanation: Explanation, language: String) throws -> ParsedExplanationBody {
        try parse(explanation, language: ContentLanguage(rawValue: language) ?? .en)
    }

    private static func normalizedCorrectAnswerParagraph(_ section: String) -> String {
        var lines = section.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        if let firstMeaningful = lines.firstIndex(where: { !$0.isEmpty }), lines[firstMeaningful].range(of: #"^Question\s+B-\d{3}-\d{3}-\d{3}\.?$"#, options: .regularExpression) != nil {
            lines.remove(at: firstMeaningful)
        }
        var text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix(correctAnswerPrefix) {
            text = String(text.dropFirst(correctAnswerPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }

    private static func parseDistractorNotes(_ section: String, startingLineNumber: Int) throws -> [ParsedDistractorNote] {
        var notes: [ParsedDistractorNote] = []
        var seenSourceIndexes: Set<Int> = []
        let lines = section.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            guard line.contains("sourceIndex") else {
                continue
            }
            let lineNumber = startingLineNumber + index
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- sourceIndex ") else {
                throw ContentError("explanation line \(lineNumber): per-choice note must use '- sourceIndex N: \"choice text\": note'")
            }
            let afterPrefix = String(trimmed.dropFirst("- sourceIndex ".count))
            guard let numberSeparator = afterPrefix.range(of: ": ") else {
                throw ContentError("explanation line \(lineNumber): per-choice note must use '- sourceIndex N: \"choice text\": note'")
            }
            let numberText = String(afterPrefix[..<numberSeparator.lowerBound])
            guard let sourceIndex = Int(numberText) else {
                throw ContentError("explanation line \(lineNumber): sourceIndex must be an integer")
            }
            guard sourceIndex != 0 else {
                throw ContentError("explanation line \(lineNumber): sourceIndex 0 must not appear in the distractor notes")
            }
            guard !seenSourceIndexes.contains(sourceIndex) else {
                throw ContentError("explanation line \(lineNumber): duplicate per-choice note for sourceIndex \(sourceIndex)")
            }
            seenSourceIndexes.insert(sourceIndex)
            let afterNumber = String(afterPrefix[numberSeparator.upperBound...])
            let quoted = try parseQuotedChoiceAndNote(afterNumber, lineNumber: lineNumber)
            notes.append(ParsedDistractorNote(sourceIndex: sourceIndex, quotedChoice: quoted.choice, note: quoted.note, lineNumber: lineNumber))
        }
        return notes
    }

    private static func parseQuotedChoiceAndNote(_ value: String, lineNumber: Int) throws -> (choice: String, note: String) {
        guard value.first == "\"" else {
            throw ContentError("explanation line \(lineNumber): quoted choice text is missing")
        }
        var index = value.index(after: value.startIndex)
        var escaped = false
        var closingQuote: String.Index?
        while index < value.endIndex {
            let character = value[index]
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                closingQuote = index
                break
            }
            index = value.index(after: index)
        }
        guard let closingQuote else {
            throw ContentError("explanation line \(lineNumber): quoted choice text is not closed")
        }
        let rawChoice = String(value[value.index(after: value.startIndex)..<closingQuote])
        let choice: String
        do {
            choice = try JSONDecoder().decode(String.self, from: Data("\"\(rawChoice)\"".utf8))
        } catch {
            throw ContentError("explanation line \(lineNumber): quoted choice text is not a valid JSON string fragment")
        }
        let remainder = value[value.index(after: closingQuote)...]
        guard remainder.hasPrefix(":") else {
            throw ContentError("explanation line \(lineNumber): expected ':' after quoted choice text")
        }
        let note = remainder.dropFirst().trimmingCharacters(in: .whitespaces)
        guard !note.isEmpty else {
            throw ContentError("explanation line \(lineNumber): note must not be empty")
        }
        return (choice, note)
    }

    private static func lineNumber(in source: String, at position: String.Index) -> Int {
        source[..<position].reduce(1) { count, character in
            character == "\n" ? count + 1 : count
        }
    }
}
