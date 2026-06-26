import CoreLocation

// Move Log'un kendi GPS göndericisi: arka planda konumu Traccar'a yollar (ayrı OsmAnd app gerekmez).
final class Tracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = Tracker()          // tek örnek: AppDelegate de arka plan açılışında erişir
    private let mgr = CLLocationManager()
    @Published var active = UserDefaults.standard.bool(forKey: "nd_tracking")
    @Published var recording = false        // manuel gezi kaydı sürüyor mu
    @Published var rideType = "moto"        // manuel gezi tipi
    @Published var rideStart: Date?         // manuel gezi başlangıcı
    private var deviceId: String?
    private var ingestURL: String?

    override init() {
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        mgr.distanceFilter = 6                        // sık gönder (sağlıklı algılama)
        // Sadece Info.plist UIBackgroundModes=location içeriyorsa aç (yoksa çökmesin)
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        if modes.contains("location") { mgr.allowsBackgroundLocationUpdates = true }
        mgr.pausesLocationUpdatesAutomatically = false
        mgr.activityType = .automotiveNavigation
        mgr.showsBackgroundLocationIndicator = true
        // kalıcı cihaz bilgisini geri yükle
        deviceId = UserDefaults.standard.string(forKey: "nd_dev")
        ingestURL = UserDefaults.standard.string(forKey: "nd_ingest")
        // Takip daha önce açıksa (relaunch / arka plandan konumla uyandırma) hemen sürdür.
        // Bug fix: eskiden start() yalnızca toggle'a elle dokununca çağrılırdı; app yeniden
        // açılınca 'active' true görünür ama GPS basmazdı -> otomatik algılama hiç tetiklenmezdi.
        if active, deviceId != nil { beginUpdates() }
    }

    // CLLocationManager'ı fiilen başlatan tek nokta (hem canlı hem significant-change).
    private func beginUpdates() {
        let st = mgr.authorizationStatus
        if st == .notDetermined || st == .authorizedWhenInUse { mgr.requestAlwaysAuthorization() }
        mgr.startUpdatingLocation()
        mgr.startMonitoringSignificantLocationChanges()   // app kapansa bile hareketle uyanır
    }

    private func persist(deviceId: String, url: String) {
        self.deviceId = deviceId; self.ingestURL = url
        UserDefaults.standard.set(deviceId, forKey: "nd_dev")
        UserDefaults.standard.set(url, forKey: "nd_ingest")
    }

    func start(deviceId: String, url: String) {
        persist(deviceId: deviceId, url: url)
        beginUpdates()
        set(true)
    }

    func stop() {
        mgr.stopUpdatingLocation()
        mgr.stopMonitoringSignificantLocationChanges()
        set(false)
    }

    // --- Manuel gezi kaydı (tip seçilebilir + sonradan değiştirilebilir) ---
    func startRide(type: String, deviceId: String, url: String) {
        persist(deviceId: deviceId, url: url)
        beginUpdates()
        DispatchQueue.main.async { self.rideType = type; self.rideStart = Date(); self.recording = true }
    }

    func endRide() -> (from: Double, to: Double, type: String)? {
        guard let s = rideStart else { return nil }
        let r = (s.timeIntervalSince1970, Date().timeIntervalSince1970, rideType)
        if !active {                                   // oto-takip kapalıysa GPS'i tamamen durdur
            mgr.stopUpdatingLocation()
            mgr.stopMonitoringSignificantLocationChanges()
        }
        DispatchQueue.main.async { self.recording = false; self.rideStart = nil }
        return r
    }

    private func set(_ v: Bool) {
        DispatchQueue.main.async { self.active = v }
        UserDefaults.standard.set(v, forKey: "nd_tracking")
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last, let id = deviceId, let base = ingestURL,
              var comps = URLComponents(string: base) else { return }
        comps.queryItems = [
            .init(name: "id", value: id),
            .init(name: "lat", value: String(loc.coordinate.latitude)),
            .init(name: "lon", value: String(loc.coordinate.longitude)),
            .init(name: "timestamp", value: String(Int(loc.timestamp.timeIntervalSince1970))),
            .init(name: "speed", value: String(max(0, loc.speed) * 1.94384)),  // m/s -> knot
            .init(name: "altitude", value: String(loc.altitude)),
            .init(name: "accuracy", value: String(loc.horizontalAccuracy)),
            .init(name: "bearing", value: String(max(0, loc.course))),
        ]
        guard let url = comps.url else { return }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        URLSession.shared.dataTask(with: req).resume()
    }
}
