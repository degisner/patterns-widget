import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct Provider: AppIntentTimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), rows: [])
    }

    @MainActor
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), rows: getRows())
    }
    
    @MainActor
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        var date = Date.now
        
        for i in 0 ..< 5 {
            date = date.byAdding(.hour, value: i)
            let entry = SimpleEntry(date: date, rows: getRows())
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        return timeline
    }
    
    @MainActor
    func getRows() -> [Row] {
        GridWidgetViewModel.shared.getRows()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let rows: [Row]
}

struct GridEntryView : View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: Provider.Entry

    var body: some View {
        if entry.rows.isEmpty {
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
            VStack(spacing: 0) {
                ForEach(0 ..< rowsNumber(of: proxy.size.width), id: \.self) { index in
                    if entry.rows.indices.contains(index) {
                        let row = entry.rows[index]
                        
                        if row.id != 0 {
                            Spacer(minLength: 0)
                        }
                        
                        rowView(row: row, width: proxy.size.width)
                    } else {
                        Rectangle().fill(.backgroundWidget)
                            .frame(height: size(of: proxy.size.width))
                    }
                }
            }
            .padding(.vertical, padding(of: proxy.size.width))
        }
    }
    
    func rowView(row: Row, width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text(row.icon)
                .font(font(of: width))
                .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 0)
            
            ForEach(firstItemIndex(of: width) ..< 11, id: \.self) { index in
                if row.items.indices.contains(index) {
                    let item = row.items[index]
                    itemView(row: row, item: item, width: width)
                }
            }
        }
        .padding(.horizontal, padding(of: width))
    }
    
    func itemView(row: Row, item: Item, width: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .foregroundStyle(row.color)
                .opacity(item.isLogged ? 0.3 : 0.2)
            
            Button(intent: LogIntent(rowID: row.id, itemID: item.id)) {
                Rectangle()
                    .foregroundStyle(.backgroundWidget)
            }
            .buttonStyle(.borderless)
            
            RoundedRectangle(cornerRadius: item.isLogged ? 4 : 7, style: .continuous)
                .foregroundStyle(row.color)
                .frame(width: 14, height: 14)
                .scaleEffect(item.isLogged ? 1 : 0.6)
                .opacity(item.isLogged ? 1 : 0.3)
        }
        .frame(width: size(of: width), height: size(of: width))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.isLogged)
    }
    
    // Small widget width:
    // iPhone Mini's width is 155
    // iPhone 15 Pro's width is 158
    // iPhone 15 Pro Max's width is 170
    //
    // Medium & Large widget width:
    // iPhone Mini's width is 329
    // iPhone 15 Pro's width is 338
    // iPhone 15 Pro Max's width is 364
    func size(of width: CGFloat) -> CGFloat {
        switch widgetFamily {
        case .systemSmall:
            switch width {
            case ..<156: return 24
            case ..<160: return 26
            default:     return 28
            }
        default:
            switch width {
            case ..<335: return 24.5
            case ..<350: return 25.75
            default:     return 27.6
            }
        }
    }
    
    func rowsNumber(of width: CGFloat) -> Int {
        switch widgetFamily {
        case .systemLarge:  return width < 335 ? 11 : 12
        case .systemMedium: return 5
        default:            return 5
        }
    }
    
    func firstItemIndex(of width: CGFloat) -> Int {
        switch widgetFamily {
        case .systemSmall: return 7
        default:           return width < 335 ? 1 : 0
        }
    }
    
    func padding(of width: CGFloat) -> CGFloat {
        switch widgetFamily {
        case .systemSmall:
            switch width {
            case ..<156: return 10
            case ..<160: return 14
            default:     return 15
            }
        case .systemMedium:
            switch width {
            case ..<335: return 10
            case ..<350: return 14
            default:     return 16
            }
        default:
            switch width {
            case ..<335: return 11
            case ..<350: return 14
            default:     return 16
            }
        }
    }
    
    func font(of width: CGFloat) -> Font {
        switch widgetFamily {
        case .systemSmall: return width < 156 ? .footnote : .subheadline
        default:           return width < 335 ? .footnote : .subheadline
        }
    }
}

struct LogIntent: AppIntent {
    // Empty to conform to AppIntent protocol
    init(){}

    static var title: LocalizedStringResource = "Log a day"

    @Parameter(title: "row id")
    var rowID: Int
    
    @Parameter(title: "item id")
    var itemID: Int

    init(rowID: Int, itemID: Int) {
        self.rowID = rowID
        self.itemID = itemID
    }

    func perform() async throws -> some IntentResult {
        await GridWidgetViewModel.shared.update(rowID: rowID, itemID: itemID)

        return .result()
    }
}

struct Grid: Widget {
    let kind: String = "MyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GridEntryView(entry: entry)
                .containerBackground(.backgroundWidget, for: .widget)
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
    SimpleEntry(date: .now, rows: GridWidgetViewModel.shared.getRows())
}
