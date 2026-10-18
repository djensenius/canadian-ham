import Foundation

#if os(iOS)
@MainActor
enum DuoPosture: Equatable, Sendable {
    case unavailable
    case closed
    case partiallyOpen
    case unfolded
    case unknown
}

@MainActor
protocol DuoPostureProviding: AnyObject {
    var posture: DuoPosture { get }
    var onPostureChanged: ((DuoPosture) -> Void)? { get set }
}

@MainActor
final class UnavailableDuoPostureProvider: DuoPostureProviding {
    private(set) var posture: DuoPosture = .unavailable
    var onPostureChanged: ((DuoPosture) -> Void)?
}

@MainActor
enum DuoPostureProviderFactory {
    static func makeProvider() -> any DuoPostureProviding {
        UnavailableDuoPostureProvider()
    }
}
#endif
