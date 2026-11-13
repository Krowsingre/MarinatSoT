import SwiftUI
import MarinCore

private enum Paper {
    static let light = Color(red: 0.99, green: 0.93, blue: 0.78)
    static let dark = Color(red: 0.94, green: 0.82, blue: 0.62)
    static let edge = Color(red: 0.55, green: 0.40, blue: 0.25)
    static let ink = Color(red: 0.13, green: 0.12, blue: 0.20)
    static let glow = Color(red: 1.0, green: 0.68, blue: 0.26)
    static let cream = Color(red: 1.0, green: 0.96, blue: 0.86)
    static let wash = Color(red: 0.42, green: 0.62, blue: 0.84)

    static var fill: LinearGradient {
        LinearGradient(colors: [light, dark], startPoint: .top, endPoint: .bottom)
    }
}

/// The pages that the home screen's buttons open.
private enum HomeSheet: String, Identifiable {
    case newGame, load, settings, credits, accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newGame: return "New Game"
        case .load: return "Load"
        case .settings: return "Settings"
        case .credits: return "Credits"
        case .accessibility: return "Accessibility"
        }
    }
}

/// The home screen: the creator's painted title scene, with the main menu over the water.
///
/// Only the buttons that are needed are shown. Continue and Load appear once there is a voyage
/// to return to. There is no Quit button: an iPhone app does not close itself.
///
/// The painting is a still picture for now. The buttons are drawn in code until separate
/// painted button artwork is available.
struct HomeView: View {
    @ObservedObject var controller: SeaController
    @State private var sheet: HomeSheet?

    @AppStorage("settings.music") private var music = true
    @AppStorage("settings.sounds") private var sounds = true
    @AppStorage("access.reduceMotion") private var reduceMotion = false

    var body: some View {
        ZStack {
            // The painting fills the screen. Its top edge is kept, so the title is never cut off.
            GeometryReader { proxy in
                Image("HomeBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    .clipped()
            }
            .ignoresSafeArea()
            .accessibilityLabel("Marin and the Sea of Tales")

            VStack(spacing: 0) {
                Spacer()
                menu
                HStack(spacing: 18) {
                    footerButton("Credits", symbol: "book", sheet: .credits)
                    Rectangle().fill(Paper.cream.opacity(0.7)).frame(width: 1, height: 14)
                    footerButton("Accessibility", symbol: "figure.arms.open", sheet: .accessibility)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 10)

            if let sheet {
                sheetCard(sheet)
            }
        }
    }

    // MARK: - Menu

    private var menu: some View {
        HStack(spacing: 10) {
            if controller.hasVoyage {
                menuButton("Continue", wide: true) {
                    controller.continueVoyage()
                }
            }
            menuButton("New Game", wide: !controller.hasVoyage) {
                if controller.hasVoyage {
                    sheet = .newGame
                } else {
                    controller.startNewVoyage()
                }
            }
            if controller.hasVoyage {
                menuButton("Load") { sheet = .load }
            }
            menuButton("Settings") { sheet = .settings }
        }
    }

    private func menuButton(_ label: String, wide: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 19, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Paper.ink)
                .padding(.horizontal, wide ? 30 : 22)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Paper.fill)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Paper.glow, lineWidth: 2.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Paper.glow.opacity(0.55), lineWidth: 1)
                                .padding(4)
                        )
                        .shadow(color: Paper.glow.opacity(0.85), radius: 8)
                )
        }
        .buttonStyle(.plain)
    }

    private func footerButton(_ label: String, symbol: String, sheet target: HomeSheet) -> some View {
        Button {
            sheet = target
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(label)
            }
            .font(.system(size: 14, design: .serif))
            .foregroundStyle(Paper.cream)
            .shadow(color: .black.opacity(0.7), radius: 3)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pages

    private func sheetCard(_ current: HomeSheet) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { sheet = nil }

            VStack(spacing: 12) {
                Text(current.title)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                sheetBody(current)
            }
            .font(.system(size: 16, design: .serif))
            .foregroundStyle(Paper.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .padding(.vertical, 22)
            .frame(maxWidth: 470)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Paper.fill)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Paper.edge.opacity(0.55), lineWidth: 1.4))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 3)
            )
        }
    }

    @ViewBuilder
    private func sheetBody(_ current: HomeSheet) -> some View {
        switch current {
        case .newGame:
            Text("Marin already has a voyage under way, with \(summary). Starting again will lose it.")
            HStack(spacing: 14) {
                cardButton("Keep my voyage") { sheet = nil }
                cardButton("Start again", strong: true) {
                    sheet = nil
                    controller.startNewVoyage()
                }
            }

        case .load:
            if controller.hasVoyage {
                Button {
                    sheet = nil
                    controller.continueVoyage()
                } label: {
                    VStack(spacing: 3) {
                        Text("Marin's voyage")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                        Text(summary)
                            .font(.system(size: 13, design: .serif))
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Paper.wash.opacity(0.28)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Paper.edge.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else {
                Text("There is no saved voyage yet.")
            }
            Text("The game keeps one voyage for now. More places to save will come later.")
                .font(.system(size: 12, design: .serif))
                .italic()
            cardButton("Close") { sheet = nil }

        case .settings:
            VStack(spacing: 8) {
                Toggle("Music", isOn: $music)
                Toggle("Sound effects", isOn: $sounds)
            }
            .tint(Paper.wash)
            .frame(maxWidth: 260)
            Text("These are remembered, but there is no sound in the game yet.")
                .font(.system(size: 12, design: .serif))
                .italic()
            cardButton("Close") { sheet = nil }

        case .credits:
            Text("Marin and the Sea of Tales")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .italic()
            Text("Created by Kenn A Welch")
            Text("Krowsingre Publishing LLC")
            Text(versionLine)
                .font(.system(size: 12, design: .serif))
                .opacity(0.7)
            cardButton("Close") { sheet = nil }

        case .accessibility:
            Toggle("Reduce motion", isOn: $reduceMotion)
                .tint(Paper.wash)
                .frame(maxWidth: 260)
                .onChange(of: reduceMotion) { _, value in
                    controller.setReduceMotion(value)
                }
            Text("Calms the waves and removes flashes of lightning. More options will come later.")
                .font(.system(size: 12, design: .serif))
                .italic()
            cardButton("Close") { sheet = nil }
        }
    }

    private var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return "Version \(version) (\(build))"
    }

    private var summary: String {
        let words = controller.voyage.vocabulary.count
        let poems = controller.voyage.poems.count
        return "\(words) \(words == 1 ? "word" : "words") and \(poems) \(poems == 1 ? "poem" : "poems")"
    }

    private func cardButton(_ label: String, strong: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Capsule().fill(Paper.wash.opacity(strong ? 0.5 : 0.22)))
                .overlay(Capsule().stroke(Paper.edge.opacity(0.35), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
}
