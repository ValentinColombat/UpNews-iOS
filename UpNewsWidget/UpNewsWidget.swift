import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let timeline = Timeline(entries: [SimpleEntry(date: Date())], policy: .atEnd)
        completion(timeline)
    }
}

struct UpNewsWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        Text("Hello")
            .foregroundColor(.white)
            .font(.largeTitle)
            .bold()
            .containerBackground(for: .widget) {
                Color.blue
            }
    }
}

@main
struct UpNewsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UpNewsWidget", provider: Provider()) { entry in
            UpNewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hello Widget")
        .description("Widget basique")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
