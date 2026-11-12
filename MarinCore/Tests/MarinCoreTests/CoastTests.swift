import XCTest
@testable import MarinCore

final class SeededRandomTests: XCTestCase {
    func testSameSeedGivesSameSequence() {
        var a = SeededRandom(seed: 42)
        var b = SeededRandom(seed: 42)
        for _ in 0 ..< 20 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testValuesStayInRange() {
        var random = SeededRandom(seed: 7)
        for _ in 0 ..< 500 {
            let unit = random.unit()
            XCTAssertGreaterThanOrEqual(unit, 0)
            XCTAssertLessThan(unit, 1)
            let whole = random.whole(2, 5)
            XCTAssertTrue((2 ... 5).contains(whole))
            let ranged = random.range(-3, 3)
            XCTAssertTrue((-3.0 ... 3.0).contains(ranged))
        }
    }
}

final class CoastTests: XCTestCase {
    func testSameStretchAlwaysLooksTheSame() {
        for stretch in -20 ... 20 {
            XCTAssertEqual(Coast.features(stretch: stretch), Coast.features(stretch: stretch))
            XCTAssertEqual(Coast.mountains(stretch: stretch), Coast.mountains(stretch: stretch))
        }
    }

    func testHomeWatersHaveAnArchAndAVillage() {
        XCTAssertTrue(Coast.features(stretch: 0).contains { $0.kind == .arch })
        XCTAssertTrue(Coast.features(stretch: 1).contains { $0.kind == .settlement })
    }

    func testFeaturesSitInsideTheirStretch() {
        for stretch in -50 ... 50 {
            for feature in Coast.features(stretch: stretch) {
                XCTAssertGreaterThanOrEqual(feature.x, 0)
                XCTAssertLessThan(feature.x, Coast.stretchWidth)
                XCTAssertGreaterThan(feature.width, 0)
                XCTAssertGreaterThan(feature.height, 0)
                for fall in feature.waterfalls {
                    XCTAssertTrue((0.0 ... 1.0).contains(fall))
                }
            }
        }
    }

    func testTheCoastVariesAsYouSail() {
        var sets: [CoastSet: Int] = [:]
        var kinds: Set<CoastFeatureKind> = []
        for stretch in 2 ..< 400 {
            sets[Coast.set(forStretch: stretch), default: 0] += 1
            for feature in Coast.features(stretch: stretch) {
                kinds.insert(feature.kind)
            }
        }
        for set in CoastSet.allCases {
            XCTAssertGreaterThan(sets[set, default: 0], 20, "\(set) is too rare")
        }
        XCTAssertTrue(kinds.isSuperset(of: [.cliff, .arch, .stack, .settlement]))
    }

    func testDifferentSeedsGiveDifferentSeas() {
        var differences = 0
        for stretch in 2 ..< 40 where Coast.set(forStretch: stretch, seed: 1) != Coast.set(forStretch: stretch, seed: 2) {
            differences += 1
        }
        XCTAssertGreaterThan(differences, 5)
    }

    func testMountainsAreAlwaysPresent() {
        for stretch in -10 ... 10 {
            let mountains = Coast.mountains(stretch: stretch)
            XCTAssertTrue((2 ... 3).contains(mountains.count))
            XCTAssertTrue(mountains.allSatisfy { $0.kind == .mountain })
        }
    }
}
