//
//  CompanionsView.swift
//  UpNews-iOS

import SwiftUI
import Supabase
import ConfettiSwiftUI

// MARK: - Companion Model

struct CompanionCharacter: Identifiable {
    let id: String
    let name: String
    let imageName: String? // Image asset
    let emoji: String? // Fallback emoji
    let unlockLevel: Int
    let isUnlocked: Bool
    let isEquipped: Bool
}

struct CompanionsView: View {
    
    // MARK: - State
    
    @EnvironmentObject private var userDataService: UserDataService // ✅ AJOUTÉ
    @State private var selectedCompanionId: String = ""
    @State private var isLoading = true
    
    // Notifications
    @State private var showNotificationPermission = false
    @State private var showNotificationDenied = false
    
    // ✅ AJOUTÉ : Déblocage de compagnons
    @State private var showUnlockPopup = false
    @State private var unlockedCompanions: [(name: String, imageName: String)] = []
    @State private var confettiCounter = 0
    
    // Ordre des compagnons selon le nouveau système de déblocage
    @State private var companions: [CompanionCharacter] = [
        // Niveau 1 (Débloqués automatiquement - Onboarding)
        CompanionCharacter(id: "mousse", name: "Mousse", imageName: "mousse", emoji: nil, unlockLevel: 1, isUnlocked: true, isEquipped: false),
        CompanionCharacter(id: "cannelle", name: "Cannelle", imageName: "cannelle", emoji: nil, unlockLevel: 1, isUnlocked: true, isEquipped: false),
        CompanionCharacter(id: "givre_et_plume", name: "Givre et Plume", imageName: "givre_et_plume", emoji: nil, unlockLevel: 1, isUnlocked: true, isEquipped: false),
        
        // Niveau 2
        CompanionCharacter(id: "brume", name: "Brume", imageName: "brume", emoji: nil, unlockLevel: 2, isUnlocked: false, isEquipped: false),
        CompanionCharacter(id: "flocon", name: "Flocon", imageName: "flocon", emoji: nil, unlockLevel: 2, isUnlocked: false, isEquipped: false),
        
        // Niveau 3
        CompanionCharacter(id: "vera", name: "Vera", imageName: "vera", emoji: nil, unlockLevel: 3, isUnlocked: false, isEquipped: false),
        
        // Niveau 4
        CompanionCharacter(id: "jura", name: "Jura", imageName: "jura", emoji: nil, unlockLevel: 4, isUnlocked: false, isEquipped: false),
        
        // Niveau 5
        CompanionCharacter(id: "caramel", name: "Caramel", imageName: "caramel", emoji: nil, unlockLevel: 5, isUnlocked: false, isEquipped: false),
        CompanionCharacter(id: "ecorce", name: "Écorce", imageName: "ecorce", emoji: nil, unlockLevel: 5, isUnlocked: false, isEquipped: false),
        CompanionCharacter(id: "luciole", name: "Luciole", imageName: "luciole", emoji: nil, unlockLevel: 5, isUnlocked: false, isEquipped: false),
        
        // Niveau 6
        CompanionCharacter(id: "olga", name: "Olga", imageName: "olga", emoji: nil, unlockLevel: 6, isUnlocked: false, isEquipped: false),
        
        // Niveau 7
        CompanionCharacter(id: "luka", name: "Luka", imageName: "luka", emoji: nil, unlockLevel: 7, isUnlocked: false, isEquipped: false),
        
        // Niveau 8
        CompanionCharacter(id: "nina", name: "Nina", imageName: "nina", emoji: nil, unlockLevel: 8, isUnlocked: false, isEquipped: false),
        
        // Niveau 10
        CompanionCharacter(id: "mochi", name: "Mochi", imageName: "mochi", emoji: nil, unlockLevel: 10, isUnlocked: false, isEquipped: false),
        CompanionCharacter(id: "seve", name: "Sève", imageName: "seve", emoji: nil, unlockLevel: 10, isUnlocked: false, isEquipped: false),
        
        // Niveau 15
        CompanionCharacter(id: "pepite", name: "Pépite", imageName: "pepite", emoji: nil, unlockLevel: 15, isUnlocked: false, isEquipped: false),
        
        // Niveau 20
        CompanionCharacter(id: "noisette", name: "Noisette", imageName: "noisette", emoji: nil, unlockLevel: 20, isUnlocked: false, isEquipped: false)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.upNewsBackground
                    .ignoresSafeArea()
                if isLoading {
                    LoadingView()
                }
                
                else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header avec niveau
                            headerSection
                            
                            // Barre de progression animée
                            xpProgressSection
                            
                            // Carte boost notification
                            if shouldShowNotificationBoost {
                                NotificationBoostCard {
                                    handleNotificationBoostTap()
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Liste des compagnons
                            companionsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await loadUserData()
            }
            .fullScreenCover(isPresented: $showNotificationPermission) {
                NotificationPermissionView(
                    onAllow: { handleNotificationAllow() },
                    onLater: { handleNotificationLater() }
                )
                .background(ClearBackgroundView())
            }
            .alert("Notifications désactivées", isPresented: $showNotificationDenied) {
                Button("Annuler", role: .cancel) { }
                Button("Ouvrir Réglages") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Active les notifications dans les réglages iOS pour recevoir tes rappels quotidiens et débloquer +80 XP.")
            }
            // ✅ AJOUTÉ : Overlay pour la popup de déblocage
            .overlay {
                if showUnlockPopup {
                    UnlockCompanionPopup(
                        companions: unlockedCompanions,
                        onDismiss: {
                            showUnlockPopup = false
                        },
                        onNavigateToCompanions: nil // On est déjà sur la page Compagnons
                    )
                }
            }
            // ✅ AJOUTÉ : Confettis
            .confettiCannon(
                trigger: $confettiCounter,
                num: 50,
                radius: 500
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("Compagnons")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Badge niveau
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("Niv. \(userDataService.currentLevel)")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.25))
            .cornerRadius(20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color.upNewsOrange.opacity(0.9), Color.upNewsOrange.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.top, 30)
    }
    
