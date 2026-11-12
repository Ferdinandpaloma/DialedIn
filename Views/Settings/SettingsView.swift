import SwiftUI

struct SettingsView: View {
    @Environment(ShowerController.self) private var controller
    @AppStorage(AppKeys.setupComplete) private var setupComplete = false
    @State private var showPairing = false
    @State private var confirmReset = false

    var body: some View {
        @Bindable var c = controller
        NavigationStack {
            Form {
                Section("Safety") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Safety cap")
                                .font(.title3.weight(.semibold))
                            Spacer()
                            Text(controller.units.string(controller.cap))
                                .font(.title.weight(.bold))
                                .foregroundStyle(Theme.red)
                        }
                        Slider(
                            value: Binding(get: { Double(controller.cap) },
                                           set: { controller.setCap(Int($0.rounded())) }),
                            in: 100...115, step: 1
                        ) {
                            Text("Safety cap")
                        } minimumValueLabel: {
                            Text("100°")
                        } maximumValueLabel: {
                            Text("115°")
                        }
                        .tint(Theme.red)
                        .accessibilityValue(controller.units.spoken(controller.cap))
                        Text("ONDO will never let the water go above this.")
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    .padding(.vertical, 6)
                }

                Section("Display & sound") {
                    Picker("Units", selection: $c.units) {
                        ForEach(TemperatureUnit.allCases) { unit in
                            Text(unit.name).tag(unit)
                        }
                    }
                    .frame(minHeight: 44)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chime volume")
                        Slider(value: $c.chimeVolume) {
                            Text("Chime volume")
                        } minimumValueLabel: {
                            Image(systemName: "speaker.fill").accessibilityHidden(true)
                        } maximumValueLabel: {
                            Image(systemName: "speaker.wave.3.fill").accessibilityHidden(true)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Family") {
                    Toggle(isOn: .constant(false)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Caregiver alerts")
                            Text("Coming in ONDO Connect")
                                .foregroundStyle(Theme.secondaryInk)
                        }
                    }
                    .disabled(true)
                    .frame(minHeight: 44)
                }

                Section("Devices") {
                    LabeledContent("ONDO Dial", value: "Paired · \(Int(controller.batteryLevel * 100))%")
                    LabeledContent("ONDO Sense", value: controller.senseConnected ? "Connected" : "Not found")
                    if let brand = controller.valveBrand {
                        LabeledContent("Valve", value: "\(brand.name) · Adapter \(brand.adapter)")
                    }
                    Button("Re-run pairing") { showPairing = true }
                        .frame(minHeight: 44)
                }

                Section {
                    Toggle("Demo mode (20 s auto-off)", isOn: $c.demoMode)
                        .frame(minHeight: 44)
                    Button("Reset demo", role: .destructive) { confirmReset = true }
                        .frame(minHeight: 44)
                } header: {
                    Text("Demo")
                } footer: {
                    Text("This is a mock app. No Bluetooth, network or real device is used.")
                        .font(.body)
                }
            }
            .navigationTitle("Settings")
            .fullScreenCover(isPresented: $showPairing) {
                PairingFlowView(onFinish: { showPairing = false }, onCancel: { showPairing = false })
                    .environment(controller)
            }
            .confirmationDialog("Reset the demo?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset demo", role: .destructive) {
                    controller.resetDemo()
                    setupComplete = false
                }
            } message: {
                Text("Presets, history and pairing go back to the start and the welcome screen shows again.")
            }
        }
    }
}
