import SwiftUI
import AVKit
import UIKit

// .sheet(item:) için: player hazır olmadan sheet açılmasın (ilk dokunuşta kara ekran bug'ı).
struct PlayerBox: Identifiable { let id = UUID(); let player: AVPlayer }

struct RoutesView: View {
    @EnvironmentObject var store: Store
    @State private var rides: [Ride] = []
    @State private var playerBox: PlayerBox?
    @State private var editRide: Ride?
    @State private var savingId: String? = nil
    @State private var savedId: String? = nil

    func typeLabel(_ t: String?) -> String {
        switch t { case "moto": return L("Motosiklet","Motorcycle"); case "bike": return L("Bisiklet","Cycling")
        case "run": return L("Koşu","Running"); case "walk": return L("Yürüyüş","Walking"); default: return L("Diğer","Other") }
    }
    func typeIcon(_ t: String?) -> String {
        switch t { case "moto": return "motorcycle"; case "bike": return "bicycle"
        case "run": return "figure.run"; case "walk": return "figure.walk"; default: return "point.topleft.down.curvedto.point.bottomright.up" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(rides) { r in
                            HStack(spacing: 14) {
                                Image(systemName: typeIcon(r.type)).font(.system(size: 22))
                                    .foregroundStyle(Brand.accent).frame(width: 50, height: 50).glassPanel(16)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(r.date).font(.system(size: 17, weight: .semibold))
                                    Menu {
                                        ForEach(RIDE_TYPES, id: \.id) { t in
                                            Button {
                                                Task { if await store.setRideType(r.id, t.id) { rides = await store.rides() } }
                                            } label: { Label(rideLabel(t.id), systemImage: t.icon) }
                                        }
                                    } label: {
                                        HStack(spacing: 3) {
                                            Text(typeLabel(r.type))
                                            Image(systemName: "chevron.down").font(.system(size: 9))
                                        }.font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                // İzle
                                Button { play(r) } label: {
                                    Image(systemName: "play.fill").font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white).frame(width: 42, height: 42)
                                        .background(Brand.gradient, in: Circle())
                                }.buttonStyle(.plain)
                                // Düzenle (süre/görünüm/en-boy/müzik ile yeniden oluştur)
                                Button { editRide = r } label: {
                                    Image(systemName: "slider.horizontal.3").font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Brand.accent).frame(width: 42, height: 42).glassPanel(21)
                                }.buttonStyle(.plain)
                                // Kaydet (videoyu galeriye indir)
                                Button { save(r) } label: {
                                    Group {
                                        if savingId == r.id { ProgressView() }
                                        else if savedId == r.id { Image(systemName: "checkmark").foregroundStyle(.green) }
                                        else { Image(systemName: "square.and.arrow.down").foregroundStyle(Brand.accent) }
                                    }.font(.system(size: 16, weight: .semibold)).frame(width: 42, height: 42).glassPanel(21)
                                }.buttonStyle(.plain).disabled(savingId == r.id)
                            }
                            .padding(14).glassPanel(20).smoothAppear()
                        }
                    }.padding(16)
                }
            }
            .navigationTitle("Move Log")
        }
        .task { rides = await store.rides() }
        .sheet(item: $playerBox) { box in
            VideoPlayer(player: box.player)
                .ignoresSafeArea()
                .onAppear { box.player.play() }              // view hazır olunca oynat (kara kare olmaz)
                .onDisappear { box.player.pause() }
        }
        .sheet(item: $editRide) { r in
            GenerateSheet(from: r.ts ?? 0, to: r.to ?? 0, type: r.type ?? "moto",
                          mode: r.mode ?? "flat", aspect: r.aspect ?? "16:9",
                          speed: r.speed ?? "medium", rideId: r.id)
        }
    }

    func play(_ r: Ride) {
        let asset = AVURLAsset(url: store.videoURL(r.id), options: ["AVURLAssetHTTPHeaderFieldsKey": store.authHeader])
        let p = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        playerBox = PlayerBox(player: p)   // sheet(item:) ile player garanti hazır
    }

    func save(_ r: Ride) {
        savingId = r.id
        Task {
            defer { savingId = nil }
            var req = URLRequest(url: store.videoURL(r.id))
            for (k, v) in store.authHeader { req.setValue(v, forHTTPHeaderField: k) }
            guard let (data, _) = try? await URLSession.shared.data(for: req) else { return }
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("\(r.id).mp4")
            try? data.write(to: tmp)
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tmp.path) {
                UISaveVideoAtPathToSavedPhotosAlbum(tmp.path, nil, nil, nil)
            }
            savedId = r.id
            try? await Task.sleep(for: .seconds(2))
            if savedId == r.id { savedId = nil }
        }
    }
}
