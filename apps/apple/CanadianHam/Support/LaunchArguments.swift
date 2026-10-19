import Foundation
import SwiftUI

enum AppLaunchArguments {
    static func value(after option: String, in arguments: [String] = ProcessInfo.processInfo.arguments) -> String? {
        guard let optionIndex = arguments.firstIndex(of: option) else { return nil }
        let valueIndex = arguments.index(after: optionIndex)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
    }
}

#if DEBUG
func canadianHamParsedHorizontalSizeClass(_ rawValue: String) -> UserInterfaceSizeClass? {
    switch rawValue.lowercased() {
    case "compact":
        return .compact
    case "regular":
        return .regular
    default:
        return nil
    }
}

func canadianHamSimulatedHorizontalSizeClassFromLaunchArguments(arguments: [String] = ProcessInfo.processInfo.arguments) -> UserInterfaceSizeClass? {
    guard let rawValue = AppLaunchArguments.value(after: "-CanadianHamSimulatedHorizontalSizeClass", in: arguments) else { return nil }
    return canadianHamParsedHorizontalSizeClass(rawValue)
}
#endif
