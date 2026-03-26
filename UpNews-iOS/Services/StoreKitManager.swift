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
    @Published var shouldDismissSubscriptionView = false
    
    // MARK: - Product IDs (À configurer dans App Store Connect)
    
    private let productIDs: [String] = [
        "com.valentin.upnews.premium.m",  // Abonnement mensuel
        "com.valentin.upnews.premium.y"   // Abonnement annuel
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
        shouldDismissSubscriptionView = false
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            if subscriptionTier == .premium {
                await syncSubscriptionWithSupabase(tier: .premium)
                
                // ✅ Succès : Abonnement Premium restauré
                errorMessage = nil
                print("✅ Restauration réussie : Premium activé")
                
                // Fermer la vue après un court délai
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
                shouldDismissSubscriptionView = true
            } else {
                // ⚠️ Aucun abonnement trouvé
                errorMessage = "Aucun abonnement actif trouvé. Veuillez souscrire à un abonnement."
                print("⚠️ Restauration : Aucun abonnement trouvé")
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
        let previousTier = subscriptionTier
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
        
        let newTier: SubscriptionTier = hasPremium ? .premium : .free
        subscriptionTier = newTier
        print("🔄 Statut abonnement mis à jour: \(subscriptionTier.rawValue)")
        
        // Synchroniser avec Supabase si le tier a changé (premium → free)
        if previousTier == .premium && newTier == .free {
            print("⚠️ Passage de premium → free détecté, synchronisation Supabase...")
            await syncSubscriptionWithSupabase(tier: .free)
        }
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
    
    
    private func syncSubscriptionWithSupabase(tier: SubscriptionTier) async {
        do {
            // Vérifier que l'utilisateur est authentifié
            _ = try await SupabaseConfig.client.auth.session
            
            if tier == .free {
                // Passage en free : mise à jour directe dans Supabase
                do {
                    try await updateSubscriptionTierDirectly(tier: "free")
                    print("✅ Supabase mis à jour : free")
                } catch {
                    print("❌ Erreur mise à jour Supabase vers free: \(error)")
                }
            } else {
                // Passage en premium : validation via Edge Function
                do {
                    try await validateSubscriptionWithBackend()
                    print("✅ Validation backend réussie")
                } catch {
                    print("⚠️ Validation backend échouée: \(error)")
                    
                    #if DEBUG
                    // En mode DEBUG (tests StoreKit), on met à jour directement la base
                    do {
                        try await updateSubscriptionTierDirectly(tier: "premium")
                    } catch {
                        print("❌ Impossible de mettre à jour le tier en mode test: \(error)")
                        print("⚠️ L'abonnement local fonctionne mais la synchro Supabase a échoué")
                    }
                    #else
                    // En PRODUCTION, on ne fait rien si l'Edge Function échoue
                    print("❌ PRODUCTION : Validation échouée, abonnement non activé")
                    throw error
                    #endif
                }
            }
            
            // Mettre à jour le UserDataService
            do {
                try await UserDataService.shared.loadAllData()
                print("✅ Données utilisateur rechargées après changement de tier")
            } catch {
                print("⚠️ Erreur rechargement données: \(error)")
            }
            
        } catch {
            print("❌ Erreur synchronisation abonnement avec Supabase: \(error)")
        }
    }
    
    /// Met à jour directement le subscription_tier dans Supabase (pour les tests)
    private func updateSubscriptionTierDirectly(tier: String) async throws {
        print("🔄 Mise à jour directe du subscription_tier en mode test...")
        
        // Utiliser une fonction RPC avec SECURITY DEFINER pour contourner les RLS
        do {
            let params: [String: String] = ["p_tier": tier]
            
            try await SupabaseConfig.client
                .rpc("update_subscription_tier_test", params: params)
                .execute()
            
            print("✅ subscription_tier mis à jour via RPC dans Supabase")
        } catch {
            print("❌ Erreur RPC update_subscription_tier_test: \(error)")
            print("ℹ️  Assurez-vous que la fonction RPC existe dans Supabase")
            
            throw error
        }
    }
    
    /// Valide l'abonnement auprès du backend via Edge Function
    private func validateSubscriptionWithBackend() async throws {
        print("🔄 Appel Edge Function validate-subscription...")
        
        // Récupérer la dernière transaction vérifiée
        var latestTransaction: Transaction?
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    latestTransaction = transaction
                    break
                }
            }
        }
        
        guard let transaction = latestTransaction else {
            throw NSError(domain: "StoreKit", code: -2, userInfo: [NSLocalizedDescriptionKey: "Aucune transaction trouvée"])
        }
        
        print("   📤 Transaction ID: \(transaction.originalID)")
        
        // ⚠️ En mode test StoreKit, l'ID est souvent 0, ce qui fait échouer la validation
        // On lève une erreur pour permettre la mise à jour directe
        if transaction.originalID == 0 {
            print("⚠️ Transaction ID = 0 détecté (mode test StoreKit)")
            throw NSError(domain: "StoreKit", code: -3, userInfo: [NSLocalizedDescriptionKey: "Mode test StoreKit - validation backend ignorée"])
        }
        
        // Préparer la requête
        let requestBody: [String: Any] = [
            "originalTransactionId": String(transaction.originalID)
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Appeler l'Edge Function
        do {
            try await SupabaseConfig.client.functions.invoke(
                "validate-subscription",
                options: FunctionInvokeOptions(body: jsonData)
            )
            
            print("✅ Edge Function appelée avec succès")
        } catch {
            print("❌ Erreur Edge Function: \(error)")
            throw error
        }
    }
    
    // MARK: - Helpers
    
    /// Obtenir le produit mensuel
    var monthlyProduct: Product? {
        products.first { $0.id == "com.valentin.upnews.premium.m" }
    }
    
    /// Obtenir le produit annuel
    var yearlyProduct: Product? {
        products.first { $0.id == "com.valentin.upnews.premium.y" }
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
