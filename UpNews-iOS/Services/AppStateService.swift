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
        
        // 3. Vérifier compagnon
        let hasCompanion = await userDataService.checkCompanion()
        
        guard hasCompanion else {
            currentScreen = .companionSelection
            return
        }
        
        // 4. Charger le profil pour vérifier les catégories
        do {
            try await userDataService.loadUserProfile()
            
            guard !userDataService.preferredCategories.isEmpty else {
                currentScreen = .categorySelection
                return
            }
            
            // 5. Charger le reste des données (articles, streak, stats)
            try await userDataService.loadArticlesAndStats()
            
            currentScreen = .main
            
        } catch {
            currentScreen = .companionSelection
        }
    }
    
    /// Appelé après connexion (Email ou Google)
    func handleAuthentication() async {
        currentScreen = .loading
        
        // Petit délai pour stabiliser la session (surtout pour Google OAuth)
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        let hasCompanion = await userDataService.checkCompanion()
        
        guard hasCompanion else {
            currentScreen = .companionSelection
            return
        }
        
        do {
            try await userDataService.loadUserProfile()
            
            guard !userDataService.preferredCategories.isEmpty else {
                currentScreen = .categorySelection
                return
            }
            
            try await userDataService.loadArticlesAndStats()
            
            currentScreen = .main
            
        } catch {
            currentScreen = .companionSelection
        }
    }
    
    /// Appelé après sélection du compagnon
    func handleCompanionSelected() async {
        currentScreen = .loading
        
        // Petit délai pour laisser Supabase propager l'update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        do {
            try await userDataService.loadUserProfile()
            
            if userDataService.preferredCategories.isEmpty {
                currentScreen = .categorySelection
            } else {
                try await userDataService.loadArticlesAndStats()
                currentScreen = .main
            }
        } catch {
            currentScreen = .categorySelection
        }
    }
    
    /// Appelé après sélection des catégories
    func handleCategoriesSelected() async {
        currentScreen = .loading
        
        // Petit délai pour laisser Supabase propager l'update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        do {
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
