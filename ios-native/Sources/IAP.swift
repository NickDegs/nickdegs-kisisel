import StoreKit

// Gerçek StoreKit 2 — premium font kilidi (tek seferlik satın alma)
@MainActor final class IAP: ObservableObject {
    static let productID = "com.nickdegs.kisisel.premiumfonts"
    @Published var product: Product?
    @Published var purchased = UserDefaults.standard.bool(forKey: "nd_premium")
    @Published var working = false
    private var updates: Task<Void, Never>?

    init() {
        updates = listenForTransactions()
        Task { await load(); await refresh() }
    }
    deinit { updates?.cancel() }

    var priceText: String { product?.displayPrice ?? "" }

    func load() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.productID, t.revocationDate == nil {
                owned = true
            }
        }
        setPurchased(owned)
    }

    @discardableResult
    func buy() async -> Bool {
        guard let product else { return false }
        working = true; defer { working = false }
        do {
            switch try await product.purchase() {
            case .success(let v):
                if case .verified(let t) = v { await t.finish(); setPurchased(true); return true }
                return false
            default: return false
            }
        } catch { return false }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    private func setPurchased(_ v: Bool) {
        purchased = v
        UserDefaults.standard.set(v, forKey: "nd_premium")
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let t) = update {
                    await t.finish()
                    if t.productID == Self.productID, t.revocationDate == nil {
                        await self?.setPurchased(true)
                    }
                }
            }
        }
    }
}
