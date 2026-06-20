import SwiftUI
import MapKit

struct MapTab: View {
    @EnvironmentObject var store: Store
    @StateObject private var loc = LocationManager()
    @State private var positions: [Position] = []
    @State private var centered = false
    @State private var cam: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
        span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4))))

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cam) {
                    UserAnnotation()   // kendi konumun (mavi nokta)
                    ForEach(positions) { p in
                        Annotation(p.device, coordinate: CLLocationCoordinate2D(latitude: p.lat, longitude: p.lon)) {
                            Image(systemName: "mappin.circle.fill").font(.title)
                                .foregroundStyle(p.online ? .green : Brand.accent)
                        }
                    }
                }
                .mapControls { MapUserLocationButton(); MapCompass() }
                .ignoresSafeArea(edges: .top)

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
            loc.request()                       // konum izni iste + kendi konumun
            positions = await store.positions()
        }
        .onChange(of: loc.coordinate?.latitude) { _, _ in
            // ilk konum gelince haritayı kullanıcıya ortala
            if !centered, let c = loc.coordinate {
                centered = true
                withAnimation { cam = .region(MKCoordinateRegion(center: c,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))) }
            }
        }
    }
}
