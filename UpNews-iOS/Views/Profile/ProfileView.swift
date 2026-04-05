import SwiftUI
import Supabase
import Auth

struct ProfileView: View {
    
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject private var userDataService: UserDataService
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false // ✅ NOUVEAU
    @State private var isDeleting = false // ✅ NOUVEAU
    @State private var deleteError: String? // ✅ NOUVEAU
    @State private var showAccountDeletionInfo = false // ✅ NOUVEAU
    @State private var showSubscriptionView = false // ✅ NOUVEAU - pour le modal Premium
    @State private var showPremiumInfo = false // ✅ NOUVEAU - pour les utilisateurs déjà Premium
    
    // Uniquement les données locales à la vue
    @State private var userEmail = ""
    
    // Préférences
    @State private var selectedLanguage = "Français"
    @State private var notificationTime = "9:00"
    @State private var showLanguagePicker = false
    @State private var showTimePicker = false
    @State private var showCategoryPicker = false // ✅ NOUVEAU
    
    // Notifications
    @State private var showNotificationPermission = false
    @State private var showNotificationDenied = false
    
    // Chargement
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
                
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header avec dégradé
                        profileHeader
                            .padding(.top, 0)
                        
                        // Statistiques
                        statsGrid
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                        
                        // Premium Section
                        premiumSection
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                        
                        // Préférences
                        preferencesSection
                            .padding(.top, 20)
                            .padding(.horizontal, 20)

                        
                        // Logout
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Compte")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color(red: 0.17, green: 0.24, blue: 0.21))
                                .padding(.horizontal, 4)
                            
