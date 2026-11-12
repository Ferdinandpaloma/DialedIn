import Charts
import SwiftUI

struct HistoryView: View {
    private struct DayUse: Identifiable {
        let date: Date
        let gallons: Double
        var id: Date { date }
    }

    @Environment(ShowerController.self) private var controller

    private var week: [DayUse] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let total = controller.history
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.gallons }
            return DayUse(date: day, gallons: total)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Chart(week) { day in
                        BarMark(x: .value("Day", day.date, unit: .day),
                                y: .value("Gallons", day.gallons))
                            .foregroundStyle(Calendar.current.isDateInToday(day.date) ? Theme.orange : Theme.blue)
                            .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                                .font(.body)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisValueLabel().font(.body)
                        }
                    }
                    .frame(height: 220)
                    .padding(.vertical, 8)
                } header: {
                    Text("Water use this week")
                } footer: {
                    Text("\(Formatting.gallons(week.reduce(0) { $0 + $1.gallons })) in the last 7 days")
                        .font(.body)
                }

                Section("Recent showers") {
                    ForEach(controller.history) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(Formatting.dayAndTime(record.date))
                                .font(.title3.weight(.semibold))
                            HStack(spacing: 16) {
                                Label("\(Int(record.durationMinutes.rounded())) min", systemImage: "timer")
                                Label(Formatting.gallons(record.gallons), systemImage: "drop.fill")
                                Label(controller.units.short(record.averageTemp), systemImage: "thermometer.medium")
                            }
                            .font(.body)
                            .foregroundStyle(Theme.secondaryInk)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(
                            "\(Formatting.dayAndTime(record.date)). \(Int(record.durationMinutes.rounded())) minutes, \(String(format: "%.1f", record.gallons)) gallons, average \(controller.units.spoken(record.averageTemp))."
                        )
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}
