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
    @Published var preferredCategories: [String] = [] // ✅ NOUVEAU
    
    // Articles
    @Published var articles: [Article] = []
    @Published var mainArticle: Article?
    @Published var secondaryArticles: [Article] = []
    @Published var selectedMainArticleId: UUID? // ✅ NOUVEAU - ID de l'article sélectionné
    @Published var selectedMainArticleDate: String? // ✅ NOUVEAU - Date de sélection
    
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
        
        // 2. Chargement du profil
        try await loadUserProfile()
        
        // 3. Chargement des articles
        try await loadArticles()
        
        // 4. Charge les stats d'articles
        articlesReadToday = try await fetchArticlesReadToday()
        articlesReadThisMonth = try await fetchArticlesReadThisMonth()
        
        print("✅ Toutes les données chargées")
    }
    
    /// Charge uniquement les articles et les stats (utilisé après loadUserProfile)
    func loadArticlesAndStats() async throws {
        // STOCKER L'userId si pas déjà fait
        if currentUserId == nil {
            let session = try await SupabaseConfig.client.auth.session
            currentUserId = session.user.id.uuidString
        }
        
        // 1. Mise à jour du streak
        let updatedStreak = try await StreakService.shared.updateStreak()
        currentStreak = updatedStreak
        
        // 2. Chargement des articles
        try await loadArticles()
        
        // 3. Charge les stats d'articles
        articlesReadToday = try await fetchArticlesReadToday()
        articlesReadThisMonth = try await fetchArticlesReadThisMonth()
        
        print("✅ Articles et stats chargés")
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
    
    // MARK: - Preferred Categories Management
    
    /// Sauvegarde les catégories préférées dans Supabase (sans recharger les articles)
    func savePreferredCategories(_ categories: [String]) async throws {
        print("💾 UserDataService: savePreferredCategories() - Catégories: \(categories)")
        let session = try await SupabaseConfig.client.auth.session
        
        struct CategoryUpdate: Encodable {
            let preferred_categories: [String]
        }
        
        let update = CategoryUpdate(preferred_categories: categories)
        
        try await SupabaseConfig.client
            .from("users")
            .update(update)
            .eq("id", value: session.user.id.uuidString)
            .execute()
        
        // Mise à jour locale
        preferredCategories = categories
        
        print("✅ UserDataService: Catégories préférées sauvegardées: \(categories)")
    }
    
    /// Sauvegarde les catégories ET recharge les articles (utilisé depuis ProfileView)
    func updatePreferredCategories(_ categories: [String]) async throws {
        try await savePreferredCategories(categories)
        
        // Recharger les articles avec les nouvelles préférences
        try await loadArticles()
        
        print("🔄 Articles rechargés avec nouvelles préférences")
    }
    
    // MARK: - Private Methods
    
    /// Charge les articles du jour depuis Supabase
    private func loadArticles() async throws {
        print("📰 UserDataService: loadArticles() - Début")
        let fetchedArticles = try await ArticleService.shared.fetchTodayArticles()
        
        articles = fetchedArticles
        print("📰 UserDataService: \(fetchedArticles.count) articles récupérés")
        
        // Obtenir la date du jour au format yyyy-MM-dd
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        // Vérifier si on a déjà un article principal sélectionné pour aujourd'hui
        if let savedArticleId = selectedMainArticleId,
           let savedDate = selectedMainArticleDate,
           savedDate == today {
            // Chercher l'article sauvegardé dans les articles récupérés
            if let savedArticle = fetchedArticles.first(where: { $0.id == savedArticleId }) {
                print("📰 UserDataService: Article du jour déjà sélectionné: \(savedArticle.title)")
                mainArticle = savedArticle
                
                // Articles secondaires : tous sauf le principal
                secondaryArticles = Array(fetchedArticles.filter { $0.id != savedArticleId }.prefix(4))
                print("📰 UserDataService: \(secondaryArticles.count) articles secondaires sélectionnés")
                return
            } else {
                print("⚠️ UserDataService: Article sauvegardé introuvable, nouvelle sélection")
            }
        } else {
            print("📰 UserDataService: Pas d'article du jour ou date différente, nouvelle sélection")
        }
        
        // Nouvelle sélection d'article principal
        try await selectNewMainArticle(from: fetchedArticles, today: today)
    }
    
    /// Sélectionne et sauvegarde un nouvel article principal
    private func selectNewMainArticle(from fetchedArticles: [Article], today: String) async throws {
        // Sélection intelligente du mainArticle basée sur les catégories préférées
        if !preferredCategories.isEmpty {
            print("📰 UserDataService: Filtrage par catégories préférées: \(preferredCategories)")
            
            // Filtrer les articles selon les catégories préférées
            let preferredArticles = fetchedArticles.filter { article in
                preferredCategories.contains(article.category.lowercased())
            }
            
            print("📰 UserDataService: \(preferredArticles.count) articles correspondent aux préférences")
            
            if !preferredArticles.isEmpty {
                // Sélection aléatoire parmi les articles préférés
                mainArticle = preferredArticles.randomElement()
                print("📰 UserDataService: Article principal sélectionné: \(mainArticle?.title ?? "none") - Catégorie: \(mainArticle?.category ?? "none")")
                
                // Sauvegarder la sélection
                if let selectedArticle = mainArticle {
                    try await saveMainArticleSelection(articleId: selectedArticle.id, date: today)
                }
                
                // Articles secondaires : mélange d'articles préférés et autres
                let remainingPreferred = preferredArticles.filter { $0.id != mainArticle?.id }
                let otherArticles = fetchedArticles.filter { article in
                    article.id != mainArticle?.id && !preferredCategories.contains(article.category.lowercased())
                }
                
                // Prioriser les articles préférés, puis compléter avec d'autres
                let combined = remainingPreferred + otherArticles
                secondaryArticles = Array(combined.prefix(4))
                print("📰 UserDataService: \(secondaryArticles.count) articles secondaires sélectionnés")
            } else {
                print("⚠️ UserDataService: Aucun article ne correspond aux préférences, fallback")
                // Fallback si aucun article préféré n'est disponible
                try await fallbackArticleSelection(from: fetchedArticles, today: today)
            }
        } else {
            print("⚠️ UserDataService: Pas de catégories préférées, fallback")
            // Fallback si pas de catégories préférées définies
            try await fallbackArticleSelection(from: fetchedArticles, today: today)
        }
    }
    
    /// Sélection par défaut des articles (fallback)
    private func fallbackArticleSelection(from articles: [Article], today: String) async throws {
        if let first = articles.first {
            mainArticle = first
            
            // Sauvegarder la sélection
            try await saveMainArticleSelection(articleId: first.id, date: today)
            
            secondaryArticles = Array(articles.dropFirst().prefix(4))
        }
    }
    
    /// Sauvegarde l'article principal sélectionné dans Supabase
    private func saveMainArticleSelection(articleId: UUID, date: String) async throws {
        let session = try await SupabaseConfig.client.auth.session
        
        struct MainArticleUpdate: Encodable {
            let selected_main_article_id: UUID
            let selected_main_article_date: String
        }
        
        let update = MainArticleUpdate(
            selected_main_article_id: articleId,
            selected_main_article_date: date
        )
        
        try await SupabaseConfig.client
            .from("users")
            .update(update)
            .eq("id", value: session.user.id.uuidString)
            .execute()
        
        // Mise à jour locale
        selectedMainArticleId = articleId
        selectedMainArticleDate = date
        
        print("✅ UserDataService: Article principal sauvegardé pour la journée")
    }
    
    /// Charge le profil utilisateur depuis Supabase
    func loadUserProfile() async throws {
        print("📥 UserDataService: loadUserProfile() - Début")
        let session = try await SupabaseConfig.client.auth.session
        
        struct UserProfile: Decodable {
            let display_name: String
            let selected_companion_id: String?
            let current_xp: Int
            let max_xp: Int
            let current_level: Int
            let preferred_categories: [String]?
            let selected_main_article_id: UUID? // ✅ NOUVEAU
            let selected_main_article_date: String? // ✅ NOUVEAU
        }
        
        let response = try await SupabaseConfig.client
            .from("users")
            .select("display_name, selected_companion_id, current_xp, max_xp, current_level, preferred_categories, selected_main_article_id, selected_main_article_date")
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
        selectedCompanionId = profile.selected_companion_id ?? ""
        currentXp = profile.current_xp
        maxXp = profile.max_xp
        currentLevel = profile.current_level
        preferredCategories = profile.preferred_categories ?? []
        selectedMainArticleId = profile.selected_main_article_id // ✅ NOUVEAU
        selectedMainArticleDate = profile.selected_main_article_date // ✅ NOUVEAU
        
        print("📥 UserDataService: Profil chargé:")
        print("   - Nom: \(displayName)")
        print("   - Compagnon: \(selectedCompanionId)")
        print("   - Catégories: \(preferredCategories)")
        print("   - Niveau: \(currentLevel), XP: \(currentXp)/\(maxXp)")
        print("   - Article du jour: \(selectedMainArticleId?.uuidString ?? "none"), date: \(selectedMainArticleDate ?? "none")")
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
        preferredCategories = []
        selectedMainArticleId = nil // ✅ NOUVEAU
        selectedMainArticleDate = nil // ✅ NOUVEAU
        currentUserId = nil
    }
}
