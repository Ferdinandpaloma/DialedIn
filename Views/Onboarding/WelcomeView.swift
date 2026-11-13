import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var showPairing = LaunchOptions.screen.map { $0.isOnboarding && $0 != .welcome } ?? false

    var body: some View {
        if showPairing {
            PairingFlowView(onFinish: onFinish, onCancel: {
                withAnimation(.easeInOut) { showPairing = false }
            })
            .transition(.move(edge: .trailing))
        } else {
            WelcomeView {
                withAnimation(.easeInOut) { showPairing = true }
            }
            .transition(.move(edge: .leading))
        }
    }
}

struct WelcomeView: View {
    var onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                OndoLogo(onDark: true)
                    .padding(.top, 8)

                DialView(setPoint: 102, waterTemp: 102, cap: 110, status: .ready)
                    .frame(maxWidth: 290)
                    .padding(.vertical, 8)
                    .accessibilityHidden(true)

                VStack(spacing: 14) {
                    Text("The thermostat for your shower")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Set your temperature once. ONDO warms the water, chimes when it’s ready, and never goes above your safety cap.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            Button("Set up my ONDO", action: onStart)
                .buttonStyle(.ondoPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.navy)
        }
        .background(Theme.navy.ignoresSafeArea())
    }
}
