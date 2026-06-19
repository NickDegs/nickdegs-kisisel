import SwiftUI
import PhotosUI
import UIKit

let EMOJIS = ["🙂","😎","🧑","👩","🧔","🦊","🦁","🐯","🦅","🏍️","🚲","🏃","🏔️","🌊","⚡️","🔥","⭐️","🎯"]

struct FontChoice: Identifiable, Hashable {
    var id: String; var label: String; var design: Font.Design; var free: Bool
}
let FONT_CHOICES: [FontChoice] = [
    .init(id: "default", label: L("Varsayılan","Default"), design: .default, free: true),
    .init(id: "serif", label: "Editorial", design: .serif, free: false),
    .init(id: "rounded", label: "Rounded", design: .rounded, free: false),
    .init(id: "mono", label: "Mono", design: .monospaced, free: false),
]

struct ProfileView: View {
    @EnvironmentObject var store: Store
    @AppStorage("nd_font") var fontId = "default"
    @AppStorage("nd_scheme") var scheme = "dark"
    @AppStorage("nd_premium") var premium = false
    @State private var prof: Profile?
    @State private var friends: [Friend] = []
    @State private var stats: Stats?
    @State private var showAvatar = false
    @State private var showAddFriend = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        // künye
                        VStack(spacing: 8) {
                            Button { showAvatar = true } label: {
                                AvatarView(name: prof?.name ?? store.me, avatar: prof?.avatar, size: 96)
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "pencil").font(.caption.bold()).foregroundStyle(.white)
                                            .frame(width: 30, height: 30).background(Brand.accent, in: Circle())
                                            .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: 2))
                                    }
                            }
                            Text(prof?.name ?? store.me).font(.system(size: 25, weight: .bold))
                            Text(L("Move Log üyesi","Move Log member")).font(.caption).foregroundStyle(.secondary)
                        }.padding(.top, 8)

                        HStack(spacing: 12) {
                            stat("\(stats?.totalRides ?? 0)", L("Rota","Routes"))
                            stat("\(friends.count)", L("Arkadaş","Friends"))
                        }

                        section(L("Arkadaşlar","Friends"))
                        ForEach(friends) { f in
                            HStack(spacing: 12) {
                                AvatarView(name: f.name ?? f.username, avatar: f.avatar, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.name ?? f.username).font(.system(size: 16, weight: .semibold))
                                    Text("@\(f.username)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }.padding(12).glassPanel(18).smoothAppear()
                        }
                        Button { showAddFriend = true } label: {
                            Label(L("Arkadaş ekle","Add friend"), systemImage: "person.badge.plus")
                        }.buttonStyle(.glassy)

                        section(L("Tipografi","Typography"))
                        ForEach(FONT_CHOICES) { f in
                            Button {
                                if f.free || premium { fontId = f.id } else { showPaywall = true }
                            } label: {
                                HStack {
                                    Text(f.label).fontDesign(f.design)
                                    Spacer()
                                    if fontId == f.id { Image(systemName: "checkmark").foregroundStyle(Brand.accent) }
                                    else if !f.free && !premium { Image(systemName: "lock.fill").foregroundStyle(.secondary) }
                                }.padding(.horizontal, 16).padding(.vertical, 14)
                            }.buttonStyle(.plain).glassPanel(16).smoothAppear()
                            .animation(.snappy(duration: 0.3), value: fontId)
                        }

                        section(L("Görünüm","Appearance"))
                        Picker("", selection: $scheme) {
                            Text(L("Açık","Light")).tag("light")
                            Text(L("Koyu","Dark")).tag("dark")
                        }.pickerStyle(.segmented)

                        Button(L("Çıkış","Sign out")) { store.logout() }
                            .buttonStyle(.glassy).padding(.top, 8).tint(.red)
                    }.padding(16)
                }
            }
            .navigationTitle(L("Profil","Profile"))
        }
        .task {
            prof = await store.profile(); friends = await store.friends(); stats = await store.stats()
            if AppEnv.demo {
                try? await Task.sleep(for: .milliseconds(450))
                if AppEnv.screen == "paywall" { showPaywall = true }
                if AppEnv.screen == "avatar" { showAvatar = true }
            }
        }
        .sheet(isPresented: $showAvatar) { AvatarSheet(onDone: { Task { prof = await store.profile() } }) }
        .sheet(isPresented: $showAddFriend) { AddFriendSheet(onDone: { Task { friends = await store.friends() } }) }
        .sheet(isPresented: $showPaywall) { PaywallSheet(premium: $premium) }
    }

    func stat(_ v: String, _ k: String) -> some View {
        VStack(spacing: 4) {
            Text(v).font(.system(size: 27, weight: .bold)).foregroundStyle(Brand.gradient)
            Text(k).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 16).glassPanel(20)
    }
    func section(_ t: String) -> some View {
        Text(t.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
    }
}

struct AvatarSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    var onDone: () -> Void
    @State private var photoItem: PhotosPickerItem?
    @State private var uploading = false

    var body: some View {
        ZStack {
            AuroraBackground()
            ScrollView {
                VStack(spacing: 18) {
                    Text(L("Profil resmi","Profile picture")).font(.title2.bold())

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        if uploading { ProgressView() }
                        else { Label(L("Fotoğraf seç","Choose photo"), systemImage: "photo.on.rectangle") }
                    }.buttonStyle(.glassyProminent()).disabled(uploading)

                    Text(L("VEYA EMOJİ SEÇ","OR PICK AN EMOJI")).font(.caption).foregroundStyle(.secondary).padding(.top, 4)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(EMOJIS, id: \.self) { e in
                            Button(e) {
                                Task { await store.setAvatar(Avatar(type: "emoji", value: e)); onDone(); dismiss() }
                            }.font(.system(size: 30)).frame(width: 46, height: 46).glassPanel(14)
                        }
                    }
                }.padding(24)
            }
        }
        .presentationDetents([.medium, .large])
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            uploading = true
            Task {
                defer { uploading = false }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let img = UIImage(data: data),
                      let jpeg = img.scaled(maxDim: 512).jpegData(compressionQuality: 0.8) else { return }
                _ = await store.uploadPhoto(jpeg)
                onDone(); dismiss()
            }
        }
    }
}

