import SwiftUI
import SpriteKit

@main
struct MarinApp: App {
    var body: some Scene {
        WindowGroup {
            SeaView()
        }
    }
}

/// The main screen: the sea, filling the whole phone.
struct SeaView: View {
    @State private var scene = SeaScene(settings: SeaSettings.fromLaunchArguments())

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
    }
}
