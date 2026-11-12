import Foundation

enum MockData {
    /// A week of believable showers, newest first. "Today 7:42 AM · 6.1 gal" is the most recent.
    static func history(now: Date = .now, calendar: Calendar = .current) -> [ShowerRecord] {
        // (days ago, hour, minute, minutes, gallons, avg °F)
        let rows: [(Int, Int, Int, Double, Double, Double)] = [
            (0, 7, 42, 7.6, 6.1, 102),
            (1, 19, 10, 5.5, 4.4, 98),
            (1, 7, 35, 8.2, 6.6, 102),
            (2, 7, 50, 7.1, 5.7, 101),
            (3, 8, 5, 9.0, 7.2, 102),
            (4, 7, 40, 6.8, 5.4, 102),
            (5, 20, 2, 4.9, 3.9, 98),
            (5, 7, 38, 7.9, 6.3, 102),
            (6, 7, 45, 8.4, 6.7, 103),
        ]
        let today = calendar.startOfDay(for: now)
        return rows.compactMap { daysAgo, hour, minute, minutes, gallons, temp in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today),
                  let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
            else { return nil }
            return ShowerRecord(date: date, durationMinutes: minutes, gallons: gallons, averageTemp: temp)
        }
    }
}

enum Formatting {
    /// "Today 7:42 AM", "Yesterday 7:35 AM", "Monday 8:05 AM"
    static func dayAndTime(_ date: Date, calendar: Calendar = .current) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(date) { return "Today \(time)" }
        if calendar.isDateInYesterday(date) { return "Yesterday \(time)" }
        return "\(date.formatted(.dateTime.weekday(.wide))) \(time)"
    }

    static func gallons(_ value: Double) -> String { String(format: "%.1f gal", value) }

    /// "0:18" / "19:59"
    static func countdown(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
