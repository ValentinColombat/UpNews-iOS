//
//  HomeFeedView.swift
//  UpNews-iOS

import SwiftUI

struct HomeFeedView: View {
    
    // MARK: - State
    
    @State private var articles: [Article] = []
    @State private var mainArticle: Article?
    @State private var secondaryArticles: [Article] = []
    
    // User data - DONNÉES STATIQUES POUR CANVAS
    @State private var displayName: String = "Valentin"
    @State private var currentStreak: Int = 7
    @State private var selectedCompanionId: String = "cannelle"
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                
                if let main = mainArticle {
                    mainArticleCard(main)
                }
                
                secondaryArticlesSection
            }
            .padding(.bottom, 40)
        }
        .background(Color.upNewsBackground)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            loadMockData()
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
            .frame(height: 500)
            
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
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .offset(y:15)
                    
                    Spacer()
                    
                    // Bonjour + Prénom (CENTRÉ)
                    VStack(spacing: 4) {
                        Text("Bonjour")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
                            .offset(y: 5)
                        Text(displayName)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    // Pastille droite - Niveau
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "sunrise.fill")
                                        .foregroundColor(.upNewsOrange)
                                        .font(.system(size: 24))
                                )
                            
                            Text("Niv. 5")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                            
                        }
                        .offset(y:15)
                    }
                .padding(.horizontal, 30)
                .padding(.top, 60)
                
                Spacer()
                
                ZStack {
                    // Compagnon centré
                    if !selectedCompanionId.isEmpty {
                        Image(selectedCompanionId)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 280)
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 80))
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
                
                // CTA Button
                Button {
                    // Preview action
                } label: {
                    HStack(spacing: 8) {
                        Text("Découvre ta bonne nouvelle")
                            .font(.system(size: 16, weight: .semibold))
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
                
            }
        }
        .frame(height: 500)
        .ignoresSafeArea(edges: .top)
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
            Text(article.summary)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Boutons Lire / Audio
            HStack(spacing: 12) {
                // Bouton Lire
                Button {
                    // Preview action
                } label: {
                    Label("Lire", systemImage: "book.fill")
                        .font(.system(size: 16, weight: .semibold))
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
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .shadow(radius: 1, x: 0, y: 2)
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
            .padding(.top, 20)
            .padding(.horizontal, 30)
            
            // Liste articles
            VStack(spacing: 12) {
                ForEach(secondaryArticles) { article in
                    Button {
                        // Preview action
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1, x: 0, y: 2)
    }
    
    // MARK: - MOCK DATA FOR CANVAS
    
    private func loadMockData() {
        // Date du jour
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let isoFormatter = ISO8601DateFormatter()
        let now = isoFormatter.string(from: Date())
        
        // Article principal
        mainArticle = Article(
            id: UUID(),
            publishedDate: today,
            language: "fr",
            title: "Des forêts urbaines fleurissent dans 50 villes européennes",
            summary: "Une initiative collaborative transforme les espaces urbains en havens de verdure et de biodiversité, avec des résultats mesurables dès la première année.",
            content: """
            Une vague verte déferle sur l'Europe. Plus de 50 villes ont lancé des projets ambitieux de micro-forêts urbaines, transformant parkings et friches en havres de biodiversité.
            
            Ces espaces verts, inspirés de la méthode Miyawaki, croissent 10 fois plus vite que les forêts traditionnelles et créent des îlots de fraîcheur précieux en période de canicule.
            
            À Paris, Lyon, Barcelone et Amsterdam, des milliers d'arbres indigènes sont plantés avec l'aide de citoyens volontaires, créant ainsi un lien social fort autour de l'environnement.
            
            Les résultats sont déjà visibles : augmentation de 40% de la biodiversité locale et baisse de 3°C de la température dans ces zones.
            """,
            category: "ecology",
            imageUrl: nil,
            sourceUrl: "https://example.com/forets-urbaines",
            createdAt: now
        )
        
        // Articles secondaires
        secondaryArticles = [
            Article(
                id: UUID(),
                publishedDate: today,
                language: "fr",
                title: "Les abeilles sauvages reviennent dans nos jardins",
                summary: "Une augmentation de 40% observée en 2 ans grâce aux initiatives citoyennes.",
                content: "Les populations d'abeilles sauvages sont en nette progression dans les zones urbaines grâce aux efforts de plantation de fleurs mellifères.",
                category: "ecology",
                imageUrl: nil,
                sourceUrl: "https://example.com/abeilles",
                createdAt: now
            ),
            Article(
                id: UUID(),
                publishedDate: today,
                language: "fr",
                title: "Une batterie solaire recyclable à 99%",
                summary: "Innovation majeure dans le stockage d'énergie propre.",
                content: "Des chercheurs ont mis au point une batterie solaire dont 99% des composants peuvent être recyclés, révolutionnant le stockage d'énergie renouvelable.",
                category: "technology",
                imageUrl: nil,
                sourceUrl: "https://example.com/batterie",
                createdAt: now
            ),
            Article(
                id: UUID(),
                publishedDate: today,
                language: "fr",
                title: "Les coraux se régénèrent plus vite que prévu",
                summary: "Découverte scientifique encourageante pour les océans.",
                content: "Une nouvelle étude montre que certaines espèces de coraux ont une capacité de régénération deux fois plus rapide qu'anticipé.",
                category: "science",
                imageUrl: nil,
                sourceUrl: "https://example.com/coraux",
                createdAt: now
            )
        ]
    }
}

// MARK: - Preview CANVAS

#Preview {
    HomeFeedView()
}
