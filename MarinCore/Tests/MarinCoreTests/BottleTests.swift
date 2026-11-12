import XCTest
@testable import MarinCore

final class BottleTests: XCTestCase {
    func testTheFirstBottleIsNeverEmpty() {
        for seed in 0 ..< 200 {
            var random = SeededRandom(seed: UInt64(seed))
            let bottle = Fishing.nextCatch(for: Voyage(), random: &random)
            XCTAssertFalse(bottle.isEmpty)
            XCTAssertEqual(bottle.id, BottleLibrary.firstVoyage[0].id)
        }
    }

    func testKeepingABottleAddsItsWordsOnce() {
        var voyage = Voyage()
        let bottle = BottleLibrary.firstVoyage[0]
        XCTAssertEqual(voyage.keep(bottle), bottle.words)
        XCTAssertEqual(voyage.vocabulary, bottle.words)
        XCTAssertEqual(voyage.keep(bottle), [])
        XCTAssertEqual(voyage.vocabulary, bottle.words)
        XCTAssertEqual(voyage.foundBottles, [bottle.id])
    }

    func testAnEmptyBottleGivesNoWords() {
        var voyage = Voyage()
        XCTAssertEqual(voyage.keep(.empty), [])
        XCTAssertEqual(voyage.vocabulary, [])
        XCTAssertEqual(voyage.emptyBottles, 1)
    }

    func testBottlesComeInOrderAndEveryOneCanBeFound() {
        var voyage = Voyage()
        var random = SeededRandom(seed: 99)
        var order: [String] = []
        var casts = 0
        while voyage.foundBottles.count < BottleLibrary.firstVoyage.count && casts < 500 {
            let bottle = Fishing.nextCatch(for: voyage, random: &random)
            if !bottle.isEmpty { order.append(bottle.id) }
            voyage.keep(bottle)
            casts += 1
        }
        XCTAssertEqual(order, BottleLibrary.firstVoyage.map(\.id))
        let allWords = BottleLibrary.firstVoyage.flatMap(\.words)
        XCTAssertEqual(voyage.vocabulary, allWords)
        XCTAssertEqual(Set(allWords).count, allWords.count, "a placeholder word is repeated")
    }

    func testOnceEverythingIsFoundBottlesAreEmpty() {
        var voyage = Voyage()
        for bottle in BottleLibrary.firstVoyage { voyage.keep(bottle) }
        var random = SeededRandom(seed: 5)
        for _ in 0 ..< 20 {
            XCTAssertTrue(Fishing.nextCatch(for: voyage, random: &random).isEmpty)
        }
    }

    func testEmptyBottlesAreAReasonableShare() {
        var voyage = Voyage()
        voyage.keep(BottleLibrary.firstVoyage[0])
        var random = SeededRandom(seed: 2026)
        var empties = 0
        let casts = 4000
        for _ in 0 ..< casts where Fishing.nextCatch(for: voyage, random: &random).isEmpty {
            empties += 1
        }
        let share = Double(empties) / Double(casts)
        XCTAssertGreaterThan(share, 0.15)
        XCTAssertLessThan(share, 0.25)
    }

    func testTheWaitForABiteIsShort() {
        var random = SeededRandom(seed: 3)
        for _ in 0 ..< 200 {
            let delay = Fishing.biteDelay(random: &random)
            XCTAssertTrue((2.5 ... 6.0).contains(delay))
        }
    }

    func testAVoyageCanBeSavedAndLoaded() throws {
        var voyage = Voyage()
        voyage.keep(BottleLibrary.firstVoyage[0])
        voyage.keep(.empty)
        let data = try JSONEncoder().encode(voyage)
        XCTAssertEqual(try JSONDecoder().decode(Voyage.self, from: data), voyage)
    }
}
