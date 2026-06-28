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
    private var lastSent: CLLocation?       // ışınlanma filtresi için son gönderilen konum
    private var lastLoc: CLLocation?        // en son geçerli konum (heartbeat için)
    private var heartbeat: Timer?           // 15 sn'de bir zorunlu gönderim (boşluk/ışınlanma olmasın)

    override init() {
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // En detaylı rota: konum mesafe-tabanlı; 5 m'de bir gönder (hareket halinde
        // BestForNavigation ~1 sn'de bir fix verir → motorda saniyenin altında nokta).
        // 5 m, GPS titremesini (jitter) yakalamadan en yoğun temiz takip noktası.
        mgr.distanceFilter = 5
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
        startHeartbeat()
    }

    // 15 sn HEARTBEAT: hareket az olsa/iOS arka planda seyreltse bile son konumu en geç 15 sn'de
    // bir Traccar'a yollar -> iz boşluksuz/yoğun, "ışınlanma" olmaz, anlık takip + en kaliteli video.
    private func startHeartbeat() {
        DispatchQueue.main.async {
            self.heartbeat?.invalidate()
            self.heartbeat = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
                guard let self, let loc = self.lastLoc, loc.timestamp.timeIntervalSinceNow > -30 else { return }
                self.sendLoc(loc, force: true)
            }
        }
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
        heartbeat?.invalidate(); heartbeat = nil
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
        guard let loc = locs.last else { return }
        // GPS gürültü / ışınlanma filtresi (kötü sinyali minimuma indir)
        guard loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= 50 else { return }   // doğruluk kötü = at
        guard loc.timestamp.timeIntervalSinceNow > -15 else { return }                    // bayat fix = at
        lastLoc = loc
        sendLoc(loc, force: false)
    }

    // Konumu Traccar'a gönder. force=false: ışınlanma filtresi uygula (mesafe-tabanlı normal akış).
    // force=true: 15 sn heartbeat (duruyor olsa bile düzenli nokta -> boşluk yok).
    private func sendLoc(_ loc: CLLocation, force: Bool) {
        guard let id = deviceId, let base = ingestURL, var comps = URLComponents(string: base) else { return }
        if !force, let prev = lastSent {
            let d = loc.distance(from: prev)
            let dt = loc.timestamp.timeIntervalSince(prev.timestamp)
            if dt > 0, d / dt > 70 { return }        // >252 km/h imkânsız = ışınlanma, at
        }
        lastSent = loc
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
