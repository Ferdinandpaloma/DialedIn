import SwiftUI

enum ShowerStatus: Equatable {
    case off, warming, ready, correcting

    var label: String {
        switch self {
        case .off: "OFF"
        case .warming: "WARMING"
        case .ready: "READY"
        case .correcting: "CORRECTING"
        }
    }

    var spokenLabel: String {
        switch self {
        case .off: "Off"
        case .warming: "Warming up"
        case .ready: "Ready"
        case .correcting: "Correcting temperature"
        }
    }

    var isRunning: Bool { self != .off }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case fahrenheit, celsius

    var id: String { rawValue }
    var symbol: String { self == .fahrenheit ? "°F" : "°C" }
    var name: String { self == .fahrenheit ? "Fahrenheit (°F)" : "Celsius (°C)" }

    /// Converts a Fahrenheit value into this unit.
    func convert(_ fahrenheit: Double) -> Double {
        self == .fahrenheit ? fahrenheit : (fahrenheit - 32) * 5 / 9
    }

    /// "102" or "38.9"
    func number(_ fahrenheit: Double) -> String {
        switch self {
        case .fahrenheit: String(Int(fahrenheit.rounded()))
        case .celsius: String(format: "%.1f", convert(fahrenheit))
        }
    }

    /// "102 °F"
    func string(_ fahrenheit: Double) -> String { "\(number(fahrenheit)) \(symbol)" }
    func string(_ fahrenheit: Int) -> String { string(Double(fahrenheit)) }

    /// "102°"
    func short(_ fahrenheit: Double) -> String { "\(number(fahrenheit))°" }
    func short(_ fahrenheit: Int) -> String { short(Double(fahrenheit)) }

    /// "102 degrees Fahrenheit" for VoiceOver.
    func spoken(_ fahrenheit: Double) -> String {
        "\(number(fahrenheit)) degrees \(self == .fahrenheit ? "Fahrenheit" : "Celsius")"
    }
    func spoken(_ fahrenheit: Int) -> String { spoken(Double(fahrenheit)) }
}

enum PresetColor: String, CaseIterable, Identifiable {
    case orange, blue, green, navy, red

    var id: String { rawValue }
    var name: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .orange: Theme.orange
        case .blue: Theme.blue
        case .green: Theme.green
        case .navy: Theme.navy
        case .red: Theme.red
        }
    }
}

struct Preset: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var temperature: Int
    var color: PresetColor

    static var defaults: [Preset] {
        [
            Preset(name: "Margaret", temperature: 102, color: .orange),
            Preset(name: "Guest", temperature: 98, color: .blue),
        ]
    }
}

struct PairableDevice: Identifiable, Hashable {
    enum Kind { case dial, sense }
    enum Signal: String {
        case strong = "Strong", good = "Good"
        var bars: Int { self == .strong ? 4 : 3 }
    }

    let id: String
    let kind: Kind
    let name: String
    let location: String
    let signal: Signal

    var displayName: String { "\(name) · \(location)" }

    static let mockFound: [PairableDevice] = [
        PairableDevice(id: "dial", kind: .dial, name: "ONDO Dial", location: "Bathroom", signal: .strong),
        PairableDevice(id: "sense", kind: .sense, name: "ONDO Sense", location: "Shower arm", signal: .good),
    ]
}

enum ValveBrand: String, CaseIterable, Identifiable {
    case moen, delta, kohler, pfister, americanStandard, other

    var id: String { rawValue }

    var name: String {
        switch self {
        case .moen: "Moen PosiTemp"
        case .delta: "Delta Monitor 13/14"
        case .kohler: "Kohler Rite-Temp"
        case .pfister: "Pfister"
        case .americanStandard: "American Standard"
        case .other: "Other"
        }
    }

    var adapter: String {
        switch self {
        case .moen: "A"
        case .delta: "B"
        case .kohler: "C"
        case .pfister: "D"
        case .americanStandard: "E"
        case .other: "F"
        }
    }

    var adapterNote: String {
        self == .other
            ? "Adapter F is the universal adapter. It fits most single-handle valves."
            : "Adapter \(adapter) is in the box, labeled with a large letter \(adapter)."
    }
}

struct ShowerRecord: Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var durationMinutes: Double
    var gallons: Double
    var averageTemp: Double
}

struct ScheduledWarmUp: Equatable {
    var time: Date
    var temperature: Int
}
