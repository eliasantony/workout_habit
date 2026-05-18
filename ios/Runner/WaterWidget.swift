import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todayMl: 0, goalMl: 2500, progressPercent: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), todayMl: 1250, goalMl: 2500, progressPercent: 0.5)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.example.hydro_habit")
        let todayMl = userDefaults?.integer(forKey: "todayMl") ?? 0
        let goalMl = userDefaults?.integer(forKey: "goalMl") ?? 2500
        let progressPercent = userDefaults?.double(forKey: "progressPercent") ?? 0.0

        let entry = SimpleEntry(date: Date(), todayMl: todayMl, goalMl: goalMl, progressPercent: progressPercent)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let todayMl: Int
    let goalMl: Int
    let progressPercent: Double
}

struct WaterWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Hydro Habit")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.blue)
            
            Text("\(entry.todayMl)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.blue)
            
            Text("of \(entry.goalMl) ml")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            ProgressView(value: entry.progressPercent)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 6)
                .cornerRadius(3)
        }
        .padding()
    }
}

@main
struct WaterWidget: Widget {
    let kind: String = "WaterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WaterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hydro Habit")
        .description("Track your daily water intake.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