                            logoutSection
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                .background(Color(red: 0.98, green: 0.97, blue: 0.96))
            }
        }
        .task {
            await loadProfileData()
        }
        .refreshable {
            await loadProfileData()
        }
        .alert("Déconnexion", isPresented: $showLogoutConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Se déconnecter", role: .destructive) {
                Task {
                    await authService.signOut()
                }
            }
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ?")
        }
        // ✅ NOUVEAU - Alert de suppression de compte
        .alert("Supprimer mon compte", isPresented: $showDeleteAccountConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer définitivement", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("Cette action est irréversible. Toutes vos données (profil, progression, articles lus) seront définitivement supprimées.")
        }
        // ✅ NOUVEAU - Alert d'erreur
        .alert("Erreur", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            if let error = deleteError {
                Text(error)
            }
        }
        // ✅ NOUVEAU - Modal d'abonnement (pour utilisateurs gratuits)
        .fullScreenCover(isPresented: $showSubscriptionView) {
            SubscriptionView(onDismiss: {
                showSubscriptionView = false
            })
            .environmentObject(userDataService)
        }
        // ✅ NOUVEAU - Fiche Premium (pour utilisateurs déjà Premium)
        .overlay {
            if showPremiumInfo {
                PremiumInfoSheet(onDismiss: {
                    showPremiumInfo = false
                })
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        ZStack {
            // Dégradé de fond
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.48, green: 0.63, blue: 0.36),
                    Color(red: 0.72, green: 0.84, blue: 0.63)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Éléments décoratifs
            decorativeElements
            
            // Contenu
            VStack(spacing: 12) {
                // Avatar avec compagnon - UTILISE userDataService
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 85, height: 85)
                        .shadow(color: Color.black.opacity(0.2), radius: 12, y: 4)
                    
                    Image(userDataService.selectedCompanionId)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .blur(radius: 8)
                        .opacity(0.5)
                    
                    Image(userDataService.selectedCompanionId)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                }
                
                // Nom
                Text(userDataService.displayName)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                
                // Email
                Text(userEmail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
                    .shadow(radius: 3)
                
                // Badge Premium sous l'email
                premiumBadge
                    .padding(.top, 4)
            }
        }
        .frame(height: 240) // Augmenté de 220 à 240 pour accommoder le badge
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Premium Badge (dans le header)
    
    private var premiumBadge: some View {
        Button {
            // Si l'utilisateur est Premium, on affiche PremiumInfoSheet
            // Sinon, on affiche SubscriptionView
            if userDataService.isPremium {
                showPremiumInfo = true
            } else {
                showSubscriptionView = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: userDataService.isPremium ? "crown.fill" : "crown")
                    .font(.system(size: 12, weight: .bold))
                
                Text(userDataService.isPremium ? "Premium" : "Gratuit")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(userDataService.isPremium ? .upNewsOrange : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(userDataService.isPremium ? Color.white : Color.white.opacity(0.25))
                    .shadow(
                        color: userDataService.isPremium ? Color.upNewsOrange.opacity(0.3) : Color.black.opacity(0.1),
                        radius: userDataService.isPremium ? 8 : 4,
                        y: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var decorativeElements: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 150, height: 150)
                .offset(x: -100, y: -50)
            
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 120, height: 120)
                .offset(x: 120, y: 80)
            
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 80, height: 80)
                .offset(x: 80, y: -70)
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 14) {
            // Articles aujourd'hui
            StatCard(
                iconName: "text.book.closed",
                value: "\(userDataService.articlesReadToday)",
                label: "Aujourd'hui",
                iconColor: Color.upNewsGreen.opacity(0.6),
                valueColor: Color.upNewsGreen.opacity(0.6)
            )
            
            // Streak
            StatCard(
                iconName: "flame",
                value: "\(userDataService.currentStreak)",
                label: "Série",
                iconColor: Color.upNewsOrange.opacity(0.6),
                valueColor: Color.upNewsOrange.opacity(0.6)
            )
            
            // Articles ce mois
            StatCard(
                iconName: "book.pages",
                value: "\(userDataService.articlesReadThisMonth)",
                label: "Ce mois-ci",
                iconColor: Color.upNewsLightPurple,
                valueColor: Color.upNewsLightPurple
            )
            
            // XP
            StatCard(
                iconName: "star.fill",
                value: "\(userDataService.maxXp-userDataService.currentXp)",
                label: "XP restante",
                iconColor: Color.upNewsBlueMid,
                valueColor: Color.upNewsBlueMid
            )
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(userDataService.isPremium ? "Mon abonnement" : "Premium")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(red: 0.17, green: 0.24, blue: 0.21))
                .padding(.horizontal, 4)
            
            if userDataService.isPremium {
                // Version Premium : Voir mes avantages
                premiumActiveBanner
            } else {
                // Version Gratuite : Passez Premium
                premiumUpgradeBanner
            }
        }
    }
    
    // Banner pour les utilisateurs Premium
    private var premiumActiveBanner: some View {
        Button {
            showPremiumInfo = true
        } label: {
            HStack(spacing: 14) {
                // Icône Premium
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.upNewsOrange, Color.upNewsOrange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Premium")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.upNewsBlack)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.upNewsGreen)
                    }
                    
                    Text("Voir mes avantages")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.upNewsOrange.opacity(0.15), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.upNewsOrange.opacity(0.3), Color.upNewsOrange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // Banner pour les utilisateurs Gratuits
    private var premiumUpgradeBanner: some View {
        Button {
            showSubscriptionView = true
        } label: {
            VStack(spacing: 0) {
                // Section principale
                HStack(spacing: 14) {
                    // Icône avec dégradé
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.upNewsOrange, Color.upNewsOrange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.upNewsOrange.opacity(0.3), radius: 8, y: 3)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Passez Premium")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.upNewsBlack)
                        
                        Text("Débloquez tous les avantages")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.upNewsOrange)
                }
                .padding(18)
                
                // Séparateur
                Divider()
                    .padding(.horizontal, 18)
                
                // Avantages rapides
                VStack(spacing: 10) {
                    premiumFeatureRow(icon: "newspaper.fill", text: "Tous les articles")
                    premiumFeatureRow(icon: "headphones", text: "Audio haute qualité")
                    premiumFeatureRow(icon: "pawprint.fill", text: "Tous les compagnons")
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                
                // Badge essai gratuit
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 12))
                        Text("14 jours d'essai gratuit")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.upNewsOrange)
                    )
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.upNewsOrange.opacity(0.2), radius: 16, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.upNewsOrange.opacity(0.4), Color.upNewsOrange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.upNewsBlueMid)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.upNewsBlack.opacity(0.8))
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.upNewsGreen)
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Préférences")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(red: 0.17, green: 0.24, blue: 0.21))
                .padding(.horizontal, 4)
            
            SettingsGroup {
                // ✅ NOUVEAU - Catégories préférées
                SettingsRow(
                    iconName: "star.circle.fill",
                    title: "Thématiques préférées",
                    value: categoriesPreviewText,
                    action: { showCategoryPicker = true }
                )
                
                SettingsRow(
                    iconName: "globe",
                    title: "Langue",
                    value: "Français",
                    action: { }
                )
                .disabled(true)
                
                SettingsRow(
                    iconName: "bell.fill",
                    title: "Notifications",
                    value: notificationTime,
                    action: { handleNotificationTap() }
                )
            }
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(
                selectedTime: $notificationTime,
                onSave: { time in
                    Task {
                        await saveNotificationTime(time)
                    }
                }
            )
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPreferencesSheet()
        }
        // ✅ NOUVEAU - Sheet d'information sur la suppression
        .sheet(isPresented: $showAccountDeletionInfo) {
            AccountDeletionInfoView()
        }
        // ✅ NOUVEAU - Pop-up permission notifications
        .fullScreenCover(isPresented: $showNotificationPermission) {
            NotificationPermissionView(
                onAllow: { handleNotificationAllow() },
                onLater: { handleNotificationLater() }
            )
            .background(ClearBackgroundView())
        }
        // ✅ NOUVEAU - Alert si notifications refusées
        .alert("Notifications désactivées", isPresented: $showNotificationDenied) {
            Button("Annuler", role: .cancel) { }
            Button("Ouvrir Réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Active les notifications dans les réglages iOS pour recevoir tes rappels quotidiens.")
        }
    }
    
    // ✅ NOUVEAU - Texte d'aperçu des catégories
    private var categoriesPreviewText: String {
        let count = userDataService.preferredCategories.count
        if count == 0 {
            return "Aucune"
        } else if count == 1 {
            return userDataService.preferredCategories.first?.capitalized ?? "1 catégorie"
        } else if count == 6 {
            return "Toutes"
        } else {
            return "\(count) catégories"
        }
    }
    
    // MARK: - Logout Section
    private var logoutSection: some View {
        VStack(spacing: 16) {
            // Bouton de déconnexion (seul dans son groupe)
            SettingsGroup {
                Button(action: {
                    showLogoutConfirmation = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18))
                            .foregroundColor(.upNewsOrange)
                            .frame(width: 28)
                        
                        Text("Se déconnecter")
                            .font(.system(size: 16))
                            .foregroundColor(.upNewsOrange)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                }
            }
            
            // Liens d'information (politique de confidentialité et suppression de compte)
            VStack(alignment: .leading, spacing: 0) {
                // Lien vers la politique de confidentialité
                Link(destination: URL(string: "https://valentincolombat.github.io/upnews-privacy/")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text("Politique de confidentialité")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
                
                // Ligne de séparation discrète
                Divider()
                    .background(Color.secondary.opacity(0.2))
                    .padding(.leading, 23)
                
                // Texte d'information discret (cliquable)
                Button(action: {
                    showAccountDeletionInfo = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text("En savoir plus sur la suppression de compte")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            
            // Bouton de suppression de compte (séparé visuellement)
            SettingsGroup {
                Button(action: {
                    showDeleteAccountConfirmation = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 28)
                        
                        Text("Supprimer mon compte")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        if isDeleting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                }
                .disabled(isDeleting)
            }
        }
    }
    

    // MARK: - Data Loading
    private func loadProfileData() async {
        isLoading = true
        
        do {
            let session = try await SupabaseConfig.client.auth.session
            userEmail = session.user.email ?? "email@example.com"
            
            //  Tout vient de UserDataService.loadAllData()
            try await userDataService.loadAllData()
            
            // Charger l'heure de notification (hybride)
            if let savedTime = userDataService.notificationTime {
                notificationTime = savedTime
            } else if let localTime = UserDefaults.standard.string(forKey: "notificationTime") {
                notificationTime = localTime
            }
            
        } catch is CancellationError {
            // Annulation normale (navigation, reconstruction de la vue), on ignore silencieusement
            return
        } catch {
            print("Erreur chargement donnees utilisateur: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Notification Handlers
    
    /// Gère le clic sur le bouton Notifications
    private func handleNotificationTap() {
        Task {
            let isAuthorized = await NotificationManager.shared.checkAuthorizationStatus()
            
            if isAuthorized {
                // Permission déjà accordée → Ouvrir directement le picker
                showTimePicker = true
            } else {
                // Pas encore de permission → Montrer notre pop-up custom
                showNotificationPermission = true
            }
        }
    }
    
    /// L'utilisateur a cliqué sur "Activer" dans notre pop-up
    private func handleNotificationAllow() {
        Task {
            // Demander la permission système
            let granted = await NotificationManager.shared.requestAuthorization()
            
            if granted {
                // Permission accordée → Donner le bonus XP
                do {
                    try await userDataService.claimNotificationBonus()
                   
                    
                    // Ouvrir le time picker
                    await MainActor.run {
                        showTimePicker = true
                    }
                } catch {
                print("Erreur bonus XP: \(error)")
                }
            } else {
                // Permission refusée → Montrer l'alert pour aller dans Réglages
                await MainActor.run {
                    showNotificationDenied = true
                }
            }
        }
    }
    
    /// L'utilisateur a cliqué sur "Plus tard"
    private func handleNotificationLater() {
        // Sauvegarder la date pour masquer la carte pendant 3 jours
        let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        UserDefaults.standard.set(threeDaysLater, forKey: "notificationBoostHiddenUntil")
       
    }
    
    /// Sauvegarde l'heure choisie et programme la notification
    private func saveNotificationTime(_ time: String) async {
        do {
            // Sauvegarder (hybride: UserDefaults + Supabase)
            try await userDataService.saveNotificationTime(time)
            
            // Programmer la notification locale
            await NotificationManager.shared.scheduleDailyNotification(at: time)
            
           
        } catch {
            print("Erreur sauvegarde heure: \(error)")
        }
    }
    
    // MARK: - Delete Account
    
    /// ✅ Suppression complète du compte utilisateur
    /// 
    /// **Flow automatique via triggers PostgreSQL :**
    /// 1. Suppression du profil `users` (cette fonction)
    /// 2. CASCADE : Suppression automatique de `user_article_interactions`
    /// 3. TRIGGER : Suppression automatique de `auth.users`
    ///
    /// **Résultat :** L'utilisateur peut se réinscrire avec le même email
    private func deleteAccount() async {
        isDeleting = true
        deleteError = nil
        
        do {
            // 1. Récupérer l'ID utilisateur
            let session = try await SupabaseConfig.client.auth.session
            let userId = session.user.id.uuidString
            
            
            
            // 2. Supprimer le profil utilisateur
            //    Le trigger PostgreSQL supprimera automatiquement auth.users
            //    Le CASCADE supprimera automatiquement user_article_interactions
            try await SupabaseConfig.client
                .from("users")
                .delete()
                .eq("id", value: userId)
                .execute()
            
            
            
            // 3. Réinitialiser l'état local
            await MainActor.run {
                userDataService.reset()
            }
            
            // 4. Déconnexion
            await authService.signOut()
            
           
            
        } catch {
            print("Erreur suppression compte: \(error.localizedDescription)")
            
            await MainActor.run {
                deleteError = "Impossible de supprimer le compte : \(error.localizedDescription)"
                isDeleting = false
            }
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let iconName: String
    let value: String
    let label: String
    var iconColor: Color = Color(red: 0.48, green: 0.63, blue: 0.36)
    var valueColor: Color = Color(red: 0.48, green: 0.63, blue: 0.36)
    var labelColor: Color = Color(red: 0.4, green: 0.4, blue: 0.4)
    var backgroundColor: Color = .white
    
    var body: some View {
        VStack(spacing: 10) {
            
            Image(systemName: iconName)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(iconColor)
               
                Text(value)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(valueColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            
            // Label en dessous
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(labelColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .padding(.horizontal, 18)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.08), radius: 16, y: 4)
    }
}

// MARK: - Settings Group Component
struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 2)
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let iconName: String
    let title: String
    var value: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.upNewsBlack.opacity(0.6))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.17, green: 0.24, blue: 0.21))
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.upNewsBlack.opacity(0.6))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.gray.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 54)
    }
}

