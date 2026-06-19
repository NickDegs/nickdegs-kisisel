import SwiftUI
import AVKit

struct RoutesView: View {
    @EnvironmentObject var store: Store
    @State private var rides: [Ride] = []
    @State private var player: AVPlayer?
    @State private var showPlayer = false

    func typeLabel(_ t: String?) -> String {
        switch t { case "moto": return L("Motosiklet","Motorcycle"); case "bike": return L("Bisiklet","Cycling")
        case "run": return L("Koşu","Running"); case "walk": return L("Yürüyüş","Walking"); default: return L("Diğer","Other") }
    }
    func typeIcon(_ t: String?) -> String {
        switch t { case "moto": return "figure.outdoor.cycle"; case "bike": return "bicycle"
        case "run": return "figure.run"; case "walk": return "figure.walk"; default: return "clock" }
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
                                    Label(typeLabel(r.type), systemImage: "play.circle.fill")
                                        .font(.caption).foregroundStyle(.secondary).labelStyle(.titleAndIcon)
                                }
                                Spacer()
                                Button(L("İzle","Play")) { play(r) }.buttonStyle(.glassy).fixedSize()
                            }
                            .padding(14).glassPanel(20).smoothAppear()
                        }
                    }.padding(16)
                }
            }
            .navigationTitle("Move Log")
        }
        .task { rides = await store.rides() }
        .sheet(isPresented: $showPlayer) {
            if let player { VideoPlayer(player: player).ignoresSafeArea().onDisappear { player.pause() } }
        }
    }

    func play(_ r: Ride) {
        let asset = AVURLAsset(url: store.videoURL(r.id), options: ["AVURLAssetHTTPHeaderFieldsKey": store.authHeader])
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        showPlayer = true
        player?.play()
    }
}
