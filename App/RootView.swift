import AudioToolbox
import SwiftUI

struct RootView: View {
    @Environment(ShowerController.self) private var controller
    @AppStorage(AppKeys.setupComplete) private var setupComplete = false
    @State private var bannerText: String?
    @State private var bannerToken = 0

    var body: some View {
        ZStack(alignment: .top) {
            if setupComplete {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut) { setupComplete = true }
                }
                .transition(.opacity)
            }

            if let bannerText {
                ReadyBanner(text: bannerText)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onTapGesture { withAnimation { self.bannerText = nil } }
            }
        }
        .sensoryFeedback(.success, trigger: controller.readyEventCount)
        .onChange(of: controller.readyEventCount) { showReadyBanner() }
        .task {
            LaunchOptions.prepare(controller)
            controller.startSimulationLoop()
        }
    }

    private func showReadyBanner() {
        let text = "Your shower is ready at \(controller.units.string(controller.setPoint))"
        withAnimation(.spring(duration: 0.4)) { bannerText = text }
        if controller.chimeVolume > 0 {
            AudioServicesPlaySystemSound(1057) // mock chime
        }
        AccessibilityNotification.Announcement(text).post()
        bannerToken += 1
        let token = bannerToken
        Task {
            try? await Task.sleep(for: .seconds(5))
            if token == bannerToken {
                withAnimation(.easeInOut) { bannerText = nil }
            }
        }
    }
}
