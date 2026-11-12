import SwiftUI

/// Four-step mock pairing: install check → search & pair → valve brand → calibrate & cap.
struct PairingFlowView: View {
    enum Step: Int {
        case install = 1, search, valve, calibrate
    }
    enum SearchPhase { case searching, found, failed }
    enum PairState { case idle, pairing, paired }

    var onFinish: () -> Void
    var onCancel: (() -> Void)?

    @Environment(ShowerController.self) private var controller
    @State private var step: Step
    @State private var installChecks: [Bool]
    @State private var searchPhase: SearchPhase
    @State private var pairStates: [String: PairState]
    @State private var hasFailedOnce = false
    @State private var selectedBrand: ValveBrand?
    @State private var calibrationProgress: Double
    @State private var calibrationStarted = false
    @State private var capValue = Double(ShowerController.defaultCap)

    private static let installItems: [(title: String, detail: String)] = [
        ("Dial mounted on valve", "The ONDO Dial sits where your old handle was."),
        ("ONDO Sense between arm and showerhead", "Hand-tight is enough. No tools needed."),
        ("Batteries in (4×AA)", "The light on the dial blinks blue when it has power."),
    ]

    init(onFinish: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.onFinish = onFinish
        self.onCancel = onCancel
        var step = Step.install
        var checks = [false, false, false]
        var phase = SearchPhase.searching
        var pairs: [String: PairState] = [:]
        var progress = 0.0
        var brand: ValveBrand?
        switch LaunchOptions.screen {
        case .searching:
            step = .search; checks = [true, true, true]; phase = .found; pairs = ["dial": .paired]
        case .valve:
            step = .valve; checks = [true, true, true]; phase = .found
            pairs = ["dial": .paired, "sense": .paired]; brand = .moen
        case .calibrate:
            step = .calibrate; checks = [true, true, true]; phase = .found
            pairs = ["dial": .paired, "sense": .paired]; brand = .moen; progress = 1
        default:
            break
        }
        _step = State(initialValue: step)
        _installChecks = State(initialValue: checks)
        _searchPhase = State(initialValue: phase)
        _pairStates = State(initialValue: pairs)
        _calibrationProgress = State(initialValue: progress)
        _selectedBrand = State(initialValue: brand)
        _calibrationStarted = State(initialValue: progress >= 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    content
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !(step == .search && searchPhase == .failed) {
                Button(footerTitle, action: advance)
                    .buttonStyle(.ondoPrimary)
                    .disabled(!canContinue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: step)
        .animation(.easeInOut(duration: 0.3), value: searchPhase)
    }

    // MARK: Header & footer

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .frame(width: 48, height: 48)
                        .foregroundStyle(Theme.navy)
                }
                .accessibilityLabel(step == .install ? "Back to welcome" : "Back")
                .opacity(step == .install && onCancel == nil ? 0 : 1)
                .disabled(step == .install && onCancel == nil)
                Spacer()
                OndoLogo()
                Spacer()
                Color.clear.frame(width: 48, height: 48)
            }
            StepIndicator(current: step.rawValue, total: 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var footerTitle: String {
        step == .calibrate ? "Finish" : "Continue"
    }

    private var canContinue: Bool {
        switch step {
        case .install: installChecks.allSatisfy { $0 }
        case .search: PairableDevice.mockFound.allSatisfy { pairStates[$0.id] == .paired }
        case .valve: selectedBrand != nil
        case .calibrate: calibrationProgress >= 1
        }
    }

    private func advance() {
        switch step {
        case .install:
            step = .search
            if searchPhase != .found { startSearch() }
        case .search:
            step = .valve
        case .valve:
            step = .calibrate
            startCalibration()
        case .calibrate:
            controller.completePairing(valveBrand: selectedBrand, cap: Int(capValue))
            onFinish()
        }
    }

    private func goBack() {
        if let previous = Step(rawValue: step.rawValue - 1) {
            step = previous
        } else {
            onCancel?()
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case .install: installStep
        case .search: searchStep
        case .valve: valveStep
        case .calibrate: calibrateStep
        }
    }

    private func title(_ text: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(Theme.secondaryInk)
        }
    }

