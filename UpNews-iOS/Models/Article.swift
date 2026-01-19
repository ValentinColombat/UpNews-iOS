import Foundation
import SwiftUI  

struct Article: Identifiable, Codable, Hashable {
    let id: UUID
    let publishedDate: String
    let language: String
    let title: String
    let summary: String
    let content: String
    let category: String
    let imageUrl: String?
    let sourceUrl: String?
    let createdAt: String
    
    // MARK: - CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case id
        case publishedDate = "published_date"
        case language
        case title
        case summary
        case content
        case category
        case imageUrl = "image_url"
        case sourceUrl = "source_url"
        case createdAt = "created_at"
    }
    
    // MARK: - Computed Properties
    
    var isToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return publishedDate == today
    }
    
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "ecology", "ecologie", "écologie":
            return "leaf.fill"
        case "tech", "technologie":
            return "cpu.fill"
        case "social":
            return "heart.fill"
        case "culture":
            return "theatermasks.fill"
        case "science":
            return "flask.fill"
        case "health", "santé", "sante":
            return "cross.case.fill"
        default:
            return "newspaper.fill"
        }
    }
    
    var categoryColor: Color {
        switch category.lowercased() {
        case "ecology", "ecologie", "écologie":
            return .categoryEcology      // 6CC241 - Vert vif
        case "tech", "technologie":
            return .categoryTech         // 689EB1 - Bleu
        case "social":
            return .categorySocial       // FE813C - Orange
        case "culture":
            return .categoryCulture      // C4C1F2 - Violet clair
        case "science":
            return .categoryScience      // FEE155 - Jaune
        case "health", "santé", "sante":
            return .categoryHealth       // F9E1E1 - Rose clair
        default:
            return .categoryDefault      // 2C3E35 - Gris foncé
        }
    }
    
    /// Extrait les premières lignes du contenu pour l'aperçu
    var contentPreview: String {
        // Nettoie le contenu des balises markdown éventuelles
        let cleaned = content
            .replacingOccurrences(of: "**", with: "")  // Enlève le gras
            .replacingOccurrences(of: "##", with: "")  // Enlève les titres
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prend les 150 premiers caractères
        if cleaned.count <= 150 {
            return cleaned
        }
        
        // Coupe à 150 caractères en essayant de finir à un espace
        let preview = cleaned.prefix(150)
        if let lastSpace = preview.lastIndex(of: " ") {
            return String(preview[..<lastSpace]) + "..."
        }
        
        return String(preview) + "..."
    }
}
