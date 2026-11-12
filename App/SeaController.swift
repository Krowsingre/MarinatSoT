import SwiftUI
import MarinCore

/// Connects the buttons on screen to the sea scene.
final class SeaController: ObservableObject {
    /// True while the line is in the water.
    @Published var isFishing = false
    /// The part of the day, for the icon in the corner.
    @Published var phase: DayPhase = .day

    let scene: SeaScene

    init() {
        let settings = SeaSettings.fromLaunchArguments()
        scene = SeaScene(settings: settings)
        isFishing = settings.startFishing
        scene.fishing = settings.startFishing
        scene.wantsSail = settings.startSailing && !settings.startFishing
        scene.onPhaseChange = { [weak self] phase in
            DispatchQueue.main.async {
                self?.phase = phase
            }
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
}
