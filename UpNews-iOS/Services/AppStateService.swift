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
        case categorySelection 
        case main
    }
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Point d'entrée unique pour initialiser l'app
    func initialize(hasCompletedOnboarding: Bool) async {
        
        currentScreen = .loading
        
        // 1. Onboarding non terminé
        guard hasCompletedOnboarding else {
            currentScreen = .onboarding
            return
        }
        
        // 2. Vérifier authentification
        await authService.checkAuthStatus()
        
        guard authService.isAuthenticated else {
            currentScreen = .auth
            return
        }
        
        // Utilisateur EST authentifié
        
        // 3. Vérifier compagnon
        let hasCompanion = await userDataService.checkCompanion()
        
        guard hasCompanion else {
            currentScreen = .companionSelection
            return
        }
        
        // 4. Charger le profil pour vérifier les catégories
        do {
            try await userDataService.loadUserProfile()
            
            // Vérifier si l'utilisateur a des catégories préférées
            guard !userDataService.preferredCategories.isEmpty else {
                currentScreen = .categorySelection
                return
            }
            
            // 5. Charger le reste des données (articles, streak, stats)
            try await userDataService.loadArticlesAndStats()
            
            currentScreen = .main
            
        } catch {
            // En cas d'erreur, on ne déconnecte pas, on va quand même à companion
            currentScreen = .companionSelection
        }
    }
    
    /// Appelé après connexion (Email ou Google)
    func handleAuthentication() async {
        currentScreen = .loading
        
        // Petit délai pour stabiliser la session (surtout pour Google OAuth)
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        // Vérifier si l'utilisateur a déjà un compagnon
        let hasCompanion = await userDataService.checkCompanion()
        
        guard hasCompanion else {
            currentScreen = .companionSelection
            return
        }
        
        // L'utilisateur a un compagnon, charger le profil complet
        do {
            try await userDataService.loadUserProfile()
            
            // Vérifier si l'utilisateur a des catégories préférées
            guard !userDataService.preferredCategories.isEmpty else {
                currentScreen = .categorySelection
                return
            }
            
            // Charger les articles et stats
            try await userDataService.loadArticlesAndStats()
            
            currentScreen = .main
            
        } catch {
            // En cas d'erreur, retourner à companionSelection pour sécurité
            currentScreen = .companionSelection
        }
    }
    
    /// Appelé après sélection du compagnon
    func handleCompanionSelected() async {
        currentScreen = .loading
        
        // Petit délai pour laisser Supabase propager l'update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        do {
            // Recharger le profil complet pour récupérer le compagnon
            try await userDataService.loadUserProfile()
            
            // Vérifier si l'utilisateur a des catégories préférées
            if userDataService.preferredCategories.isEmpty {
                currentScreen = .categorySelection
            } else {
                // L'utilisateur a déjà des catégories (cas rare)
                try await userDataService.loadArticlesAndStats()
                currentScreen = .main
            }
        } catch {
            currentScreen = .categorySelection // Continuer quand même
        }
    }
    
    /// Appelé après sélection des catégories
    func handleCategoriesSelected() async {
        currentScreen = .loading
        
        // Petit délai pour laisser Supabase propager l'update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        do {
            // Recharger TOUT pour être sûr d'avoir toutes les données
            try await userDataService.loadAllData()
            
            currentScreen = .main
        } catch {
            currentScreen = .auth
        }
    }
    
    /// Appelé lors de la déconnexion
    func handleSignOut() {
        userDataService.reset()
        currentScreen = .auth
    }
}
