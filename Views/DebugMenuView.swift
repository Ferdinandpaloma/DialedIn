import SwiftUI

/// Hidden menu: long-press the ONDO logo anywhere it appears.
struct DebugMenuView: View {
    @Environment(ShowerController.self) private var controller
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppKeys.setupComplete) private var setupComplete = false

    var body: some View {
        @Bindable var c = controller
        NavigationStack {
            Form {
                Section {
                    Toggle("Simulate pairing failure", isOn: $c.simulatePairingFailure)
                    Toggle("Demo mode (20 s auto-off)", isOn: $c.demoMode)
                } header: {
                    Text("Pairing & timing")
                } footer: {
                    Text("With pairing failure on, the next “Pair” tap fails once and shows the retry screen.")
                }

                Section("Shower") {
                    Button("Simulate toilet flush") {
                        controller.simulateFlush()
                        dismiss()
                    }
                    .disabled(!controller.status.isRunning)
                    Button("Skip to ready") {
                        controller.skipToReady()
                        dismiss()
                    }
                    .disabled(!controller.status.isRunning)
                }

                Section {
                    Button("Reset demo", role: .destructive) {
                        controller.resetDemo()
                        setupComplete = false
                        dismiss()
                    }
                }
            }
            .navigationTitle("Debug menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
