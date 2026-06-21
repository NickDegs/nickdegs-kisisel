import SwiftUI

let API = "https://kisisel-api.nickdegs.com"

// MARK: - Modeller
struct Avatar: Codable, Hashable { var type: String = "initials"; var value: String? = nil }
struct Ride: Codable, Identifiable, Hashable {
    var id: String; var date: String; var type: String?; var mode: String?; var size: Double
}
struct Stats: Codable { var totalRides: Int; var byType: [String:Int]; var latest: Ride? }
struct Position: Codable, Identifiable, Hashable {
    var device: String; var lat: Double; var lon: Double; var speedKmh: Double; var online: Bool
    var id: String { device }
}
struct Profile: Codable { var username: String?; var name: String; var avatar: Avatar }
struct Friend: Codable, Identifiable, Hashable {
    var username: String; var name: String?; var avatar: Avatar?; var online: Bool?
    var id: String { username }
}
struct Message: Codable, Identifiable, Hashable {
    var id: String?; var frm: String; var text: String?; var ts: Double; var type: String?; var media: String?
    var mid: String { id ?? "\(frm)\(ts)" }
}
struct Convo: Codable, Identifiable, Hashable {
    var username: String; var name: String?; var avatar: Avatar?; var online: Bool?
    var unread: Int?; var last: Message?
    var id: String { username }
}

// MARK: - API + Durum
@MainActor final class Store: ObservableObject {
    @Published var token: String = UserDefaults.standard.string(forKey: "nd_token") ?? ""
    @Published var me: String = ""
    @Published var loginError = false
    var loggedIn: Bool { !token.isEmpty || (AppEnv.demo && AppEnv.screen != "hero") }
    init() { if AppEnv.demo && AppEnv.screen != "hero" { me = "me" } }

    private func dec() -> JSONDecoder { let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; return d }

    private func req(_ path: String, method: String = "GET", body: [String:Any]? = nil) async throws -> Data {
        var r = URLRequest(url: URL(string: API + path)!)
        r.httpMethod = method
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty { r.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        if let body { r.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, resp) = try await URLSession.shared.data(for: r)
        if let h = resp as? HTTPURLResponse, h.statusCode == 401 { await MainActor.run { self.logout() } }
        return data
    }

    func login(_ user: String, _ pass: String) async {
        loginError = false
        do {
            var r = URLRequest(url: URL(string: API + "/auth/login")!)
            r.httpMethod = "POST"; r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.httpBody = try JSONSerialization.data(withJSONObject: ["user": user, "password": pass])
            let (data, _) = try await URLSession.shared.data(for: r)
            if let o = try JSONSerialization.jsonObject(with: data) as? [String:Any], let t = o["token"] as? String {
                token = t; me = user
                UserDefaults.standard.set(t, forKey: "nd_token")
            } else { loginError = true }
        } catch { loginError = true }
    }
    func loginWithApple(_ identityToken: String, name: String) async {
        loginError = false
        do {
            var r = URLRequest(url: URL(string: API + "/auth/apple")!)
            r.httpMethod = "POST"; r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.httpBody = try JSONSerialization.data(withJSONObject: ["identity_token": identityToken, "name": name])
            let (data, _) = try await URLSession.shared.data(for: r)
            if let o = try JSONSerialization.jsonObject(with: data) as? [String:Any], let t = o["token"] as? String {
                token = t; me = (o["user"] as? String) ?? ""
                UserDefaults.standard.set(t, forKey: "nd_token")
            } else { loginError = true }
        } catch { loginError = true }
    }
    func logout() { token = ""; UserDefaults.standard.removeObject(forKey: "nd_token") }

    func deleteAccount() async {
        _ = try? await req("/api/account", method: "DELETE")
        UserDefaults.standard.removeObject(forKey: "nd_premium")
        logout()
    }

    func rides() async -> [Ride] {
        if AppEnv.demo { return DemoData.rides }
        return (try? dec().decode([String:[Ride]].self, from: await req("/api/rides"))["rides"]) ?? []
    }
    func stats() async -> Stats? {
        if AppEnv.demo { return DemoData.stats }
        return try? dec().decode(Stats.self, from: await req("/api/stats")) }
    func positions() async -> [Position] {
        if AppEnv.demo { return DemoData.positions }
        return (try? dec().decode([String:[Position]].self, from: await req("/api/gps/live"))["positions"]) ?? []
    }
    func profile() async -> Profile? {
        if AppEnv.demo { return Profile(username: "me", name: Demo.user, avatar: Avatar()) }
        return try? dec().decode(Profile.self, from: await req("/api/profile")) }
    func friends() async -> [Friend] {
        if AppEnv.demo { return DemoData.friends }
        return (try? dec().decode([String:[Friend]].self, from: await req("/api/friends"))["friends"]) ?? []
    }
    func setAvatar(_ a: Avatar) async {
        let body: [String:Any] = ["avatar": ["type": a.type, "value": a.value ?? ""]]
        _ = try? await req("/api/profile", method: "PUT", body: body)
    }
    func addFriend(_ u: String) async -> Bool {
        guard let d = try? await req("/api/friends", method: "POST", body: ["username": u]) else { return false }
        return (try? JSONSerialization.jsonObject(with: d)) != nil
    }
    func invite() async -> String {
        guard let d = try? await req("/api/invite", method: "POST"),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String:Any] else { return "" }
        return (o["link"] as? String) ?? ""
    }
    func chatList() async -> [Convo] {
        if AppEnv.demo { return DemoData.convos }
        return (try? dec().decode([String:[Convo]].self, from: await req("/api/chat/list"))["conversations"]) ?? []
    }
    func chatWith(_ other: String) async -> [Message] {
        if AppEnv.demo { return DemoData.thread }
        struct R: Codable { var messages: [Message] }
        return (try? dec().decode(R.self, from: await req("/api/chat/with/" + other)).messages) ?? []
    }
    func send(_ to: String, _ text: String) async {
        _ = try? await req("/api/chat/send", method: "POST", body: ["to": to, "text": text])
    }
    func uploadPhoto(_ jpeg: Data) async -> String? {
        let dataURL = "data:image/jpeg;base64," + jpeg.base64EncodedString()
        guard let d = try? await req("/api/profile/photo", method: "POST", body: ["data": dataURL]),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String:Any] else { return nil }
        return o["url"] as? String
    }
    func trackerInfo() async -> (id: String, url: String)? {
        guard let d = try? await req("/api/tracker"),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
              let id = o["deviceId"] as? String, let url = o["url"] as? String else { return nil }
        return (id, url)
    }
    func setRideType(_ rideId: String, _ type: String) async -> Bool {
        guard let d = try? await req("/api/rides/\(rideId)/type", method: "POST", body: ["type": type]),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String:Any] else { return false }
        return (o["ok"] as? Bool) ?? false
    }
    func setName(_ name: String) async {
        _ = try? await req("/api/profile", method: "PUT", body: ["name": name])
    }
    func generateRide(from: Double, to: Double, type: String, mode: String, aspect: String, premium: Bool, music: String = "") async -> Bool {
        let body: [String:Any] = ["from": from, "to": to, "type": type, "mode": mode,
                                  "aspect": aspect, "premium": premium, "music": music]
        guard let d = try? await req("/api/rides/generate", method: "POST", body: body),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String:Any] else { return false }
        return (o["ok"] as? Bool) ?? false
    }
    func videoURL(_ id: String) -> URL { URL(string: API + "/api/rides/\(id)/video")! }
    var authHeader: [String:String] { ["Authorization": "Bearer " + token] }
}

