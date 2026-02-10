//
//  UpNewsWidget.swift
//  UpNewsWidget
//
//  Widget simplifié pour test

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), message: "Hello World")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), message: "Hello World")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), message: "Hello World")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let message: String
}

// MARK: - Widget View

struct UpNewsWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Text("👋")
                .font(.system(size: 50))
            
            Text(entry.message)
                .font(.title)
                .fontWeight(.bold)
            
            Text(entry.date, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .containerBackground(for: .widget) {
            Color.orange.opacity(0.2)
        }
    }
}

// MARK: - Widget Configuration

@main
struct UpNewsWidget: Widget {
    let kind: String = "UpNewsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            UpNewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hello World Widget")
        .description("Widget de test simplifié")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

struct UpNewsWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UpNewsWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                message: "Hello World"
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            UpNewsWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                message: "Hello World"
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
