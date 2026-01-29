//
//  UserDataService.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 20/01/2026.

import SwiftUI
import Supabase
import Combine

@MainActor
class UserDataService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = UserDataService()
    
    // MARK: - Published Properties
    
    // User data
    @Published var displayName: String = ""
    @Published var currentStreak: Int = 0
    @Published var selectedCompanionId: String = ""
    @Published var currentXp: Int = 0
    @Published var maxXp: Int = 100
    @Published var currentLevel: Int = 1
    @Published var articlesReadToday: Int = 0
    @Published var articlesReadThisMonth: Int = 0
    
    // Articles
    @Published var articles: [Article] = []
    @Published var mainArticle: Article?
    @Published var secondaryArticles: [Article] = []
    
    // ✅ AJOUTER CETTE PROPRIÉTÉ
    private var currentUserId: String?
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Companion Check
    
    /// Vérifie si l'utilisateur a sélectionné un compagnon
    func checkCompanion() async -> Bool {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            struct UserCompanion: Decodable {
                let selected_companion_id: String?
            }
            
            let response = try await SupabaseConfig.client
                .from("users")
                .select("selected_companion_id")
                .eq("id", value: session.user.id.uuidString)
                .execute()
            
            let users = try JSONDecoder().decode([UserCompanion].self, from: response.data)
            
            if let companion = users.first?.selected_companion_id, !companion.isEmpty {
                print("✅ Compagnon trouvé: \(companion)")
                selectedCompanionId = companion
                return true
            } else {
                print("⚠️ Pas de compagnon sélectionné")
                return false
            }
        } catch {
            print("❌ Erreur vérification compagnon: \(error)")
            return false
        }
    }
    
    // MARK: - Data Loading
    
    /// Charge TOUTES les données utilisateur (streak, articles, profil)
    func loadAllData() async throws {
    
        // STOCKER L'userId dès le début
        let session = try await SupabaseConfig.client.auth.session
        currentUserId = session.user.id.uuidString
        
        // 1. Mise à jour du streak
        
        let updatedStreak = try await StreakService.shared.updateStreak()
        currentStreak = updatedStreak
        
        
        // 2. Chargement des articles
        
        try await loadArticles()
        
        
        // 3. Chargement du profil
        
        try await loadUserProfile()
        
        
        // 4. Charge les stats d'articles
        
        articlesReadToday = try await fetchArticlesReadToday()
        articlesReadThisMonth = try await fetchArticlesReadThisMonth()
        
        print("Données chargées")
       
    }
    
    // MARK: - XP Management
    
    /// Sauvegarde l'XP et le niveau dans Supabase
    func saveXpAndLevel() async throws {
        let session = try await SupabaseConfig.client.auth.session
        
        struct XpUpdate: Encodable {
            let current_xp: Int
            let current_level: Int
        }
        
        let update = XpUpdate(current_xp: currentXp, current_level: currentLevel)
        
        try await SupabaseConfig.client
            .from("users")
            .update(update)
            .eq("id", value: session.user.id.uuidString)
            .execute()
        
        print("💾 XP sauvegardé: \(currentXp) XP, Niveau \(currentLevel)")
    }
    
    // MARK: - Private Methods
    
    /// Charge les articles du jour depuis Supabase
    private func loadArticles() async throws {
        let fetchedArticles = try await ArticleService.shared.fetchTodayArticles()
        
        articles = fetchedArticles
        
        if let first = fetchedArticles.first {
            mainArticle = first
            secondaryArticles = Array(fetchedArticles.dropFirst().prefix(4))
        }
    }
    
    /// Charge le profil utilisateur depuis Supabase
    private func loadUserProfile() async throws {
        let session = try await SupabaseConfig.client.auth.session
        
        struct UserProfile: Decodable {
            let display_name: String
            let selected_companion_id: String?
            let current_xp: Int
            let max_xp: Int
            let current_level: Int
        }
        
        let response = try await SupabaseConfig.client
            .from("users")
            .select("display_name, selected_companion_id, current_xp, max_xp, current_level")
            .eq("id", value: session.user.id.uuidString)
            .execute()
        
        let users = try JSONDecoder().decode([UserProfile].self, from: response.data)
        
        guard let profile = users.first else {
            throw NSError(
                domain: "UserDataService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Profil utilisateur introuvable"]
            )
        }
        
        // Mise à jour des propriétés
        displayName = profile.display_name
        selectedCompanionId = profile.selected_companion_id ?? selectedCompanionId
        currentXp = profile.current_xp
        maxXp = profile.max_xp
        currentLevel = profile.current_level
    }
    
    // MARK: - Articles Stats
    
    /// Compte le nombre d'articles lus aujourd'hui
    func fetchArticlesReadToday() async throws -> Int {
        guard let userId = currentUserId else {
            print("❌ Pas d'userId")
            return 0
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let formatter = ISO8601DateFormatter()
        let todayString = formatter.string(from: today)
        let tomorrowString = formatter.string(from: tomorrow)
        
        let response = try await SupabaseConfig.client
            .from("user_article_interactions")
            .select("id", head: false, count: .exact)
            .eq("user_id", value: userId)
            .eq("is_read", value: true)
            .gte("read_at", value: todayString)
            .lt("read_at", value: tomorrowString)
            .execute()
        
        let count = response.count ?? 0
        
        return count
    }

    /// Compte le nombre d'articles lus ce mois-ci
    func fetchArticlesReadThisMonth() async throws -> Int {
        guard let userId = currentUserId else {
            print("❌ Pas d'userId")
            return 0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components) else { return 0 }
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return 0 }
        
        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: startOfMonth)
        let endString = formatter.string(from: startOfNextMonth)
        
        let response = try await SupabaseConfig.client
            .from("user_article_interactions")
            .select("id", head: false, count: .exact)
            .eq("user_id", value: userId)
            .eq("is_read", value: true)
            .gte("read_at", value: startString)
            .lt("read_at", value: endString)
            .execute()
        
        let count = response.count ?? 0
        
        return count
    }
    
    // MARK: - Reset
    
    /// Réinitialise toutes les données (utilisé lors de la déconnexion)
    func reset() {
        print("🔄 UserData: Reset des données")
        displayName = ""
        currentStreak = 0
        selectedCompanionId = ""
        currentXp = 0
        maxXp = 100
        currentLevel = 1
        articles = []
        mainArticle = nil
        secondaryArticles = []
        articlesReadToday = 0
        articlesReadThisMonth = 0
        currentUserId = nil // ✅ Reset aussi l'userId
    }
}
