import SwiftUI

@main
struct MoveLogApp: App {
    @StateObject private var store = Store()
    @StateObject private var iap = IAP()
    @StateObject private var cloud = CloudSync()
    @StateObject private var tracker = Tracker()
    @AppStorage("nd_font") var fontId = "default"
    @AppStorage("nd_scheme") var scheme = "dark"
    var design: Font.Design {
        switch fontId { case "serif": return .serif; case "rounded": return .rounded; case "mono": return .monospaced; default: return .default }
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if store.loggedIn { RootView() } else { LoginView() }
            }
            .environmentObject(store)
            .environmentObject(iap)
            .environmentObject(cloud)
            .environmentObject(tracker)
            .tint(Brand.accent)
            .fontDesign(design)
            .preferredColorScheme(scheme == "light" ? .light : .dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var sel = RootView.initialTab()
    static func initialTab() -> Int {
        switch AppEnv.screen { case "chat": return 1; case "gps","map": return 2; case "stats": return 3; case "profile","paywall","avatar": return 4; default: return 0 }
    }
    var body: some View {
        TabView(selection: $sel) {
            RoutesView().tabItem { Label(L("Rotalar","Routes"), systemImage: "map") }.tag(0)
            ChatListView().tabItem { Label(L("Sohbet","Chat"), systemImage: "bubble.left.and.bubble.right") }.tag(1)
            MapTab().tabItem { Label(L("Harita","Map"), systemImage: "location") }.tag(2)
            StatsView().tabItem { Label(L("İstatistik","Stats"), systemImage: "chart.bar") }.tag(3)
            ProfileView().tabItem { Label(L("Profil","Profile"), systemImage: "person.crop.circle") }.tag(4)
        }
        // iOS 26'da TabView otomatik Liquid Glass tab bar kullanır.
        .task { if store.me.isEmpty { let p = await store.profile(); store.me = p?.username ?? "" } }
    }
}

// Yeniden kullanılabilir avatar (emoji / foto / baş harf)
struct AvatarView: View {
    var name: String
    var avatar: Avatar?
    var size: CGFloat = 46
    @EnvironmentObject var store: Store
    var body: some View {
        let a = avatar ?? Avatar()
        Group {
            if a.type == "emoji", let v = a.value, !v.isEmpty {
                Text(v).font(.system(size: size * 0.6))
                    .frame(width: size, height: size).background(.ultraThinMaterial, in: Circle())
            } else if a.type == "photo", let v = a.value, let url = URL(string: v.hasPrefix("http") ? v : API + v) {
                AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.3) }
                    .frame(width: size, height: size).clipShape(Circle())
            } else {
                Text(initials(name)).font(.system(size: size * 0.4, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: size, height: size).background(avatarColor(name), in: Circle())
            }
        }
        .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
    }
}

// Cam başlık şeridi (ekran üstü)
struct ScreenTitle: View {
    var text: String
    var body: some View {
        Text(text).font(.system(size: 32, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 6)
    }
}
