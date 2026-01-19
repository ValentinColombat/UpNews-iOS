import SwiftUI

struct ProfileView: View {
    // Données statiques directement dans la vue
    @State private var userName = "Marie Dupont"
    @State private var userEmail = "marie.dupont@email.com"
    @State private var articlesRead = 42
    @State private var currentStreak = 7
    @State private var unlockedZones = 3
    @State private var totalPoints = 250
    @State private var selectedLanguage = "Français"
    @State private var notificationTime = "9:00"
    @State private var selectedCompanionId: String = "cannelle"
    
    // Picker pour séléction de la langue et de l'heure
    @State private var showLanguagePicker = false
    @State private var showTimePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header avec dégradé
                profileHeader
                    .padding(.top, 0)
                
                // Statistiques
                statsGrid
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // Préférences
                preferencesSection
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // Abonnement
                subscriptionCard
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
            }
        }
        .background(Color(red: 0.98, green: 0.97, blue: 0.96))
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        ZStack {
            // Dégradé de fond
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.48, green: 0.63, blue: 0.36),  // primaryGreen
                    Color(red: 0.72, green: 0.84, blue: 0.63)   // lightGreen
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Éléments décoratifs
            decorativeElements
            
            // Contenu
            VStack(spacing: 12) {
                // Avatar avec compagnon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 85, height: 85)
                        .shadow(color: Color.black.opacity(0.2), radius: 12, y: 4)
                    
                    Image(selectedCompanionId)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .blur(radius: 8)
                        .opacity(0.5)
                    
                    Image(selectedCompanionId)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                }
                
                // Nom
                Text(userName)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                
                // Email
                Text(userEmail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
                    .shadow(radius: 3)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 20)
    }
    
    private var decorativeElements: some View {
        ZStack {
            // Cercles décoratifs
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
            // Carte Articles
            StatCard(
                iconName: "text.book.closed",
                value: "\(articlesRead)",
                label: "Articles lus",
                iconColor: Color.upNewsGreen.opacity(0.6),
                valueColor: Color.upNewsGreen.opacity(0.6)
            )
            
            // Carte Streak
            StatCard(
                iconName: "flame",
                value: "\(currentStreak)",
                label: "Jours de suite",
                iconColor: Color.upNewsOrange.opacity(0.6),
                valueColor: Color.upNewsOrange.opacity(0.6)
            )
            
            // Carte Mois
            StatCard(
                iconName:"apple.books.pages",
                value: "\(unlockedZones)",
                label: "Articles lus ce mois-ci",
                iconColor: Color.upNewsLightPurple,
                valueColor: Color.upNewsLightPurple
            )
            
            // Carte Points
            StatCard(
                iconName: "star",
                value: "\(totalPoints)",
                label: "Points acquis",
                iconColor: Color.upNewsBlueMid,
                valueColor: Color.upNewsBlueMid
            )
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
                    action: { showTimePicker = true }
                )
            }
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(selectedTime: $notificationTime)
        }
    }
    
    // MARK: - Subscription Card
    private var subscriptionCard: some View {
        VStack(spacing: 16) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.94, green: 0.47, blue: 0.34),  // coral
                    Color(red: 0.96, green: 0.78, blue: 0.37)   // warmYellow
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .frame(height: 250)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    
                    Text("ESSAI GRATUIT")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text("Encore 30 jours")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("Profitez de toutes les fonctionnalités")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            )
            .shadow(color: Color(red: 0.94, green: 0.47, blue: 0.34).opacity(0.3), radius: 24, y: 8)
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
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(valueColor)
            
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(labelColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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
    
    @State private var pickerTime: Date
    
    init(selectedTime: Binding<String>) {
        self._selectedTime = selectedTime
        
        // Convertir le String "9:00" en Date pour le picker
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
                
                // Bouton Valider
                Button {
                    // Convertir la Date en String "HH:mm"
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    selectedTime = formatter.string(from: pickerTime)
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

// MARK: - Preview
#Preview {
    ProfileView()
}
