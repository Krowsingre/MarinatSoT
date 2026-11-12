import Foundation

/// A bottle fished from the sea. It holds a letter, and the letter gives words.
/// An empty bottle holds nothing, and leaves a blank page for free writing.
public struct Bottle: Equatable, Codable, Sendable, Identifiable {
    public var id: String
    public var letter: String
    public var words: [String]

    public init(id: String, letter: String, words: [String]) {
        self.id = id
        self.letter = letter
        self.words = words
    }

    public var isEmpty: Bool { words.isEmpty }

    public static let empty = Bottle(id: "empty", letter: "", words: [])
}

/// The bottles that can be found.
public enum BottleLibrary {
    /// PLACEHOLDER CONTENT. These letters and words exist only so the game can be played
    /// while it is being built. The real letters are the creator's to write.
    public static let firstVoyage: [Bottle] = [
        Bottle(id: "b01", letter: "The tide keeps what it is given.", words: ["tide", "salt", "keeps"]),
        Bottle(id: "b02", letter: "A gull followed us past the last light.", words: ["gull", "light", "follows"]),
        Bottle(id: "b03", letter: "Small boats remember every harbor.", words: ["boat", "harbor", "remembers"]),
        Bottle(id: "b04", letter: "Under the grey water, something silver waits.", words: ["grey", "silver", "waits"]),
        Bottle(id: "b05", letter: "The wind carried a name out beyond the stones.", words: ["wind", "stone", "carries"]),
        Bottle(id: "b06", letter: "Hush now. The moon is hauling in her net.", words: ["moon", "net", "hush"]),
        Bottle(id: "b07", letter: "Far from home, the lantern still burns.", words: ["lantern", "home", "far"]),
        Bottle(id: "b08", letter: "Old songs drift where the deep begins.", words: ["song", "deep", "drifts"]),
        Bottle(id: "b09", letter: "Bright morning, and the sea as wide as a tale.", words: ["morning", "sea", "tale"]),
        Bottle(id: "b10", letter: "The shore is only where the waves rest.", words: ["shore", "wave", "rests"])
    ]
}

/// What a voyager has gathered so far. This is what gets saved.
public struct Voyage: Equatable, Codable, Sendable {
    /// Every word found, in the order it was found.
    public var vocabulary: [String] = []
    /// The bottles already found, by id.
    public var foundBottles: [String] = []
    /// How many empty bottles have come up.
    public var emptyBottles = 0
    /// The poems the voyager has composed and kept.
    public var poems: [Poem] = []

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case vocabulary, foundBottles, emptyBottles, poems
    }

    /// Loads a saved voyage. Anything missing from an older save starts empty.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        vocabulary = try values.decodeIfPresent([String].self, forKey: .vocabulary) ?? []
        foundBottles = try values.decodeIfPresent([String].self, forKey: .foundBottles) ?? []
        emptyBottles = try values.decodeIfPresent(Int.self, forKey: .emptyBottles) ?? 0
        poems = try values.decodeIfPresent([Poem].self, forKey: .poems) ?? []
    }

    /// Keeps a bottle: remembers it and adds its words. Returns the words that were new.
    @discardableResult
    public mutating func keep(_ bottle: Bottle) -> [String] {
        if bottle.isEmpty {
            emptyBottles += 1
            return []
        }
        if !foundBottles.contains(bottle.id) {
            foundBottles.append(bottle.id)
        }
        var fresh: [String] = []
        for word in bottle.words where !vocabulary.contains(word) {
            vocabulary.append(word)
            fresh.append(word)
        }
        return fresh
    }
}

/// The rules of fishing. There is no skill and no way to fail: cast, wait, and something comes.
public enum Fishing {
    /// How often a bottle comes up empty. A placeholder for "a reasonable percentage".
    public static let emptyChance = 0.2

    /// Decides what the next bottle is. The very first is never empty.
    public static func nextCatch(for voyage: Voyage,
                                 library: [Bottle] = BottleLibrary.firstVoyage,
                                 random: inout SeededRandom) -> Bottle {
        let remaining = library.filter { !voyage.foundBottles.contains($0.id) }
        guard let next = remaining.first else { return .empty }
        if voyage.foundBottles.isEmpty { return next }
        return random.unit() < emptyChance ? .empty : next
    }

    /// How long, in seconds, before something drifts to the line.
    public static func biteDelay(random: inout SeededRandom) -> Double {
        random.range(2.5, 6.0)
    }
}
