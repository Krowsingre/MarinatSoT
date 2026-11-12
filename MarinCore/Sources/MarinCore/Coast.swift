import Foundation

/// One piece of scenery along the horizon.
public enum CoastFeatureKind: String, CaseIterable, Sendable {
    case cliff, arch, stack, settlement, mountain
}

/// Where a piece of scenery sits and how big it is. Sizes are in points on a 390-point-tall screen.
public struct CoastFeature: Equatable, Sendable {
    public var kind: CoastFeatureKind
    /// The centre of the feature, measured from the start of its stretch.
    public var x: Double
    public var width: Double
    public var height: Double
    /// Where waterfalls fall, each 0 ... 1 across the feature's width.
    public var waterfalls: [Double]
    /// A seed for the feature's small details, so it always draws the same way.
    public var detail: UInt64
}

/// The kinds of coast that a stretch of sea can pass. Each is a coherent set of scenery.
public enum CoastSet: String, CaseIterable, Sendable {
    case openSea, cliffs, archCoast, settlement
}

/// Decides what scenery lies along each stretch of the sea.
///
/// The sea is divided into stretches. Each stretch is given one kind of coast, and
/// its scenery is arranged from that kind's parts. The same stretch always comes out the same.
public enum Coast {
    public static let defaultSeed: UInt64 = 0x5EA0_F7A1_E500_0001
    public static let stretchWidth = 700.0
    public static let mountainStretchWidth = 520.0

    public static func set(forStretch stretch: Int, seed: UInt64 = defaultSeed) -> CoastSet {
        // The home waters always open with an arch and a village.
        if stretch == 0 { return .archCoast }
        if stretch == 1 { return .settlement }
        var random = SeededRandom(seed: SeededRandom.mix(seed, 0xA11CE, key(stretch)))
        let roll = random.unit()
        if roll < 0.25 { return .openSea }
        if roll < 0.60 { return .cliffs }
        if roll < 0.80 { return .archCoast }
        return .settlement
    }

    public static func features(stretch: Int, seed: UInt64 = defaultSeed) -> [CoastFeature] {
        var random = SeededRandom(seed: SeededRandom.mix(seed, 0xC0A57, key(stretch)))
        let w = stretchWidth
        var list: [CoastFeature] = []

        func add(_ kind: CoastFeatureKind, at fraction: Double,
                 width: ClosedRange<Double>, height: ClosedRange<Double>, falls: ClosedRange<Int> = 0 ... 0) {
            let count = random.whole(falls.lowerBound, falls.upperBound)
            var waterfalls: [Double] = []
            for index in 0 ..< count {
                let slot = (Double(index) + random.range(0.2, 0.8)) / Double(count)
                waterfalls.append(slot)
            }
            let jitter = random.range(-0.04, 0.04)
            list.append(CoastFeature(
                kind: kind,
                x: min(max((fraction + jitter) * w, 0), w - 1),
                width: random.range(width.lowerBound, width.upperBound),
                height: random.range(height.lowerBound, height.upperBound),
                waterfalls: waterfalls,
                detail: random.next()
            ))
        }

        switch set(forStretch: stretch, seed: seed) {
        case .openSea:
            let stacks = random.whole(0, 2)
            for _ in 0 ..< stacks {
                add(.stack, at: random.range(0.1, 0.9), width: 22 ... 48, height: 22 ... 60)
            }
        case .cliffs:
            add(.cliff, at: 0.25, width: 260 ... 360, height: 105 ... 160, falls: 1 ... 2)
            add(.cliff, at: 0.74, width: 180 ... 270, height: 65 ... 110, falls: 0 ... 1)
            add(.stack, at: 0.52, width: 22 ... 44, height: 24 ... 58)
        case .archCoast:
            add(.cliff, at: 0.20, width: 250 ... 320, height: 115 ... 160, falls: 1 ... 1)
            add(.stack, at: 0.44, width: 22 ... 40, height: 22 ... 46)
            add(.arch, at: 0.62, width: 150 ... 195, height: 70 ... 96)
            add(.stack, at: 0.84, width: 24 ... 46, height: 26 ... 60)
        case .settlement:
            add(.stack, at: 0.12, width: 24 ... 44, height: 24 ... 54)
            add(.settlement, at: 0.56, width: 300 ... 370, height: 70 ... 96, falls: 1 ... 2)
            add(.stack, at: 0.92, width: 20 ... 36, height: 20 ... 40)
        }
        return list.sorted { $0.x < $1.x }
    }

    /// The far mountains behind the coast, for one stretch of the mountain layer.
    public static func mountains(stretch: Int, seed: UInt64 = defaultSeed) -> [CoastFeature] {
        var random = SeededRandom(seed: SeededRandom.mix(seed, 0x30BB, key(stretch)))
        let count = random.whole(2, 3)
        var list: [CoastFeature] = []
        for index in 0 ..< count {
            let slot = (Double(index) + random.range(0.15, 0.85)) / Double(count)
            list.append(CoastFeature(
                kind: .mountain,
                x: slot * mountainStretchWidth,
                width: random.range(260, 460),
                height: random.range(80, 170),
                waterfalls: [],
                detail: random.next()
            ))
        }
        return list
    }

    private static func key(_ stretch: Int) -> UInt64 {
        UInt64(bitPattern: Int64(stretch))
    }
}
