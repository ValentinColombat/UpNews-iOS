//
//  ArticleDetailView.swift
//  UpNews-iOS

import SwiftUI
import Supabase
import Auth
import ConfettiSwiftUI

struct ArticleDetailView: View {
    // MARK: - Properties
    
    let article: Article
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userDataService = UserDataService.shared
    @State private var isLiked = false
    @State private var isFavorite = false
    @State private var isPlaying = false
    @State private var playbackSpeed: Float = 1.0
    @State private var hasClaimedXp = false
    @State private var hasMarkedAsRead = false
    
    // Déblocage de nouveaux compagnons avec confettis
    @State private var showUnlockPopup = false
    @State private var unlockedCompanions: [(name: String, imageName: String)] = []
    @State private var confettiCounter = 0
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack {
                        heroSection
                        
                        // Contenu principal (fond blanc)
                        VStack(spacing: 24) {
                            // Header : Catégorie + Actions rapides
                            headerSection
                            
                            // Player Audio
                            audioPlayerSection
                            
                            // Contenu de l'article avec image intégrée intelligemment
                            VStack(alignment: .leading, spacing: 20) {
                                let paragraphs = article.content.components(separatedBy: "\n\n")
                                
                                ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                                    // Texte du paragraphe
                                    Text(paragraph)
                                        .font(.system(size: 17))
                                        .foregroundColor(.upNewsBlack.opacity(0.8))
                                        .lineSpacing(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Insérer l'image après le 2ème paragraphe
                                    if index == 1 && paragraphs.count > 2 {
                                        inlineGeneratedImage
                                    }
                                }
                            }
                            .padding(.horizontal, 5)
                            
                            // Section source
                            sourceSection
                            
                            // ✅ DÉTECTEUR DE SCROLL - 70% du contenu
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(
                                        key: ViewOffsetKey.self,
                                        value: geometry.frame(in: .named("scroll")).minY
                                    )
                            }
                            .frame(height: 1)
                            
                            // Points gagnés
                            pointsEarnedSection
                            
                            // Retour accueil rapide
                            returnToHomeButton
                            
                            // Boutons d'action
                            actionButtonsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .background(Color.upNewsBackground)
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ViewOffsetKey.self) { offset in
                    let triggerPoint = geometry.size.height / 2
                    
                    if offset < triggerPoint && !hasMarkedAsRead {
                        hasMarkedAsRead = true
                        Task {
                            do {
                                try await markArticleAsRead()
                                try await userDataService.loadAllData()
                            } catch {
                                print("❌ Erreur marquage article: \(error)")
                            }
                        }
                    }
                }
                .background(Color.upNewsBackground)
                .ignoresSafeArea(edges: .top)
                .navigationBarHidden(true)
                .confettiCannon(
                    trigger: $confettiCounter,
                    num: 50,
                    radius: 500
                )
                
