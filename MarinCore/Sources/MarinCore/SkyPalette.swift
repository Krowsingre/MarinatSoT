import Foundation

/// A colour as red, green and blue, each 0 ... 1.
public struct RGB: Equatable, Sendable {
    public var r: Double
    public var g: Double
    public var b: Double

    public init(_ r: Double, _ g: Double, _ b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    public func mixed(with other: RGB, t: Double) -> RGB {
        let x = min(max(t, 0), 1)
        return RGB(r + (other.r - r) * x, g + (other.g - g) * x, b + (other.b - b) * x)
    }

    public func scaled(_ factor: Double) -> RGB {
        RGB(r * factor, g * factor, b * factor)
    }

    /// The grey with the same brightness.
    public var grey: RGB {
        let v = r * 0.3 + g * 0.59 + b * 0.11
        return RGB(v, v, v)
    }
}

/// The colours of the sky and water at one moment.
public struct SkyPalette: Equatable, Sendable {
    public var skyTop: RGB
    public var horizon: RGB
    public var waterTop: RGB
    public var waterDeep: RGB
    /// How visible the stars are, 0 ... 1.
    public var stars: Double

    public init(skyTop: RGB, horizon: RGB, waterTop: RGB, waterDeep: RGB, stars: Double) {
        self.skyTop = skyTop
        self.horizon = horizon
        self.waterTop = waterTop
        self.waterDeep = waterDeep
        self.stars = stars
    }

    public func mixed(with other: SkyPalette, t: Double) -> SkyPalette {
        SkyPalette(
            skyTop: skyTop.mixed(with: other.skyTop, t: t),
            horizon: horizon.mixed(with: other.horizon, t: t),
            waterTop: waterTop.mixed(with: other.waterTop, t: t),
            waterDeep: waterDeep.mixed(with: other.waterDeep, t: t),
            stars: stars + (other.stars - stars) * min(max(t, 0), 1)
        )
    }
}

/// Works out the colours of the sea for any hour and any weather.
public enum Sky {
    private static let night = SkyPalette(
        skyTop: RGB(0.03, 0.05, 0.13),
        horizon: RGB(0.09, 0.13, 0.27),
        waterTop: RGB(0.05, 0.11, 0.22),
        waterDeep: RGB(0.01, 0.02, 0.06),
        stars: 1
    )

    /// The colours at fixed hours through the day. Hours between are blended.
    private static let keys: [(hour: Double, palette: SkyPalette)] = [
        (0, night),
        (4.5, night),
        (5.6, SkyPalette(
            skyTop: RGB(0.16, 0.20, 0.40),
            horizon: RGB(0.86, 0.53, 0.46),
            waterTop: RGB(0.20, 0.28, 0.42),
            waterDeep: RGB(0.02, 0.05, 0.12),
            stars: 0.4)),
        (7, SkyPalette(
            skyTop: RGB(0.45, 0.66, 0.88),
            horizon: RGB(0.98, 0.84, 0.68),
            waterTop: RGB(0.30, 0.55, 0.66),
            waterDeep: RGB(0.03, 0.12, 0.22),
            stars: 0)),
        (12, SkyPalette(
            skyTop: RGB(0.33, 0.62, 0.90),
            horizon: RGB(0.80, 0.91, 0.96),
            waterTop: RGB(0.25, 0.62, 0.72),
            waterDeep: RGB(0.03, 0.16, 0.28),
            stars: 0)),
        (17, SkyPalette(
            skyTop: RGB(0.36, 0.58, 0.85),
            horizon: RGB(0.96, 0.86, 0.70),
            waterTop: RGB(0.27, 0.56, 0.66),
            waterDeep: RGB(0.03, 0.13, 0.24),
            stars: 0)),
        (19, SkyPalette(
            skyTop: RGB(0.25, 0.22, 0.45),
            horizon: RGB(0.96, 0.52, 0.35),
            waterTop: RGB(0.25, 0.27, 0.42),
            waterDeep: RGB(0.03, 0.05, 0.13),
            stars: 0.25)),
        (20.5, SkyPalette(
            skyTop: RGB(0.06, 0.08, 0.20),
            horizon: RGB(0.20, 0.18, 0.36),
            waterTop: RGB(0.08, 0.13, 0.26),
            waterDeep: RGB(0.01, 0.03, 0.08),
            stars: 0.85)),
        (22, night)
    ]

    /// The palette for an hour of the day, greyed and darkened by stormy weather.
    public static func palette(atHour rawHour: Double, storminess: Double = 0) -> SkyPalette {
        let hour = SeaClock.normalized(rawHour)
        var base = keys[keys.count - 1].palette
        for index in 0 ..< keys.count {
            let current = keys[index]
            let nextHour = index + 1 < keys.count ? keys[index + 1].hour : 24
            let nextPalette = index + 1 < keys.count ? keys[index + 1].palette : keys[0].palette
            if hour >= current.hour && hour < nextHour {
                let t = (hour - current.hour) / (nextHour - current.hour)
                base = current.palette.mixed(with: nextPalette, t: t)
                break
            }
        }
        return stormy(base, amount: storminess)
    }

    private static func stormy(_ palette: SkyPalette, amount: Double) -> SkyPalette {
        let a = min(max(amount, 0), 1)
        guard a > 0 else { return palette }
        func dull(_ colour: RGB) -> RGB {
            colour.mixed(with: colour.grey.scaled(0.62), t: a * 0.8)
        }
        return SkyPalette(
            skyTop: dull(palette.skyTop),
            horizon: dull(palette.horizon),
            waterTop: dull(palette.waterTop),
            waterDeep: dull(palette.waterDeep),
            stars: palette.stars * (1 - a)
        )
    }
}
