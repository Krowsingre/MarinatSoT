import SwiftUI
import MarinCore

/// The three places reached from the top-right icons.
enum Panel: String, Identifiable {
    case journal, poetry, chart

    var id: String { rawValue }

    var title: String {
        switch self {
        case .journal: return "Journal"
        case .poetry: return "Poetry"
        case .chart: return "Chart"
        }
    }
}

private enum Parchment {
    static let light = Color(red: 0.98, green: 0.94, blue: 0.82)
    static let dark = Color(red: 0.93, green: 0.85, blue: 0.69)
    static let edge = Color(red: 0.55, green: 0.42, blue: 0.28)
    static let ink = Color(red: 0.24, green: 0.19, blue: 0.15)
    static let wash = Color(red: 0.42, green: 0.62, blue: 0.84)

    static var fill: LinearGradient {
        LinearGradient(colors: [light, dark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// The controls laid over the sea.
struct HUD: View {
    @ObservedObject var controller: SeaController
    @Binding var panel: Panel?

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                TimeBadge(phase: controller.phase)
                Spacer()
                HStack(spacing: 10) {
                    IconButton(label: "Journal") { Image(systemName: "book").font(.system(size: 20)) } action: { panel = .journal }
                    IconButton(label: "Poetry") { QuillIcon().frame(width: 24, height: 24) } action: { panel = .poetry }
                    IconButton(label: "Chart") { Image(systemName: "safari").font(.system(size: 21)) } action: { panel = .chart }
                }
            }
            Spacer()
            HStack(alignment: .bottom) {
                SailButton(controller: controller)
                Spacer()
                CastButton(controller: controller)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

/// The sun or moon in the corner, showing the time of day.
private struct TimeBadge: View {
    let phase: DayPhase

    private var symbol: String {
        switch phase {
        case .dawn: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .dusk: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 22))
            .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.48))
            .frame(width: 50, height: 50)
            .background(Circle().fill(Color(red: 0.24, green: 0.32, blue: 0.56).opacity(0.78)))
            .accessibilityLabel("Time of day: \(phase.rawValue)")
    }
}

/// A small square parchment button.
private struct IconButton<Icon: View>: View {
    let label: String
    @ViewBuilder let icon: () -> Icon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon()
                .foregroundStyle(Parchment.ink)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Parchment.fill)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Parchment.edge.opacity(0.55), lineWidth: 1.2))
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// The shape shared by the two main buttons.
private struct Pill<Icon: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        HStack(spacing: 10) {
            icon()
                .foregroundStyle(Parchment.ink)
                .frame(width: 34, height: 38)
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular, design: .serif))
                }
                Capsule()
                    .fill(Parchment.wash.opacity(0.7))
                    .frame(width: 58, height: 2)
                    .padding(.top, 2)
            }
            .foregroundStyle(Parchment.ink)
        }
        .padding(.horizontal, 20)
        .frame(height: 62)
        .background(
            Capsule()
                .fill(Parchment.fill)
                .overlay(Capsule().stroke(Parchment.edge.opacity(0.55), lineWidth: 1.4))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
        )
    }
}

/// Hold to sail. The longer it is held, the farther the boat travels.
private struct SailButton: View {
    @ObservedObject var controller: SeaController
    @State private var held = false

    var body: some View {
        Pill(title: "Sail", subtitle: "Hold to Sail") {
            Image(systemName: "sailboat.fill").font(.system(size: 26))
        }
        .scaleEffect(held ? 0.95 : 1)
        .opacity(controller.isFishing ? 0.45 : 1)
        .animation(.easeOut(duration: 0.15), value: held)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !held {
                        held = true
                        controller.setSailing(true)
                    }
                }
                .onEnded { _ in
                    held = false
                    controller.setSailing(false)
                }
        )
        .accessibilityLabel("Sail. Hold to sail.")
    }
}

/// Tap to cast the line; tap again to reel it in.
private struct CastButton: View {
    @ObservedObject var controller: SeaController

    var body: some View {
        Button {
            controller.toggleFishing()
        } label: {
            Pill(title: controller.isFishing ? "Reel In" : "Cast Line", subtitle: nil) {
                HookIcon()
                    .stroke(Parchment.ink, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 34)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A fishing hook.
private struct HookIcon: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.addEllipse(in: CGRect(x: point(0.60, 0.0).x, y: point(0.60, 0.0).y,
                                   width: rect.width * 0.24, height: rect.width * 0.24))
        path.move(to: point(0.72, 0.16))
        path.addLine(to: point(0.72, 0.66))
        path.addQuadCurve(to: point(0.44, 0.94), control: point(0.72, 0.94))
        path.addQuadCurve(to: point(0.16, 0.66), control: point(0.16, 0.94))
        path.addLine(to: point(0.16, 0.52))
        path.move(to: point(0.16, 0.52))
        path.addLine(to: point(0.36, 0.64))
        return path
    }
}

/// A quill pen.
private struct QuillIcon: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: w * 0.30, y: h * 0.74))
                    path.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.06), control: CGPoint(x: w * 0.22, y: h * 0.22))
                    path.addQuadCurve(to: CGPoint(x: w * 0.30, y: h * 0.74), control: CGPoint(x: w * 0.86, y: h * 0.66))
                }
                .fill(Parchment.ink.opacity(0.85))
                Path { path in
                    path.move(to: CGPoint(x: w * 0.08, y: h * 0.96))
                    path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.38))
                }
                .stroke(Parchment.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
        }
    }
}

/// A placeholder page for a part of the game that is not built yet.
struct PanelCard: View {
    let panel: Panel
    let close: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture(perform: close)
            VStack(spacing: 12) {
                Text(panel.title)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                Text("This part of the game is not built yet.")
                    .font(.system(size: 15, design: .serif))
                Button("Close", action: close)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .padding(.top, 6)
            }
            .foregroundStyle(Parchment.ink)
            .padding(.horizontal, 44)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Parchment.fill)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Parchment.edge.opacity(0.55), lineWidth: 1.4))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
            )
        }
    }
}
