//
//  SubscriptionView.swift
//  UpNews-iOS

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    
    @StateObject private var storeManager = StoreKitManager.shared
    @EnvironmentObject private var userDataService: UserDataService
    
    var onDismiss: (() -> Void)? = nil // ✅ Callback personnalisé
    
    @State private var selectedProductID: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var showContent = false // ✅ Pour l'animation d'apparition
    
    var body: some View {
        ZStack {
            // Fond flou avec overlay sombre (comme UnlockCompanionPopup)
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .blur(radius: showContent ? 0 : 20)
                .onTapGesture {
                    // Fermer en tapant sur le fond
                    dismissView()
                }
            
            VStack(spacing: 0) {
                // Carte principale avec effet glass
                VStack(spacing: 0) {
                    // Close button intégré
                    closeButton
                    
                    ScrollView {
                        VStack(spacing: 28) {
                            // Header
                            headerSection
                            
                            // Free trial banner
                            freeTrialBanner
                            
                            // Features list
                            featuresSection
                            
                            // Product cards
                            if storeManager.isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                            } else {
                                productsSection
                            }
                            
                            // CTA Button
                            ctaButton
                            
                            // Restore purchases
                            restoreButton
                            
                            // Legal links
                            legalSection
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                    .frame(maxHeight: 640) // Réduit de 700 à 640
                }
                .background(
                    // Effet glassmorphique moderne (comme UnlockCompanionPopup)
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.95),
                                        Color.white.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Bordure lumineuse
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.upNewsOrange.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                )
                .shadow(color: .upNewsOrange.opacity(0.3), radius: 40, x: 0, y: 20)
                .padding(.horizontal, 24)
                .padding(.bottom, 20) // Espace au-dessus de la tab bar
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(storeManager.errorMessage ?? "Une erreur est survenue")
        }
        .alert("Bienvenue en Premium !", isPresented: $showSuccess) {
            Button("Super !") {
                dismissView()
            }
        } message: {
            Text("Tous tes avantages sont maintenant débloqués")
        }
        .onChange(of: storeManager.subscriptionTier) { _, newTier in
            if newTier == .premium {
                showSuccess = true
            }
        }
    }
    
    // MARK: - Dismiss Helper
    
    private func dismissView() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss?()
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                dismissView()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.upNewsBlack.opacity(0.6))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
        }
        .padding(.top, 16)
        .padding(.trailing, 20)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.upNewsOrange.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.upNewsOrange)
            }
            
            Text("Premium")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.upNewsBlack)
            
            Text("Débloque tous les avantages d'UpNews")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Free Trial Banner
    
    private var freeTrialBanner: some View {
        HStack(spacing: 8) {
            Spacer()
            
            Image(systemName: "gift.fill")
                .font(.system(size: 18))
                .foregroundColor(.upNewsOrange)
            
            Text("14 jours d'essai gratuit")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.upNewsOrange)
            
            Spacer()
        }    
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "newspaper.fill", color: .upNewsBlueMid, title: "Tous les articles")
            featureRow(icon: "headphones", color: .upNewsBlueMid, title: "Audio haute qualité")
            featureRow(icon: "book.fill", color: .upNewsBlueMid, title: "Bibliothèque complète")
            featureRow(icon: "pawprint.fill", color: .upNewsBlueMid, title: "Tous les compagnons")
            featureRow(icon: "bolt.fill", color: .upNewsBlueMid, title: "XP bonus x2")
        }
    }
    
    private func featureRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.upNewsBlack)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.upNewsBlueMid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.6))
        .cornerRadius(12)
    }
    
    // MARK: - Products Section
    
    private var productsSection: some View {
        VStack(spacing: 12) {
            if let monthly = storeManager.monthlyProduct {
                productCard(monthly, isRecommended: false)
            }
            
            if let yearly = storeManager.yearlyProduct {
                productCard(yearly, isRecommended: true)
            }
        }
    }
    
    private func productCard(_ product: Product, isRecommended: Bool) -> some View {
        Button {
            selectedProductID = product.id
        } label: {
            VStack(spacing: 14) {
                // Ligne du haut : Badge + REDUCTION + case à cocher
                HStack(spacing: 6) {
                    // Badge selon le type
                    if isRecommended {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("POPULAIRE")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.upNewsOrange)
                        .cornerRadius(10)
                        .fixedSize()
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("LE PLUS SIMPLE")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.upNewsBlueMid)
                        .cornerRadius(10)
                        .fixedSize()
                    }
                    
                    // Badge REDUCTION (si annuel)
                    if product.id.contains("yearly"), let discount = storeManager.yearlyDiscount {
                        Text("-\(discount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.upNewsGreen)
                            .cornerRadius(10)
                            .fixedSize()
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Case à cocher
                    Image(systemName: selectedProductID == product.id ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26))
                        .foregroundColor(selectedProductID == product.id ? .upNewsGreen : .gray.opacity(0.3))
                }
                
                // Ligne du milieu : Image + UPNEWS + Prix
                HStack(spacing: 12) {
                    // Image compagnon
                    Image(isRecommended ? "nina" : "mousse")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 65, height: 65)
                        .padding(5)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Nom du compagnon
                        Text(isRecommended ? "ANNUEL" : "MENSUEL")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.upNewsBlack)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .fixedSize()
                        
                        // Prix avec période (orange)
                        Text(isRecommended ? "39,99 € / an" : "3,99 € / mois")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.upNewsOrange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .fixedSize()
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        selectedProductID == product.id
                            ? Color.gray.opacity(0.08)
                            : Color.white
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        selectedProductID == product.id 
                            ? Color.white 
                            : Color.gray.opacity(0.2),
                        lineWidth: selectedProductID == product.id ? 2.5 : 1
                    )
            }
            .shadow(
                color: selectedProductID == product.id 
                    ? Color.upNewsOrange.opacity(0.2) 
                    : Color.black.opacity(0.05),
                radius: selectedProductID == product.id ? 8 : 3,
                x: 0,
                y: selectedProductID == product.id ? 3 : 2
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - CTA Button
    
    private var ctaButton: some View {
        VStack(spacing: 8) {
            Button {
                purchaseSelectedProduct()
            } label: {
                HStack(spacing: 12) {
                    if storeManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Commencer l'essai gratuit")
                            .font(.system(size: 18, weight: .bold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.upNewsOrange, Color.upNewsOrange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.upNewsOrange.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .disabled(selectedProductID == nil || storeManager.isLoading)
            .opacity(selectedProductID == nil ? 0.5 : 1.0)
            
            Text("14 jours gratuits, puis renouvellement automatique")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button {
            Task {
                await storeManager.restorePurchases()
            }
        } label: {
            Text("Restaurer mes achats")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.upNewsBlueMid)
        }
        .disabled(storeManager.isLoading)
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(spacing: 8) {
            
            Text("Annule à tout moment depuis les réglages de ton compte")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Link("Conditions d'utilisation", destination: URL(string: "https://valentincolombat.github.io/upnews-CGU/")!)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Link("Politique de confidentialité", destination: URL(string: "https://valentincolombat.github.io/upnews-privacy/")!)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Purchase Logic
    
    private func purchaseSelectedProduct() {
        guard let productID = selectedProductID,
              let product = storeManager.products.first(where: { $0.id == productID }) else {
            return
        }
        
        Task {
            do {
                let transaction = try await storeManager.purchase(product)
                if transaction != nil {
                    // Achat réussi
                    showSuccess = true
                }
            } catch {
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionView()
        .environmentObject(UserDataService.shared)
}
