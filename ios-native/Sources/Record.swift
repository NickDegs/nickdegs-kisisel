import SwiftUI

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
    @State private var mode = "flyover"
    @State private var aspect = "16:9"
    @State private var sending = false
    @State private var done = false
    @State private var showPaywall = false

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
                    modeRow("flyover", L("Kuş bakışı (Flyover)","Flyover"), free: false)
                    modeRow("3d", L("3B Takip","3D"), free: false)

                    field(L("En-boy","Aspect"))
                    Picker("", selection: $aspect) {
                        Text("16:9").tag("16:9"); Text("9:16").tag("9:16")
                    }.pickerStyle(.segmented)

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
                                                              mode: useMode, aspect: aspect, premium: premium)
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
