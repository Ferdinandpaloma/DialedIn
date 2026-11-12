import SwiftUI

enum HomeRoute: Hashable {
    case session
}

struct HomeView: View {
    @Environment(ShowerController.self) private var controller
    @State private var path: [HomeRoute] = LaunchOptions.screen?.opensSession == true ? [.session] : []
    @State private var newPreset: Preset?

    private var units: TemperatureUnit { controller.units }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        OndoLogo()
                        Spacer()
                    }
                    dial
                    startButtons
                    statusCard
                    if let scheduled = controller.scheduledWarmUp {
                        scheduledCard(scheduled)
                    }
                    presets
                    infoCards
                }
                .padding(20)
            }
            .background(Color.white)
            .toolbar(.hidden, for: .navigationBar)
            .navigationTitle("Home")
            .navigationDestination(for: HomeRoute.self) { _ in
                SessionView()
            }
            .sheet(item: $newPreset) { preset in
                PresetEditorView(preset: preset, isNew: true) { controller.savePreset($0) }
                    .environment(controller)
            }
        }
    }

    // MARK: Sections

    private var dial: some View {
        Button {
            path.append(.session)
        } label: {
            DialView(setPoint: controller.setPoint,
                     waterTemp: controller.waterTemp,
                     cap: controller.cap,
                     status: controller.status,
                     units: units)
                .frame(maxWidth: 320)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens temperature controls")
    }

    @ViewBuilder
    private var startButtons: some View {
        if controller.status.isRunning {
            HStack(spacing: 12) {
                Button {
                    path.append(.session)
                } label: {
                    Label("Shower controls", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.ondoPrimary(Theme.navy))
                Button("Stop") { controller.stop() }
                    .buttonStyle(.ondoSecondary(Theme.red))
                    .frame(maxWidth: 130)
                    .accessibilityLabel("Stop shower")
            }
        } else {
            Button {
                controller.start()
                path.append(.session)
            } label: {
                Label("Start shower", systemImage: "drop.fill")
            }
            .buttonStyle(.ondoPrimary)
            .accessibilityHint("Starts warming the water to \(units.spoken(controller.setPoint))")
        }
    }

    private var valveText: String {
        switch controller.status {
        case .off: "Valve closed"
        case .warming: "Valve open · Warming"
        case .ready: "Valve open · Ready"
        case .correcting: "Valve adjusting"
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: controller.status.isRunning ? "shower.fill" : "thermometer.medium")
                .font(.title2)
                .foregroundStyle(controller.status.isRunning ? Theme.orange : Theme.blue)
                .frame(width: 32)
                .accessibilityHidden(true)
            Text("Water \(units.string(controller.waterTemp)) · \(valveText)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .ondoCard()
        .accessibilityElement(children: .combine)
    }

    private func scheduledCard(_ scheduled: ScheduledWarmUp) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "alarm.fill")
                .font(.title2)
                .foregroundStyle(Theme.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Warm-up scheduled")
                    .font(.title3.weight(.semibold))
                Text("\(units.string(scheduled.temperature)) by \(scheduled.time.formatted(date: .omitted, time: .shortened))")
                    .font(.body)
                    .foregroundStyle(Theme.secondaryInk)
            }
            Spacer(minLength: 8)
            Button("Cancel") {
                withAnimation { controller.scheduledWarmUp = nil }
            }
            .font(.headline)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Cancel scheduled warm-up")
        }
        .ondoCard(Theme.orange.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
            .strokeBorder(Theme.orange.opacity(0.6), lineWidth: 2))
    }

    private var presets: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(controller.presets) { preset in
                        Button {
                            controller.setTarget(preset.temperature)
                            path.append(.session)
                        } label: {
                            PresetChip(preset: preset, units: units)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Sets the temperature and opens controls")
                    }
                    Button {
                        newPreset = Preset(name: "", temperature: controller.setPoint, color: .green)
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.navy)
                            .frame(minWidth: 110, minHeight: 96)
                            .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                                .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add preset")
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var infoCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                InfoCard(icon: "battery.75percent", tint: Theme.green,
                         title: "Battery", value: "\(Int(controller.batteryLevel * 100))%")
                InfoCard(icon: "thermometer.medium", tint: Theme.blue,
                         title: "ONDO Sense",
                         value: controller.senseConnected ? "Connected" : "Not found")
            }
            if let last = controller.history.first {
                InfoCard(icon: "clock.fill", tint: Theme.orange, title: "Last shower",
                         value: "\(Formatting.dayAndTime(last.date)) · \(Formatting.gallons(last.gallons))")
            }
        }
    }
}
