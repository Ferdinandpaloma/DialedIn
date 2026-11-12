import Foundation

/// Screens the app can be launched straight into, for screenshots and demos:
///
///     xcrun simctl launch booted com.ondo.mock -ondoScreen ready
enum DemoScreen: String {
    case welcome, install, searching, valve, calibrate
    case home, setpoint, warming, ready, flush
    case presets, history, settings

    var isOnboarding: Bool {
        [.welcome, .install, .searching, .valve, .calibrate].contains(self)
    }

    var opensSession: Bool {
        [.setpoint, .warming, .ready, .flush].contains(self)
    }

    var tab: AppTab {
        switch self {
        case .presets: .presets
        case .history: .history
        case .settings: .settings
        default: .home
        }
    }
}

@MainActor
enum LaunchOptions {
    static let screen: DemoScreen? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-ondoScreen"), i + 1 < args.count else { return nil }
        return DemoScreen(rawValue: args[i + 1])
    }()

    private static var prepared = false

    /// Runs before any view: decides whether onboarding shows.
    static func applyDefaults() {
        guard let screen else { return }
        UserDefaults.standard.set(!screen.isOnboarding, forKey: AppKeys.setupComplete)
    }

    /// Puts the simulation into the requested state (once per launch).
    static func prepare(_ controller: ShowerController) {
        guard !prepared, let screen else { return }
        prepared = true
        if !screen.isOnboarding {
            controller.completePairing(valveBrand: .moen, cap: ShowerController.defaultCap)
        }
        switch screen {
        case .warming:
            controller.start()
            controller.advance(by: 2.5)
        case .ready:
            controller.start()
            controller.advance(by: 6.0)   // reaches READY live about a second later, so the banner fires
        case .flush:
            controller.demoMode = false
            controller.start()
            controller.advance(by: 11)
            controller.simulateFlush()
        default:
            break
        }
    }
}
