import SwiftUI
import SpriteKit

@main
struct MarinApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
    }
}

/// The whole app: the sea, with either the home screen or the game's controls laid over it.
struct GameView: View {
    @StateObject private var controller = SeaController()
    @State private var panel: Panel?
    @State private var paused = false

    var body: some View {
        ZStack {
            SpriteView(scene: controller.scene)
                .ignoresSafeArea()

            if controller.atHome {
                HomeView(controller: controller)
                    .transition(.opacity)
            } else {
                game
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: controller.atHome)
        .onAppear {
            if controller.opensComposing {
                panel = .poetry
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    /// The controls and pages shown while playing.
    private var game: some View {
        ZStack {
            HUD(controller: controller, panel: $panel) {
                paused = true
            }

            if let panel {
                if panel == .poetry {
                    ComposeView(controller: controller) {
                        self.panel = nil
                    }
                } else {
                    PanelCard(panel: panel, poems: controller.voyage.poems) {
                        self.panel = nil
                    }
                }
            }

            if let caught = controller.caught {
                CatchCard(caught: caught) {
                    controller.caught = nil
                }
            }

            if paused {
                PauseCard {
                    paused = false
                } leave: {
                    paused = false
                    panel = nil
                    controller.returnHome()
                }
            }
        }
    }
}
