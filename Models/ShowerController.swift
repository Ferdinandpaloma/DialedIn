import Foundation
import Observation

/// Simulated ONDO system: devices, set-point, safety cap and the water-temperature model.
///
/// The simulation is a pure function of `tick(_:)` calls, so tests can drive it
/// deterministically. In the app, `startSimulationLoop()` calls `tick` ~20× per second.
@MainActor
@Observable
final class ShowerController {

    // MARK: Constants

    static let minSetPoint = 90
    static let scaleMax = 115
    static let capRange = 100...115
    static let defaultCap = 110
    static let defaultSetPoint = 102
    /// ± band that counts as "ready".
    static let tolerance = 1.0
    static let ambientTemp = 68.0
    static let coldStartTemp = 65.0
    static let flushSpike = 4.0
    /// Time constant (s) of the controller rejecting a disturbance: within ±1 °F of target in ~2.2 s.
    static let correctionTimeConstant = 1.6
    static let warmUpDuration: TimeInterval = 10
    static let gallonsPerMinute = 0.8

    enum SetResult: Equatable { case ok, capped, atMinimum }

    // MARK: Settings

    var units: TemperatureUnit = .fahrenheit
    var chimeVolume: Double = 0.7
    /// Demo mode shortens the 20-minute auto-off to 20 seconds.
    var demoMode = true
    var simulatePairingFailure = false

    // MARK: Devices & content

    private(set) var valveBrand: ValveBrand?
    private(set) var isPaired = false
    let batteryLevel = 0.92
    var senseConnected = true
    var presets: [Preset] = Preset.defaults
    private(set) var history: [ShowerRecord] = MockData.history()
    var scheduledWarmUp: ScheduledWarmUp?

    // MARK: Live state

    private(set) var cap = ShowerController.defaultCap
    private(set) var setPoint = ShowerController.defaultSetPoint
    private(set) var waterTemp = ShowerController.ambientTemp
    private(set) var status: ShowerStatus = .off
    private(set) var autoOffRemaining: TimeInterval?
    /// Increments each time the water first reaches the set-point (drives banner, chime, haptic).
    private(set) var readyEventCount = 0
    /// Increments each time a request is clamped by the safety cap (drives warning haptic).
    private(set) var capHitCount = 0

    var autoOffDuration: TimeInterval { demoMode ? 20 : 20 * 60 }

    // MARK: Simulation internals

    @ObservationIgnored private var base = ShowerController.ambientTemp
    @ObservationIgnored private var rampStart = ShowerController.coldStartTemp
    @ObservationIgnored private var rampTarget = Double(ShowerController.defaultSetPoint)
    @ObservationIgnored private var rampElapsed: TimeInterval = 0
    @ObservationIgnored private var rampDuration: TimeInterval = ShowerController.warmUpDuration
    @ObservationIgnored private var disturbance = 0.0
    @ObservationIgnored private var jitter = 0.0
    @ObservationIgnored private var jitterTarget = 0.0
    @ObservationIgnored private var jitterClock: TimeInterval = 0
    @ObservationIgnored private var sessionElapsed: TimeInterval = 0
    @ObservationIgnored private var tempSum = 0.0
    @ObservationIgnored private var tempSamples = 0
    @ObservationIgnored private let random: () -> Double
    @ObservationIgnored private var loopTask: Task<Void, Never>?

    /// - Parameter random: source of values in 0...1 used for the ±0.5 °F hold jitter.
    init(random: @escaping () -> Double = { Double.random(in: 0...1) }) {
        self.random = random
    }

    // MARK: Set-point & cap

    @discardableResult
    func setTarget(_ requested: Int) -> SetResult {
        var value = requested
        var result = SetResult.ok
        if value > cap {
            value = cap
            result = .capped
            capHitCount += 1
        } else if value < Self.minSetPoint {
            value = Self.minSetPoint
            result = .atMinimum
        }
        if value != setPoint {
            setPoint = value
            if status.isRunning { retarget() }
        }
        return result
    }

    @discardableResult
    func increment() -> SetResult { setTarget(setPoint + 1) }

    @discardableResult
    func decrement() -> SetResult { setTarget(setPoint - 1) }

    func setCap(_ value: Int) {
        let clamped = min(max(value, Self.capRange.lowerBound), Self.capRange.upperBound)
        guard clamped != cap else { return }
        cap = clamped
        if setPoint > cap {
            setPoint = cap
            if status.isRunning { retarget() }
        }
        presets = presets.map { preset in
            var p = preset
            p.temperature = min(p.temperature, clamped)
            return p
        }
        if status.isRunning { waterTemp = min(waterTemp, Double(cap)) }
    }

    func savePreset(_ preset: Preset) {
        var p = preset
        p.temperature = min(max(p.temperature, Self.minSetPoint), cap)
        if let index = presets.firstIndex(where: { $0.id == p.id }) {
            presets[index] = p
        } else {
            presets.append(p)
        }
    }

    func completePairing(valveBrand: ValveBrand?, cap: Int) {
        self.valveBrand = valveBrand
        isPaired = true
        setCap(cap)
    }

    // MARK: Shower control

