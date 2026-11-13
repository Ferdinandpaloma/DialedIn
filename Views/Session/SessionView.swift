import SwiftUI

/// Set-point + live shower screen: drag the dial or use − / +, then Start (or schedule).
struct SessionView: View {
    enum WarmUpMode: String, CaseIterable, Identifiable {
        case now = "Now", later = "Later"
        var id: String { rawValue }
    }

    @Environment(ShowerController.self) private var controller
    @Environment(\.dismiss) private var dismiss
    @State private var isOverCap = false
    @State private var showCapMessage = false
    @State private var capMessageToken = 0
    @State private var warmUpMode: WarmUpMode = .now
    @State private var warmUpTime: Date = SessionView.defaultWarmUpTime()

    private var units: TemperatureUnit { controller.units }
    private var isRunning: Bool { controller.status.isRunning }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DialView(setPoint: controller.setPoint,
                         waterTemp: controller.waterTemp,
                         cap: controller.cap,
                         status: controller.status,
                         units: units,
                         onDrag: handleDrag)
                    .frame(maxWidth: 330)
                    .accessibilityHint("Swipe up or down to change the temperature")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: adjust(by: 1)
                        case .decrement: adjust(by: -1)
                        @unknown default: break
                        }
                    }

                if showCapMessage {
                    capMessage
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }

                stepperRow

                if isRunning {
                    liveCard
                    demoCard
                } else {
                    warmUpCard
                }
            }
            .padding(20)
        }
        .background(Theme.background)
        .safeAreaInset(edge: .bottom) { actionButton }
        .navigationTitle(isRunning ? "Your shower" : "Set temperature")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: controller.setPoint)
        .sensoryFeedback(.warning, trigger: controller.capHitCount)
        .animation(.easeInOut(duration: 0.25), value: isRunning)
        .animation(.easeInOut(duration: 0.25), value: controller.status)
    }

    // MARK: Pieces

    private var capMessage: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title2)
                .foregroundStyle(Theme.red)
                .accessibilityHidden(true)
            Text("Capped at \(units.short(controller.cap)) for safety")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(Theme.red.opacity(0.12)))
        .accessibilityElement(children: .combine)
    }

    private var stepperRow: some View {
        HStack {
            RoundIconButton(systemName: "minus", label: "Cooler") { adjust(by: -1) }
            Spacer()
            VStack(spacing: 2) {
                Text("Set to")
                    .font(.body)
                    .foregroundStyle(Theme.secondaryInk)
                Text(units.string(controller.setPoint))
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(controller.setPoint)))
                    .animation(.snappy, value: controller.setPoint)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            RoundIconButton(systemName: "plus", label: "Warmer") { adjust(by: 1) }
        }
    }

    private var warmUpCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Warm up by")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 10) {
                ForEach(WarmUpMode.allCases) { mode in
                    let selected = warmUpMode == mode
                    Button {
                        warmUpMode = mode
                    } label: {
                        Text(mode == .now ? "Now" : "A set time")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(selected ? .white : Theme.navy)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected ? Theme.navy : Theme.background))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            if warmUpMode == .later {
                DatePicker("Ready by", selection: $warmUpTime, displayedComponents: .hourAndMinute)
                    .font(.title3)
                Text("ONDO will start warming a few minutes early so the water is ready at this time.")
                    .font(.body)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
        .ondoCard()
    }

    private var liveCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Water now")
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryInk)
                Spacer()
                Text(units.string(controller.waterTemp))
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: controller.waterTemp))
                    .animation(.snappy, value: units.number(controller.waterTemp))
            }
            .accessibilityElement(children: .combine)

            switch controller.status {
            case .correcting:
                Label("Correcting…", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .symbolEffect(.pulse)
            case .warming:
                Text("Warming to \(units.string(controller.setPoint)). We’ll chime when it’s ready.")
                    .font(.body)
                    .foregroundStyle(Theme.ink)
            default:
                EmptyView()
            }

            if let remaining = controller.autoOffRemaining {
                Label("Auto-off in \(Formatting.countdown(remaining))", systemImage: "timer")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.secondaryInk)
                    .accessibilityLabel("Turns off automatically in \(Int(remaining.rounded(.up))) seconds")
            }
        }
        .ondoCard()
    }

    private var demoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Demo controls")
                .font(.headline)
                .foregroundStyle(Theme.secondaryInk)
            Button {
                controller.simulateFlush()
            } label: {
                Label("Simulate toilet flush", systemImage: "toilet.fill")
            }
            .buttonStyle(.ondoSecondary)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        Group {
            if isRunning {
                Button {
                    controller.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.ondoStop)
                .accessibilityLabel("Stop shower")
            } else if warmUpMode == .later {
                Button {
                    controller.scheduledWarmUp = ScheduledWarmUp(time: warmUpTime, temperature: controller.setPoint)
                    dismiss()
                } label: {
                    Label("Schedule warm-up", systemImage: "alarm.fill")
                }
                .buttonStyle(.ondoPrimary(Theme.navy))
            } else {
                Button {
                    controller.start()
                } label: {
                    Label("Start", systemImage: "drop.fill")
                }
                .buttonStyle(.ondoPrimary)
                .accessibilityLabel("Start shower")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.background)
    }

    // MARK: Actions

    private func handleDrag(_ requested: Int) {
        if requested > controller.cap {
            if !isOverCap {
                isOverCap = true
                controller.setTarget(requested)
                flashCapMessage()
            }
        } else {
            isOverCap = false
            controller.setTarget(requested)
        }
    }

    private func adjust(by delta: Int) {
        if controller.setTarget(controller.setPoint + delta) == .capped {
            flashCapMessage()
        }
    }

    private func flashCapMessage() {
        withAnimation(.spring(duration: 0.3)) { showCapMessage = true }
        AccessibilityNotification.Announcement("Capped at \(units.spoken(controller.cap)) for safety").post()
        capMessageToken += 1
        let token = capMessageToken
        Task {
            try? await Task.sleep(for: .seconds(3))
            if token == capMessageToken {
                withAnimation(.easeOut) { showCapMessage = false }
            }
        }
    }

    private static func defaultWarmUpTime() -> Date {
        Calendar.current.nextDate(after: .now,
                                  matching: DateComponents(hour: 7, minute: 30),
                                  matchingPolicy: .nextTime) ?? .now
    }
}
