import SwiftUI
import MapKit

struct MapTab: View {
    @EnvironmentObject var store: Store
    @State private var positions: [Position] = []
    @State private var cam: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
        span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)))

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cam) {
                    ForEach(positions) { p in
                        Annotation(p.device, coordinate: CLLocationCoordinate2D(latitude: p.lat, longitude: p.lon)) {
                            Image(systemName: "mappin.circle.fill").font(.title)
                                .foregroundStyle(p.online ? .green : Brand.accent)
                        }
                    }
                }.ignoresSafeArea(edges: .top)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(positions) { p in
                            HStack(spacing: 8) {
                                Circle().fill(p.online ? .green : .gray).frame(width: 9, height: 9)
                                Text("\(p.device) · \(String(format: "%.0f", p.speedKmh)) \(L("km/s","km/h"))")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10).glassCapsule()
                        }
                    }.padding(16)
                }
            }
            .navigationTitle(L("Canlı GPS","Live GPS"))
        }
        .task {
            positions = await store.positions()
            if let f = positions.first {
                cam = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: f.lat, longitude: f.lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
            }
        }
    }
}
