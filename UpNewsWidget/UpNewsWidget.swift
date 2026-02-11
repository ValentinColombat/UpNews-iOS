import WidgetKit
import SwiftUI

// MARK: - Entry Model 
struct SimpleEntry: TimelineEntry {
    let date: Date
    let articlesCount: Int
}

// MARK: - Provider
struct SimpleProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), articlesCount: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), articlesCount: 1))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.upnews.shared")
        let hasReadToday = sharedDefaults?.bool(forKey: "hasReadToday") ?? false
        let articlesCount = hasReadToday ? 0 : 1
        
        let entry = SimpleEntry(date: Date(), articlesCount: articlesCount)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget View
struct SimpleWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        ZStack {
            Text(timeBasedMessage)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                
                if entry.articlesCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text("\(entry.articlesCount)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: -4)
                }
            }
            .padding(2)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [.orange, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var timeBasedMessage: String {
        let hour = Calendar.current.component(.hour, from: entry.date)
        
        switch hour {
        case 5..<9:
            return "Bon matin"
        case 9..<12:
            return "Bonne journée"
        case 12..<14:
            return "Bon appétit"
        case 14..<18:
            return "Bon après-midi"
        case 18..<22:
            return "Bonne soirée"
        case 22..<24:
            return "Bonne nuit"
        default:
            return "Dors bien"
        }
    }
}

// MARK: - Widget Configuration
@main
struct UpNewsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UpNewsWidget", provider: SimpleProvider()) { entry in
            SimpleWidgetView(entry: entry)
        }
        .configurationDisplayName("UpNews")
        .description("Votre article quotidien vous attend")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    UpNewsWidget()
} timeline: {
    SimpleEntry(date: .now, articlesCount: 1)
    SimpleEntry(date: .now, articlesCount: 0)
}

