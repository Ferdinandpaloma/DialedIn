import SwiftUI

/// Big, full-width filled button (60 pt tall).
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.orange
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(isEnabled ? color : Theme.offGray)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Light gray card-style button with navy text.
struct SecondaryButtonStyle: ButtonStyle {
    var foreground: Color = Theme.navy

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(foreground)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .shadow(color: Theme.shadow, radius: 10, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Compact pill button used inside rows (still ≥ 44 pt tall).
struct PillButtonStyle: ButtonStyle {
    var color: Color = Theme.orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(minWidth: 72, minHeight: 48)
            .background(Capsule().fill(color))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Gentle tinted button (light color wash, deep-colored text). Used for Stop.
struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Theme.red
    var text: Color = Theme.redDeep

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(text)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(tint.opacity(0.13)))
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == SoftButtonStyle {
    static var ondoStop: SoftButtonStyle { SoftButtonStyle() }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var ondoPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func ondoPrimary(_ color: Color) -> PrimaryButtonStyle { PrimaryButtonStyle(color: color) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var ondoSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    static func ondoSecondary(_ color: Color) -> SecondaryButtonStyle { SecondaryButtonStyle(foreground: color) }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var ondoPill: PillButtonStyle { PillButtonStyle() }
}
