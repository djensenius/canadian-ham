import Foundation

public enum FrontMatterValue: Equatable, Sendable {
    case string(String)
    case integer(Int)
    case null
    case stringArray([String])
    case object([String: String?])
}

public struct FrontMatterDocument: Equatable, Sendable {
    public let frontMatter: [String: FrontMatterValue]
    public let bodyMarkdown: String

    public init(frontMatter: [String: FrontMatterValue], bodyMarkdown: String) {
        self.frontMatter = frontMatter
        self.bodyMarkdown = bodyMarkdown
    }
}

public enum StrictFrontMatterParser {
    public static func parse(markdown: String, path: String = "<memory>") throws -> FrontMatterDocument {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        var lines = normalized.components(separatedBy: "\n")
        if lines.last == "" {
            lines.removeLast()
        }
        guard lines.first == "---" else {
            throw ContentError("\(path): missing opening front matter delimiter")
        }
        guard let closingIndex = lines.dropFirst().firstIndex(of: "---") else {
            throw ContentError("\(path): missing closing front matter delimiter")
        }

        let frontMatterLines = Array(lines[1..<closingIndex])
        let bodyLines = closingIndex + 1 < lines.endIndex ? Array(lines[(closingIndex + 1)..<lines.endIndex]) : []
        return FrontMatterDocument(
            frontMatter: try parseFrontMatterLines(frontMatterLines, path: path),
            bodyMarkdown: bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private static func parseFrontMatterLines(_ lines: [String], path: String) throws -> [String: FrontMatterValue] {
        var data: [String: FrontMatterValue] = [:]
        var currentKey: String?

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 2
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }

            if line.hasPrefix("  - ") {
                guard let key = currentKey, case let .stringArray(existing) = data[key] else {
                    throw ContentError("\(path):\(lineNumber): array item is not under an array key")
                }
                let scalar = try parseScalar(String(line.dropFirst(4)), path: path, lineNumber: lineNumber)
                guard case let .string(value) = scalar else {
                    throw ContentError("\(path):\(lineNumber): array items must be strings")
                }
                data[key] = .stringArray(existing + [value])
                continue
            }

            if line.hasPrefix("  ") {
                guard let key = currentKey, case var .object(object) = data[key] else {
                    throw ContentError("\(path):\(lineNumber): object entry is not under an object key")
                }
                let nested = String(line.dropFirst(2))
                guard let separator = nested.range(of: ": ") else {
                    throw ContentError("\(path):\(lineNumber): unsupported indentation")
                }
                let nestedKey = String(nested[..<separator.lowerBound])
                guard isKey(nestedKey) else {
                    throw ContentError("\(path):\(lineNumber): expected nested key-value front matter line")
                }
                if object.keys.contains(nestedKey) {
                    throw ContentError("\(path):\(lineNumber): duplicate nested key \(nestedKey)")
                }
                let rawValue = String(nested[separator.upperBound...])
                let scalar = try parseScalar(rawValue, path: path, lineNumber: lineNumber)
                switch scalar {
                case let .string(value):
                    object[nestedKey] = value
                case .null:
                    object.updateValue(nil, forKey: nestedKey)
                case .integer, .stringArray, .object:
                    throw ContentError("\(path):\(lineNumber): object values must be strings or null")
                }
                data[key] = .object(object)
                continue
            }

            if line.hasPrefix(" ") {
                throw ContentError("\(path):\(lineNumber): unsupported indentation")
            }

            guard let colon = line.firstIndex(of: ":") else {
                throw ContentError("\(path):\(lineNumber): expected key-value front matter line")
            }
            let key = String(line[..<colon])
            guard isKey(key) else {
                throw ContentError("\(path):\(lineNumber): expected key-value front matter line")
            }
            if data.keys.contains(key) {
                throw ContentError("\(path):\(lineNumber): duplicate key \(key)")
            }
            let rawValueWithPossibleSpace = String(line[line.index(after: colon)...])
            if rawValueWithPossibleSpace.trimmingCharacters(in: .whitespaces).isEmpty {
                let following = lines[(index + 1)..<lines.endIndex].first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                data[key] = following?.hasPrefix("  - ") == true ? .stringArray([]) : .object([:])
            } else {
                guard rawValueWithPossibleSpace.hasPrefix(" ") else {
                    throw ContentError("\(path):\(lineNumber): expected a space after ':'")
                }
                data[key] = try parseScalar(rawValueWithPossibleSpace, path: path, lineNumber: lineNumber)
            }
            currentKey = key
        }

        return data
    }

