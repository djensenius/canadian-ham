private let millisecondsPerSecond: Int64 = 1_000
private let secondsPerDay: Int64 = 86_400
private let millisecondsPerDay = secondsPerDay * millisecondsPerSecond

public enum CanonicalTimestamp {
    public static func require(_ value: String, fieldName: String) throws {
        _ = try epochMilliseconds(value, fieldName: fieldName)
    }

    public static func epochMilliseconds(_ value: String, fieldName: String) throws -> Int64 {
        let bytes = Array(value.utf8)
        guard bytes.count == 24,
              bytes[4] == asciiHyphen,
              bytes[7] == asciiHyphen,
              bytes[10] == asciiT,
              bytes[13] == asciiColon,
              bytes[16] == asciiColon,
              bytes[19] == asciiDot,
              bytes[23] == asciiZ else {
            throw timestampError(fieldName)
        }

        let year = try digits(bytes, 0..<4, fieldName: fieldName)
        let month = try digits(bytes, 5..<7, fieldName: fieldName)
        let day = try digits(bytes, 8..<10, fieldName: fieldName)
        let hour = try digits(bytes, 11..<13, fieldName: fieldName)
        let minute = try digits(bytes, 14..<16, fieldName: fieldName)
        let second = try digits(bytes, 17..<19, fieldName: fieldName)
        let millisecond = try digits(bytes, 20..<23, fieldName: fieldName)

        guard month >= 1, month <= 12,
              day >= 1, day <= daysInMonth(year: year, month: month),
              hour >= 0, hour <= 23,
              minute >= 0, minute <= 59,
              second >= 0, second <= 59,
              millisecond >= 0, millisecond <= 999 else {
            throw timestampError(fieldName)
        }

        let dayCount = daysFromCivil(year: Int64(year), month: Int64(month), day: Int64(day))
        return dayCount * millisecondsPerDay
            + Int64(hour) * 3_600_000
            + Int64(minute) * 60_000
            + Int64(second) * 1_000
            + Int64(millisecond)
    }

    public static func string(fromEpochMilliseconds epochMilliseconds: Int64) -> String {
        let days = floorDiv(epochMilliseconds, millisecondsPerDay)
        let dayMilliseconds = epochMilliseconds - days * millisecondsPerDay
        let civil = civilFromDays(days)
        let hour = dayMilliseconds / 3_600_000
        let minute = (dayMilliseconds % 3_600_000) / 60_000
        let second = (dayMilliseconds % 60_000) / 1_000
        let millisecond = dayMilliseconds % 1_000
        return "\(pad(civil.year, 4))-\(pad(civil.month, 2))-\(pad(civil.day, 2))T\(pad(hour, 2)):\(pad(minute, 2)):\(pad(second, 2)).\(pad(millisecond, 3))Z"
    }

    public static func addSeconds(_ value: String, seconds: Int, fieldName: String = "timestamp") throws -> String {
        let epoch = try epochMilliseconds(value, fieldName: fieldName)
        return string(fromEpochMilliseconds: epoch + Int64(seconds) * millisecondsPerSecond)
    }
}

private let asciiHyphen: UInt8 = 45
private let asciiT: UInt8 = 84
private let asciiColon: UInt8 = 58
private let asciiDot: UInt8 = 46
private let asciiZ: UInt8 = 90
private let asciiZero: UInt8 = 48
private let asciiNine: UInt8 = 57

private func timestampError(_ fieldName: String) -> EngineError {
    EngineError("\(fieldName) must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS.sssZ")
}

private func digits(_ bytes: [UInt8], _ range: Range<Int>, fieldName: String) throws -> Int {
    var output = 0
    for index in range {
        let byte = bytes[index]
        guard byte >= asciiZero, byte <= asciiNine else {
            throw timestampError(fieldName)
        }
        output = output * 10 + Int(byte - asciiZero)
    }
    return output
}

private func daysInMonth(year: Int, month: Int) -> Int {
    switch month {
    case 1, 3, 5, 7, 8, 10, 12:
        return 31
    case 4, 6, 9, 11:
        return 30
    case 2:
        return isLeapYear(year) ? 29 : 28
    default:
        return 0
    }
}

private func isLeapYear(_ year: Int) -> Bool {
    (year.isMultiple(of: 4) && !year.isMultiple(of: 100)) || year.isMultiple(of: 400)
}

private func daysFromCivil(year: Int64, month: Int64, day: Int64) -> Int64 {
    var adjustedYear = year
    adjustedYear -= month <= 2 ? 1 : 0
    let era = floorDiv(adjustedYear, 400)
    let yearOfEra = adjustedYear - era * 400
    let monthPrime = month + (month > 2 ? -3 : 9)
    let dayOfYear = (153 * monthPrime + 2) / 5 + day - 1
    let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
    return era * 146_097 + dayOfEra - 719_468
}

private func civilFromDays(_ days: Int64) -> (year: Int64, month: Int64, day: Int64) {
    let z = days + 719_468
    let era = floorDiv(z, 146_097)
    let dayOfEra = z - era * 146_097
    let yearOfEra = (dayOfEra - dayOfEra / 1_460 + dayOfEra / 36_524 - dayOfEra / 146_096) / 365
    var year = yearOfEra + era * 400
    let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
    let monthPrime = (5 * dayOfYear + 2) / 153
    let day = dayOfYear - (153 * monthPrime + 2) / 5 + 1
    let month = monthPrime + (monthPrime < 10 ? 3 : -9)
    year += month <= 2 ? 1 : 0
    return (year, month, day)
}

private func floorDiv(_ lhs: Int64, _ rhs: Int64) -> Int64 {
    let quotient = lhs / rhs
    let remainder = lhs % rhs
    return remainder != 0 && ((remainder > 0) != (rhs > 0)) ? quotient - 1 : quotient
}

private func pad(_ value: Int64, _ width: Int) -> String {
    let raw = String(value)
    if raw.count >= width {
        return raw
    }
    return String(repeating: "0", count: width - raw.count) + raw
}
