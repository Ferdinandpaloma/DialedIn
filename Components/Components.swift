import SwiftUI

// MARK: - Card

private struct CardModifier: ViewModifier {
    var fill: Color = Theme.card
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(fill))
    }
}

extension View {
    func ondoCard(_ fill: Color = Theme.card) -> some View { modifier(CardModifier(fill: fill)) }
}

// MARK: - Logo (long-press opens the hidden debug menu)

struct OndoLogo: View {
    var onDark = false
    @Environment(ShowerController.self) private var controller
    @State private var showDebug = false

    var body: some View {
        HStack(spacing: 10) {
            DialGlyph().frame(width: 36, height: 36)
            Text("ONDO")
                .font(.title2.weight(.heavy))
                .tracking(5)
                .foregroundStyle(onDark ? .white : Theme.navy)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.8) { showDebug = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ONDO")
        .accessibilityAddTraits(.isHeader)
        .accessibilityAction(named: "Open debug menu") { showDebug = true }
        .sheet(isPresented: $showDebug) {
            DebugMenuView().environment(controller)
        }
    }
}

// MARK: - Step indicator

struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(current) of \(total)")
                .font(.headline)
                .foregroundStyle(Theme.secondaryInk)
            HStack(spacing: 6) {
                ForEach(1...total, id: \.self) { i in
                    Capsule()
                        .fill(i <= current ? Theme.orange : Theme.hairline)
                        .frame(height: 8)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current) of \(total)")
    }
}

// MARK: - Ready banner

struct ReadyBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(Theme.green)
            Text(text)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(Theme.navy))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
            .strokeBorder(Theme.green, lineWidth: 3))
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Signal bars

struct SignalBars: View {
    let level: Int
    var max: Int = 4

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(1...max, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= level ? Theme.green : Theme.hairline)
                    .frame(width: 6, height: CGFloat(6 + i * 5))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Info card

struct InfoCard: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(.body)
                .foregroundStyle(Theme.secondaryInk)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
        }
        .ondoCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Round icon button (− / +)

struct RoundIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.navy)
                .frame(width: 76, height: 76)
                .background(Circle().fill(Theme.card))
                .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Preset chip

struct PresetChip: View {
    let preset: Preset
    let units: TemperatureUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle().fill(preset.color.color).frame(width: 14, height: 14)
                Text(preset.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
            }
            Text(units.string(preset.temperature))
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.ink)
        }
        .padding(18)
        .frame(minWidth: 160, minHeight: 96, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
            .fill(preset.color.color.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
            .strokeBorder(preset.color.color.opacity(0.6), lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(preset.name) preset, \(units.spoken(preset.temperature))")
    }
}
