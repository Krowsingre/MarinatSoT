import XCTest
@testable import MarinCore

final class PoetryTests: XCTestCase {
    private func voyage(bottles: Int) -> Voyage {
        var voyage = Voyage()
        for bottle in BottleLibrary.firstVoyage.prefix(bottles) { voyage.keep(bottle) }
        return voyage
    }

    private var oneLine: PoemForm { Poetry.forms[0] }

    func testComposingStartsAtASingleLine() {
        let forms = Poetry.unlockedForms(for: Voyage())
        XCTAssertEqual(forms.map(\.id), ["one"])
        XCTAssertEqual(forms[0].lines, 1)
    }

    func testLongerFormsOpenWithWordsAndPractice() {
        var voyage = voyage(bottles: 3)
        XCTAssertEqual(Poetry.unlockedForms(for: voyage).count, 1)
        for index in 0 ..< 3 {
            XCTAssertNotNil(Poetry.keep(lines: [["the", "tide", ["keeps", "salt", "gull"][index]]], form: oneLine, in: &voyage))
        }
        XCTAssertEqual(Poetry.unlockedForms(for: voyage).map(\.id), ["one", "two"])
    }

    func testASoundLineCanBeKept() {
        var voyage = voyage(bottles: 1)
        let poem = Poetry.keep(lines: [["the", "tide", "keeps", "salt"]], form: oneLine, in: &voyage)
        XCTAssertEqual(poem?.text, "the tide keeps salt")
        XCTAssertEqual(voyage.poems.count, 1)
    }

    func testProblemsAreCaught() {
        let voyage = voyage(bottles: 1)
        XCTAssertEqual(Poetry.problem(with: [["tide"]], form: oneLine, voyage: voyage), .lineTooShort(0))
        XCTAssertEqual(Poetry.problem(with: [["the", "tide", "the", "tide", "the", "tide", "the"]], form: oneLine, voyage: voyage),
                       .lineTooLong(0))
        XCTAssertEqual(Poetry.problem(with: [["the", "dragon"]], form: oneLine, voyage: voyage), .unknownWord("dragon"))
        XCTAssertEqual(Poetry.problem(with: [["the", "of", "and"]], form: oneLine, voyage: voyage), .lineNeedsFoundWord(0))
        XCTAssertEqual(Poetry.problem(with: [["the", "tide"], ["salt", "keeps"]], form: oneLine, voyage: voyage), .wrongLineCount)
        XCTAssertNil(Poetry.problem(with: [["salt", "tide"]], form: oneLine, voyage: voyage))
    }

    func testAnUnsoundPoemIsNotKept() {
        var voyage = voyage(bottles: 1)
        XCTAssertNil(Poetry.keep(lines: [["the", "dragon"]], form: oneLine, in: &voyage))
        XCTAssertTrue(voyage.poems.isEmpty)
    }

    func testSmallWordsDoNotClashWithPlaceholderVocabulary() {
        let found = Set(BottleLibrary.firstVoyage.flatMap(\.words))
        XCTAssertTrue(found.isDisjoint(with: Poetry.smallWords))
    }
}

final class MagicTests: XCTestCase {
    private func voyageWithWords() -> Voyage {
        var voyage = Voyage()
        for bottle in BottleLibrary.firstVoyage { voyage.keep(bottle) }
        return voyage
    }

    func testAnOrdinarySeaHasNoMagic() {
        XCTAssertEqual(Magic.level(for: Voyage()), 0)
        XCTAssertEqual(Magic.level(for: voyageWithWords()), 0, "words alone, unwritten, bring no magic")
    }

    func testMagicGrowsAsPoemsAccumulate() {
        var voyage = voyageWithWords()
        var last = 0.0
        let lines: [[String]] = [
            ["the", "tide", "keeps"], ["salt", "and", "gull"], ["my", "boat", "remembers"],
            ["grey", "moon", "waits"], ["the", "lantern", "is", "far"]
        ]
        for line in lines {
            Poetry.keep(lines: [line], form: Poetry.forms[0], in: &voyage)
            let level = Magic.level(for: voyage)
            XCTAssertGreaterThan(level, last)
            last = level
        }
        XCTAssertLessThan(last, 1, "a handful of lines is not yet a fully magical sea")
    }

    func testNoSinglePoemIsEnough() {
        var voyage = voyageWithWords()
        Poetry.keep(lines: [["tide", "salt", "gull", "boat", "moon", "sea"]], form: Poetry.forms[0], in: &voyage)
        XCTAssertLessThan(Magic.level(for: voyage), 0.25)
    }

    func testRepeatingTheSamePoemAddsNothing() {
        var voyage = voyageWithWords()
        Poetry.keep(lines: [["the", "tide", "keeps"]], form: Poetry.forms[0], in: &voyage)
        let once = Magic.level(for: voyage)
        for _ in 0 ..< 30 {
            Poetry.keep(lines: [["the", "tide", "keeps"]], form: Poetry.forms[0], in: &voyage)
        }
        XCTAssertEqual(Magic.level(for: voyage), once)
    }

    func testMagicNeverPassesFull() {
        var voyage = voyageWithWords()
        let words = voyage.vocabulary
        for index in 0 ..< 80 {
            let line = ["the", words[index % words.count], "of", words[(index * 7 + 3) % words.count], String(index % 2 == 0 ? "and" : "still")]
            Poetry.keep(lines: [line], form: Poetry.forms[0], in: &voyage)
        }
        XCTAssertEqual(Magic.level(for: voyage), 1)
    }

    func testTheMagicTakesItsCharacterFromTheVoyagersOwnWords() {
        var voyage = voyageWithWords()
        Poetry.keep(lines: [["the", "moon", "waits"]], form: Poetry.forms[0], in: &voyage)
        Poetry.keep(lines: [["moon", "and", "lantern"]], form: Poetry.forms[0], in: &voyage)
        Poetry.keep(lines: [["my", "moon", "lantern"]], form: Poetry.forms[0], in: &voyage)
        XCTAssertEqual(Magic.favouriteWords(for: voyage, limit: 2), ["moon", "lantern"])
        XCTAssertEqual(Magic.favouriteWords(for: Voyage()), [])
    }

    func testAnOlderSaveWithoutPoemsStillLoads() throws {
        let old = #"{"vocabulary":["tide"],"foundBottles":["b01"],"emptyBottles":2}"#
        let voyage = try JSONDecoder().decode(Voyage.self, from: Data(old.utf8))
        XCTAssertEqual(voyage.vocabulary, ["tide"])
        XCTAssertEqual(voyage.emptyBottles, 2)
        XCTAssertTrue(voyage.poems.isEmpty)
    }
}
