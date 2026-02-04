//  HomeFeedView. swift
//  UpNews-iOS

import SwiftUI
import Supabase
import Auth

struct HomeFeedView: View {
    
    @EnvironmentObject private var userDataService: UserDataService // ✅ CHANGÉ en @EnvironmentObject
    @ObservedObject private var authService = AuthService.shared
    
    private var xpProgress: Double {
        guard userDataService.maxXp > 0 else { return 0 }
        return Double(userDataService.currentXp) / Double(userDataService.maxXp)
    }
    
    var body: some View {
        NavigationStack {
            if userDataService.mainArticle == nil && userDataService.secondaryArticles.isEmpty {
                // État vide - Aucun article disponible
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        heroCard
                        
                        if let main = userDataService.mainArticle {
                            mainArticleCard(main)
                        }
                        
                        secondaryArticlesSection
                    }
                    .padding(. bottom, 40)
                }
                .background(Color.upNewsBackground)
                .ignoresSafeArea(edges: .top)
            }
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
                // Header avec les 2 pastilles
                HStack(alignment: .top) {
                    // Pastille gauche - Streak
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 50, height: 50)
                            .overlay(
                                FlameLottieView()
                            )
                        
                        Text("\(userDataService.currentStreak) jour\(userDataService.currentStreak > 1 ? "s" : "")")
                            . font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
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
                        Text(userDataService.displayName.prefix(10))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y:  2)
                    }
                    
                    Spacer()
                    
                    // Pastille droite - Niveau DYNAMIQUE
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "sunrise.fill")
                                    . foregroundColor(.upNewsOrange)
                                    .font(.system(size: 24))
                            )
                        
                        Text("Niv.  \(userDataService.currentLevel)")
                            .font(.system(size: 14, weight:  .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    }
                    . offset(y: 15)
                }
                . padding(.horizontal, 30)
                .padding(.top, 60)
                
                Spacer()
                
                ZStack {
                    // Compagnon centré
                    if !userDataService.selectedCompanionId.isEmpty {
                        ZStack {
                            
                            Image(userDataService.selectedCompanionId)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                                .blur(radius: 30)
                                .opacity(0.6)
                                .offset(x: 5, y: -10)
                            
                            
                            Image(userDataService.selectedCompanionId)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 280)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("Aucun compagnon")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(height: 280)
                    }
                    
                    // Barre XP à droite DYNAMIQUE
                    HStack {
                        Spacer()
                        ProgressBar(progress: xpProgress, orientation: .vertical)
                            .frame(width: 12, height: 220)
                            .padding(.bottom, 20)
                            .padding(.trailing, 50)
                    }
                }
                .frame(height: 280)
                
                Spacer()
                
                // CTA Button avec NavigationLink
                if let main = userDataService.mainArticle {
                    NavigationLink(destination: ArticleDetailView(article: main, autoPlayAudio:false)) {
                        HStack(spacing: 8) {
                            Text("Découvre ta bonne nouvelle")
                                .font(.system(size: 16, weight:  .semibold))
                            Image(systemName: "sun.haze.fill")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            ZStack {
                                // Fond glassmorphique
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                
                                // Teinte colorée orange
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.upNewsOrange)
                                
                                // Reflet lumineux en haut
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                
                                // Bordure grise subtile
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.upNewsOrange.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
        .frame(height: 500)
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK:  - Main Article Card
    
    private func mainArticleCard(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Badge catégorie avec style Liquid Glass
            CategoryTagView(article: article)
            
            // Titre
            Text(article.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.upNewsBlack)
                .lineLimit(3)
            
            // Description
            Text(article.contentPreview)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Boutons Lire / Audio (Style Liquid Glass coloré)
            HStack(spacing: 12) {
                // Bouton Lire (Orange Liquid Glass)
                NavigationLink(destination: ArticleDetailView(article: article, autoPlayAudio: false)) {
                    Label("Lire", systemImage: "book.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            ZStack {
                                // Fond glassmorphique
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                
                                // Teinte colorée
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.upNewsOrange)
                                
                                // Reflet lumineux en haut
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                
                                // Bordure brillante
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.upNewsOrange.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                // Bouton Audio (Vert Liquid Glass)
                if article.audioUrl != nil {
                    NavigationLink(destination: ArticleDetailView(article: article, autoPlayAudio: true)) {
                        Label("Audio", systemImage: "headphones")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                ZStack {
                                    // Fond glassmorphique
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                    
                                    // Teinte colorée
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.upNewsBlueMid)
                                    
                                    // Reflet lumineux en haut
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0)
                                                ],
                                                startPoint: .top,
                                                endPoint: .center
                                            )
                                        )
                                    
                                    // Bordure brillante
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.upNewsBlueMid.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                } else {
                    // Bouton Audio désactivé (Gris Liquid Glass)
                    Button(action: {}) {
                        ZStack(alignment: .topTrailing) {
                            Label("Audio", systemImage: "headphones")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    ZStack {
                                        // Fond glassmorphique
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                        
                                        // Teinte grisée
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.05))
                                        
                                        // Bordure subtile
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    }
                                )
                            
                            // Badge "indisponible"
                            Image(systemName: "speaker.slash.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(5)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .offset(x: -6, y: 6)
                        }
                    }
                    .disabled(true)
                }
            }
        }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .shadow(radius: 1, x: 0, y: 2)
        }
        
        // MARK: - Secondary Articles Section
        
        private var secondaryArticlesSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Voir tous les articles du jour")
                        .font(. system(size: 18, weight: .semibold))
                        .foregroundColor(.upNewsBlack)
                    
                    Text("...")
                        .font(.system(size: 18))
                        .foregroundColor(. secondary)
                }
                . padding(.top, 20)
                .padding(.horizontal, 30)
                
                VStack(spacing: 12) {
                    ForEach(userDataService.secondaryArticles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article, autoPlayAudio:false)) {
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
                // Icône de catégorie avec style Liquid Glass
                CategoryIconBadge(article: article)
                
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
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(. gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 1, x: 0, y: 2)
        }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ZStack {
            Color.upNewsBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Icône avec animation
                ZStack {
                    Circle()
                        .fill(Color.upNewsOrange.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.upNewsOrange)
                }
                
                VStack(spacing: 12) {
                    Text("Nos petits journalistes sont en congé")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.upNewsBlack)
                        .multilineTextAlignment(.center)
                    
                    Text("Reviens un peu plus tard !")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                // Illustration décorative (optionnelle)
                HStack(spacing: 16) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.upNewsBlueMid.opacity(0.6))
                    
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.upNewsGreen.opacity(0.6))
                    
                    Image(systemName: "beach.umbrella.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.upNewsOrange.opacity(0.6))
                }
                .padding(.top, 8)
            }
            .padding(40)
        }
    }
}


// MARK: - Preview

#Preview {
    HomeFeedView()
}
