//
//  HomeFeedView.swift
//  UpNews-iOS

import SwiftUI
import Supabase
import Auth

struct HomeFeedView: View {
    
    // MARK: - State
    
    @State private var articles: [Article] = []
    @State private var mainArticle: Article?
    @State private var secondaryArticles:  [Article] = []
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // User data
    @State private var displayName: String = ""
    @State private var currentStreak: Int = 0
    @State private var selectedCompanionId: String = ""
    
    @StateObject private var authService = AuthService.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    
                    if let main = mainArticle {
                        mainArticleCard(main)
                    }
                    
                    secondaryArticlesSection
                }
                .padding(. bottom, 40)
            }
            .background(Color.upNewsBackground)
            .ignoresSafeArea(edges: .top)
        }
        .task {
            await loadAllData()
        }
    }
    
    // MARK: - Hero Card (PLEIN ÉCRAN)
    
    private var heroCard: some View {
        ZStack {
            // Background image PLEIN ÉCRAN
            GeometryReader { geometry in
                Image("BackgroundHomePage2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: 500)
                    .blur(radius: 3)
                    .clipped()
            }
            . frame(height: 500)
            
            VStack(spacing: 0) {
                // Header avec les 2 pastilles UNIQUEMENT
                HStack(alignment: .top) {
                    //Pastille gauche - Streak
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 50, height: 50)
                            .overlay(
                                FlameLottieView()
                            )
                        
                        Text("\(currentStreak) jour\(currentStreak > 1 ? "s" : "")")
                            . font(.system(size: 14, weight: .bold))
                            .foregroundColor(. white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    . offset(y: 15)
                    
                    Spacer()
                    
                    // Bonjour + Prénom (CENTRÉ)
                    VStack(spacing: 4) {
                        Text("Bonjour")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y:  2)
                            .offset(y: 5)
                        Text(displayName)
                            . font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y:  2)
                    }
                    
                    Spacer()
                    
                    // Pastille droite - Niveau
                    VStack(spacing:  4) {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "sunrise.fill")
                                    .foregroundColor(.upNewsOrange)
                                    .font(.system(size: 24))
                            )
                        
                        Text("Niv. 5")
                            .font(.system(size: 14, weight:  .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    }
                    . offset(y: 15)
                }
                . padding(. horizontal, 30)
                .padding(.top, 60)
                
                Spacer()
                
                ZStack {
                    // Compagnon centré
                    if !selectedCompanionId.isEmpty {
                        Image(selectedCompanionId)
                            .resizable()
                            . scaledToFit()
                            .frame(height: 280)
                    } else {
                        Image(systemName: "pawprint.fill")
                            . font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(height: 180)
                    }
                    
                    // Barre XP à droite (overlay)
                    HStack {
                        Spacer()
                        ProgressBar(progress: 0.65, orientation: .vertical)
                            .frame(width: 12, height: 220)
                            .padding(.bottom, 20)
                            .padding(.trailing, 50)
                    }
                }
                .frame(height: 280)
                
                Spacer()
                
                // CTA Button avec NavigationLink
                if let main = mainArticle {
                    NavigationLink(destination: ArticleDetailView(article: main)) {
                        HStack(spacing: 8) {
                            Text("Découvre ta bonne nouvelle")
                                .font(.system(size: 16, weight:  .semibold))
                            Image(systemName: "sun.haze.fill")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange.opacity(0.95))
                        .cornerRadius(12)
                        .shadow(radius: 1, x: 0, y: 2)
                    }
                    .padding(.horizontal, 30)
                } else {
                    // Bouton disabled pendant le chargement
                    HStack(spacing: 8) {
                        Text("Chargement...")
                            .font(.system(size: 16, weight: . semibold))
                        Image(systemName: "sun.haze.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                }
            }
        }
        .frame(height: 500)
        .ignoresSafeArea(edges:  .top)
    }
    
    // MARK: - Main Article Card
    
    private func mainArticleCard(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Badge catégorie
            HStack {
                Image(systemName: article.categoryIcon)
                    .font(. caption)
                Text(article.category.capitalized)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.upNewsBackground)
            .foregroundColor(.black)
            .cornerRadius(8)
            
            // Titre
            Text(article.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.upNewsBlack)
                .lineLimit(3)
            
            // Description
            Text(article.contentPreview)
                .font(.system(size: 15))
                .foregroundColor(. secondary)
                .lineLimit(3)
            
            // Boutons Lire / Audio
            HStack(spacing: 12) {
                // Bouton Lire avec NavigationLink
                NavigationLink(destination: ArticleDetailView(article: article)) {
                    Label("Lire", systemImage: "book.fill")
                        . font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.upNewsOrange)
                        .cornerRadius(12)
                }
                
                // Bouton Audio
                Button(action: {
                    // Preview action
                }) {
                    Label("Audio", systemImage: "headphones")
                        .font(.system(size: 16, weight: . semibold))
                        . foregroundColor(.white)
                        .frame(maxWidth: . infinity)
                        .frame(height: 48)
                        .background(Color.gray)
                        .cornerRadius(12)
                }
                .disabled(true)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .shadow(radius: 1, x: 0, y:  2)
    }
    
    // MARK: - Secondary Articles Section
    
    private var secondaryArticlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Titre section
            HStack {
                Text("Voir tous les articles du jour")
                    .font(.system(size: 18, weight:  .semibold))
                    .foregroundColor(.upNewsBlack)
                
                Text("...")
                    .font(.system(size: 18))
                    .foregroundColor(. secondary)
            }
            . padding(.top, 20)
            .padding(.horizontal, 30)
            
            // Liste articles
            VStack(spacing: 12) {
                ForEach(secondaryArticles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        secondaryArticleCard(article)
                    }
                    .buttonStyle(. plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func secondaryArticleCard(_ article: Article) -> some View {
        HStack(spacing: 12) {
            // Badge catégorie
            VStack {
                Image(systemName: article.categoryIcon)
                    . font(.caption)
                    .foregroundColor(article.categoryColor)
            }
            . frame(width: 40, height: 40)
            .background(article.categoryColor.opacity(0.1))
            .cornerRadius(8)
            
            // Titre + catégorie
            VStack(alignment: .leading, spacing: 4) {
                Text(article.category.capitalized)
                    . font(.caption)
                    .foregroundColor(.secondary)
                
                Text(article.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.upNewsBlack)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName:  "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1, x: 0, y: 2)
    }
    
    // MARK:  - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle. fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Erreur")
                .font(.title2)
                .fontWeight(. bold)
            
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Réessayer") {
                Task {
                    await loadAllData()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.upNewsPrimary)
        }
        .padding()
    }
    
    // MARK: - Data Loading
    
    /// Charge toutes les données (articles + user)
    private func loadAllData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Mettre à jour la streak
            let updatedStreak = try await StreakService.shared.updateStreak()
            
            // Charger séquentiellement
            try await loadArticles()
            try await loadUserData()
            
            await MainActor.run {
                currentStreak = updatedStreak
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Impossible de charger les données :  \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Charge les articles depuis Supabase
    private func loadArticles() async throws {
        let fetchedArticles = try await ArticleService.shared.fetchTodayArticles()
        
        await MainActor.run {
            articles = fetchedArticles
            
            // Article principal = premier article
            if let first = fetchedArticles.first {
                mainArticle = first
                // Articles secondaires = les autres (max 4)
                secondaryArticles = Array(fetchedArticles.dropFirst().prefix(4))
            }
        }
    }
    
    /// Charge les données utilisateur depuis Supabase
    private func loadUserData() async throws {
        let session = try await SupabaseConfig.client.auth.session
        
        // Récupérer les données utilisateur
        struct UserProfile: Decodable {
            let display_name: String
            let current_streak: Int
            let selected_companion_id: String?
        }
        
        let response = try await SupabaseConfig.client
            .from("users")
            .select("display_name, current_streak, selected_companion_id")
            .eq("id", value: session.user.id.uuidString)
            .execute()
        
        let users = try JSONDecoder().decode([UserProfile].self, from: response.data)
        
        await MainActor.run {
            if let profile = users.first {
                displayName = profile.display_name
                currentStreak = profile.current_streak
                selectedCompanionId = profile.selected_companion_id ??  ""
            }
        }
    }
}

// MARK: - Preview CANVAS

#Preview {
    HomeFeedView()
}
