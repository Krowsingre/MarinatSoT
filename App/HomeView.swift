import SwiftUI
import MarinCore

private enum Paper {
    static let light = Color(red: 0.98, green: 0.93, blue: 0.80)
    static let dark = Color(red: 0.92, green: 0.82, blue: 0.64)
    static let edge = Color(red: 0.55, green: 0.40, blue: 0.25)
    static let ink = Color(red: 0.22, green: 0.17, blue: 0.13)
    static let glow = Color(red: 1.0, green: 0.66, blue: 0.28)
    static let navy = Color(red: 0.09, green: 0.13, blue: 0.30)
    static let cream = Color(red: 1.0, green: 0.96, blue: 0.86)
    static let wash = Color(red: 0.42, green: 0.62, blue: 0.84)

    static var fill: LinearGradient {
        LinearGradient(colors: [light, dark], startPoint: .top, endPoint: .bottom)
    }
}

/// The pages that the home screen's buttons open.
private enum HomeSheet: String, Identifiable {
    case newGame, load, settings, quit, credits, accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newGame: return "New Game"
        case .load: return "Load"
        case .settings: return "Settings"
        case .quit: return "Quit"
        case .credits: return "Credits"
        case .accessibility: return "Accessibility"
        }
    }
}

/// The home screen: the title over the living sea, with the main menu along the bottom.
///
/// The sea behind it is the game's own scene, already moving. The title lettering, the whale
/// in the stars and the buttons are placeholders for painted and animated artwork.
struct HomeView: View {
    @ObservedObject var controller: SeaController
    @State private var sheet: HomeSheet?
    @State private var drift = false

    @AppStorage("settings.music") private var music = true
    @AppStorage("settings.sounds") private var sounds = true
    @AppStorage("access.reduceMotion") private var reduceMotion = false

    private var isDark: Bool { controller.phase == .night }
    private var titleColour: Color { isDark ? Paper.cream : Paper.navy }

    var body: some View {
        ZStack {
            // A soft wash so the title and menu read clearly over the sea.
            LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.28)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    title
                    Spacer()
                    WhaleInTheStars()
                        .frame(width: 250, height: 110)
                        .opacity(isDark ? 0.95 : (controller.phase == .day ? 0.35 : 0.75))
                        .offset(y: drift ? -4 : 5)
                        .padding(.top, 6)
                }
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
            .padding(.top, 10)
            .padding(.bottom, 12)

            if let sheet {
                sheetCard(sheet)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    // MARK: - Title

    private var title: some View {
        VStack(spacing: -14) {
            Image(systemName: "sparkle")
                .font(.system(size: 16))
                .foregroundStyle(Paper.glow)
                .padding(.bottom, 12)
            Text("Marin")
                .font(.custom("SnellRoundhand-Black", size: 74))
            Text("and the")
                .font(.custom("SnellRoundhand-Bold", size: 24))
                .padding(.vertical, 6)
            Text("Sea of Tales")
                .font(.custom("SnellRoundhand-Black", size: 60))
        }
        .foregroundStyle(titleColour)
        .shadow(color: (isDark ? Color.black : Paper.cream).opacity(0.75), radius: 6)
        .padding(.leading, 26)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Marin and the Sea of Tales")
    }

    // MARK: - Menu

    private var menu: some View {
        HStack(spacing: 8) {
            menuButton("Continue", highlighted: controller.hasVoyage, dimmed: !controller.hasVoyage) {
                controller.continueVoyage()
            }
            menuButton("New Game", highlighted: !controller.hasVoyage) {
                if controller.hasVoyage {
                    sheet = .newGame
                } else {
                    controller.startNewVoyage()
                }
            }
            menuButton("Load") { sheet = .load }
            menuButton("Settings") { sheet = .settings }
            menuButton("Quit") { sheet = .quit }
        }
    }

    private func menuButton(_ label: String, highlighted: Bool = false, dimmed: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 19, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Paper.ink)
                .padding(.horizontal, highlighted ? 26 : 20)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Paper.fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(highlighted ? Paper.glow : Paper.edge.opacity(0.6),
                                        lineWidth: highlighted ? 2.4 : 1.2)
                        )
                        .shadow(color: highlighted ? Paper.glow.opacity(0.9) : .black.opacity(0.25),
                                radius: highlighted ? 9 : 3, y: highlighted ? 0 : 2)
                )
        }
        .buttonStyle(.plain)
        .disabled(dimmed)
        .opacity(dimmed ? 0.55 : 1)
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
            .shadow(color: .black.opacity(0.6), radius: 3)
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

        case .quit:
            Text("Marin's voyage is saved as she goes.")
            Text("To leave, swipe up from the bottom of the screen. An iPhone app is not allowed to close itself.")
                .font(.system(size: 13, design: .serif))
            cardButton("Stay") { sheet = nil }

        case .credits:
            Text("Marin and the Sea of Tales")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .italic()
            Text("Created by Kenn A Welch")
            Text("Krowsingre Publishing LLC")
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
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

/// A whale drawn in the sky as a constellation. Placeholder for painted, animated artwork.
private struct WhaleInTheStars: View {
    private let outline: [CGPoint] = [
        CGPoint(x: 0.02, y: 0.44), CGPoint(x: 0.10, y: 0.30), CGPoint(x: 0.25, y: 0.21),
        CGPoint(x: 0.45, y: 0.21), CGPoint(x: 0.62, y: 0.29), CGPoint(x: 0.76, y: 0.41),
        CGPoint(x: 0.86, y: 0.36), CGPoint(x: 0.97, y: 0.14), CGPoint(x: 0.93, y: 0.38),
        CGPoint(x: 1.00, y: 0.54), CGPoint(x: 0.86, y: 0.50), CGPoint(x: 0.74, y: 0.58),
        CGPoint(x: 0.55, y: 0.68), CGPoint(x: 0.35, y: 0.71), CGPoint(x: 0.16, y: 0.63),
        CGPoint(x: 0.04, y: 0.53)
    ]
    private let fin: [CGPoint] = [
        CGPoint(x: 0.33, y: 0.70), CGPoint(x: 0.40, y: 0.94), CGPoint(x: 0.48, y: 0.69)
    ]

    var body: some View {
        Canvas { context, size in
            func place(_ point: CGPoint) -> CGPoint {
                CGPoint(x: point.x * size.width, y: point.y * size.height)
            }
            var body = Path()
            body.addLines(outline.map(place))
            body.closeSubpath()
            var flipper = Path()
            flipper.addLines(fin.map(place))

            let line = GraphicsContext.Shading.color(.white.opacity(0.75))
            context.stroke(body, with: line, lineWidth: 1.1)
            context.stroke(flipper, with: line, lineWidth: 1.1)

            for point in (outline + fin).map(place) {
                let halo = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: halo), with: .color(.white.opacity(0.22)))
                let star = CGRect(x: point.x - 1.8, y: point.y - 1.8, width: 3.6, height: 3.6)
                context.fill(Path(ellipseIn: star), with: .color(.white))
            }
            // The eye.
            let eye = place(CGPoint(x: 0.13, y: 0.42))
            context.fill(Path(ellipseIn: CGRect(x: eye.x - 1.5, y: eye.y - 1.5, width: 3, height: 3)),
                         with: .color(.white.opacity(0.9)))
        }
        .shadow(color: Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.9), radius: 5)
        .accessibilityHidden(true)
    }
}
