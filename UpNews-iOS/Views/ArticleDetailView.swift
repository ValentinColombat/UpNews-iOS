//
//  ArticleDetailView.swift
//  UpNews-iOS

import SwiftUI

struct ArticleDetailView: View {
    
    // MARK: - Properties
    
    let article: Article
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLiked = false
    @State private var isFavorite = false
    @State private var isPlaying = false
    @State private var playbackSpeed: Float = 1.0
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                    heroSection
                // Contenu principal (fond blanc)
                VStack(spacing: 24) {
                    // Header : Catégorie + Actions rapides
                    headerSection
                    
                    // Player Audio
                    audioPlayerSection
                    
                    // Contenu de l'article
                    Text(article.content)
                        .font(.system(size: 17))
                        .foregroundColor(.upNewsBlack.opacity(0.8))
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal,5)
                    
                    // Section source
                    sourceSection
                    
                    // Boutons d'action
                    actionButtonsSection
                    
                    // Points gagnés
                    pointsEarnedSection
                   
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .background(Color.upNewsBackground)
            }
        }
        .background(Color.upNewsBackground)
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
    }

    // MARK: - Placeholder Image
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.upNewsGreen, Color.upNewsBlueMid],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 350)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.5))
            )
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        ZStack(alignment: .top) {
            // Image de fond
            
                Image("BackgroundHomePage2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .blur(radius: 5)
                   
            
            // Contenu par-dessus (Navigation + Titre)
            VStack(spacing: 16) {
                // Navigation personnalisée
                customNavigationBar

                // Titre de l'article
                Text(article.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top,20)
                    
            }
            .padding(.top, 50)
        }
        
    }
    
    // MARK: - Custom Navigation Bar
    
    private var customNavigationBar: some View {
     
            // Bouton Retour moderne (gauche)
            Button {
                dismiss()
            } label: {
                Text("<")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius:3 , x:2, y:2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            CategoryTagView(article: article)
            
            Spacer()
            
            // Actions rapides : Favoris + Partager
            HStack(spacing: 12) {
                Button {
                    isLiked.toggle()
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size:18))
                        .foregroundColor(isLiked ? .UpNewsRed : .gray)
                }
                Button {
                    isFavorite.toggle()
                } label: {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(isFavorite ? .upNewsOrange : .gray)
                }
                
                Button {
                    shareArticle()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                
            }
        }
    }
    
    // MARK: - Audio Player Section
    
    private var audioPlayerSection: some View {
        HStack(spacing: 12) {
            // Play/Pause Button
            Button {
                isPlaying.toggle()
            } label: {
                Circle()
                    .fill(Color.upNewsGreen)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.upNewsGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Infos audio
            VStack(alignment: .leading, spacing: 4) {
                Text("Écouter l'article")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.upNewsBlack)
                
                Text("3:24")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Vitesse de lecture
            Menu {
                Button("0.5x") { playbackSpeed = 0.5 }
                Button("0.75x") { playbackSpeed = 0.75 }
                Button("1.0x") { playbackSpeed = 1.0 }
                Button("1.25x") { playbackSpeed = 1.25 }
                Button("1.5x") { playbackSpeed = 1.5 }
                Button("2.0x") { playbackSpeed = 2.0 }
            } label: {
                Text("\(String(format: "%.1f", playbackSpeed))x")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.upNewsGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // J'aime
                Button {
                    isLiked.toggle()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isLiked ? .UpNewsRed : .upNewsBlack)
                        
                        Text("J'aime")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isLiked ? .red : .upNewsBlack)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
                
                // Favoris
                Button {
                    isFavorite.toggle()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20))
                            .foregroundColor(isFavorite ? .upNewsOrange : .upNewsBlack)
                        
                        Text("Favoris")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isFavorite ? .orange : .upNewsBlack)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
            }
            
            HStack(spacing: 12) {
                // Vidéo (bientôt disponible)
                Button {
                    // Disabled
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 2) {
                            Text("Vidéo")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray.opacity(0.8))
                            
                            Text("bientôt disponible")
                                .font(.system(size: 11))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
                .disabled(true)
                
                // Partager
                Button {
                    shareArticle()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundColor(.upNewsBlack)
                        
                        Text("Partager")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.upNewsBlack)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    
                    
                }
            }
        }
    }
    
    // MARK: - Points Earned Section
    
    private var pointsEarnedSection: some View {
        VStack(spacing: 8) {
            Text("✨ +15 points gagnés !✨")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .shadow(radius: 10, x: 0, y: 2)
            
            Text("Continuez comme ça !!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color.upNewsOrange,Color.upNewsBlueMid],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Source Section
    
    private var sourceSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 13))
                .foregroundColor(.upNewsGreen)
            
            if let sourceUrl = article.sourceUrl,
               let url = URL(string: sourceUrl) {
                Link(destination: url) {
                    Text(sourceUrl)
                        .font(.system(size: 12))
                        .foregroundColor(.upNewsGreen)
                        .underline()
                        .lineLimit(1)
                }
            } else {
                Text("Source non disponible")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper Functions
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "écologie", "ecology":
            "leaf.fill"
        case "technologie", "technology":
            "cpu"
        case "sciences", "science":
            "atom"
        case "social":
            "person.3.fill"
        case "culture":
            "theatermasks.fill"
        default:
            "star.fill"
        }
    }
    
    private func shareArticle() {
        // TODO: Implémenter le partage
        print("Partager l'article: \(article.title)")
    }
}

// MARK: - Preview

#Preview {
    ArticleDetailView(article: Article(
        id: UUID(),
        publishedDate: "2024-01-09",
        language: "fr",
        title: "Des forêts urbaines fleurissent dans 50 villes européennes",
        summary: "Une initiative collaborative transforme les espaces urbains en havres de verdure et de biodiversité...",
        content: """
        Une vague verte déferle sur l'Europe. Plus de 50 villes ont lancé des projets ambitieux de micro-forêts urbaines, transformant parkings et friches en havens de biodiversité.
        
        Ces espaces verts, inspirés de la méthode Miyawaki, croissent 10 fois plus vite que les forêts traditionnelles et créent des îlots de fraîcheur précieux en période de canicule.
        
        À Paris, Lyon, Barcelone et Amsterdam, des milliers d'arbres indigènes sont plantés avec l'aide de citoyens volontaires, créant ainsi un lien social fort autour de l'environnement.
        
        Les résultats sont déjà visibles : augmentation de 40% de la biodiversité locale et baisse de 3°C de la température dans ces zones.
        """,
        category: "Écologie",
        imageUrl: nil,
        sourceUrl: "https://example.com/source",
        createdAt: "2024-01-09T10:00:00Z"
    ))
}


