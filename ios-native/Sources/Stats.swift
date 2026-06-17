import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: Store
    @State private var stats: Stats?

    func label(_ k: String) -> String {
        switch k { case "moto": return L("Motosiklet","Motorcycle"); case "bike": return L("Bisiklet","Cycling")
        case "run": return L("Koşu","Running"); case "walk": return L("Yürüyüş","Walking")
        case "diğer","other": return L("Diğer","Other"); default: return k }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        row(L("Toplam rota","Total routes"), "\(stats?.totalRides ?? 0)")
                        if let bt = stats?.byType {
                            ForEach(bt.sorted(by: { $0.value > $1.value }), id: \.key) { k, v in
                                row(label(k), "\(v)")
                            }
                        }
                        if let l = stats?.latest { row(L("Son rota","Latest route"), l.date) }
                    }.padding(16)
                }
            }
            .navigationTitle(L("İstatistik","Stats"))
        }
        .task { stats = await store.stats() }
    }
    func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).font(.system(size: 22, weight: .bold)).foregroundStyle(Brand.gradient)
        }
        .padding(.horizontal, 20).padding(.vertical, 16).glassPanel(18).smoothAppear()
    }
}
