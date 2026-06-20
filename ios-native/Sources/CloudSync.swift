import Foundation

// Giriş'siz iCloud yedekleme: ayarlar (tema/font) cihazın iCloud hesabına senkronlanır.
// (Abonelik/premium zaten StoreKit ile Apple ID'ye bağlı otomatik senkron.)
@MainActor final class CloudSync: ObservableObject {
    static let keys = ["nd_font", "nd_scheme"]
    private let kv = NSUbiquitousKeyValueStore.default
    private let ud = UserDefaults.standard
    private var applying = false

    @Published var enabled: Bool {
        didSet {
            ud.set(enabled, forKey: "nd_icloud")
            if enabled { pushAll() }
        }
    }

    init() {
        enabled = ud.object(forKey: "nd_icloud") == nil ? true : ud.bool(forKey: "nd_icloud")
        NotificationCenter.default.addObserver(self, selector: #selector(cloudChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: kv)
        NotificationCenter.default.addObserver(self, selector: #selector(localChanged),
            name: UserDefaults.didChangeNotification, object: nil)
        kv.synchronize()
        if enabled { pullAll() }   // ilk açılışta iCloud'daki ayarları uygula
    }

    @objc private func cloudChanged() { if enabled { pullAll() } }

    @objc private func localChanged() {
        guard enabled, !applying else { return }
        pushAll()
    }

    private func pullAll() {        // iCloud -> yerel
        applying = true
        for k in Self.keys { if let v = kv.string(forKey: k) { ud.set(v, forKey: k) } }
        applying = false
    }

    private func pushAll() {        // yerel -> iCloud
        for k in Self.keys { if let v = ud.string(forKey: k) { kv.set(v, forKey: k) } }
        kv.synchronize()
    }
}
