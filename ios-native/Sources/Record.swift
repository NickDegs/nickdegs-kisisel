import SwiftUI
import UniformTypeIdentifiers
import Photos

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
    let rideId: String?                         // nil = yeni üretim, dolu = mevcut videoyu düzenle
    @State var type: String
    @AppStorage("nd_premium") var premium = false
    @State private var mode: String
    @State private var aspect: String
    @State private var speed: String            // "fast"=Kısa / "medium"=Orta / "slow"=Uzun
    @State private var sending = false
    @State private var done = false
    @State private var renderPct: Double = 0
    @State private var localErr = false
    @State private var showPaywall = false
    @State private var stock: [[String:String]] = []
    @State private var music = ""               // "", "stock:<id>", "upload"
    @State private var showAudioPicker = false
    @AppStorage("nd_line_color") private var lineColor = "#00E5FF"   // kullanıcının seçtiği rota çizgi rengi

    init(from: Double, to: Double, type: String, mode: String = "flat",
         aspect: String = "16:9", speed: String = "medium", rideId: String? = nil) {
        self.from = from; self.to = to; self.rideId = rideId
        _type = State(initialValue: type)
        _mode = State(initialValue: mode)
        _aspect = State(initialValue: aspect)
        _speed = State(initialValue: speed)
    }

    var body: some View {
        ZStack {
            AuroraBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(rideId == nil ? L("Video oluştur","Create video")
                                       : L("Videoyu düzenle","Edit video")).font(.title2.bold())

                    field(L("Aktivite","Activity"))
                    Picker("", selection: $type) {
                        ForEach(RIDE_TYPES, id: \.id) { t in
                            Label(rideLabel(t.id), systemImage: t.icon).tag(t.id)
                        }
                    }.pickerStyle(.menu).tint(Brand.accent)

                    field(L("Süre","Length"))
                    Picker("", selection: $speed) {
                        Text(L("Kısa","Short")).tag("fast")
                        Text(L("Orta","Medium")).tag("medium")
                        Text(L("Uzun","Long")).tag("slow")
                    }.pickerStyle(.segmented)
                    Text(L("Kısa ≈15sn, Orta ≈40sn, Uzun ≈60sn (rota uzunluğuna göre).",
                           "Short ≈15s, Medium ≈40s, Long ≈60s (scales with route length)."))
                        .font(.caption2).foregroundStyle(.secondary)

                    field(L("Görünüm","Style"))
                    modeRow("flat", L("Düz","Flat"), free: true)
                    modeRow("flyover", L("Kuş bakışı (Flyover)","Bird's-eye (Flyover)"), free: false)
                    modeRow("3d", L("3D · arazi kabartmalı","3D · terrain relief"), free: false)

                    field(L("En-boy","Aspect"))
                    Picker("", selection: $aspect) {
                        Text("16:9").tag("16:9"); Text("9:16").tag("9:16")
                    }.pickerStyle(.segmented)

                    field(L("Rota rengi","Route color"))
                    HStack(spacing: 12) {
                        ForEach(["#00E5FF","#FF3B30","#39FF14","#FFD60A","#FF7AB6","#FFFFFF","#7C4DFF","#FF8C00"], id: \.self) { hex in
                            Circle().fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1))
                                .overlay(Circle().strokeBorder(.white, lineWidth: lineColor.caseInsensitiveCompare(hex) == .orderedSame ? 3 : 0))
                                .onTapGesture { lineColor = hex }
                        }
                        Spacer()
                    }

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
                        Text(L("Rota kaydı ücretsiz. Videoya dökmek Premium: 1080p, filigransız, Flyover/3B, müzik.",
                               "Route tracking is free. Turning it into a video is Premium: 1080p, no watermark, Flyover/3D, music."))
                            .font(.caption2).foregroundStyle(.secondary)
                    }

                    Button {
                        // Kural: algılama free, videoya dökme premium.
                        if !premium { showPaywall = true; return }
                        sending = true; localErr = false
                        Task {
                            // BULUT render: sunucuya istek bırak -> Cloud Run render eder -> R2 -> bitince bildirim.
                            // Telefon yorulmaz, uygulama kapatılabilir (sıfır cihaz yükü).
                            let ok = rideId == nil
                                ? await store.generateRide(from: from, to: to, type: type, mode: mode,
                                                           aspect: aspect, premium: premium, speed: speed, music: music, line: lineColor)
                                : await store.regenerateRide(rideId!, type: type, mode: mode,
                                                             aspect: aspect, premium: premium, speed: speed, music: music, line: lineColor)
                            sending = false; done = ok; localErr = !ok
                            if ok { try? await Task.sleep(for: .seconds(1.8)); dismiss() }
                        }
                    } label: {
                        if sending { HStack(spacing: 8) { ProgressView()
                            Text(L("Kuyruğa alınıyor…", "Queuing…")) } }
                        else if done { Label(L("Bulutta hazırlanıyor 🎬","Rendering in cloud"), systemImage: "checkmark.icloud") }
                        else { Text(rideId == nil ? L("Video oluştur","Create video")
                                                  : L("Yeniden oluştur","Regenerate")) }
                    }.buttonStyle(.glassyProminent()).disabled(sending)

                    if localErr {
                        Text(L("Bu rotada konum verisi yok ya da istek başarısız.","No location data for this route or request failed."))
                            .font(.caption2).foregroundStyle(.red)
                    }
                    if done {
                        Text(L("Videon bulutta hazırlanıyor. Hazır olunca bildirim gelir; Rotalar ve Özet'te görünür.",
                               "Your video is rendering in the cloud. You'll get a notification; it shows up in Routes and Summary."))
                            .font(.caption2).foregroundStyle(Brand.accent)
                    }
                    Text(L("Video bulut sunucularında oluşturulur — telefonun yorulmaz, uygulamayı kapatabilirsin.",
                           "Rendered on our cloud servers — your phone stays free; you can close the app."))
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(24)
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(sending)   // render sırasında sheet kapatılamaz
        .sheet(isPresented: $showPaywall) { PaywallSheet(premium: $premium) }
        .task { await store.syncPremium(); stock = await store.musicList() }
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

    // Render edilen videoyu galeriye kaydet
    func saveToPhotos(_ url: URL) async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return false }
        return await withCheckedContinuation { cont in
            PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { ok, _ in cont.resume(returning: ok) }
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
        // Button + interaktif glassEffect dokunuşu yutuyordu → doğrudan tap-gesture + contentShape.
        HStack {
            Text(label)
            if !free && !premium { Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary) }
            Spacer()
            if mode == id { Image(systemName: "checkmark").foregroundStyle(Brand.accent) }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(14)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture { if free || premium { mode = id } else { showPaywall = true } }
    }
}
