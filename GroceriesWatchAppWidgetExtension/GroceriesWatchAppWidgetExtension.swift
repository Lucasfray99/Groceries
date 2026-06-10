import WidgetKit
import SwiftUI

struct GroceriesComplicationEntry: TimelineEntry {
    let date: Date
}

struct GroceriesComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> GroceriesComplicationEntry {
        GroceriesComplicationEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (GroceriesComplicationEntry) -> Void) {
        completion(GroceriesComplicationEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GroceriesComplicationEntry>) -> Void) {
        let entry = GroceriesComplicationEntry(date: .now)
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct GroceriesWatchAppWidgetExtensionEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: GroceriesComplicationEntry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            Gauge(value: 1) {
                Image(systemName: "cart")
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryCorner:
            Text("Groceries")
                .widgetLabel {
                    Image(systemName: "cart")
                }
        case .accessoryInline:
            Label("Groceries", systemImage: "cart")
        default:
            HStack(spacing: 8) {
                Image(systemName: "cart")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Groceries")
                        .font(.headline)
                    Text("Open list")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct GroceriesWatchAppWidgetExtension: Widget {
    let kind: String = "GroceriesWatchAppWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GroceriesComplicationProvider()) { entry in
            GroceriesWatchAppWidgetExtensionEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Groceries")
        .description("Open your grocery list quickly from the watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    GroceriesWatchAppWidgetExtension()
} timeline: {
    GroceriesComplicationEntry(date: .now)
}
