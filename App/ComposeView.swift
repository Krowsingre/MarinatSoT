import SwiftUI
import MarinCore

private enum Page {
    static let light = Color(red: 0.98, green: 0.94, blue: 0.82)
    static let dark = Color(red: 0.93, green: 0.85, blue: 0.69)
    static let edge = Color(red: 0.55, green: 0.42, blue: 0.28)
    static let ink = Color(red: 0.24, green: 0.19, blue: 0.15)
    static let wash = Color(red: 0.42, green: 0.62, blue: 0.84)

    static var fill: LinearGradient {
        LinearGradient(colors: [light, dark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Lays chips out left to right, wrapping onto new rows.
private struct Flow: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = usable(proposal.width)
        return CGSize(width: width, height: arrange(width: width, subviews: subviews).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                                  proposal: .unspecified)
        }
    }

    private func usable(_ width: CGFloat?) -> CGFloat {
        guard let width, width.isFinite, width > 0 else { return 300 }
        return width
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (points: [CGPoint], height: CGFloat) {
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (points, y + rowHeight)
    }
}

/// One word, as a small tile.
private struct Chip: View {
    let word: String
    var found = true

    var body: some View {
        Text(word)
            .font(.system(size: 16, weight: found ? .medium : .regular, design: .serif))
            .foregroundStyle(Page.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(found ? Page.wash.opacity(0.30) : Color.white.opacity(0.45))
            )
            .overlay(Capsule().stroke(Page.edge.opacity(0.30), lineWidth: 0.8))
    }
}

/// Where Marin composes a poem.
///
/// The form gives only the shape: how many lines, and how long each may be. Every word and
/// its place is chosen by the player from the words found at sea, with a few small joining
/// words always to hand. Nothing is typed, and no sentence is supplied to fill in.
struct ComposeView: View {
    @ObservedObject var controller: SeaController
    let close: () -> Void

    @State private var formID = Poetry.forms[0].id
    @State private var lines: [[String]] = [[]]
    @State private var active = 0

    private var forms: [PoemForm] { Poetry.unlockedForms(for: controller.voyage) }
    private var form: PoemForm { forms.first { $0.id == formID } ?? Poetry.forms[0] }
    private var problem: Poetry.Problem? {
        Poetry.problem(with: lines, form: form, voyage: controller.voyage)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: 18) {
                page
                Rectangle().fill(Page.edge.opacity(0.25)).frame(width: 1)
                bank
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Page.fill)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Page.edge.opacity(0.55), lineWidth: 1.4))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
            )
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
        }
        .foregroundStyle(Page.ink)
    }

    // MARK: - The poem

    private var page: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("A new poem")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                Spacer()
                if forms.count > 1 {
                    ForEach(forms) { option in
                        Button {
                            choose(option)
                        } label: {
                            Text(option.name)
                                .font(.system(size: 12, weight: option.id == form.id ? .semibold : .regular, design: .serif))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(option.id == form.id ? Page.wash.opacity(0.35) : Color.clear))
                                .overlay(Capsule().stroke(Page.edge.opacity(0.35), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ForEach(0 ..< form.lines, id: \.self) { index in
                lineRow(index)
            }

            Text(hint)
                .font(.system(size: 12, design: .serif))
                .italic()
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                Button("Close", action: close)
                Button("Start over") {
                    lines = Array(repeating: [], count: form.lines)
                    active = 0
                }
                Spacer()
                Button {
                    if controller.keepPoem(lines: lines, form: form) {
                        close()
                    }
                } label: {
                    Text("Keep this poem")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Page.wash.opacity(problem == nil ? 0.45 : 0.12)))
                }
                .disabled(problem != nil)
                .opacity(problem == nil ? 1 : 0.5)
            }
            .font(.system(size: 15, design: .serif))
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func lineRow(_ index: Int) -> some View {
        let words = index < lines.count ? lines[index] : []
        return HStack(alignment: .top, spacing: 8) {
            Text("\(index + 1)")
                .font(.system(size: 11, design: .serif))
                .opacity(0.5)
                .frame(width: 10)
                .padding(.top, 8)
            Flow(spacing: 5) {
                ForEach(Array(words.enumerated()), id: \.offset) { position, word in
                    Chip(word: word, found: controller.voyage.vocabulary.contains(word))
                        .onTapGesture { remove(at: position, from: index) }
                }
                if words.isEmpty {
                    Text("Tap words to place them here")
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .opacity(0.45)
                        .padding(.vertical, 5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(minHeight: 40)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(index == active ? 0.42 : 0.16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Page.wash.opacity(index == active ? 0.9 : 0), lineWidth: 1.2)
        )
        .contentShape(Rectangle())
        .onTapGesture { active = index }
    }

    private var hint: String {
        switch problem {
        case .none:
            return "This can be kept. Tap a word in the poem to take it out."
        case .lineTooShort(let index):
            return form.lines == 1
                ? "A line takes \(form.minWords) to \(form.maxWords) words."
                : "Line \(index + 1) needs at least \(form.minWords) words."
        case .lineTooLong(let index):
            return "Line \(index + 1) is full at \(form.maxWords) words."
        case .lineNeedsFoundWord(let index):
            return form.lines == 1
                ? "The line needs at least one word from the sea."
                : "Line \(index + 1) needs at least one word from the sea."
        case .unknownWord, .wrongLineCount:
            return "Each line takes \(form.minWords) to \(form.maxWords) words."
        }
    }

    // MARK: - The words

    private var bank: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Words from the sea")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                if controller.voyage.vocabulary.isEmpty {
                    Text("Marin has no words yet. Cast the line and see what the sea gives her.")
                        .font(.system(size: 14, design: .serif))
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Flow {
                        ForEach(controller.voyage.vocabulary, id: \.self) { word in
                            Chip(word: word)
                                .onTapGesture { place(word) }
                        }
                    }
                }
                Text("Small words")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .padding(.top, 4)
                Flow {
                    ForEach(Poetry.smallWords, id: \.self) { word in
                        Chip(word: word, found: false)
                            .onTapGesture { place(word) }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Changes

    private func choose(_ option: PoemForm) {
        formID = option.id
        var resized = Array(lines.prefix(option.lines))
        while resized.count < option.lines {
            resized.append([])
        }
        lines = resized
        active = min(active, option.lines - 1)
    }

    private func place(_ word: String) {
        while lines.count < form.lines {
            lines.append([])
        }
        guard active < lines.count, lines[active].count < form.maxWords else { return }
        lines[active].append(word)
    }

    private func remove(at position: Int, from index: Int) {
        guard index < lines.count, position < lines[index].count else { return }
        lines[index].remove(at: position)
        active = index
    }
}