    // MARK: - XP Progress Section
    
    private var xpProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progression vers niveau \(userDataService.currentLevel + 1)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.upNewsBlack)
                
                Spacer()
                
                Text("\(userDataService.currentXp) / \(userDataService.maxXp) XP")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.upNewsBlack)
            }
            
            // Barre de progression animée
            ProgressBar(
                progress: CGFloat(userDataService.currentXp) / CGFloat(userDataService.maxXp),
                orientation: .horizontal
            )
            .frame(height: 12)
        }
        .padding(20)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }
    
    // MARK: - Companions Section
    
    private var companionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personnages disponibles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.upNewsBlack)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(companions) { companion in
                    companionCard(companion)
                }
            }
        }
    }
    
    private func companionCard(_ companion: CompanionCharacter) -> some View {
        VStack(spacing: 12) {
            // Image ou Emoji compagnon
            if let imageName = companion.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .overlay {
                        if !companion.isUnlocked {
                            Color.black
                                .mask(
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                )
                        }
                    }
            }
            
            // Nom
            Text(companion.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.upNewsBlack)
            
            // Status
            if companion.isEquipped {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("Équipé")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.upNewsBlack)
            } else if companion.isUnlocked {
                Text("Niveau \(companion.unlockLevel)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Niveau \(companion.unlockLevel)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.upNewsOrange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            companion.isEquipped
            ? Color.upNewsBlueMid.opacity(0.1)
            : Color.white
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(companion.isEquipped ? Color.upNewsBlueMid : Color.clear, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if !companion.isUnlocked {
                LockLottieView()
                    .padding(6)
            }
        }
        .overlay(alignment: .topLeading) {
            
            //Badge NOUVEAU pour compagnons récemment débloqués
            if companion.isUnlocked && companion.unlockLevel == userDataService.currentLevel {
                Text("New")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.upNewsOrange)
                    .cornerRadius(8)
                    .padding(8)
            }
        }
        .cornerRadius(20)
        .onTapGesture {
            if companion.isUnlocked && !companion.isEquipped {
                equipCompanion(companion)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadUserData() async {
        do {
            try await userDataService.loadAllData()
            
            // Récupérer le compagnon sélectionné depuis le service
            selectedCompanionId = userDataService.selectedCompanionId
            updateUnlockedCompanions()
            updateEquippedCompanion()
            isLoading = false
        } catch {
            print("Erreur chargement donnees utilisateur: \(error)")
        }
    }
    
    private func updateUnlockedCompanions() {
        let currentLevel = userDataService.currentLevel
        
        companions = companions.map { companion in
            CompanionCharacter(
                id: companion.id,
                name: companion.name,
                imageName: companion.imageName,
                emoji: companion.emoji,
                unlockLevel: companion.unlockLevel,
                isUnlocked: currentLevel >= companion.unlockLevel,
                isEquipped: companion.isEquipped
            )
        }
    }
    
    private func updateEquippedCompanion() {
        companions = companions.map { companion in
            CompanionCharacter(
                id: companion.id,
                name: companion.name,
                imageName: companion.imageName,
                emoji: companion.emoji,
                unlockLevel: companion.unlockLevel,
                isUnlocked: companion.isUnlocked,
                isEquipped: companion.id == selectedCompanionId
            )
        }
    }
    
    // MARK: - Actions
    
    private func equipCompanion(_ companion: CompanionCharacter) {
        // Désélectionner l'ancien
        if let oldIndex = companions.firstIndex(where: { $0.isEquipped }) {
            companions[oldIndex] = CompanionCharacter(
                id: companions[oldIndex].id,
                name: companions[oldIndex].name,
                imageName: companions[oldIndex].imageName,
                emoji: companions[oldIndex].emoji,
                unlockLevel: companions[oldIndex].unlockLevel,
                isUnlocked: companions[oldIndex].isUnlocked,
                isEquipped: false
            )
        }
        
        // Sélectionner le nouveau
        if let newIndex = companions.firstIndex(where: { $0.id == companion.id }) {
            companions[newIndex] = CompanionCharacter(
                id: companion.id,
                name: companion.name,
                imageName: companion.imageName,
                emoji: companion.emoji,
                unlockLevel: companion.unlockLevel,
                isUnlocked: companion.isUnlocked,
                isEquipped: true
            )
            selectedCompanionId = companion.id
            
            // Sauvegarder dans Supabase et mettre à jour le service
            Task {
                await saveSelectedCompanion(companionId: companion.id)
            }
        }
    }
    
    private func saveSelectedCompanion(companionId: String) async {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            struct CompanionUpdate: Encodable {
                let selected_companion_id: String
            }
            
            let update = CompanionUpdate(selected_companion_id: companionId)
            
            try await SupabaseConfig.client
                .from("users")
                .update(update)
                .eq("id", value: session.user.id.uuidString)
                .execute()
            
            // Mettre à jour le UserDataService pour synchroniser partout
            userDataService.selectedCompanionId = companionId
            
            // Synchroniser avec le widget
            userDataService.syncToWidget()
            
        } catch {
            print("Erreur sauvegarde compagnon selectionne: \(error)")
        }
    }
    
    // MARK: - Notification Boost Logic
    
    /// Vérifie si on doit afficher la carte boost notification
    private var shouldShowNotificationBoost: Bool {
        // Afficher uniquement si bonus pas réclamé
        return !userDataService.notificationBonusClaimed
    }
    
    /// L'utilisateur clique sur la carte boost
    private func handleNotificationBoostTap() {
        // Toujours montrer la pop-up custom
        showNotificationPermission = true
    }
    
    /// L'utilisateur a cliqué sur "Activer"
    private func handleNotificationAllow() {
        Task {
            // ✅ AJOUTÉ : Sauvegarder le niveau AVANT le bonus
            let levelBefore = userDataService.currentLevel
            
            // Demander la permission système
            let granted = await NotificationManager.shared.requestAuthorization()
            
            if granted {
                // Permission accordée → Donner le bonus XP
                do {
                    try await userDataService.claimNotificationBonus()
                   
                    
                    let levelAfter = userDataService.currentLevel
                                    
                    //Si montée de niveau, afficher la popup
                    if levelAfter > levelBefore {
                    // Chercher les compagnons du nouveau niveau
                    let companionsByLevel: [Int: [(name: String, imageName: String)]] = [
                        2: [("Brume", "brume"), ("Flocon", "flocon")],
                        5: [("Caramel", "caramel"), ("Écorce", "ecorce"), ("Luciole", "luciole")],
                        10: [("Mochi", "mochi"), ("Sève", "seve")],
                        15: [("Pépite", "pepite")],
                        20: [("Noisette", "noisette")]
                        ]
                                        
                    if let newCompanions = companionsByLevel[levelAfter] {
                        unlockedCompanions = newCompanions
                        showUnlockPopup = true
                        confettiCounter += 1
                    }
            }
                    // ✅ AJOUTÉ : Recharger les données pour mettre à jour l'UI
                    await loadUserData()
                    
                    // Programmer notification par défaut à 9h
                    await NotificationManager.shared.scheduleDailyNotification(at: "09:00")
                    try await userDataService.saveNotificationTime("09:00")
                } catch {
                    print("Erreur reclamation bonus notification: \(error)")
                }
            } else {
                // Permission refusée
                await MainActor.run {
                    showNotificationDenied = true
                }
            }
        }
    }
    
    /// L'utilisateur a cliqué sur "Plus tard"
    private func handleNotificationLater() {
       
    }
    
    // ✅ AJOUTÉ : Vérifie les compagnons débloqués
    private func checkUnlockedCompanions(oldLevel: Int, newLevel: Int) {
        let companionsByLevel: [Int: [(name: String, imageName: String)]] = [
            2: [("Brume", "brume"), ("Flocon", "flocon")],
            3: [("Vera", "vera")],
            4: [("Jura", "jura")],
            5: [("Caramel", "caramel"), ("Écorce", "ecorce"), ("Luciole", "luciole")],
            6: [("Olga", "olga")],
            7: [("Luka", "luka")],
            8: [("Nina", "nina")],
            10: [("Mochi", "mochi"), ("Sève", "seve")],
            15: [("Pépite", "pepite")],
            20: [("Noisette", "noisette")]
        ]
        
        var newlyUnlocked: [(name: String, imageName: String)] = []
        
        // Parcourir tous les niveaux entre oldLevel et newLevel
        for level in (oldLevel + 1)...newLevel {
            if let companions = companionsByLevel[level] {
                newlyUnlocked.append(contentsOf: companions)
            }
        }
        
        // Si des compagnons ont été débloqués, afficher la popup
        if !newlyUnlocked.isEmpty {
            unlockedCompanions = newlyUnlocked
            showUnlockPopup = true
            confettiCounter += 1
            
        } else {
            
        }
    }
}
    
// MARK: - Preview

#Preview {
    CompanionsView()
}
