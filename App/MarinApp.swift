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

/// The main screen: the sea, with the controls laid over it.
struct GameView: View {
    @StateObject private var controller = SeaController()
    @State private var panel: Panel?

    var body: some View {
        ZStack {
            SpriteView(scene: controller.scene)
                .ignoresSafeArea()

            HUD(controller: controller, panel: $panel)

            if let panel {
                PanelCard(panel: panel, words: controller.voyage.vocabulary) {
                    self.panel = nil
                }
            }

            if let caught = controller.caught {
                CatchCard(caught: caught) {
                    controller.caught = nil
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
