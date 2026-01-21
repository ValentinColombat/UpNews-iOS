//
//  ContentView.swift
//  UpNews-iOS

import SwiftUI

struct ContentView: View {
    
    // MARK: - State
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var appState = AppStateService.shared
    @StateObject private var authService = AuthService.shared
    @ObservedObject private var userDataService = UserDataService.shared
    
    // MARK:  - Body
    
    var body: some View {
        Group {
            switch appState.currentScreen {
            case .loading:
                LoadingView(message: "")
                
            case .onboarding:
                OnboardingView {
                    hasCompletedOnboarding = true
                    Task {
                        await appState.initialize(hasCompletedOnboarding: true)
                    }
                }
                
            case .auth:
                AuthView()
                
            case .companionSelection:
                CompanionSelectionView {
                    Task {
                        await appState.handleCompanionSelected()
                    }
                }
                
            case .main:
                MainTabView()
                    .environmentObject(userDataService)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
        .task {
            await appState.initialize(hasCompletedOnboarding: hasCompletedOnboarding)
        }
        .onChange(of: authService.isAuthenticated) { oldValue, isAuth in
            // Ignorer si pas de changement réel
            guard oldValue != isAuth else { return }
            
            Task {
                if isAuth {
                    // Connexion (Email ou Google)
                    await appState.handleAuthentication()
                } else {
                    // Déconnexion
                    appState.handleSignOut()
                }
            }
        }
    }
}
