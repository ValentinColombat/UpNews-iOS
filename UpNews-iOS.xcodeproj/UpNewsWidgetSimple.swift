import WidgetKit
import SwiftUI

// MARK: - Entry Model STATIQUE
struct SimpleEntry: TimelineEntry {
    let date: Date
    let companionName: String = "Brume"
    let streakCount: Int = 7
    let articlesCount: Int = 3
}

// MARK: - Provider SIMPLE
struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget View SIMPLE
struct SimpleWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(
                colors: [.orange, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Contenu
            VStack(spacing: 16) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text(entry.companionName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.yellow)
                    Text("\(entry.streakCount) jours")
                        .foregroundColor(.white)
                }
                
                Text("\(entry.articlesCount) articles")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

// MARK: - Widget Configuration
@main
struct SimpleUpNewsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SimpleUpNewsWidget", provider: SimpleProvider()) { entry in
            SimpleWidgetView(entry: entry)
        }
        .configurationDisplayName("UpNews Simple")
        .description("Widget de test avec données statiques")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    SimpleUpNewsWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .systemMedium) {
    SimpleUpNewsWidget()
} timeline: {
    SimpleEntry(date: .now)
}
