import CoreGraphics
import Foundation

enum AppLaunchArguments {
    static func value(after option: String, in arguments: [String] = ProcessInfo.processInfo.arguments) -> String? {
        guard let optionIndex = arguments.firstIndex(of: option) else { return nil }
        let valueIndex = arguments.index(after: optionIndex)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
    }
}

#if DEBUG
func canadianHamParsedWindowSize(_ rawValue: String) -> CGSize? {
    let separators = CharacterSet(charactersIn: "xX,")
    let parts = rawValue.components(separatedBy: separators)
    guard parts.count == 2,
          let width = Double(parts[0]),
          let height = Double(parts[1]),
          width > 0,
          height > 0 else {
        return nil
    }
    return CGSize(width: width, height: height)
}

func canadianHamSimulatedWindowSize(default actualSize: CGSize, arguments: [String] = ProcessInfo.processInfo.arguments) -> CGSize {
    canadianHamSimulatedWindowSizeFromLaunchArguments(arguments: arguments) ?? actualSize
}

func canadianHamSimulatedWindowSizeFromLaunchArguments(arguments: [String] = ProcessInfo.processInfo.arguments) -> CGSize? {
    guard let rawValue = AppLaunchArguments.value(after: "-CanadianHamSimulatedWindowSize", in: arguments) else { return nil }
    return canadianHamParsedWindowSize(rawValue)
}
#endif
