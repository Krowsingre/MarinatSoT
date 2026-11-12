import SwiftUI
import MarinCore

/// A bottle that has just been landed, and the words it added.
struct Caught: Identifiable {
    let id = UUID()
    let bottle: Bottle
    let newWords: [String]
}

/// Connects the buttons on screen to the sea scene, and keeps what the voyager has gathered.
final class SeaController: ObservableObject {
    /// True while the line is in the water.
    @Published var isFishing = false
    /// True once a bottle has drifted onto the line.
    @Published var hasBite = false
    /// The part of the day, for the icon in the corner.
    @Published var phase: DayPhase = .day
    /// The bottle just landed, shown until the player keeps it.
    @Published var caught: Caught?
    /// The words and bottles gathered so far.
    @Published private(set) var voyage: Voyage

    let scene: SeaScene
    private var random = SeededRandom(seed: UInt64.random(in: 0 ... UInt64.max))
    private static let saveKey = "voyage.v1"

    init() {
        let settings = SeaSettings.fromLaunchArguments()
        voyage = SeaController.load()
        scene = SeaScene(settings: settings)
        isFishing = settings.startFishing
        scene.fishing = settings.startFishing
        scene.wantsSail = settings.startSailing && !settings.startFishing

        scene.onPhaseChange = { [weak self] phase in
            DispatchQueue.main.async { self?.phase = phase }
        }
        scene.onBite = { [weak self] in
            DispatchQueue.main.async { self?.hasBite = true }
        }
        scene.onCatch = { [weak self] in
            DispatchQueue.main.async { self?.land() }
        }

        if settings.demoCatch {
            let bottle = BottleLibrary.firstVoyage[0]
            caught = Caught(bottle: bottle, newWords: bottle.words)
        }
    }

    /// Called while the Sail button is held, and again when it is let go.
    func setSailing(_ sailing: Bool) {
        scene.wantsSail = sailing && !isFishing
    }

    /// Casts the line, or reels it in.
    func toggleFishing() {
        isFishing.toggle()
        scene.fishing = isFishing
        if isFishing {
            scene.wantsSail = false
        }
    }

    /// A hooked bottle has reached the boat: open it, keep its words, and save.
    private func land() {
        hasBite = false
        let bottle = Fishing.nextCatch(for: voyage, random: &random)
        let fresh = voyage.keep(bottle)
        save()
        caught = Caught(bottle: bottle, newWords: fresh)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(voyage) {
            UserDefaults.standard.set(data, forKey: SeaController.saveKey)
        }
    }

    private static func load() -> Voyage {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Voyage.self, from: data) else {
            return Voyage()
        }
        return saved
    }
}
