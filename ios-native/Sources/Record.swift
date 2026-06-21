import SwiftUI
import UniformTypeIdentifiers

// Aktivite tipleri (her yerde ortak)
let RIDE_TYPES: [(id: String, icon: String)] = [
    ("moto", "motorcycle"), ("car", "car.fill"), ("bike", "bicycle"),
    ("run", "figure.run"), ("walk", "figure.walk"),
]
func rideLabel(_ t: String) -> String {
    switch t {
    case "moto": return L("Motor","Motorcycle"); case "car": return L("Araba","Car")
    case "bike": return L("Bisiklet","Cycling"); case "run": return L("Koşu","Running")
    case "walk": return L("Yürüyüş","Walking"); default: return L("Diğer","Other")
    }
}

// Gezi bitince video oluşturma: tip (değiştirilebilir) + mod + en-boy (premium gating)
struct GenerateSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    let from: Double
    let to: Double
    @State var type: String
    @AppStorage("nd_premium") var premium = false
    @State private var mode = "3d"
    @State private var aspect = "16:9"
    @State private var sending = false
    @State private var done = false
    @State private var showPaywall = false
    @State private var stock: [[String:String]] = []
    @State private var music = ""               // "", "stock:<id>", "upload"
    @State private var showAudioPicker = false

    var body: some View {
        ZStack {
            AuroraBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(L("Video oluştur","Create video")).font(.title2.bold())

                    field(L("Aktivite","Activity"))
                    Picker("", selection: $type) {
                        ForEach(RIDE_TYPES, id: \.id) { t in
                            Label(rideLabel(t.id), systemImage: t.icon).tag(t.id)
                        }
                    }.pickerStyle(.menu).tint(Brand.accent)

                    field(L("Görünüm","Style"))
                    modeRow("flat", L("Düz","Flat"), free: true)
                    modeRow("3d", L("Flyover · 3B kuş bakışı","Flyover · 3D"), free: false)

                    field(L("En-boy","Aspect"))
                    Picker("", selection: $aspect) {
                        Text("16:9").tag("16:9"); Text("9:16").tag("9:16")
                    }.pickerStyle(.segmented)

                    field(L("Müzik","Music"))
                    Menu {
                        Button(L("Yok","None")) { music = "" }
                        ForEach(stock, id: \.self) { s in
                            Button(s["name"] ?? "") {
                                if premium { music = "stock:\(s["id"] ?? "")" } else { showPaywall = true }
                            }
                        }
                        Button(L("Kendi müziğin… (yükle)","Your own… (upload)")) {
                            if premium { showAudioPicker = true } else { showPaywall = true }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                            Text(musicLabel)
                            if !premium { Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary) }
                            Spacer(); Image(systemName: "chevron.down").font(.caption2)
                        }.padding(.horizontal, 14).padding(.vertical, 12)
                    }.buttonStyle(.plain).glassPanel(14).tint(.primary)

                    if !premium {
                        Text(L("Ücretsiz: 720p + filigran (Düz mod). Premium: 1080p, filigransız, Flyover/3B, müzik.",
                               "Free: 720p + watermark (Flat). Premium: 1080p, no watermark, Flyover/3D, music."))
                            .font(.caption2).foregroundStyle(.secondary)
                    }

                    Button {
                        let useMode = (premium ? mode : "flat")
                        sending = true
                        Task {
                            let ok = await store.generateRide(from: from, to: to, type: type,
                                                              mode: useMode, aspect: aspect, premium: premium,
                                                              music: premium ? music : "")
                            sending = false; done = ok
                            if ok { try? await Task.sleep(for: .seconds(1)); dismiss() }
                        }
                    } label: {
                        if sending { ProgressView() }
                        else if done { Label(L("Hazırlanıyor…","Preparing…"), systemImage: "checkmark") }
                        else { Text(L("Video oluştur","Create video")) }
                    }.buttonStyle(.glassyProminent()).disabled(sending)

                    Text(L("Video hazırlanınca Rotalar sekmesinde görünür.","Your video will appear in Routes when ready."))
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(24)
            }
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showPaywall) { PaywallSheet(premium: $premium) }
        .task { stock = await store.musicList() }
        .fileImporter(isPresented: $showAudioPicker, allowedContentTypes: [.audio]) { res in
            if case .success(let url) = res {
                Task {
                    let ok = url.startAccessingSecurityScopedResource()
                    defer { if ok { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url), data.count < 12_000_000 {
                        await store.addRideMusic(session: from, data: data)
                        music = "upload"
                    }
                }
            }
        }
    }

    var musicLabel: String {
        if music == "upload" { return L("Kendi müziğin","Your music") }
        if music.hasPrefix("stock:") {
            let id = String(music.dropFirst(6))
            return stock.first { $0["id"] == id }?["name"] ?? id
        }
        return L("Yok","None")
    }

    func field(_ t: String) -> some View {
        Text(t.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
    }
    func modeRow(_ id: String, _ label: String, free: Bool) -> some View {
        Button {
            if free || premium { mode = id } else { showPaywall = true }
        } label: {
            HStack {
                Text(label)
                if !free && !premium { Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary) }
                Spacer()
                if mode == id { Image(systemName: "checkmark").foregroundStyle(Brand.accent) }
            }.padding(.horizontal, 14).padding(.vertical, 12)
        }.buttonStyle(.plain).glassPanel(14)
    }
}