    private var installStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Install check", "Before we connect, make sure everything is in place.")
            ForEach(Self.installItems.indices, id: \.self) { i in
                Toggle(isOn: $installChecks[i]) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Self.installItems[i].title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                        Text(Self.installItems[i].detail)
                            .font(.body)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                }
                .tint(Theme.green)
                .ondoCard()
            }
        }
    }

    @ViewBuilder
    private var searchStep: some View {
        switch searchPhase {
        case .searching:
            VStack(spacing: 24) {
                title("Searching…", "Keep your phone within a few feet of the shower.")
                BluetoothPulse()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            }
        case .found:
            VStack(alignment: .leading, spacing: 16) {
                title("Found 2 devices", "Tap Pair on each one.")
                ForEach(PairableDevice.mockFound) { device in
                    DeviceRow(device: device, state: pairStates[device.id] ?? .idle) {
                        pair(device)
                    }
                }
            }
        case .failed:
            PairingFailureView {
                pairStates = [:]
                startSearch()
            }
        }
    }

    private var valveStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Pick your valve brand", "Look for the name on your shower handle or the round plate behind it.")
            VStack(spacing: 10) {
                ForEach(ValveBrand.allCases) { brand in
                    Button {
                        selectedBrand = brand
                    } label: {
                        HStack {
                            Text(brand.name)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: selectedBrand == brand ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(selectedBrand == brand ? Theme.orange : Theme.offGray)
                        }
                        .padding(.horizontal, 18)
                        .frame(minHeight: 60)
                        .background(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .fill(selectedBrand == brand ? Theme.orange.opacity(0.1) : Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .strokeBorder(selectedBrand == brand ? Theme.orange : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedBrand == brand ? .isSelected : [])
                }
            }
            if let brand = selectedBrand {
                HStack(spacing: 16) {
                    Text(brand.adapter)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(Circle().fill(Theme.navy))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Use adapter \(brand.adapter)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.ink)
                        Text(brand.adapterNote)
                            .font(.body)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                }
                .ondoCard()
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var calibrateStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Calibrate & safety cap", "ONDO learns how far your valve turns, then you choose the hottest it may ever get.")
            if calibrationProgress < 1 {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ProgressView().controlSize(.large)
                        Text("Turning valve to learn its range…")
                            .font(.title3.weight(.semibold))
                    }
                    ProgressView(value: calibrationProgress)
                        .tint(Theme.orange)
                        .scaleEffect(x: 1, y: 2.5, anchor: .center)
                        .padding(.vertical, 6)
                    Text("\(Int(calibrationProgress * 100))%")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(Theme.secondaryInk)
                }
                .ondoCard()
                .accessibilityElement(children: .combine)
            } else {
                Label {
                    Text("Valve range learned")
                        .font(.title3.weight(.semibold))
                } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green)
                }
                .ondoCard()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Safety cap")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        Text(controller.units.string(Int(capValue)))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.red)
                            .contentTransition(.numericText(value: capValue))
                            .animation(.snappy, value: capValue)
                    }
                    Slider(value: $capValue, in: 100...115, step: 1) {
                        Text("Safety cap")
                    } minimumValueLabel: {
                        Text("100°").font(.body)
                    } maximumValueLabel: {
                        Text("115°").font(.body)
                    }
                    .tint(Theme.red)
                    .accessibilityValue(controller.units.spoken(Int(capValue)))
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundStyle(Theme.red)
                            .accessibilityHidden(true)
                        Text("ONDO will never let the water go above this.")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .ondoCard()
            }
        }
    }

    // MARK: Mock behaviour

    private func startSearch() {
        searchPhase = .searching
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if searchPhase == .searching { searchPhase = .found }
        }
    }

    private func pair(_ device: PairableDevice) {
        pairStates[device.id] = .pairing
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if controller.simulatePairingFailure && !hasFailedOnce {
                hasFailedOnce = true
                searchPhase = .failed
                pairStates = [:]
            } else {
                withAnimation(.spring(duration: 0.4)) { pairStates[device.id] = .paired }
            }
        }
    }

    private func startCalibration() {
        guard !calibrationStarted else { return }
        calibrationStarted = true
        Task {
            while calibrationProgress < 1 {
                try? await Task.sleep(for: .milliseconds(50))
                calibrationProgress = min(1, calibrationProgress + 0.05 / 3)
            }
        }
    }
}

// MARK: - Pieces

private struct DeviceRow: View {
    let device: PairableDevice
    let state: PairingFlowView.PairState
    let onPair: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if device.kind == .dial {
                    DialGlyph().frame(width: 40, height: 40)
                } else {
                    Image(systemName: "thermometer.medium")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 56, height: 56)
            .background(Circle().fill(Theme.navy))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(device.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(device.location)
                        .font(.body)
                        .foregroundStyle(Theme.secondaryInk)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(device.displayName)
                HStack(spacing: 8) {
                    SignalBars(level: device.signal.bars)
                    Text("Signal \(device.signal.rawValue.lowercased())")
                        .font(.body)
                        .foregroundStyle(Theme.secondaryInk)
                }
            }
            Spacer(minLength: 8)

            switch state {
            case .idle:
                Button("Pair", action: onPair)
                    .buttonStyle(.ondoPill)
                    .accessibilityLabel("Pair \(device.name)")
            case .pairing:
                ProgressView()
                    .controlSize(.large)
                    .frame(width: 72, height: 48)
                    .accessibilityLabel("Pairing \(device.name)")
            case .paired:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.green)
                    .frame(width: 72, height: 48)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("\(device.name) paired")
            }
        }
        .ondoCard()
    }
}

private struct BluetoothPulse: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Theme.blue.opacity(0.6), lineWidth: 3)
                    .scaleEffect(animate ? 1 : 0.4)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(Double(i) * 0.6),
                               value: animate)
            }
            Circle()
                .fill(Theme.blue)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white)
                )
        }
        .frame(width: 240, height: 240)
        .onAppear { animate = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Searching for ONDO devices")
    }
}

private struct PairingFailureView: View {
    let onRetry: () -> Void

    private let tips = [
        "Stand within a few feet of the shower",
        "Check that the 4 AA batteries are in",
        "Make sure Bluetooth is turned on",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Theme.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .accessibilityHidden(true)
            Text("Let’s try that again")
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text("We couldn’t connect to your ONDO this time. That’s common and nothing is broken.")
                .font(.title3)
                .foregroundStyle(Theme.secondaryInk)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(tips, id: \.self) { tip in
                    Label {
                        Text(tip).font(.body)
                    } icon: {
                        Image(systemName: "checkmark").foregroundStyle(Theme.green)
                    }
                }
            }
            .ondoCard()
            Button("Try again", action: onRetry)
                .buttonStyle(.ondoPrimary)
        }
    }
}
