//
//  UserDataService.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 20/01/2026.

import SwiftUI
import Supabase
import Combine


@MainActor
class UserDataService:  ObservableObject {
    
    static let shared = UserDataService()
    
    // User data
    @Published var displayName: String = ""
    @Published var currentStreak: Int = 0
    @Published var selectedCompanionId: String = ""
    @Published var currentXp: Int = 0
    @Published var maxXp:  Int = 100
    @Published var currentLevel:  Int = 1
    
    // Articles
    @Published var articles: [Article] = []
    @Published var mainArticle: Article?
    @Published var secondaryArticles: [Article] = []
    
    private init() {}
    
    /// Charge TOUTES les données utilisateur
    func loadAllData() async throws {

        do {
            print("🔵 1. Mise à jour streak...")
            let updatedStreak = try await StreakService.shared.updateStreak()
            
            print("🔵 2. Chargement articles...")
            try await loadArticles()
            print("✅ Articles chargés")
            
            print("🔵 3. Chargement profil utilisateur...")
            try await loadUserData()
            
            currentStreak = updatedStreak
            
        } catch {
            print(" Erreur dans loadAllData() : \(error)")
            throw error
        }
    }
    
    /// Charge les articles depuis Supabase
    private func loadArticles() async throws {
        let fetchedArticles = try await ArticleService.shared.fetchTodayArticles()
        
        articles = fetchedArticles
        
        if let first = fetchedArticles.first {
            mainArticle = first
            secondaryArticles = Array(fetchedArticles.dropFirst().prefix(4))
        }
    }
    
    /// Charge les données utilisateur depuis Supabase
    private func loadUserData() async throws {
        let session = try await SupabaseConfig.client.auth.session
        
        struct UserProfile: Decodable {
            let display_name: String
            let current_streak: Int
            let selected_companion_id: String?
            let current_xp:  Int
            let max_xp: Int
            let current_level: Int
        }
        
        // ✅ FIX :   Utiliser .execute() et décoder un tableau, puis prendre le premier
        let response = try await SupabaseConfig.client
            .from("users")
            .select("display_name, current_streak, selected_companion_id, current_xp, max_xp, current_level")
            .eq("id", value: session.user.id.uuidString)
            .execute()  // ✅ Au lieu de .  single()
        
        // ✅ Décoder comme un tableau
        let users = try JSONDecoder().decode([UserProfile].self, from: response.data)
        
        // ✅ Vérifier qu'on a bien un résultat
        guard let profile = users.first else {
            throw NSError(domain: "UserDataService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Profil utilisateur introuvable"])
        }
        
        // ✅ Mettre à jour les données
        displayName = profile.display_name
        currentStreak = profile.current_streak
        selectedCompanionId = profile.selected_companion_id ??  ""
        currentXp = profile.current_xp
        maxXp = profile.max_xp
        currentLevel = profile.current_level
        
        print("✅ Profil chargé :   \(displayName) - Compagnon:  \(selectedCompanionId)")
    }
    /// Réinitialise les données (à la déconnexion)
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
    }
}
