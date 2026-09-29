import Foundation

enum AppLaunchArguments {
    static func value(after option: String, in arguments: [String] = ProcessInfo.processInfo.arguments) -> String? {
        guard let optionIndex = arguments.firstIndex(of: option) else { return nil }
        let valueIndex = arguments.index(after: optionIndex)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
    }
}
