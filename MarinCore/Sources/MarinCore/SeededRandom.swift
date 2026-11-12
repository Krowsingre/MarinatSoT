import Foundation

/// A repeatable source of random numbers. The same seed always gives the same sequence,
/// so the same stretch of sea always looks the same.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A value in 0 ..< 1.
    public mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    /// A value between two bounds.
    public mutating func range(_ low: Double, _ high: Double) -> Double {
        low + (high - low) * unit()
    }

    /// A whole number between two bounds, including both.
    public mutating func whole(_ low: Int, _ high: Int) -> Int {
        guard high > low else { return low }
        return low + Int(unit() * Double(high - low + 1))
    }

    /// Blends several numbers into one seed.
    public static func mix(_ parts: UInt64...) -> UInt64 {
        var result: UInt64 = 0x1234_5678_9ABC_DEF1
        for part in parts {
            var generator = SeededRandom(seed: result ^ part)
            result = generator.next()
        }
        return result
    }
}
