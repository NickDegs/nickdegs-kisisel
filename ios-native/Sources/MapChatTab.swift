import SwiftUI

// "Harita" sekmesi: Canlı konum (Harita) + Sohbet TEK sekmede, üstte segment geçişiyle.
// Böylece sekme sayısı 5'te kalır ve iOS'un çirkin "More" taşma menüsü oluşmaz.
struct MapChatTab: View {
    @AppStorage("nd_mapchat_seg") private var seg = 0   // 0 = Harita (canlı konum), 1 = Sohbet
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $seg) {
                Text(L("Harita", "Map")).tag(0)
                Text(L("Sohbet", "Chat")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
            if seg == 0 {
                MapTab()
            } else {
                ChatListView()
            }
        }
    }
}
