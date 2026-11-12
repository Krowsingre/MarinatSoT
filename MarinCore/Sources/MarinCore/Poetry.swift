import Foundation

/// A curated poetic structure: how many lines, and how long each may be.
public struct PoemForm: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var lines: Int
    public var minWords: Int
    public var maxWords: Int
    /// How many poems must be written before this form opens.
    public var poemsNeeded: Int
    /// How many words must be found before this form opens.
    public var wordsNeeded: Int
}

/// A poem the voyager has composed and kept.
public struct Poem: Equatable, Codable, Sendable, Identifiable {
    public var id: String
    public var form: String
    public var lines: [[String]]

    public init(id: String, form: String, lines: [[String]]) {
        self.id = id
        self.form = form
        self.lines = lines
    }

    public var text: String {
        lines.map { $0.joined(separator: " ") }.joined(separator: "\n")
    }
}

/// The rules of composing. The player arranges words they have found into a curated structure.
/// It is not free typing, and it is not filling blanks in a ready-made sentence: the structure
/// gives only the shape, and every word and its place is the player's choice.
public enum Poetry {
    /// Small joining words that are always to hand. PLACEHOLDER list.
    public static let smallWords = [
        "the", "a", "of", "in", "and", "is", "on", "to", "my",
        "where", "under", "beyond", "like", "no", "all", "still"
    ]

    /// PLACEHOLDER forms and thresholds. Composing starts at a single line and grows.
    public static let forms: [PoemForm] = [
        PoemForm(id: "one", name: "A single line", lines: 1, minWords: 2, maxWords: 6, poemsNeeded: 0, wordsNeeded: 0),
        PoemForm(id: "two", name: "Two lines", lines: 2, minWords: 2, maxWords: 6, poemsNeeded: 3, wordsNeeded: 9),
        PoemForm(id: "three", name: "Three lines", lines: 3, minWords: 2, maxWords: 6, poemsNeeded: 8, wordsNeeded: 18),
        PoemForm(id: "four", name: "Four lines", lines: 4, minWords: 2, maxWords: 7, poemsNeeded: 15, wordsNeeded: 27)
    ]

    /// The forms open to a voyager. The single line is always open.
    public static func unlockedForms(for voyage: Voyage) -> [PoemForm] {
        forms.filter { voyage.poems.count >= $0.poemsNeeded && voyage.vocabulary.count >= $0.wordsNeeded }
    }

    public enum Problem: Equatable, Sendable {
        case wrongLineCount
        case lineTooShort(Int)
        case lineTooLong(Int)
        case unknownWord(String)
        /// A line made only of small joining words.
        case lineNeedsFoundWord(Int)
    }

    /// Says what, if anything, stops these lines from being kept as a poem in this form.
    public static func problem(with lines: [[String]], form: PoemForm, voyage: Voyage) -> Problem? {
        guard lines.count == form.lines else { return .wrongLineCount }
        for (index, line) in lines.enumerated() {
            if line.count < form.minWords { return .lineTooShort(index) }
            if line.count > form.maxWords { return .lineTooLong(index) }
            for word in line where !voyage.vocabulary.contains(word) && !smallWords.contains(word) {
                return .unknownWord(word)
            }
            if !line.contains(where: { voyage.vocabulary.contains($0) }) {
                return .lineNeedsFoundWord(index)
            }
        }
        return nil
    }

    /// Keeps a poem in the voyage, if it is sound. Returns the poem, or nil if it could not be kept.
    @discardableResult
    public static func keep(lines: [[String]], form: PoemForm, in voyage: inout Voyage) -> Poem? {
        guard problem(with: lines, form: form, voyage: voyage) == nil else { return nil }
        let poem = Poem(id: "p\(voyage.poems.count + 1)", form: form.id, lines: lines)
        voyage.poems.append(poem)
        return poem
    }
}

/// How magical the world has become.
///
/// The magic of tall tales grows as the voyager's poetry accumulates. No single poem is a
/// trigger: what counts is how much has been written and how widely the found words are used.
public enum Magic {
    /// PLACEHOLDER tuning: the amount of writing at which the world is fully transformed.
    public static let fullAt = 24.0

    /// Every different poem counts by its lines, and every found word used in any poem counts a little.
    public static func points(for voyage: Voyage) -> Double {
        var seen: Set<String> = []
        var lines = 0
        var used: Set<String> = []
        for poem in voyage.poems where seen.insert(poem.text).inserted {
            lines += poem.lines.count
            for word in poem.lines.joined() where voyage.vocabulary.contains(word) {
                used.insert(word)
            }
        }
        return Double(lines) + 0.5 * Double(used.count)
    }

    /// 0 in an ordinary sea, 1 in a fully magical one.
    public static func level(for voyage: Voyage) -> Double {
        min(points(for: voyage) / fullAt, 1)
    }

    /// The found words the voyager has used most in their poems, most used first.
    /// These are what the magic takes its character from: it is the voyager's own tale.
    public static func favouriteWords(for voyage: Voyage, limit: Int = 4) -> [String] {
        var counts: [String: Int] = [:]
        for poem in voyage.poems {
            for word in poem.lines.joined() where voyage.vocabulary.contains(word) {
                counts[word, default: 0] += 1
            }
        }
        let ordered = counts.sorted { a, b in
            a.value != b.value ? a.value > b.value : a.key < b.key
        }
        return ordered.prefix(limit).map(\.key)
    }
}
