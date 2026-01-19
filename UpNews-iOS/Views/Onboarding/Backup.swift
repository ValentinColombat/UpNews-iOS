
import SwiftUI
import Supabase

struct BackupHomeFeedView: View {
    
    // MARK: - State
    
    @State private var articles: [Article] = []
    @State private var mainArticle: Article?
    @State private var secondaryArticles: [Article] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // User data
    @State private var displayName: String = ""
    @State private var currentStreak: Int = 0
    @State private var selectedCompanionId: String = ""
    
    @StateObject private var authService = AuthService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.upNewsBackground
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Chargement...")
                        .tint(Color.upNewsPrimary)
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // Hero Card - Compagnon + CTA (avec header intégré)
                            heroCard
                            
                            // Article principal
                            if let article = mainArticle {
                                mainArticleCard(article)
                            }
                            
                            // Articles secondaires
                            if !secondaryArticles.isEmpty {
                                secondaryArticlesSection
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await loadAllData()
        }
    }
    
    // MARK: - Hero Card (Compagnon)
    
    private var heroCard: some View {
        ZStack {
            // Background image avec flou
            GeometryReader { geometry in
                Image("BackgroundHomePage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: 400)
                    .blur(radius: 3)  // Flou léger
                    .clipped()
            }
            .frame(height: 400)
            
            // Overlay sombre léger pour améliorer la lisibilité du texte blanc
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.1))
                .frame(height: 400)
            
            VStack(spacing: 0) {
                // Header intégré (pastilles gauche/droite)
                HStack {
                    // Pastille gauche - Streak
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.upNewsOrange)
                                    .font(.system(size: 24))
                            )
                        
                        Text("\(currentStreak) jour\(currentStreak > 1 ? "s" : "")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                    
                    // Pastille droite - Avatar/Menu
                    Menu {
                        Button("Déconnexion") {
                            Task {
                                await authService.signOut()
                            }
                        }
                        Button("Reset Onboarding") {
                            hasCompletedOnboarding = false
                        }
                    } label: {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 20))
                            )
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Bonjour + Prénom (en blanc)
                Text("Bonjour\n\(displayName)")
                    .font(.system(size: 32, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Spacer()
                
                // Compagnon (image)
                if !selectedCompanionId.isEmpty {
                    Image(selectedCompanionId)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    // Placeholder
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(height: 200)
                }
                
                Spacer()
                
                // CTA Button
                NavigationLink {
                    if let article = mainArticle {
                        ArticleDetailView(article: article)
                    }
                } label: {
                    Text("Découvre ta bonne nouvelle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.upNewsBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(12)
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Main Article Card
    
    private func mainArticleCard(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Badge catégorie
            HStack {
                Image(systemName: article.categoryIcon)
                    .font(.caption)
                Text(article.category.capitalized)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.vertical, 6)
            .background(Color.white)
            .foregroundColor(.upNewsBlack)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // Titre
            Text(article.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.upNewsBlack)
                .lineLimit(3)
            
            // Description
            Text(article.summary)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Boutons Lire / Audio
            HStack(spacing: 12) {
                // Bouton Lire
                NavigationLink {
                    ArticleDetailView(article: article)
                } label: {
                    Text("Lire")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.upNewsOrange)
                        .cornerRadius(12)
                }
                
                // Bouton Audio (désactivé pour l'instant)
                Button(action: {
                    // TODO: Lecture audio
                }) {
                    Text("Audio")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.gray)
                        .cornerRadius(12)
                }
                .disabled(true)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Secondary Articles Section
    
    private var secondaryArticlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Titre section
            HStack {
                Text("Voir tous les articles du jour")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.upNewsBlack)
                
                Text("...")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            // Liste articles
            VStack(spacing: 12) {
                ForEach(secondaryArticles) { article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        secondaryArticleCard(article)
                    }
                    .buttonStyle(.plain)
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
                    .font(.caption)
                    .foregroundColor(article.categoryColor)
            }
            .frame(width: 40, height: 40)
            .background(article.categoryColor.opacity(0.1))
            .cornerRadius(8)
            
            // Titre + catégorie
            VStack(alignment: .leading, spacing: 4) {
                Text(article.category.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(article.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.upNewsBlack)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .cornerRadius(12)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Erreur")
                .font(.title2)
                .fontWeight(.bold)
            
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
    
    private func loadAllData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Charger séquentiellement
            try await loadUserData()
            try await loadArticles()
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Impossible de charger les données : \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func loadUserData() async throws {
        let session = try await SupabaseConfig.client.auth.session
        
        // Récupérer les données utilisateur
        struct UserProfile: Decodable {
            let display_name: String
            let current_streak: Int
            let selected_companion_id: String?
        }
        
        let profile: UserProfile = try await SupabaseConfig.client
            .from("users")
            .select("display_name, current_streak, selected_companion_id")
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value
        
        await MainActor.run {
            displayName = profile.display_name
            currentStreak = profile.current_streak
            selectedCompanionId = profile.selected_companion_id ?? ""
        }
    }
    
    private func loadArticles() async throws {
        let fetchedArticles = try await ArticleService.shared.fetchTodayArticles()
        
        await MainActor.run {
            articles = fetchedArticles
            
            // Article principal = premier article (aléatoire pour l'instant)
            if let first = fetchedArticles.first {
                mainArticle = first
                // Articles secondaires = les autres
                secondaryArticles = Array(fetchedArticles.dropFirst())
            }
        }
    }
}



