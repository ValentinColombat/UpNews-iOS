//
//  AppStateService.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 21/01/2026.

import SwiftUI
import Combine

@MainActor
class AppStateService:  ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppStateService()
    
    // MARK: - Published State
    
    @Published var currentScreen: AppScreen = .loading
    
    // MARK: - Dependencies
    
    private let authService = AuthService.shared
    private let userDataService = UserDataService.shared
    
    // MARK: - App Screen Enum
    
    enum AppScreen {
        case loading
        case onboarding
        case auth
        case companionSelection
        case categorySelection // ✅ NOUVEAU
        case main
    }
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Point d'entrée unique pour initialiser l'app
    func initialize(hasCompletedOnboarding: Bool) async {
        
        currentScreen = .loading
        
        print("🔵 AppState: initialize() - hasCompletedOnboarding: \(hasCompletedOnboarding)")
        
        // 1. Onboarding non terminé
        guard hasCompletedOnboarding else {
            print("🔵 AppState: Onboarding pas terminé → onboarding")
            currentScreen = .onboarding
            return
        }
        
        // 2. Vérifier authentification
        await authService.checkAuthStatus()
        
        print("🔵 AppState: isAuthenticated: \(authService.isAuthenticated)")
        
        guard authService.isAuthenticated else {
            print("🔵 AppState: Pas authentifié → auth")
            currentScreen = .auth
            return
        }
        
        // ✅ À PARTIR D'ICI, l'utilisateur EST authentifié
        
        // 3. Vérifier compagnon
        print("🔵 AppState: Vérification compagnon...")
        let hasCompanion = await userDataService.checkCompanion()
        
        print("🔵 AppState: hasCompanion: \(hasCompanion)")
        
        guard hasCompanion else {
            print("🔵 AppState: Pas de compagnon → companionSelection")
            currentScreen = .companionSelection
            return
        }
        
        // 4. Charger le profil pour vérifier les catégories
        print("🔵 AppState: Chargement profil...")
        do {
            try await userDataService.loadUserProfile()
            
            // Vérifier si l'utilisateur a des catégories préférées
            guard !userDataService.preferredCategories.isEmpty else {
                print("🔵 AppState: Pas de catégories → categorySelection")
                currentScreen = .categorySelection
                return
            }
            
            // 5. Charger le reste des données (articles, streak, stats)
            print("🔵 AppState: Chargement articles et stats...")
            try await userDataService.loadArticlesAndStats()
            
            print("🔵 AppState: Tout est prêt → main")
            currentScreen = .main
            
        } catch {
            print("❌ AppState: Erreur chargement données: \(error)")
            // En cas d'erreur, on ne déconnecte pas, on va quand même à companion
            currentScreen = .companionSelection
        }
    }
    
    /// Appelé après connexion (Email ou Google)
    func handleAuthentication() async {
        print("🟢 AppState: handleAuthentication() - Utilisateur connecté")
        currentScreen = .loading
        
        // Petit délai pour stabiliser la session (surtout pour Google OAuth)
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        // Après connexion, toujours aller à la sélection de compagnon
        currentScreen = .companionSelection
    }
    
    /// Appelé après sélection du compagnon
    func handleCompanionSelected() async {
        print("🔵 AppState: handleCompanionSelected() - Début")
        currentScreen = .loading
        
        // Petit délai pour laisser Supabase propager l'update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        do {
            // Recharger le profil complet pour récupérer le compagnon
            print("🔵 AppState: Chargement du profil après sélection compagnon...")
            try await userDataService.loadUserProfile()
            
            print("🔵 AppState: Profil chargé - Compagnon: \(userDataService.selectedCompanionId)")
            print("🔵 AppState: Catégories: \(userDataService.preferredCategories)")
            
            // Vérifier si l'utilisateur a des catégories préférées
            if userDataService.preferredCategories.isEmpty {
                print("🔵 AppState: Pas de catégories → categorySelection")
                currentScreen = .categorySelection
            } else {
                // L'utilisateur a déjà des catégories (cas rare)
                print("🔵 AppState: Catégories existantes → chargement articles")
                try await userDataService.loadArticlesAndStats()
                currentScreen = .main
            }
        } catch {
            print("❌ AppState: Erreur chargement profil après compagnon: \(error)")
            currentScreen = .categorySelection // Continuer quand même
        }
    }
    
    /// Appelé après sélection des catégories
    func handleCategoriesSelected() async {
        print("🟢 AppState: handleCategoriesSelected() - Début")
        currentScreen = .loading
        
        // Petit délai pour laisser Supabase propager l'update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        do {
            // Recharger TOUT pour être sûr d'avoir toutes les données
            print("🟢 AppState: Chargement complet des données...")
            try await userDataService.loadAllData()
            
            print("🟢 AppState: Données chargées - Compagnon: \(userDataService.selectedCompanionId)")
            print("🟢 AppState: Catégories: \(userDataService.preferredCategories)")
            print("🟢 AppState: Article principal: \(userDataService.mainArticle?.title ?? "none")")
            
            currentScreen = .main
        } catch {
            print("❌ AppState: Erreur chargement après catégories: \(error)")
            currentScreen = .auth
        }
    }
    
    /// Appelé lors de la déconnexion
    func handleSignOut() {
        
        userDataService.reset()
        currentScreen = .auth
    }
}
