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
    var loggedIn: Bool { !token.isEmpty }

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
    func logout() { token = ""; UserDefaults.standard.removeObject(forKey: "nd_token") }

    func rides() async -> [Ride] {
        (try? dec().decode([String:[Ride]].self, from: await req("/api/rides"))["rides"]) ?? []
    }
    func stats() async -> Stats? { try? dec().decode(Stats.self, from: await req("/api/stats")) }
    func positions() async -> [Position] {
        (try? dec().decode([String:[Position]].self, from: await req("/api/gps/live"))["positions"]) ?? []
    }
    func profile() async -> Profile? { try? dec().decode(Profile.self, from: await req("/api/profile")) }
    func friends() async -> [Friend] {
        (try? dec().decode([String:[Friend]].self, from: await req("/api/friends"))["friends"]) ?? []
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
        (try? dec().decode([String:[Convo]].self, from: await req("/api/chat/list"))["conversations"]) ?? []
    }
    func chatWith(_ other: String) async -> [Message] {
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