    func start() {
        guard !status.isRunning else { return }
        base = Self.coldStartTemp
        rampStart = base
        rampTarget = Double(setPoint)
        rampElapsed = 0
        rampDuration = Self.warmUpDuration
        disturbance = 0
        jitter = 0
        jitterTarget = 0
        jitterClock = 0
        sessionElapsed = 0
        tempSum = 0
        tempSamples = 0
        autoOffRemaining = nil
        waterTemp = base
        status = .warming
    }

    func stop() {
        guard status.isRunning else { return }
        if sessionElapsed >= 3 {
            // In demo mode 1 s of runtime stands for 1 minute.
            let minutes = demoMode ? sessionElapsed : sessionElapsed / 60
            let average = tempSamples > 0 ? tempSum / Double(tempSamples) : Double(setPoint)
            history.insert(
                ShowerRecord(date: .now,
                             durationMinutes: minutes,
                             gallons: minutes * Self.gallonsPerMinute,
                             averageTemp: average),
                at: 0)
        }
        status = .off
        autoOffRemaining = nil
        disturbance = 0
    }

    /// Debug: a toilet flush steals cold water, so the shower spikes hot. The controller pulls it back.
    func simulateFlush() {
        guard status.isRunning else { return }
        disturbance += Self.flushSpike
        waterTemp = min(base + jitter + disturbance, Double(cap))
        status = .correcting
    }

    /// Debug: jump to the end of the warm-up ramp.
    func skipToReady() {
        guard status.isRunning else { return }
        advance(by: max(0, rampDuration - rampElapsed) + 0.1)
    }

    func resetDemo() {
        stop()
        units = .fahrenheit
        chimeVolume = 0.7
        demoMode = true
        simulatePairingFailure = false
        valveBrand = nil
        isPaired = false
        presets = Preset.defaults
        history = MockData.history()
        scheduledWarmUp = nil
        cap = Self.defaultCap
        setPoint = Self.defaultSetPoint
        waterTemp = Self.ambientTemp
        base = Self.ambientTemp
    }

    // MARK: Simulation

    /// Runs the model forward in fixed steps (used by tests, demo launch states and `skipToReady`).
    func advance(by seconds: TimeInterval, step: TimeInterval = 0.05) {
        var t = 0.0
        while t < seconds {
            tick(step)
            t += step
        }
    }

    func tick(_ dt: TimeInterval) {
        guard dt > 0 else { return }

        guard status.isRunning else {
            // Valve closed: the pipe drifts back to room temperature.
            let next = waterTemp + (Self.ambientTemp - waterTemp) * min(1, dt / 3)
            if abs(next - waterTemp) > 0.005 { waterTemp = next }
            base = waterTemp
            return
        }

        sessionElapsed += dt

        // 1. Warm-up ramp with an ease-out curve.
        if rampElapsed < rampDuration {
            rampElapsed = min(rampDuration, rampElapsed + dt)
            let t = rampElapsed / rampDuration
            base = rampStart + (rampTarget - rampStart) * Self.easeOut(t)
        } else {
            base = rampTarget
        }
        let rampDone = rampElapsed >= rampDuration

        // 2. Small ±0.5 °F wander once holding.
        if rampDone {
            jitterClock += dt
            if jitterClock >= 0.8 {
                jitterClock = 0
                jitterTarget = min(max(random(), 0), 1) - 0.5
            }
            jitter += (jitterTarget - jitter) * min(1, dt * 3)
        } else {
            jitter *= max(0, 1 - dt * 3)
        }

        // 3. Disturbance rejection (exponential decay toward zero).
        if disturbance > 0 {
            disturbance *= exp(-dt / Self.correctionTimeConstant)
            if disturbance < 0.05 { disturbance = 0 }
        }

        // 4. Safety cap is absolute: the reading can never exceed it.
        waterTemp = min(base + jitter + disturbance, Double(cap))
        tempSum += waterTemp
        tempSamples += 1

        // 5. Status.
        let previous = status
        if disturbance > Self.tolerance {
            status = .correcting
        } else if abs(waterTemp - Double(setPoint)) <= Self.tolerance {
            status = .ready
        } else {
            status = .warming
        }
        if status == .ready && previous == .warming {
            readyEventCount += 1
            if autoOffRemaining == nil { autoOffRemaining = autoOffDuration }
        }

        // 6. Auto-off.
        if let remaining = autoOffRemaining {
            let next = remaining - dt
            if next <= 0 {
                stop()
            } else {
                autoOffRemaining = next
            }
        }
    }

    func startSimulationLoop() {
        guard loopTask == nil else { return }
        loopTask = Task { [weak self] in
            var last = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                guard let self else { return }
                let now = Date()
                self.tick(min(now.timeIntervalSince(last), 0.25))
                last = now
            }
        }
    }

    // MARK: Helpers

    private func retarget() {
        rampStart = base
        rampTarget = Double(setPoint)
        rampElapsed = 0
        let delta = abs(rampTarget - rampStart)
        rampDuration = max(1.5, Self.warmUpDuration * min(1, delta / 37))
    }

    private static func easeOut(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }
}