    private static func parseScalar(_ raw: String, path: String, lineNumber: Int) throws -> FrontMatterValue {
        let value = raw.trimmingCharacters(in: .whitespaces)
        if value.isEmpty {
            throw ContentError("\(path):\(lineNumber): missing scalar value")
        }
        if value == "null" {
            return .null
        }
        if value == "[]" {
            return .stringArray([])
        }
        if isIntegerLiteral(value), let integer = Int(value) {
            return .integer(integer)
        }
        if value.hasPrefix("\"") || value.hasSuffix("\"") {
            guard value.hasPrefix("\""), value.hasSuffix("\"") else {
                throw ContentError("\(path):\(lineNumber): malformed quoted string")
            }
            do {
                let decoded = try JSONDecoder().decode(String.self, from: Data(value.utf8))
                return .string(decoded)
            } catch {
                throw ContentError("\(path):\(lineNumber): malformed quoted string")
            }
        }
        if isBareScalar(value) {
            return .string(value)
        }
        throw ContentError("\(path):\(lineNumber): quote scalar values containing spaces or punctuation")
    }

    private static func isKey(_ value: String) -> Bool {
        let letters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        let alphanumerics = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        guard let first = value.unicodeScalars.first, letters.contains(first) else {
            return false
        }
        return value.unicodeScalars.allSatisfy { scalar in
            alphanumerics.contains(scalar)
        }
    }

    private static func isIntegerLiteral(_ value: String) -> Bool {
        guard !value.isEmpty else {
            return false
        }
        let digits: Substring
        if value.hasPrefix("-") {
            digits = value.dropFirst()
        } else {
            digits = value[...]
        }
        return !digits.isEmpty && digits.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    private static func isBareScalar(_ value: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._/-")
        return !value.isEmpty && value.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}

extension FrontMatterDocument {
    func requireString(_ key: String, path: String) throws -> String {
        guard case let .string(value) = frontMatter[key], !value.isEmpty else {
            throw ContentError("\(path): front matter field \(key) must be a non-empty string")
        }
        return value
    }

    func requirePositiveInteger(_ key: String, path: String) throws -> Int {
        guard case let .integer(value) = frontMatter[key], value > 0 else {
            throw ContentError("\(path): front matter field \(key) must be a positive integer")
        }
        return value
    }

    func requireStringArray(_ key: String, path: String, allowEmpty: Bool = false) throws -> [String] {
        guard case let .stringArray(value) = frontMatter[key], (allowEmpty || !value.isEmpty), value.allSatisfy({ !$0.isEmpty }) else {
            throw ContentError("\(path): front matter field \(key) must be \(allowEmpty ? "an" : "a non-empty") array of strings")
        }
        return value
    }

    func requireLocalizedTitle(path: String) throws -> LocalizedNullableText {
        guard case let .object(value) = frontMatter["title"], let en = value["en"] ?? nil, !en.isEmpty, value.keys.contains("fr") else {
            throw ContentError("\(path): front matter field title must contain en string and fr string|null")
        }
        return LocalizedNullableText(en: en, fr: value["fr"] ?? nil)
    }

    func requireStatus(_ key: String, path: String, typeName: String) throws -> ContentStatus {
        let status = try requireString(key, path: path)
        guard let value = ContentStatus(rawValue: status) else {
            throw ContentError("\(path): \(typeName) status must be one of outline, draft, review, published")
        }
        return value
    }
}
