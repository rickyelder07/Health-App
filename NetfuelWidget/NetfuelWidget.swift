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
        // Refresh every 30 min; app also calls reloadAllTimelines after food logs
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

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let data: WidgetData

    private var calorieProgress: Double {
        data.calorieGoal > 0 ? Double(data.caloriesConsumed) / Double(data.calorieGoal) : 0
    }
    private var proteinProgress: Double {
        data.proteinGoal > 0 ? data.proteinConsumed / data.proteinGoal : 0
    }
    private var carbsProgress: Double {
        data.carbsGoal > 0 ? data.carbsConsumed / data.carbsGoal : 0
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)

            VStack(spacing: 6) {
                Text("Netfuel")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ZStack {
                    // Outer: calories
                    ProgressRing(progress: calorieProgress, color: .red, lineWidth: 9)
                    // Middle: protein
                    ProgressRing(progress: proteinProgress, color: Color(red: 1, green: 0.45, blue: 0), lineWidth: 7)
                        .padding(12)
                    // Inner: carbs
                    ProgressRing(progress: carbsProgress, color: Color(red: 0.2, green: 0.8, blue: 0.4), lineWidth: 5)
                        .padding(24)

                    VStack(spacing: 0) {
                        Text("\(data.caloriesConsumed)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
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
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let data: WidgetData

    var body: some View {
        ZStack {
            Color(.systemBackground)

            HStack(spacing: 0) {
                MacroRingCell(
                    label: "Calories",
                    current: Double(data.caloriesConsumed),
                    goal: Double(data.calorieGoal),
                    unit: "kcal",
                    color: .red,
                    lineWidth: 9
                )

                Divider().padding(.vertical, 12)

                MacroRingCell(
                    label: "Protein",
                    current: data.proteinConsumed,
                    goal: data.proteinGoal,
                    unit: "g",
                    color: Color(red: 1, green: 0.45, blue: 0),
                    lineWidth: 7
                )

                Divider().padding(.vertical, 12)

                MacroRingCell(
                    label: "Carbs",
                    current: data.carbsConsumed,
                    goal: data.carbsGoal,
                    unit: "g",
                    color: Color(red: 0.2, green: 0.8, blue: 0.4),
                    lineWidth: 7
                )

                Divider().padding(.vertical, 12)

                MacroRingCell(
                    label: "Fat",
                    current: data.fatConsumed,
                    goal: data.fatGoal,
                    unit: "g",
                    color: Color(red: 0.4, green: 0.6, blue: 1),
                    lineWidth: 7
                )
            }
            .padding(.horizontal, 8)
        }
    }
}

private struct MacroRingCell: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    let lineWidth: CGFloat

    private var progress: Double { goal > 0 ? current / goal : 0 }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                ProgressRing(progress: progress, color: color, lineWidth: lineWidth)
                VStack(spacing: 0) {
                    Text("\(Int(current))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text(unit)
                        .font(.system(size: 8)).foregroundColor(.secondary)
                }
            }
            .frame(width: 54, height: 54)

            Text(label)
                .font(.caption2).foregroundColor(.secondary)
            Text("/ \(Int(goal))\(unit)")
                .font(.system(size: 9)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget Configuration

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

struct NetfuelWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NetfuelEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Widget Bundle

@main
struct NetfuelWidgetBundle: WidgetBundle {
    var body: some Widget {
        NetfuelWidget()
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
