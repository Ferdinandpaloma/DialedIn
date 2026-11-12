import XCTest
@testable import ONDO

@MainActor
final class ShowerControllerTests: XCTestCase {

    /// `random` returning 0.5 means zero jitter; 1.0 means worst-case +0.5 °F.
    private func makeController(random: Double = 0.5) -> ShowerController {
        ShowerController(random: { random })
    }

    private func run(_ c: ShowerController, seconds: Double, each: (ShowerController) -> Void = { _ in }) {
        var t = 0.0
        while t < seconds {
            c.tick(0.05)
            each(c)
            t += 0.05
        }
    }

    // MARK: Cap enforcement

    func testSetPointCannotExceedCap() {
        let c = makeController()
        XCTAssertEqual(c.cap, 110)
        XCTAssertEqual(c.setTarget(115), .capped)
        XCTAssertEqual(c.setPoint, 110)
        XCTAssertEqual(c.capHitCount, 1)
        XCTAssertEqual(c.increment(), .capped)
        XCTAssertEqual(c.setPoint, 110)
    }

    func testSetPointCannotGoBelowMinimum() {
        let c = makeController()
        XCTAssertEqual(c.setTarget(80), .atMinimum)
        XCTAssertEqual(c.setPoint, 90)
    }

    func testLoweringCapClampsSetPointAndPresets() {
        let c = makeController()
        c.setTarget(108)
        c.savePreset(Preset(name: "Hot", temperature: 108, color: .red))
        c.setCap(104)
        XCTAssertEqual(c.setPoint, 104)
        XCTAssertTrue(c.presets.allSatisfy { $0.temperature <= 104 })
        c.setCap(200)
        XCTAssertEqual(c.cap, 115, "cap is limited to 100...115")
        c.setCap(50)
        XCTAssertEqual(c.cap, 100)
    }

    // MARK: Warm-up

    func testWarmUpReachesReadyWithinTolerance() {
        let c = makeController()
        c.setTarget(102)
        c.start()
        XCTAssertEqual(c.status, .warming)
        XCTAssertEqual(c.waterTemp, 65, accuracy: 0.01)

        var previous = c.waterTemp
        run(c, seconds: 10) { c in
            if c.status == .warming {
                XCTAssertGreaterThanOrEqual(c.waterTemp, previous - 0.001, "warm-up should only climb")
            }
            previous = c.waterTemp
        }
        XCTAssertEqual(c.status, .ready)
        XCTAssertEqual(c.waterTemp, 102, accuracy: ShowerController.tolerance)
        XCTAssertEqual(c.readyEventCount, 1)
        XCTAssertNotNil(c.autoOffRemaining)
    }

    func testHoldsWithinToleranceWithJitter() {
        let c = ShowerController(random: { Double.random(in: 0...1) })
        c.demoMode = false
        c.start()
        run(c, seconds: 10)
        run(c, seconds: 60) { c in
            XCTAssertEqual(c.status, .ready)
            XCTAssertEqual(c.waterTemp, Double(c.setPoint), accuracy: 0.5 + 1e-9)
        }
        XCTAssertEqual(c.readyEventCount, 1, "holding should not re-announce ready")
    }

    // MARK: Disturbance

    func testFlushNeverExceedsCap() {
        let c = makeController(random: 1.0) // worst-case jitter pushes upward
        c.demoMode = false
        c.setTarget(110) // set-point right at the cap
        c.start()
        run(c, seconds: 12) { XCTAssertLessThanOrEqual($0.waterTemp, 110) }

        c.simulateFlush()
        XCTAssertEqual(c.status, .correcting)
        XCTAssertLessThanOrEqual(c.waterTemp, 110)
        c.simulateFlush() // two flushes back to back
        run(c, seconds: 10) { XCTAssertLessThanOrEqual($0.waterTemp, Double($0.cap)) }
    }

    func testFlushIsCorrectedWithinThreeSeconds() {
        let c = makeController()
        c.demoMode = false
        c.setTarget(102)
        c.start()
        run(c, seconds: 12)
        c.simulateFlush()
        XCTAssertEqual(c.waterTemp, 106, accuracy: 0.01)
        run(c, seconds: 3)
        XCTAssertEqual(c.status, .ready)
        XCTAssertEqual(c.waterTemp, 102, accuracy: ShowerController.tolerance)
    }

    // MARK: Auto-off

    func testAutoOffAfterTwentySecondsInDemoMode() {
        let c = makeController()
        let before = c.history.count
        c.start()
        run(c, seconds: 10)
        XCTAssertEqual(c.status, .ready)
        run(c, seconds: 21)
        XCTAssertEqual(c.status, .off)
        XCTAssertEqual(c.history.count, before + 1)
    }
}
