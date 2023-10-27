import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        var date = Date.now
        
        for i in 0 ..< 5 {
            date = date.byAdding(.hour, value: i)
            let entry = SimpleEntry(date: date)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        return timeline
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct GridEntryView : View {
    @Environment(\.widgetFamily) private var widgetFamily
    @Query(sort: \Habit.order) private var habits: [Habit]
    
    var entry: Provider.Entry

    var body: some View {
        if habits.isEmpty {
            emptyView
        } else {
            listView
        }
    }
    
    var emptyView: some View {
        VStack(spacing: 8) {
            Text("No habits")
                .font(.callout)
                .fontWeight(.medium)
            
            Text("Widgets display the first items of the list.")
                .font(.subheadline)
                .opacity(0.7)
        }
        .fontDesign(.rounded)
        .opacity(0.6)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 12)
    }
    
    var listView: some View {
        GeometryReader { proxy in
            HabitsView(habitsNumber: habitsNumber(of: proxy.size.width), width: proxy.size.width)
        }
    }
    
    func habitsNumber(of width: CGFloat) -> Int {
        switch widgetFamily {
        case .systemLarge:  return width < 335 ? 11 : 12
        case .systemMedium: return 5
        default:            return 5
        }
    }
}

struct LogIntent: AppIntent {
    // Empty to conform to AppIntent protocol
    init(){}

    static var title: LocalizedStringResource = "Log a day"

    @Parameter(title: "habit id")
    var habitID: Int
    
    @Parameter(title: "log id")
    var logID: Int

    init(habitID: Int, logID: Int) {
        self.habitID = habitID
        self.logID = logID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            let descriptor = FetchDescriptor<Log>()
            let logs = try modelContainer.mainContext.fetch(descriptor)
            let date = Date().reset(after: .day).byAdding(.day, value: logID)
            
            if let log = logs.first(where: { $0.habit?.order == habitID && $0.date.isDate(date) }) {
                modelContainer.mainContext.delete(log)
            } else {
                let log = Log(date: date)
                
                let habits = try modelContainer.mainContext.fetch(FetchDescriptor<Habit>())
                if let habit = habits.first(where: { $0.order == habitID }) {
                    log.habit = habit
                }
                
                modelContainer.mainContext.insert(log)
            }
        } catch {
            print("Error updating logs from widget. \(error.localizedDescription)")
        }

        return .result()
    }
}

struct Grid: Widget {
    let kind: String = "MyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GridEntryView(entry: entry)
                .containerBackground(.backgroundWidget, for: .widget)
                .modelContainer(modelContainer)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Habits Grid")
        .description("Log your habits directly from widgets.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    Grid()
} timeline: {
    SimpleEntry(date: .now)
}
