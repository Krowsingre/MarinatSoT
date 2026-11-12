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
        }
        .onAppear {
            if controller.opensComposing {
                panel = .poetry
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
