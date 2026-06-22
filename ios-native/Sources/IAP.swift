import StoreKit

// Gerçek StoreKit 2 — premium font kilidi (aylık / yıllık otomatik yenilenen abonelik)
@MainActor final class IAP: ObservableObject {
    static let monthlyID = "com.nickdegs.kisisel.premium.monthly"
    static let yearlyID = "com.nickdegs.kisisel.premium.yearly"
    static var ids: [String] { [monthlyID, yearlyID] }

    @Published var monthly: Product?
    @Published var yearly: Product?
    @Published var purchased = UserDefaults.standard.bool(forKey: "nd_premium")
    @Published var working = false
    @Published var lastError: String?      // satın alma hatasını arayüze göster
    @Published var loadMsg: String?        // ürün yükleme durumu
    private var updates: Task<Void, Never>?

    init() {
        updates = listenForTransactions()
        Task { await load(); await refresh() }
    }
    deinit { updates?.cancel() }

    func load() async {
        do {
            let prods = try await Product.products(for: Self.ids)
            monthly = prods.first { $0.id == Self.monthlyID }
            yearly = prods.first { $0.id == Self.yearlyID }
            loadMsg = prods.isEmpty
                ? "Ürünler mağazadan gelmedi. App Store Connect → Business → Paid Apps anlaşması + banka/vergi tamamlanmalı (birkaç saat sürebilir)."
                : nil
        } catch {
            loadMsg = "Ürünler yüklenemedi: \(error.localizedDescription)"
        }
    }

    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, Self.ids.contains(t.productID), t.revocationDate == nil {
                owned = true   // currentEntitlements yalnızca aktif (süresi geçmemiş) abonelikleri döner
            }
        }
        setPurchased(owned)
    }

    @discardableResult
    func buy(_ product: Product) async -> Bool {
        working = true; lastError = nil; defer { working = false }
        do {
            switch try await product.purchase() {
            case .success(let v):
                if case .verified(let t) = v { await t.finish(); setPurchased(true); return true }
                lastError = "Satın alma doğrulanamadı."; return false
            case .pending:
                lastError = "Onay bekleniyor (Aile Onayı / ödeme yöntemi)."; return false
            case .userCancelled:
                return false   // sessiz iptal
            @unknown default:
                lastError = "Bilinmeyen durum."; return false
            }
        } catch {
            lastError = "Satın alma hatası: \(error.localizedDescription)"
            return false
        }
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
                    await self?.refresh()
                }
            }
        }
    }
}
