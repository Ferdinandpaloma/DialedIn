import SwiftUI

enum AppKeys {
    static let setupComplete = "ondo.setupComplete"
}

@main
struct ONDOApp: App {
    @State private var controller = ShowerController()

    init() {
        LaunchOptions.applyDefaults()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(controller)
                .fontDesign(.rounded)
                .preferredColorScheme(.light)
                .tint(Theme.orange)
        }
    }
}
