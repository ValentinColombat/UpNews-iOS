import Foundation
import Supabase

/// Service pour gérer les articles depuis Supabase
class ArticleService {
    
    // MARK: - Singleton
    
    static let shared = ArticleService()
    
    private let client: SupabaseClient
    private let dateFormatter: DateFormatter  // ✅ Réutilisable
    
    // MARK: - Initialisation
    
    private init() {
        self.client = SupabaseConfig.client
        
        // ✅ FIX : Formatter configuré une seule fois
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    // MARK: - Récupération des articles
    
    /// Récupère tous les articles du jour (6 articles)
    func fetchTodayArticles() async throws -> [Article] {
        let today = dateFormatter.string(from: Date())  // ✅ Plus robuste
        
        let response = try await client
            .from("articles")
            .select()
            .eq("language", value: "fr")
            .eq("published_date", value: today)
            .order("created_at", ascending: false)  // ✅ BONUS : Tri par date
            .execute()
        
        let articles = try JSONDecoder().decode([Article].self, from: response.data)
        return articles
    }
    
    /// ✅ BONUS : Récupère un article spécifique
    func fetchArticle(id: UUID) async throws -> Article {
        let response = try await client
            .from("articles")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        
        let article = try JSONDecoder().decode(Article.self, from: response.data)
        return article
    }
    
    /// ✅ BONUS : Récupère les 7 derniers articles (historique)
    func fetchRecentArticles(limit: Int = 7) async throws -> [Article] {
        let response = try await client
            .from("articles")
            .select()
            .eq("language", value: "fr")
            .order("published_date", ascending: false)
            .limit(limit)
            .execute()
        
        let articles = try JSONDecoder().decode([Article].self, from: response.data)
        return articles
    }
}
