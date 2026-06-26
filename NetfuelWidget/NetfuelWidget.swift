import WidgetKit
import SwiftUI

// MARK: - Shared Data Model

struct WidgetData: Codable {
    var caloriesConsumed: Int
    var calorieGoal: Int
    var proteinConsumed: Double
    var proteinGoal: Double
    var carbsConsumed: Double
    var carbsGoal: Double
    var fatConsumed: Double
    var fatGoal: Double
    var lastUpdated: Date

    static var placeholder: WidgetData {
        WidgetData(
            caloriesConsumed: 1240, calorieGoal: 2000,
            proteinConsumed: 85, proteinGoal: 150,
            carbsConsumed: 130, carbsGoal: 200,
            fatConsumed: 42, fatGoal: 67,
            lastUpdated: Date()
        )
    }

    static func load() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: "group.rickyelder.Healthapp"),
              let raw = defaults.data(forKey: "netfuel.widgetData"),
              let data = try? JSONDecoder().decode(WidgetData.self, from: raw) else {
            return .placeholder
        }
        return data
    }
}

// MARK: - Timeline Provider

struct NetfuelProvider: TimelineProvider {
    func placeholder(in context: Context) -> NetfuelEntry {
        NetfuelEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (NetfuelEntry) -> Void) {
        completion(NetfuelEntry(date: Date(), data: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NetfuelEntry>) -> Void) {
        let entry = NetfuelEntry(date: Date(), data: .load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct NetfuelEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Small Widget (3 concentric rings)

struct SmallWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(spacing: 6) {
            Text("Netfuel")
                .font(.caption2).fontWeight(.semibold)
                .foregroundColor(.secondary)

            ZStack {
                ProgressRing(progress: progress(data.caloriesConsumed, data.calorieGoal), color: .red, lineWidth: 9)
                ProgressRing(progress: progress(data.proteinConsumed, data.proteinGoal), color: .orange, lineWidth: 7)
                    .padding(12)
                ProgressRing(progress: progress(data.carbsConsumed, data.carbsGoal), color: .green, lineWidth: 5)
                    .padding(24)

                VStack(spacing: 0) {
                    Text("\(data.caloriesConsumed)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("cal")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            .frame(width: 90, height: 90)

            Text("/ \(data.calorieGoal) goal")
                .font(.caption2).foregroundColor(.secondary)
        }
        .padding(10)
    }
}

// MARK: - Medium Widget (4 side-by-side rings)

struct MediumWidgetView: View {
    let data: WidgetData

    var body: some View {
        HStack(spacing: 0) {
            MacroRingCell(label: "Calories", current: Double(data.caloriesConsumed), goal: Double(data.calorieGoal), unit: "kcal", color: .red)
            Divider().padding(.vertical, 12)
            MacroRingCell(label: "Protein",  current: data.proteinConsumed, goal: data.proteinGoal, unit: "g", color: .orange)
            Divider().padding(.vertical, 12)
            MacroRingCell(label: "Carbs",    current: data.carbsConsumed,   goal: data.carbsGoal,   unit: "g", color: .green)
            Divider().padding(.vertical, 12)
            MacroRingCell(label: "Fat",      current: data.fatConsumed,     goal: data.fatGoal,     unit: "g", color: .blue)
        }
        .padding(.horizontal, 8)
    }
}

private struct MacroRingCell: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                ProgressRing(progress: progress(current, goal), color: color, lineWidth: 8)
                VStack(spacing: 0) {
                    Text("\(Int(current))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text(unit)
                        .font(.system(size: 8)).foregroundColor(.secondary)
                }
            }
            .frame(width: 54, height: 54)

            Text(label).font(.caption2).foregroundColor(.secondary)
            Text("/ \(Int(goal))\(unit)").font(.system(size: 9)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private func progress(_ current: some BinaryFloatingPoint, _ goal: some BinaryFloatingPoint) -> Double {
    guard Double(goal) > 0 else { return 0 }
    return Double(current) / Double(goal)
}

private func progress(_ current: Int, _ goal: Int) -> Double {
    guard goal > 0 else { return 0 }
    return Double(current) / Double(goal)
}

// MARK: - Entry View

struct NetfuelWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NetfuelEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(data: entry.data)
        case .systemMedium: MediumWidgetView(data: entry.data)
        default:            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Widget

struct NetfuelWidget: Widget {
    let kind = "NetfuelWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NetfuelProvider()) { entry in
            NetfuelWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Netfuel")
        .description("Track your daily calories and macros at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    NetfuelWidget()
} timeline: {
    NetfuelEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemMedium) {
    NetfuelWidget()
} timeline: {
    NetfuelEntry(date: .now, data: .placeholder)
}
