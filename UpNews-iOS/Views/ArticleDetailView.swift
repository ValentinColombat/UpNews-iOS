//
//  ArticleDetailView.swift
//  UpNews-iOS

import SwiftUI
import Supabase
import Auth
import ConfettiSwiftUI
import AVFoundation
import AVKit

struct ArticleDetailView: View {
    // MARK: - Properties
    
    @State var article: Article
    let autoPlayAudio : Bool
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Audio Player States
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false
    @State private var playbackSpeed: Double = 1.0
    @State private var isLoadingAudio = false
    @State private var audioLoadFailed = false
    @State private var audioDuration: Double = 0
    @State private var timeObserver: Any?
    @State private var currentTime: Double = 0
    @State private var confettiTrigger = 0
    @State private var playerItemObservers: [NSObjectProtocol] = []

    
    @ObservedObject private var userDataService = UserDataService.shared
    @State private var isLiked = false
    @State private var isFavorite = false
    @State private var hasClaimedXp = false
    @State private var hasMarkedAsRead = false
    
    // Déblocage de nouveaux compagnons avec confettis
    @State private var showUnlockPopup = false
    @State private var unlockedCompanions: [(name: String, imageName: String)] = []
    @State private var confettiCounter = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.upNewsBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        audioPlayerSection
                        contentWithImageSection
                        sourceSection
                        
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ViewOffsetKey.self,
                                    value: geo.frame(in: .named("scroll")).minY
                                )
                        }
                        .frame(height: 1)
                        
                        pointsEarnedSection
                        returnToHomeButton
                        actionButtonsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { offset in
                if offset < UIScreen.main.bounds.height / 2 && !hasMarkedAsRead {
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
            .navigationBarHidden(true)
            .confettiCannon(
                trigger: $confettiCounter,
                num: 50,
                radius: 500
            )
            .confettiCannon(
                trigger: $confettiTrigger,
                num: 30,
                radius: 400,
                repetitions: 1,
                repetitionInterval: 0.5
            )
            
            if showUnlockPopup {
                unlockCompanionPopup
            }
        }
        .task {
            await loadArticleInteractions()
        }
        .onDisappear {
            cleanupAudioPlayer()
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            customNavigationBar
            
            Text(article.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 24)
        }
        .padding(.top, 60)
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
        }
        .padding(.horizontal, 24)
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
    
    // MARK: - Content With Image Section
    
    private var contentWithImageSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            let paragraphs = article.content.components(separatedBy: "\n\n")
            
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                Text(paragraph)
                    .font(.system(size: 17))
                    .foregroundColor(.upNewsBlack.opacity(0.8))
                    .lineSpacing(8)
                
                // Image après le 2ème paragraphe
                if index == 1 && paragraphs.count > 2 {
                    inlineGeneratedImage
                }
            }
        }
    }
    
    // MARK: - Audio Player Section
        
    private var audioPlayerSection: some View {
        Group {
            // Cas 1 : Pas d'audio disponible
            if article.audioUrl == nil {
                audioUnavailableView
            }
            // Cas 2 : Chargement en cours
            else if isLoadingAudio {
                audioLoadingView
            }
            // Cas 3 : Échec de chargement (masqué)
            else if audioLoadFailed {
                EmptyView()
            }
            // Cas 4 : Lecteur audio fonctionnel
            else {
                audioPlayerView
            }
        }
    }

    // MARK: - Audio Unavailable View

    private var audioUnavailableView: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "speaker.slash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Audio indisponible")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                
                Text("Cet article n'a pas de version audio")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Audio Loading View

    private var audioLoadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Chargement de l'audio...")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.upNewsBlack)
                
                Text("Veuillez patienter")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Audio Player View (Badge centré en bas)

    private var audioPlayerView: some View {
        VStack(spacing: 0) {
            // Play + Waveform + Vitesse
            HStack(spacing: 14) {
                Button {
                    togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.upNewsBlueMid.opacity(0.15))
                            .frame(width: 46, height: 46)
                            .blur(radius: 6)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.upNewsBlueMid, Color.upNewsBlueMid.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                WaveformView(isPlaying: isPlaying)
                    .frame(height: 32)
                
                Spacer()
                
                Menu {
                    Button("1.0x") { changePlaybackSpeed(1.0) }
                    Button("1.25x") { changePlaybackSpeed(1.25) }
                    Button("1.5x") { changePlaybackSpeed(1.5) }
                } label: {
                    HStack(spacing: 3) {
                        Text(String(format: "%.2gx", playbackSpeed))
                            .font(.system(size: 10, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .bold))
                    }
                    .foregroundColor(.upNewsBlueMid)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.upNewsBlueMid.opacity(0.1))
                    .cornerRadius(7)
                }
            }
            .padding(.bottom, 10)
            
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 3)
                    
                    Capsule()
                        .fill(Color.upNewsBlueMid)
                        .frame(
                            width: geometry.size.width * CGFloat(currentTime / max(audioDuration, 0.1)),
                            height: 3
                        )
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newTime = (value.location.x / geometry.size.width) * audioDuration
                            seekToTime(max(0, min(newTime, audioDuration)))
                        }
                )
            }
            .frame(height: 3)
            .padding(.bottom, 8)
            
            // Timing + Badge XP
            ZStack {
                HStack {
                    Text(formatDuration(currentTime))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Spacer()
                    
                    Text(formatDuration(audioDuration))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                if hasClaimedXp {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                        
                        Text("+20 XP")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.upNewsBlueMid)
                    )
                    .shadow(color: Color.upNewsBlueMid.opacity(0.3), radius: 6, x: 0, y: 3)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 20)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasClaimedXp)
        .task {
            setupAudioPlayer()
        }
    }
    // MARK: - Inline Generated Image
    
    private var inlineGeneratedImage: some View {
        GeometryReader { geometry in
            Group {
                if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: geometry.size.width, height: 200)
                                .overlay(ProgressView().tint(.upNewsBlueMid))
                                .cornerRadius(12)
                            
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: 200)
                                .clipped()
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                            
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: geometry.size.width, height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.gray.opacity(0.5))
                                        Text("Image non disponible")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray.opacity(0.7))
                                    }
                                )
                                .cornerRadius(12)
                            
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: geometry.size.width, height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("Aucune image")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        )
                        .cornerRadius(12)
                }
            }
        }
        .frame(height: 200)
        .clipped()
        .padding(.vertical, 8)
    }
    
    // MARK: - Source Section
    
    private var sourceSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 13))
                .foregroundColor(.upNewsBlueMid)
            
            if let sourceUrl = article.sourceUrl, let url = URL(string: sourceUrl) {
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
    }
    
    // MARK: - Points Earned Section
    
    private var pointsEarnedSection: some View {
        Button {
            claimXpPoints()
        } label: {
            VStack(spacing: 8) {
                Text(hasClaimedXp ? "Points récupérés !" : "+20 points gagnés!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
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
            .shadow(radius: 4, x: 0, y: 2)
        }
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
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - Unlock Companion Popup

    private var unlockCompanionPopup: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Croix rouge pour fermer (en haut à droite)
                HStack {
                    Spacer()
                    Button {
                        showUnlockPopup = false
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, -8)
                
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
                
                // Navigation vers CompanionsView
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
            
            print("🔵 Chargement des interactions pour article: \(article.id.uuidString)")
            
            let response = try await SupabaseConfig.client
                .from("user_article_interactions")
                .select("is_liked, is_favorite, is_read, has_claimed_xp")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("article_id", value: article.id.uuidString)
                .execute()
            
            let interactions = try JSONDecoder().decode([ArticleInteraction].self, from: response.data)
            
            if let interaction = interactions.first {
                print("✅ Interaction trouvée:")
                print("   - is_liked: \(interaction.is_liked)")
                print("   - is_favorite: \(interaction.is_favorite)")
                print("   - is_read: \(interaction.is_read)")
                print("   - has_claimed_xp: \(interaction.has_claimed_xp)")  // ← IMPORTANT
                
                isLiked = interaction.is_liked
                isFavorite = interaction.is_favorite
                hasClaimedXp = interaction.has_claimed_xp
                hasMarkedAsRead = interaction.is_read
            } else {
                print("⚠️ Aucune interaction trouvée pour cet article")
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
                    let has_claimed_xp: Bool
                }
                
                let interaction = NewInteraction(
                    user_id: session.user.id.uuidString,
                    article_id: article.id.uuidString,
                    is_liked: field == "is_liked" ? value : false,
                    is_favorite: field == "is_favorite" ? value : false,
                    is_read: field == "is_read" ? value : false,
                    has_claimed_xp: false
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
            print("Erreur update interaction: \(error)")
        }
    }
    

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
                    let has_claimed_xp: Bool
                }
                
                let interaction = NewInteraction(
                    user_id: session.user.id.uuidString,
                    article_id: article.id.uuidString,
                    is_read: true,
                    read_at: readAt,
                    is_liked: false,
                    is_favorite: false,
                    has_claimed_xp: false
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
    
    private func markXpAsClaimed() async throws {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            print("🔵 Début markXpAsClaimed pour article: \(article.id.uuidString)")
            
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
            
            print("✅ XP marqué comme récupéré dans Supabase")
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
        
        confettiTrigger += 1
        
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
    
    // MARK: - Audio Player Functions
    
    private func handleAudioCompletion() {
        guard !hasClaimedXp else {
            print("⚠️ Points déjà récupérés")
            return
        }
        
        print("🎉 Traitement de la fin de l'audio")
        
        hasMarkedAsRead = true
        
        let pointsToAdd = 20
        userDataService.currentXp += pointsToAdd
        
        var didLevelUp = false
        while userDataService.currentXp >= userDataService.maxXp {
            userDataService.currentXp -= userDataService.maxXp
            userDataService.currentLevel += 1
            didLevelUp = true
        }
        
        hasClaimedXp = true
        
        // ✅ NOUVEAU : Déclencher les confettis !
        confettiTrigger += 1
        
        Task {
            do {
                try await markArticleAsRead()
                print("✅ Article marqué comme lu")
                
                try await markXpAsClaimed()
                print("✅ XP marqué comme récupéré")
                
                try await userDataService.saveXpAndLevel()
                print("✅ XP utilisateur sauvegardé")
                
                print("✅ Points récupérés et sauvegardés après écoute de l'audio")
                
                if didLevelUp {
                    checkUnlockedCompanions(newLevel: userDataService.currentLevel)
                }
            } catch {
                print("❌ Erreur sauvegarde XP après audio: \(error)")
            }
        }
    }
    
    private func seekToTime(_ time: Double) {
        let targetTime = CMTime(seconds: time, preferredTimescale: 600)
        audioPlayer?.seek(to: targetTime)
        currentTime = time
    }
    
    private func configureAudioSession() {
        print("🔵 Configuration de l'Audio Session")
        
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
            print("✅ Audio Session configurée")
        } catch {
            print("❌ Erreur configuration Audio Session: \(error.localizedDescription)")
        }
        #else
        // Sur macOS, pas besoin de configurer AVAudioSession
        print("⚠️ Audio Session non configurée (macOS)")
        #endif
    }

    private func setupAudioPlayer() {
        print("🔵 setupAudioPlayer() appelé")
        
        guard audioPlayer == nil else {
            print("⚠️ audioPlayer existe déjà, on skip")
            return
        }
        
        print("🔵 article.audioUrl = \(article.audioUrl ?? "nil")")
        
        guard let audioUrlString = article.audioUrl,
              let url = URL(string: audioUrlString) else {
            print("❌ URL audio invalide ou nil")
            audioLoadFailed = true
            return
        }
        
        print("🎵 URL valide : \(url)")
        
        configureAudioSession()
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Erreur réseau HEAD request : \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.audioLoadFailed = true
                    self.isLoadingAudio = false
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ HEAD request status : \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("❌ Le fichier n'est pas accessible (status \(httpResponse.statusCode))")
                    DispatchQueue.main.async {
                        self.audioLoadFailed = true
                        self.isLoadingAudio = false
                    }
                    return
                }
            }
        }.resume()
        
        isLoadingAudio = true
        
        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)
        
        // ✅ NOUVEAU : Auto-play si demandé
        if autoPlayAudio {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if !self.audioLoadFailed && self.audioPlayer != nil {
                    self.togglePlayPause()
                    print("▶️ Auto-play activé depuis le bouton Audio")
                }
            }
        }
        
        // Observer le temps de lecture
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let currentSeconds = CMTimeGetSeconds(time)
            if currentSeconds.isFinite {
                self.currentTime = currentSeconds
                
                if self.audioDuration > 0 {
                    let progress = currentSeconds / self.audioDuration
                    if progress >= 0.95 && !self.hasClaimedXp && !self.hasMarkedAsRead {
                        print("🎉 Audio terminé à 95%, récupération des points")
                        self.handleAudioCompletion()
                    }
                }
            }
        }
        
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                let duration = playerItem.asset.duration
                
                if duration.isValid && !duration.isIndefinite {
                    self.audioDuration = CMTimeGetSeconds(duration)
                    print("✅ Audio duration set : \(self.audioDuration)s")
                }
                
                self.isLoadingAudio = false
            }
        }
        
        let endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            print("🎉 Audio terminé naturellement")
            if !self.hasClaimedXp {
                self.handleAudioCompletion()
            }
        }
        playerItemObservers.append(endObserver)
        
        let failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            print("❌ AVPlayerItemFailedToPlayToEndTime : \(notification)")
            DispatchQueue.main.async {
                self.audioLoadFailed = true
                self.isLoadingAudio = false
            }
        }
        playerItemObservers.append(failObserver)
        
        let errorObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewErrorLogEntry,
            object: playerItem,
            queue: .main
        ) { notification in
            print("❌ AVPlayerItemNewErrorLogEntry : \(notification)")
            DispatchQueue.main.async {
                self.audioLoadFailed = true
                self.isLoadingAudio = false
            }
        }
        playerItemObservers.append(errorObserver)
        
        print("🔵 setupAudioPlayer() terminé")
    }

    private func togglePlayPause() {
        print("🔵 togglePlayPause() appelé, isPlaying = \(isPlaying)")
        
        guard let player = audioPlayer else {
            print("❌ audioPlayer est nil")
            return
        }
        
        if isPlaying {
            player.pause()
            isPlaying = false
            print("⏸️ Audio mis en pause")
        } else {
            player.play()
            isPlaying = true
            print("▶️ Audio en lecture")
        }
    }

    private func changePlaybackSpeed(_ speed: Double) {
        print("🔵 changePlaybackSpeed(\(speed)) appelé")
        playbackSpeed = speed
        audioPlayer?.rate = Float(speed)
        
        if !isPlaying {
            audioPlayer?.pause()
            print("⏸️ Resté en pause après changement de vitesse")
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds > 0 else {
            return "0:00"
        }
        
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func cleanupAudioPlayer() {
        print("🧹 cleanupAudioPlayer() appelé")
        
        guard audioPlayer != nil else {
            print("⚠️ Pas de player à cleanup")
            return
        }
        
        // ✅ Retirer l'observer de temps
        if let observer = timeObserver {
            audioPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Retirer tous les observateurs NotificationCenter stockés
        for observer in playerItemObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        playerItemObservers.removeAll()
        
        // Arrêter et libérer le player
        audioPlayer?.pause()
        audioPlayer?.replaceCurrentItem(with: nil)
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        
        // Désactiver l'AudioSession (iOS uniquement)
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ Audio Session désactivée")
        } catch {
            print("⚠️ Erreur désactivation Audio Session: \(error.localizedDescription)")
        }
        #endif
        
        print("🧹 Cleanup terminé")
    }
}

// MARK: - Preference Key
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
