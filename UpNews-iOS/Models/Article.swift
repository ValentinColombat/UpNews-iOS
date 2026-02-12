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
    let audioUrl: String?
    let audioFormat: String?

    
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
        case audioUrl = "audio_url"
        case audioFormat = "audio_format"
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
        case "ecologie", "écologie":
            return "leaf.fill"
        case "santé", "sante":
            return "cross.case.fill"
        case "sciences-et-tech":
            return "flask.fill"
        case "social-et-culture":
            return "theatermasks.fill"
        default:
            return "newspaper.fill"
        }
    }
    
    var categoryColor: Color {
        switch category.lowercased() {
        case "ecologie", "écologie":
            return .categoryEcology      // Vert vif
        case "santé", "sante":
            return .categoryHealth       // Rose clair
        case "sciences-et-tech":
            return .categoryTech         // Bleu
        case "social-et-culture":
            return .categoryCulture      // Violet clair
        default:
            return .categoryDefault      // Gris foncé
        }
    }
    
    /// Nom formaté de la catégorie pour l'affichage (avec "&" au lieu de "-et-")
    var categoryDisplayName: String {
        switch category.lowercased() {
        case "ecologie", "écologie":
            return "Écologie"
        case "santé", "sante":
            return "Santé"
        case "sciences-et-tech":
            return "Sciences & Tech"
        case "social-et-culture":
            return "Social & Culture"
        default:
            return category.capitalized
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
        if cleaned.count <= 70 {
            return cleaned
        }
        
        // Coupe à 150 caractères en essayant de finir à un espace
        let preview = cleaned.prefix(70)
        if let lastSpace = preview.lastIndex(of: " ") {
            return String(preview[..<lastSpace]) + "..."
        }
        
        return String(preview) + "..."
    }
}