                // Popup déblocage compagnons
                if showUnlockPopup {
                    unlockCompanionPopup
                }
            }
            .task {
                await loadArticleInteractions()
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 10) {
            // Navigation personnalisée
            customNavigationBar
            
            // Titre de l'article
            Text(article.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
        .padding(.top, 30)
        .padding(.bottom, 15)
    }
    
    // MARK: - Custom Navigation Bar
    
    private var customNavigationBar: some View {
        Button {
            dismiss()
        } label: {
            Text("<")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black.opacity(0.6))
                .shadow(radius: 4, x: 2, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 30)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            CategoryTagView(article: article)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    Task { await toggleLike() }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isLiked ? .UpNewsRed : .gray)
                }
                
                Button {
                    Task { await toggleFavorite() }
                } label: {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(isFavorite ? .upNewsOrange : .gray)
                }
                
                ShareArticle(article: article)
            }
        }
    }
    
    // MARK: - Audio Player Section
    
    private var audioPlayerSection: some View {
        HStack(spacing: 12) {
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Écouter l'article")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.upNewsBlack)
                
                Text("3:24")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
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
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Inline Generated Image
    
    private var inlineGeneratedImage: some View {
        VStack(spacing: 8) {
            Image("Illustration")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .padding(.vertical, 4)
        .padding(.trailing, 10)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    Task { await toggleLike() }
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
                
                Button {
                    Task { await toggleFavorite() }
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
                
                ShareLink(
                    item: URL(string: article.sourceUrl ?? "https://upnews.app")!,
                    subject: Text("📰 \(article.title)"),
                    message: Text(article.summary)
                ) {
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
        Button {
            claimXpPoints()
        } label: {
            VStack(spacing: 8) {
                Text(hasClaimedXp ? "✅ Points récupérés !" : "+20 points gagnés!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 10, x: 0, y: 2)
                
                Text(hasClaimedXp ? "Bravo !" : "Appuyez pour récupérer")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: hasClaimedXp ? [Color.green, Color.green.opacity(0.8)] : [Color.upNewsOrange, Color.upNewsOrange.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
        .disabled(hasClaimedXp)
    }
    
    // MARK: - Source Section
    
    private var sourceSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 13))
                .foregroundColor(.upNewsBlueMid)
            
            if let sourceUrl = article.sourceUrl,
               let url = URL(string: sourceUrl) {
                Link(destination: url) {
                    Text(String(sourceUrl.prefix(50)))
                        .font(.system(size: 12))
                        .foregroundColor(.upNewsBlueMid)
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
    
    // MARK: - Return to Home Button
    
    private var returnToHomeButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Retour à l'accueil")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.white)
            .cornerRadius(16)
            .shadow(color: Color.upNewsGreen.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Unlock Companion Popup

    private var unlockCompanionPopup: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    showUnlockPopup = false
                }
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 60))
                    
                    Text("Nouveaux compagnons débloqués !")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.upNewsBlack)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    ForEach(unlockedCompanions, id: \.name) { companion in
                        HStack(spacing: 16) {
                            Image(companion.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            
                            Text(companion.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.upNewsBlack)
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.upNewsBlueMid.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
                
                NavigationLink(destination: CompanionsView()) {
                    Text("Super !")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.upNewsOrange, Color.upNewsOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    showUnlockPopup = false
                })
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadArticleInteractions() async {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            let response = try await SupabaseConfig.client
                .from("user_article_interactions")
                .select("is_liked, is_favorite, is_read, has_claimed_xp")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("article_id", value: article.id.uuidString)
                .execute()
            
            let interactions = try JSONDecoder().decode([ArticleInteraction].self, from: response.data)
            
            if let interaction = interactions.first {
                isLiked = interaction.is_liked
                isFavorite = interaction.is_favorite
                hasClaimedXp = interaction.has_claimed_xp
                hasMarkedAsRead = interaction.is_read
            }
        } catch {
            print("❌ Erreur chargement interactions: \(error)")
        }
    }
    
    private func toggleLike() async {
        isLiked.toggle()
        await updateInteraction(field: "is_liked", value: isLiked)
    }
    
    private func toggleFavorite() async {
        isFavorite.toggle()
        await updateInteraction(field: "is_favorite", value: isFavorite)
    }
    
    // ✅ Mise à jour de updateInteraction pour inclure has_claimed_xp
    private func updateInteraction(field: String, value: Bool) async {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            let checkResponse = try await SupabaseConfig.client
                .from("user_article_interactions")
                .select("id")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("article_id", value: article.id.uuidString)
                .execute()
            
            let existing = try JSONDecoder().decode([EmptyResponse].self, from: checkResponse.data)
            
            if existing.isEmpty {
                struct NewInteraction: Encodable {
                    let user_id: String
                    let article_id: String
                    let is_liked: Bool
                    let is_favorite: Bool
                    let is_read: Bool
                    let has_claimed_xp: Bool  // ✅ Ajouté
                }
                
                let interaction = NewInteraction(
                    user_id: session.user.id.uuidString,
                    article_id: article.id.uuidString,
                    is_liked: field == "is_liked" ? value : false,
                    is_favorite: field == "is_favorite" ? value : false,
                    is_read: field == "is_read" ? value : false,
                    has_claimed_xp: false  // ✅ Par défaut false
                )
                
                try await SupabaseConfig.client
                    .from("user_article_interactions")
                    .insert(interaction)
                    .execute()
            } else {
                if field == "is_liked" {
                    struct UpdateLike: Encodable {
                        let is_liked: Bool
                    }
                    let update = UpdateLike(is_liked: value)
                    
                    try await SupabaseConfig.client
                        .from("user_article_interactions")
                        .update(update)
                        .eq("user_id", value: session.user.id.uuidString)
                        .eq("article_id", value: article.id.uuidString)
                        .execute()
                } else if field == "is_favorite" {
                    struct UpdateFavorite: Encodable {
                        let is_favorite: Bool
                    }
                    let update = UpdateFavorite(is_favorite: value)
                    
                    try await SupabaseConfig.client
                        .from("user_article_interactions")
                        .update(update)
                        .eq("user_id", value: session.user.id.uuidString)
                        .eq("article_id", value: article.id.uuidString)
                        .execute()
                } else if field == "is_read" {
                    struct UpdateRead: Encodable {
                        let is_read: Bool
                    }
                    let update = UpdateRead(is_read: value)
                    
                    try await SupabaseConfig.client
                        .from("user_article_interactions")
                        .update(update)
                        .eq("user_id", value: session.user.id.uuidString)
                        .eq("article_id", value: article.id.uuidString)
                        .execute()
                }
            }
        } catch {
            print("❌ Erreur update interaction: \(error)")
        }
    }
    
    // ✅ Mise à jour de markArticleAsRead
    private func markArticleAsRead() async throws {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            let checkResponse = try await SupabaseConfig.client
                .from("user_article_interactions")
                .select("id")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("article_id", value: article.id.uuidString)
                .execute()
            
            let existing = try JSONDecoder().decode([EmptyResponse].self, from: checkResponse.data)
            
            let readAt = ISO8601DateFormatter().string(from: Date())
            
            if existing.isEmpty {
                struct NewInteraction: Encodable {
                    let user_id: String
                    let article_id: String
                    let is_read: Bool
                    let read_at: String
                    let is_liked: Bool
                    let is_favorite: Bool
                    let has_claimed_xp: Bool  // ✅ Ajouté
                }
                
                let interaction = NewInteraction(
                    user_id: session.user.id.uuidString,
                    article_id: article.id.uuidString,
                    is_read: true,
                    read_at: readAt,
                    is_liked: false,
                    is_favorite: false,
                    has_claimed_xp: false  // ✅ Par défaut false
                )
                
                try await SupabaseConfig.client
                    .from("user_article_interactions")
                    .insert(interaction)
                    .execute()
            } else {
                struct UpdateRead: Encodable {
                    let is_read: Bool
                    let read_at: String
                }
                
                let update = UpdateRead(is_read: true, read_at: readAt)
                
                try await SupabaseConfig.client
                    .from("user_article_interactions")
                    .update(update)
                    .eq("user_id", value: session.user.id.uuidString)
                    .eq("article_id", value: article.id.uuidString)
                    .execute()
            }
        } catch {
            throw error
        }
    }
    
    // ✅ Nouvelle fonction pour marquer le claim des XP
    private func markXpAsClaimed() async throws {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            struct UpdateXpClaimed: Encodable {
                let has_claimed_xp: Bool
            }
            
            let update = UpdateXpClaimed(has_claimed_xp: true)
            
            try await SupabaseConfig.client
                .from("user_article_interactions")
                .update(update)
                .eq("user_id", value: session.user.id.uuidString)
                .eq("article_id", value: article.id.uuidString)
                .execute()
            
            print("✅ XP marqué comme récupéré")
        } catch {
            print("❌ Erreur marquage XP claimed: \(error)")
            throw error
        }
    }
    
    private func claimXpPoints() {
        guard !hasClaimedXp else { return }
        
        let pointsToAdd = 20
        userDataService.currentXp += pointsToAdd
        
        var didLevelUp = false
        while userDataService.currentXp >= userDataService.maxXp {
            userDataService.currentXp -= userDataService.maxXp
            userDataService.currentLevel += 1
            didLevelUp = true
        }
        
        hasClaimedXp = true
        
        Task {
            do {
                try await userDataService.saveXpAndLevel()
                try await markXpAsClaimed()  // ✅ Marquer le claim (pas la lecture)
                try await markArticleAsRead() // ✅ S'assurer que l'article est aussi marqué comme lu
                
                if didLevelUp {
                    checkUnlockedCompanions(newLevel: userDataService.currentLevel)
                }
            } catch {
                print("❌ Erreur sauvegarde XP: \(error)")
            }
        }
    }
    
    
    private func checkUnlockedCompanions(newLevel: Int) {
        let companionsByLevel: [Int: [(name: String, imageName: String)]] = [
            2: [("Brume", "brume"), ("Flocon", "flocon")],
            5: [("Caramel", "caramel"), ("Écorce", "ecorce"), ("Luciole", "luciole")],
            10: [("Mochi", "mochi"), ("Sève", "seve")],
            15: [("Pépite", "pepite")],
            20: [("Noisette", "noisette")]
        ]
        
        if let newCompanions = companionsByLevel[newLevel] {
            unlockedCompanions = newCompanions
            showUnlockPopup = true
            confettiCounter += 1
        }
    }
    
    // MARK: - Models
    
    struct ArticleInteraction: Decodable {
        let is_liked: Bool
        let is_favorite: Bool
        let is_read: Bool
        let has_claimed_xp: Bool
    }
    
    struct EmptyResponse: Decodable {
        let id: String
    }
}

// MARK: - Preference Key
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


