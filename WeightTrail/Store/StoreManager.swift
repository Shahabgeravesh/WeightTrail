import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published private(set) var isLoading = false
    
    private let productIDs = ["com.weighttrail.progress"]
    
    init() {
        // Load purchased state immediately from UserDefaults
        if UserDefaults.standard.bool(forKey: "isProgressUnlocked") {
            purchasedProductIDs.insert("com.weighttrail.progress")
        }
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    func loadProducts() async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            self.products = try await Product.products(for: self.productIDs)
        } catch {
            print("Failed to load products:", error)
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            await self.processPurchase(verification)
        case .pending:
            throw StoreError.pending
        case .userCancelled:
            throw StoreError.userCancelled
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    func restorePurchases() async throws {
        self.isLoading = true
        defer { self.isLoading = false }
        
        try? await AppStore.sync()
        await self.updatePurchasedProducts()
    }
    
    func updatePurchasedProducts() async {
        for await verification in Transaction.currentEntitlements {
            await self.processPurchase(verification)
        }
    }
    
    private func processPurchase(_ verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else {
            return
        }
        
        // Update purchased products and persist to UserDefaults
        self.purchasedProductIDs.insert(transaction.productID)
        UserDefaults.standard.set(true, forKey: "isProgressUnlocked")
        
        // Finish the transaction
        await transaction.finish()
    }
    
    private func listenForTransactions() async {
        for await verification in Transaction.updates {
            await self.processPurchase(verification)
        }
    }
    
    var isProgressUnlocked: Bool {
        // Check both UserDefaults and StoreKit state
        return UserDefaults.standard.bool(forKey: "isProgressUnlocked") || 
               purchasedProductIDs.contains("com.weighttrail.progress")
    }
    
    func verifyPurchase() async {
        await updatePurchasedProducts()
        print("Progress unlocked: \(isProgressUnlocked)")
        print("Purchased products: \(purchasedProductIDs)")
    }
}

enum StoreError: LocalizedError {
    case pending
    case userCancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .pending:
            return "Purchase is pending approval"
        case .userCancelled:
            return "Purchase was cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
} 