extension UIImage {
    // Yükleme öncesi küçült (backend 3MB sınırı + hız)
    func scaled(maxDim: CGFloat) -> UIImage {
        let f = min(maxDim / size.width, maxDim / size.height, 1)
        if f >= 1 { return self }
        let sz = CGSize(width: size.width * f, height: size.height * f)
        return UIGraphicsImageRenderer(size: sz).image { _ in draw(in: CGRect(origin: .zero, size: sz)) }
    }
}

struct AddFriendSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    var onDone: () -> Void
    @State private var uname = ""; @State private var link = ""; @State private var err = false
    var body: some View {
        ZStack {
            AuroraBackground()
            VStack(alignment: .leading, spacing: 16) {
                Text(L("Arkadaş ekle","Add friend")).font(.title2.bold())
                Text(L("KULLANICI ADIYLA","BY USERNAME")).font(.caption).foregroundStyle(.secondary)
                HStack {
                    TextField("@" + L("kullanıcı","username"), text: $uname)
                        .textInputAutocapitalization(.never).padding(12).glassPanel(14)
                    Button(L("Ekle","Add")) {
                        Task { if await store.addFriend(uname.trimmingCharacters(in: CharacterSet(charactersIn: " @"))) { onDone(); dismiss() } else { err = true } }
                    }.buttonStyle(.glassy).fixedSize()
                }
                if err { Text(L("Kullanıcı bulunamadı","User not found")).font(.footnote).foregroundStyle(.red) }
                Divider().padding(.vertical, 8)
                Text(L("DAVET BAĞLANTISI","INVITE LINK")).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text(link.isEmpty ? "…" : link).font(.footnote).lineLimit(1).padding(12).glassPanel(14)
                    ShareLink(item: link) { Image(systemName: "square.and.arrow.up") }.disabled(link.isEmpty)
                }
                Spacer()
            }.padding(24)
        }
        .task { link = await store.invite() }
        .presentationDetents([.medium])
    }
}

struct PaywallSheet: View {
    @Binding var premium: Bool
    @EnvironmentObject var iap: IAP
    @Environment(\.dismiss) var dismiss
    @State private var failed = false

    var body: some View {
        ZStack {
            AuroraBackground()
            ScrollView {
                VStack(spacing: 14) {
                    Image(systemName: "star.fill").font(.system(size: 32)).foregroundStyle(Brand.gradient)
                        .frame(width: 62, height: 62).glassPanel(31)
                    Text("Move Log PREMIUM").font(.title2.bold())
                    Text(L("Tüm premium yazı tiplerini aç.","Unlock all premium fonts."))
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)

                    // Yıllık — öne çıkan (en avantajlı)
                    if let y = iap.yearly {
                        planButton(y, period: L("yıl","yr"), badge: L("EN AVANTAJLI","BEST VALUE"))
                    }
                    // Aylık
                    if let m = iap.monthly {
                        planButton(m, period: L("ay","mo"), badge: nil)
                    }
                    if iap.monthly == nil && iap.yearly == nil {
                        ProgressView().padding(.vertical, 8)
                    }

                    Button(L("Satın alımları geri yükle","Restore purchases")) {
                        Task { await iap.restore(); premium = iap.purchased; if iap.purchased { dismiss() } }
                    }.font(.footnote).foregroundStyle(.secondary).padding(.top, 2)

                    if failed { Text(L("Satın alma tamamlanmadı.","Purchase didn’t complete."))
                        .font(.footnote).foregroundStyle(.red) }

                    // App Store kuralı: oto-yenileme açıklaması + Şartlar/Gizlilik linkleri
                    Text(L("Abonelik otomatik yenilenir; dönem sonundan en az 24 saat önce iptal etmezsen ücretlendirilirsin. Ayarlar’dan istediğin zaman iptal edebilirsin.",
                           "Subscription auto-renews unless canceled at least 24h before the period ends. Manage or cancel anytime in Settings."))
                        .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.top, 6)
                    HStack(spacing: 18) {
                        Link(L("Kullanım Şartları","Terms of Use"), destination: URL(string: "https://app.nickdegs.com/terms.html")!)
                        Link(L("Gizlilik","Privacy"), destination: URL(string: "https://app.nickdegs.com/privacy.html")!)
                    }.font(.caption2).tint(Brand.accent)

                    Button(L("Belki sonra","Maybe later")) { dismiss() }.foregroundStyle(.secondary).padding(.top, 2)
                }.padding(26)
            }
        }
        .presentationDetents([.large])
        .onAppear { if iap.monthly == nil && iap.yearly == nil { Task { await iap.load() } } }
    }

    func planButton(_ p: Product, period: String, badge: String?) -> some View {
        Button {
            Task { let ok = await iap.buy(p); premium = iap.purchased; if ok { dismiss() } else { failed = true } }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.displayName).font(.system(size: 16, weight: .semibold))
                    Text("\(p.displayPrice) / \(period)").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if iap.working { ProgressView() }
                else if let badge {
                    Text(badge).font(.caption2.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 5).background(Brand.gradient, in: Capsule())
                }
            }.frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain).padding(16).glassPanel(20).disabled(iap.working)
    }
}
