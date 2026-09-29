import Foundation

public struct ContentError: Error, Equatable, Sendable, LocalizedError {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}

extension ContentError {
    static func readFailure(_ url: URL, _ error: Error) -> ContentError {
        ContentError("Unable to read \(url.path(percentEncoded: false)): \(error.localizedDescription)")
    }

    static func decodeFailure(_ url: URL, _ error: Error) -> ContentError {
        ContentError("Unable to decode \(url.path(percentEncoded: false)): \(error.localizedDescription)")
    }
}
