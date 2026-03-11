//
//  StoreKitManager.swift
//  UpNews-iOS

import Foundation
import StoreKit
import Supabase
import Combine


// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free: return "Gratuit"
        case .premium: return "Premium"
        }
    }
}

// MARK: - StoreKit Manager

@MainActor
class StoreKitManager: ObservableObject {
    
    static let shared = StoreKitManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionTier: SubscriptionTier = .free
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Product IDs (À configurer dans App Store Connect)
    
    private let productIDs: [String] = [
        "com.valentin.upnews.premium.monthly",  // Abonnement mensuel
        "com.valentin.upnews.premium.yearly"     // Abonnement annuel
    ]
    
    // MARK: - Transaction Listener
    
    private var transactionListener: Task<Void, Never>?
    
    // MARK: - Initialization
    
    private init() {
        // Démarrer l'écoute des transactions
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Products
    
    /// Charge les produits disponibles depuis l'App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        print("🔍 Tentative de chargement des produits StoreKit...")
        print("🔍 Product IDs recherchés: \(productIDs)")
        
        do {
            let fetchedProducts = try await Product.products(for: productIDs)
            products = fetchedProducts.sorted { $0.price < $1.price }
            
            print("✅ Produits StoreKit chargés: \(products.count)")
            
            if products.isEmpty {
                print("⚠️ Aucun produit trouvé ! Vérifiez :")
                print("   1. Le fichier StoreKitConfig.storekit existe")
                print("   2. Les Product IDs correspondent exactement")
                print("   3. Le fichier est activé dans Edit Scheme > Run > Options")
            } else {
                for product in products {
                    print("   📦 Produit: \(product.id) - \(product.displayName) - \(product.displayPrice)")
                }
            }
        } catch {
            errorMessage = "Impossible de charger les produits : \(error.localizedDescription)"
            print("❌ Erreur chargement produits StoreKit: \(error)")
            print("   Type d'erreur: \(type(of: error))")
            print("   Détails: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Product
    
    /// Acheter un produit
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Vérifier la transaction
                let transaction = try checkVerified(verification)
                
                // Finaliser la transaction
                await transaction.finish()
                
                // Mettre à jour le statut d'abonnement
                await updateSubscriptionStatus()
                
                // Synchroniser avec Supabase
                await syncSubscriptionWithSupabase(tier: .premium)
                
                isLoading = false
                return transaction
                
            case .pending:
                isLoading = false
                errorMessage = "Achat en attente d'approbation"
                return nil
                
            case .userCancelled:
                isLoading = false
                errorMessage = "Achat annulé"
                return nil
                
            @unknown default:
                isLoading = false
                errorMessage = "Erreur inconnue"
                return nil
            }
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de l'achat : \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restaurer les achats
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            if subscriptionTier == .premium {
                await syncSubscriptionWithSupabase(tier: .premium)
            }
            
            isLoading = false
        } catch {
            errorMessage = "Erreur lors de la restauration : \(error.localizedDescription)"
            print("❌ Erreur restauration achats: \(error)")
            isLoading = false
        }
    }
    
    // MARK: - Update Subscription Status
    
    /// Mettre à jour le statut d'abonnement en fonction des transactions
    func updateSubscriptionStatus() async {
        var hasPremium = false
        
        // Vérifier les transactions actives
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    hasPremium = true
                    purchasedProductIDs.insert(transaction.productID)
                }
            }
        }
        
        subscriptionTier = hasPremium ? .premium : .free
        print("🔄 Statut abonnement mis à jour: \(subscriptionTier.rawValue)")
    }
    
    // MARK: - Listen for Transactions
    
    /// Écouter les mises à jour de transactions
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }
    
    // MARK: - Verify Transaction
    
    /// Vérifier l'intégrité d'une transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Sync with Supabase
    
    /// Synchroniser le statut d'abonnement avec Supabase
    private func syncSubscriptionWithSupabase(tier: SubscriptionTier) async {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            struct SubscriptionUpdate: Encodable {
                let subscription_tier: String
                let subscription_updated_at: String
            }
            
            let update = SubscriptionUpdate(
                subscription_tier: tier.rawValue,
                subscription_updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseConfig.client
                .from("users")
                .update(update)
                .eq("id", value: session.user.id.uuidString)
                .execute()
            
            print("✅ Statut abonnement synchronisé avec Supabase: \(tier.rawValue)")
            
            // Mettre à jour le UserDataService
            try await UserDataService.shared.loadAllData()
            
        } catch {
            print("❌ Erreur synchronisation abonnement avec Supabase: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    /// Obtenir le produit mensuel
    var monthlyProduct: Product? {
        products.first { $0.id == "com.valentin.upnews.premium.monthly" }
    }
    
    /// Obtenir le produit annuel
    var yearlyProduct: Product? {
        products.first { $0.id == "com.valentin.upnews.premium.yearly" }
    }
    
    /// Calculer les économies annuelles (si applicable)
    var yearlyDiscount: String? {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else {
            return nil
        }
        
        let monthlyYearlyCost = monthly.price * 12
        let savings = monthlyYearlyCost - yearly.price
        let percentage = (savings / monthlyYearlyCost) * 100
        
        // Convertir Decimal en Double pour le formatage
        let percentageDouble = NSDecimalNumber(decimal: percentage).doubleValue
        
        return String(format: "%.0f%%", percentageDouble)
    }
    
    /// Vérifier si l'utilisateur est Premium
    var isPremium: Bool {
        subscriptionTier == .premium
    }
}
