import CoreLocation

// Move Log'un kendi GPS göndericisi: arka planda konumu Traccar'a yollar (ayrı OsmAnd app gerekmez).
final class Tracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let mgr = CLLocationManager()
    @Published var active = UserDefaults.standard.bool(forKey: "nd_tracking")
    private var deviceId: String?
    private var ingestURL: String?

    override init() {
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBest
        mgr.distanceFilter = 20                       // her 20m'de bir gönder
        // Sadece Info.plist UIBackgroundModes=location içeriyorsa aç (yoksa çökmesin)
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        if modes.contains("location") { mgr.allowsBackgroundLocationUpdates = true }
        mgr.pausesLocationUpdatesAutomatically = false
        mgr.activityType = .automotiveNavigation
        mgr.showsBackgroundLocationIndicator = true
    }

    func start(deviceId: String, url: String) {
        self.deviceId = deviceId; self.ingestURL = url
        let st = mgr.authorizationStatus
        if st == .notDetermined || st == .authorizedWhenInUse { mgr.requestAlwaysAuthorization() }
        mgr.startUpdatingLocation()
        set(true)
    }

    func stop() {
        mgr.stopUpdatingLocation()
        set(false)
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
