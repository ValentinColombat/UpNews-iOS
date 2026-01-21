//
//  UserDataService. swift
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
    
    // MARK:  - Published Properties
    
    // User data
    @Published var displayName: String = ""
    @Published var currentStreak: Int = 0
    @Published var selectedCompanionId: String = ""
    @Published var currentXp: Int = 0
    @Published var maxXp: Int = 100
    @Published var currentLevel:  Int = 1
    
    // Articles
    @Published var articles: [Article] = []
    @Published var mainArticle: Article?
    @Published var secondaryArticles: [Article] = []
    
    // MARK: - Init
    
    private init() {}
    
    // MARK:  - Companion Check
    
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
                print(" Compagnon trouvé: \(companion)")
                selectedCompanionId = companion
                return true
            } else {
                print(" Pas de compagnon sélectionné")
                return false
            }
        } catch {
            print(" Erreur vérification compagnon: \(error)")
            return false
        }
    }
    
    // MARK: - Data Loading
    
    /// Charge TOUTES les données utilisateur (streak, articles, profil)
    func loadAllData() async throws {
        print(" UserData: Début chargement données")
        
        // 1. Mise à jour du streak
        print(" UserData: Mise à jour streak...")
        let updatedStreak = try await StreakService.shared.updateStreak()
        currentStreak = updatedStreak
        print(" UserData: Streak = \(updatedStreak)")
        
        // 2. Chargement des articles
        print(" UserData:  Chargement articles...")
        try await loadArticles()
        print(" UserData: Articles chargés (\(articles.count))")
        
        // 3. Chargement du profil
        print(" UserData:  Chargement profil...")
        try await loadUserProfile()
        print(" UserData: Profil chargé:  \(displayName)")
        
        print(" UserData:  Toutes les données chargées")
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
        selectedCompanionId = profile.selected_companion_id ??  selectedCompanionId
        currentXp = profile.current_xp
        maxXp = profile.max_xp
        currentLevel = profile.current_level
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
    }
}
