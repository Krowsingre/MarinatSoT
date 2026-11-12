import Foundation

/// The weather over the sea on a given day. Storms are occasional.
public enum Weather: String, CaseIterable, Sendable {
    case clear, cloudy, rain, storm

    /// How much of the sky is covered by cloud, 0 ... 1.
    public var cloudCover: Double {
        switch self {
        case .clear: return 0.15
        case .cloudy: return 0.6
        case .rain: return 0.85
        case .storm: return 1.0
        }
    }

    /// How hard it is raining, 0 ... 1.
    public var rain: Double {
        switch self {
        case .clear, .cloudy: return 0
        case .rain: return 0.55
        case .storm: return 1.0
        }
    }

    /// How dark and grey the light becomes, 0 ... 1.
    public var storminess: Double {
        switch self {
        case .clear: return 0
        case .cloudy: return 0.15
        case .rain: return 0.45
        case .storm: return 1.0
        }
    }

    /// How much taller the waves are than on a calm day.
    public var waveScale: Double {
        switch self {
        case .clear: return 1.0
        case .cloudy: return 1.15
        case .rain: return 1.4
        case .storm: return 2.2
        }
    }
}

/// Decides each day's weather. The same day always gives the same weather.
public enum WeatherForecast {
    public static let defaultSeed: UInt64 = 0x4D41_5249_4E00_0001

    public static func weather(onDay dayIndex: Int, seed: UInt64 = defaultSeed) -> Weather {
        let roll = unitValue(dayIndex: dayIndex, seed: seed)
        if roll < 0.50 { return .clear }
        if roll < 0.78 { return .cloudy }
        if roll < 0.93 { return .rain }
        return .storm
    }

    /// A repeatable value in 0 ..< 1 for a day.
    static func unitValue(dayIndex: Int, seed: UInt64) -> Double {
        var z = seed &+ UInt64(bitPattern: Int64(dayIndex)) &* 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z = z ^ (z >> 31)
        return Double(z >> 11) / Double(1 << 53)
    }
}
