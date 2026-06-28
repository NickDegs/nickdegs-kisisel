import SwiftUI

@main
struct MoveLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = Store()
    @StateObject private var iap = IAP()
    @StateObject private var cloud = CloudSync()
    @StateObject private var tracker = Tracker.shared
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
    @EnvironmentObject var tracker: Tracker
    @State private var sel = RootView.initialTab()
    @State private var ann: Announcement?
    @AppStorage("nd_ann_seen") private var annSeen = 0
    static func initialTab() -> Int {
        switch AppEnv.screen { case "videos": return 1; case "chat": return 2; case "gps","map": return 3; case "stats": return 4; case "profile","paywall","avatar": return 5; default: return 0 }
    }
    var body: some View {
        TabView(selection: $sel) {
            RoutesView().tabItem { Label(L("Rotalar","Routes"), systemImage: "map") }.tag(0)
            VideosView().tabItem { Label(L("Videolarım","My Videos"), systemImage: "film.stack") }.tag(1)
            ChatListView().tabItem { Label(L("Sohbet","Chat"), systemImage: "bubble.left.and.bubble.right") }.tag(2)
            MapTab().tabItem { Label(L("Harita","Map"), systemImage: "location") }.tag(3)
            SummariesView().tabItem { Label(L("Özet","Summary"), systemImage: "doc.text.magnifyingglass") }.tag(4)
            ProfileView().tabItem { Label(L("Profil","Profile"), systemImage: "person.crop.circle") }.tag(5)
        }
        // iOS 26'da TabView otomatik Liquid Glass tab bar kullanır.
        .safeAreaInset(edge: .top) {
            if let a = ann, a.ts > annSeen {
                AnnouncementBanner(a: a) { annSeen = a.ts; withAnimation { ann = nil } }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task {
            if store.me.isEmpty { let p = await store.profile(); store.me = p?.username ?? "" }
            await store.syncPremium()                 // premium'u açılışta cihaza yansıt (kilitler kalksın)
            await store.registerPush()
            // Oto-takip açıksa her açılışta GPS göndermeyi yeniden başlat (relaunch'ta sessizce
            // durmasın diye). start() idempotent: zaten çalışıyorsa zarar vermez.
            if tracker.active, let t = await store.trackerInfo() { tracker.start(deviceId: t.id, url: t.url) }
            if let a = await store.announcement(), a.ts > annSeen { withAnimation { ann = a } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ndApns)) { _ in
            Task { await store.registerPush() }
        }
    }
}

// Admin panelinden gelen uygulama içi duyuru banner'ı
struct AnnouncementBanner: View {
    let a: Announcement
    var onClose: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "megaphone.fill").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(a.title).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                if !a.body.isEmpty {
                    Text(a.body).font(.caption).foregroundStyle(.white.opacity(0.92)).fixedSize(horizontal: false, vertical: true)
                }
                if !a.url.isEmpty, let u = URL(string: a.url) {
                    Link(L("Detay","Details"), destination: u).font(.caption.bold()).tint(.white).padding(.top, 2)
                }
            }
            Spacer(minLength: 4)
            Button(action: onClose) { Image(systemName: "xmark").font(.caption.bold()).foregroundStyle(.white.opacity(0.85)) }
        }
        .padding(14)
        .background(Brand.gradient, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.2)))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        .padding(.horizontal, 12).padding(.top, 6)
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
