import StoreKit

// Gerçek StoreKit 2 — premium abonelik (aylık / yıllık otomatik yenilenen)
// iPad / "Designed for iPhone" race düzeltmesi: satın alma sonrası premium'u
// doğrulanmış transaction'dan DİREKT açarız; currentEntitlements cache'ini
// (iPad'de geç dolar) BEKLEMEYİZ. refresh() yalnızca ek güvence / restore.
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
        Task {
            await load()
            // Uçuş sonrası / Ask to Buy / Family Sharing: bitmemiş işlemleri yakala
            for await result in Transaction.unfinished {
                if case .verified(let t) = result {
                    apply(t)
                    await t.finish()
                }
            }
            await refresh()
        }
    }
    deinit { updates?.cancel() }

    // Doğrulanmış transaction'dan premium'u HEMEN aç (cache bekleme)
    private func apply(_ t: Transaction) {
        if Self.ids.contains(t.productID), t.revocationDate == nil {
            setPurchased(true)
        }
    }

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

    // Sahiplik/expiry tespiti (launch + restore). Yalnızca YÜKSELTİR ya da
    // gerçekten hiç entitlement yoksa düşürür; taze satın almayı ezmez.
    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, Self.ids.contains(t.productID), t.revocationDate == nil {
                owned = true
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
                if case .verified(let t) = v {
                    apply(t)              // ← premium'u HEMEN aç (cache'i bekleme)
                    await t.finish()
                    return purchased
                }
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
        let gift = UserDefaults.standard.bool(forKey: "nd_gift")   // hediye kodu kalıcı
        purchased = v || gift
        UserDefaults.standard.set(v || gift, forKey: "nd_premium")
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let t) = update {
                    self?.apply(t)        // ← cache'e güvenme, direkt aç
                    await t.finish()
                }
            }
        }
    }
}
