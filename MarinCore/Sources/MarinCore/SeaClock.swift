import Foundation

/// The four parts of a day at sea.
public enum DayPhase: String, CaseIterable, Sendable {
    case night, dawn, day, dusk
}

/// Turns a moment in time into the hour of the day at sea, and describes that hour.
public enum SeaClock {
    public static let dawnStart = 5.0
    public static let dayStart = 7.0
    public static let duskStart = 18.0
    public static let nightStart = 20.0

    /// Wraps any hour value into 0 ..< 24.
    public static func normalized(_ hour: Double) -> Double {
        let wrapped = hour.truncatingRemainder(dividingBy: 24)
        return wrapped < 0 ? wrapped + 24 : wrapped
    }

    /// The fractional hour of the day (0 ..< 24) for a date.
    public static func hour(for date: Date, calendar: Calendar = .current) -> Double {
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour = Double(parts.hour ?? 0)
        let minute = Double(parts.minute ?? 0)
        let second = Double(parts.second ?? 0)
        return hour + minute / 60 + second / 3600
    }

    /// A whole-number index of the day, used to pick that day's weather.
    public static func dayIndex(for date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        return Int((start.timeIntervalSinceReferenceDate / 86_400).rounded(.down))
    }

    public static func phase(atHour rawHour: Double) -> DayPhase {
        let hour = normalized(rawHour)
        if hour < dawnStart { return .night }
        if hour < dayStart { return .dawn }
        if hour < duskStart { return .day }
        if hour < nightStart { return .dusk }
        return .night
    }

    /// How much daylight there is: 0 in full night, 1 in full day, easing through dawn and dusk.
    public static func daylight(atHour rawHour: Double) -> Double {
        let hour = normalized(rawHour)
        switch phase(atHour: hour) {
        case .night:
            return 0
        case .day:
            return 1
        case .dawn:
            return smooth((hour - dawnStart) / (dayStart - dawnStart))
        case .dusk:
            return 1 - smooth((hour - duskStart) / (nightStart - duskStart))
        }
    }

    private static func smooth(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }
}
