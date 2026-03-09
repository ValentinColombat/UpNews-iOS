//
//  ContentView.swift
//  UpNews-iOS

import SwiftUI

struct ContentView: View {
    
    // MARK: - State
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var appState = AppStateService.shared
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
                    appState.currentScreen = .auth
                }
                
            case .auth:
                AuthView()
                
            case .companionSelection:
                CompanionSelectionView {
                    Task {
                        await appState.handleCompanionSelected()
                    }
                }
            
            case .categorySelection:
                CategorySelectionView {
                    Task {
                        await appState.handleCategoriesSelected()
                    }
                }
                
            case .main:
                MainTabView()
                    .environmentObject(userDataService)
            }
        }
        .task {
            await appState.initialize(hasCompletedOnboarding: hasCompletedOnboarding)
        }
    }
}

