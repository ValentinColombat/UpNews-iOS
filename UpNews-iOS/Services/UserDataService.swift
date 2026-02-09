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
    
    // Notifications
    @Published var notificationTime: String? = nil // Heure de notification (ex: "09:00")
    @Published var notificationBonusClaimed: Bool = false // Bonus +80 XP réclamé
    
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
    
    /// Vérifie si l'utilisateur a sélectionné un compagnon ET un pseudo
    func checkCompanion() async -> Bool {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            struct UserCompanion: Decodable {
                let selected_companion_id: String?
                let display_name: String?
            }
            
            let response = try await SupabaseConfig.client
                .from("users")
                .select("selected_companion_id, display_name")
                .eq("id", value: session.user.id.uuidString)
                .execute()
            
            let users = try JSONDecoder().decode([UserCompanion].self, from: response.data)
            
            if let user = users.first,
               let companion = user.selected_companion_id, !companion.isEmpty,
               let displayName = user.display_name, !displayName.isEmpty {
                selectedCompanionId = companion
                return true
            } else {
                return false
            }
        } catch {
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
    }
    
    // MARK: - Preferred Categories Management
    
    /// Sauvegarde les catégories préférées dans Supabase (sans recharger les articles)
    func savePreferredCategories(_ categories: [String]) async throws {
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
    }
    
    /// Sauvegarde les catégories ET recharge les articles (utilisé depuis ProfileView)
    func updatePreferredCategories(_ categories: [String]) async throws {
        try await savePreferredCategories(categories)
        
        // Recharger les articles avec les nouvelles préférences
        try await loadArticles()
    }
    
    // MARK: - Private Methods
    
    /// Charge les articles du jour depuis Supabase
    private func loadArticles() async throws {
        let fetchedArticles = try await ArticleService.shared.fetchTodayArticles()
        
        articles = fetchedArticles
        
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
                mainArticle = savedArticle
                
                // Articles secondaires : tous sauf le principal
                secondaryArticles = Array(fetchedArticles.filter { $0.id != savedArticleId }.prefix(4))
                return
            }
        }
        
        // Nouvelle sélection d'article principal
        try await selectNewMainArticle(from: fetchedArticles, today: today)
    }
    
    /// Sélectionne et sauvegarde un nouvel article principal
    private func selectNewMainArticle(from fetchedArticles: [Article], today: String) async throws {
        // Sélection intelligente du mainArticle basée sur les catégories préférées
        if !preferredCategories.isEmpty {
            // Filtrer les articles selon les catégories préférées
            let preferredArticles = fetchedArticles.filter { article in
                preferredCategories.contains(article.category.lowercased())
            }
            
            if !preferredArticles.isEmpty {
                // Sélection aléatoire parmi les articles préférés
                mainArticle = preferredArticles.randomElement()
                
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
            } else {
                // Fallback si aucun article préféré n'est disponible
                try await fallbackArticleSelection(from: fetchedArticles, today: today)
            }
        } else {
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
    }
    
    /// Charge le profil utilisateur depuis Supabase
    func loadUserProfile() async throws {
        let session = try await SupabaseConfig.client.auth.session
        
        struct UserProfile: Decodable {
            let display_name: String
            let selected_companion_id: String?
            let current_xp: Int
            let max_xp: Int
            let current_level: Int
            let preferred_categories: [String]?
            let selected_main_article_id: UUID?
            let selected_main_article_date: String?
            let notification_time: String?
            let notification_bonus_claimed: Bool?
        }
        
        let response = try await SupabaseConfig.client
            .from("users")
            .select("display_name, selected_companion_id, current_xp, max_xp, current_level, preferred_categories, selected_main_article_id, selected_main_article_date, notification_time, notification_bonus_claimed")
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
        selectedMainArticleId = profile.selected_main_article_id
        selectedMainArticleDate = profile.selected_main_article_date
        notificationTime = profile.notification_time
        notificationBonusClaimed = profile.notification_bonus_claimed ?? false
    }
    
    // MARK: - Articles Stats
    
    /// Compte le nombre d'articles lus aujourd'hui
    func fetchArticlesReadToday() async throws -> Int {
        guard let userId = currentUserId else {
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
        selectedMainArticleId = nil
        selectedMainArticleDate = nil
        currentUserId = nil
        notificationTime = nil
        notificationBonusClaimed = false
    }
    
    // MARK: - Notification Management
    
    /// Donne le bonus XP pour l'activation des notifications (+80 XP)
    func claimNotificationBonus() async throws {
        guard !notificationBonusClaimed else {
            
            return
        }
        
        let session = try await SupabaseConfig.client.auth.session
        
        // Ajouter 80 XP
        currentXp += 80
        
        // Vérifier si on passe de niveau(x)
        while currentXp >= 100 {
            currentXp -= 100
            currentLevel += 1
        }
        
        // Marquer le bonus comme réclamé
        notificationBonusClaimed = true
        
        // Sauvegarder dans Supabase
        struct NotificationBonusUpdate: Encodable {
            let current_xp: Int
            let current_level: Int
            let notification_bonus_claimed: Bool
        }
        
        let update = NotificationBonusUpdate(
            current_xp: currentXp,
            current_level: currentLevel,
            notification_bonus_claimed: true
        )
        
        try await SupabaseConfig.client
            .from("users")
            .update(update)
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }
    
    /// Sauvegarde l'heure de notification (hybride: UserDefaults + Supabase)
    func saveNotificationTime(_ time: String) async throws {
        // 1. Sauvegarder localement (rapide, offline)
        UserDefaults.standard.set(time, forKey: "notificationTime")
        notificationTime = time
        
        // 2. Sauvegarder dans Supabase (backup, sync)
        let session = try await SupabaseConfig.client.auth.session
        
        struct NotificationTimeUpdate: Encodable {
            let notification_time: String
        }
        
        let update = NotificationTimeUpdate(notification_time: time)
        
        try await SupabaseConfig.client
            .from("users")
            .update(update)
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }
    
    /// Calcule le max XP pour un niveau donné
    private func calculateMaxXp(for level: Int) -> Int {
        return 100 + (level - 1) * 50
    }
}