// MARK: - Time Picker Sheet
struct TimePickerSheet: View {
    @Binding var selectedTime: String
    @Environment(\.dismiss) var dismiss
    
    let onSave: (String) -> Void
    
    @State private var pickerTime: Date
    
    init(selectedTime: Binding<String>, onSave: @escaping (String) -> Void) {
        self._selectedTime = selectedTime
        self.onSave = onSave
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let time = formatter.date(from: selectedTime.wrappedValue) ?? Date()
        self._pickerTime = State(initialValue: time)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choisissez l'heure de notification")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.top, 30)
                
                DatePicker(
                    "",
                    selection: $pickerTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
                
                Button {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    let timeString = formatter.string(from: pickerTime)
                    selectedTime = timeString
                    onSave(timeString)
                    dismiss()
                } label: {
                    Text("Valider")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.upNewsGreen)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("Heure de notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Category Preferences Sheet

struct CategoryPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userDataService: UserDataService // ✅ CHANGÉ en @EnvironmentObject
    
    @State private var selectedCategories: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // ScrollView principal avec tout le contenu
                ScrollView {
                    VStack(spacing: 20) {
                        // Info text en haut
                        Text("Sélectionne au moins une catégorie pour personnaliser ton fil d'actualité")
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        
                        // Categories Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(CategoryItem.allCategoriesCompact) { category in
                                CompactCategoryCard(
                                    category: category,
                                    isSelected: selectedCategories.contains(category.id)
                                ) {
                                    toggleCategory(category.id)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Selection count et messages dans le scroll
                        VStack(spacing: 8) {
                            if selectedCategories.isEmpty {
                                Text("Sélectionne au moins une catégorie")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(selectedCategories.count) catégorie\(selectedCategories.count > 1 ? "s" : "") sélectionnée\(selectedCategories.count > 1 ? "s" : "")")
                                    .font(.caption)
                                    .foregroundColor(.upNewsGreen)
                            }
                            
                            // Error message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .padding(.bottom, 110) // Espace pour le bouton flottant
                }
                
                // Bouton flottant en bas avec dégradé
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Dégradé subtil pour indiquer qu'on peut scroller
                        LinearGradient(
                            colors: [
                                Color(UIColor.systemBackground).opacity(0),
                                Color(UIColor.systemBackground).opacity(0.95),
                                Color(UIColor.systemBackground)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 30)
                        
                        // Zone du bouton
                        Button {
                            saveCategories()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Enregistrer")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedCategories.isEmpty ? Color.gray : Color.upNewsGreen)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                        .disabled(selectedCategories.isEmpty || isLoading)
                        .shadow(color: selectedCategories.isEmpty ? .clear : Color.upNewsGreen.opacity(0.3), radius: 12, y: 4)
                        .padding(.bottom, 30)
                        .background(Color(UIColor.systemBackground))
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Mes thématiques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Charger les catégories actuelles
                selectedCategories = Set(userDataService.preferredCategories)
            }
        }
    }
    
    private func toggleCategory(_ categoryId: String) {
        withAnimation(.spring(response: 0.3)) {
            if selectedCategories.contains(categoryId) {
                selectedCategories.remove(categoryId)
            } else {
                selectedCategories.insert(categoryId)
            }
        }
    }
    
    private func saveCategories() {
        guard !selectedCategories.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Utiliser updatePreferredCategories pour recharger les articles
                try await userDataService.updatePreferredCategories(Array(selectedCategories))
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur : \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Compact Category Card (for sheet)

struct CompactCategoryCard: View {
    let category: CategoryItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(category.color.opacity(isSelected ? 1.0 : 0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? .white : category.color)
                    
                    // Checkmark
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 16, height: 16)
                            )
                            .offset(x: 18, y: -18)
                    }
                }
                
                // Name
                Text(category.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.upNewsBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Description
                Text(category.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? category.color.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 6 : 2,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}