// İsimden baş harf + tutarlı renk avatarı
func initials(_ name: String) -> String {
    let p = name.split(separator: " ")
    let a = p.first?.first.map(String.init) ?? "?"
    let b = p.count > 1 ? (p.last?.first.map(String.init) ?? "") : ""
    return (a + b).uppercased()
}
func avatarColor(_ name: String) -> Color {
    var h = 0; for c in name.unicodeScalars { h = (h &* 31 &+ Int(c.value)) % 360 }
    return Color(hue: Double(h)/360.0, saturation: 0.5, brightness: 0.55)
}

// MARK: - Demo veri (native ekran görüntüleri)
enum DemoData {
    static var rides: [Ride] {
        let types = ["moto","bike","run","walk","moto","bike"]
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        return types.enumerated().map { i, t in
            let d = Calendar.current.date(byAdding: .day, value: -i*5, to: Date())!
            return Ride(id: "d\(i)", date: df.string(from: d), type: t, mode: "flyover", size: (1.2 + Double(i)*0.9)*1048576)
        }
    }
    static var stats: Stats { Stats(totalRides: 24, byType: ["moto":11,"bike":7,"run":4,"walk":2], latest: rides.first) }
    static func uname(_ s: String) -> String { s.lowercased().replacingOccurrences(of: " ", with: "") }
    static var positions: [Position] {
        let (la, lo): (Double, Double) = Demo.city[currentLang()] ?? Demo.city["en"]!
        let nm = Demo.nm; let sp: [Double] = [0, 32, 0]
        var out: [Position] = []
        for i in 1...3 {
            let lat: Double = la + Double(i - 2) * 0.012
            let lon: Double = lo + Double(i - 2) * 0.014
            out.append(Position(device: nm[i], lat: lat, lon: lon, speedKmh: sp[i - 1], online: i == 2))
        }
        return out
    }
    static var friends: [Friend] {
        let nm = Demo.nm
        var out: [Friend] = []
        for i in 1...3 { out.append(Friend(username: uname(nm[i]), name: nm[i], avatar: Avatar(), online: i == 2)) }
        return out
    }
    static var convos: [Convo] {
        let nm = Demo.nm
        let th = Demo.thread[currentLang()] ?? Demo.thread["en"]!
        let now: Double = Date().timeIntervalSince1970
        var out: [Convo] = []
        for i in 1...3 {
            let txt: String = th[min(i, th.count - 1)]
            let msg = Message(id: "l\(i)", frm: nm[i], text: txt, ts: now - Double(i) * 900, type: "text", media: nil)
            out.append(Convo(username: uname(nm[i]), name: nm[i], avatar: Avatar(), online: i == 2, unread: i == 1 ? 2 : 0, last: msg))
        }
        return out
    }
    static var thread: [Message] {
        let th = Demo.thread[currentLang()] ?? Demo.thread["en"]!
        let other = Demo.nm[1]
        let now: Double = Date().timeIntervalSince1970
        var out: [Message] = []
        for (i, t) in th.enumerated() {
            let frm: String = (i % 2 == 1) ? "me" : other
            let ts: Double = now - Double(th.count - i) * 240
            out.append(Message(id: "m\(i)", frm: frm, text: t, ts: ts, type: "text", media: nil))
        }
        return out
    }
}
