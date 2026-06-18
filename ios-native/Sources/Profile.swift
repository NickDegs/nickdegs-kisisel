import SwiftUI
import PhotosUI

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
        .task { prof = await store.profile(); friends = await store.friends(); stats = await store.stats() }
        .confirmationDialog(L("Profil resmi","Profile picture"), isPresented: $showAvatar, titleVisibility: .visible) {
            // emoji seçenekleri
            ForEach(EMOJIS.prefix(8), id: \.self) { e in
                Button(e) { Task { await store.setAvatar(Avatar(type: "emoji", value: e)); prof = await store.profile() } }
            }
        }
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
            VStack(spacing: 16) {
                Image(systemName: "star.fill").font(.system(size: 34)).foregroundStyle(Brand.gradient)
                    .frame(width: 64, height: 64).glassPanel(32)
                Text("Move Log PREMIUM").font(.title2.bold())
                Text(L("Sevdiğin yazı tipini seç. Tek seferlik satın alma.","Choose the typeface you love. One-time purchase."))
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)

                Button {
                    Task {
                        let ok = await iap.buy()
                        premium = iap.purchased
                        if ok { dismiss() } else { failed = true }
                    }
                } label: {
                    if iap.working { ProgressView() }
                    else { Text(iap.priceText.isEmpty ? L("Premium'u Aç","Unlock Premium")
                                : L("Premium'u Aç","Unlock Premium") + " · " + iap.priceText) }
                }
                .buttonStyle(.glassyProminent()).disabled(iap.working || iap.product == nil)

                Button(L("Satın alımları geri yükle","Restore purchases")) {
                    Task { await iap.restore(); premium = iap.purchased; if iap.purchased { dismiss() } }
                }.font(.footnote).foregroundStyle(.secondary)

                if failed { Text(L("Satın alma tamamlanmadı.","Purchase didn’t complete."))
                    .font(.footnote).foregroundStyle(.red) }
                Button(L("Belki sonra","Maybe later")) { dismiss() }.foregroundStyle(.secondary)
            }.padding(28)
        }
        .presentationDetents([.medium])
        .onAppear { if iap.product == nil { Task { await iap.load() } } }
    }
}
