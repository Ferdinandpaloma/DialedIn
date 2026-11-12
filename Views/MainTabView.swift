import SwiftUI

enum AppTab: Hashable {
    case home, presets, history, settings
}

struct MainTabView: View {
    @State private var selection: AppTab = LaunchOptions.screen?.tab ?? .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)
            PresetsView()
                .tabItem { Label("Presets", systemImage: "person.2.fill") }
                .tag(AppTab.presets)
            HistoryView()
                .tabItem { Label("History", systemImage: "chart.bar.fill") }
                .tag(AppTab.history)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }
}
