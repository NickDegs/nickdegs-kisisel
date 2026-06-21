import SwiftUI
import MapKit

struct MapTab: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var tracker: Tracker
    @StateObject private var loc = LocationManager()
    @State private var positions: [Position] = []
    @State private var centered = false
    @State private var showTypePicker = false
    @State private var genRange: GenRange?
    @State private var cam: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
        span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4))))

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cam) {
                    UserAnnotation()
                    ForEach(positions) { p in
                        Annotation(p.device, coordinate: CLLocationCoordinate2D(latitude: p.lat, longitude: p.lon)) {
                            Image(systemName: "mappin.circle.fill").font(.title)
                                .foregroundStyle(p.online ? .green : Brand.accent)
                        }
                    }
                }
                .mapControls { MapUserLocationButton(); MapCompass() }
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 10) {
                    if !positions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(positions) { p in
                                    HStack(spacing: 8) {
                                        Circle().fill(p.online ? .green : .gray).frame(width: 9, height: 9)
                                        Text("\(p.device) · \(String(format: "%.0f", p.speedKmh)) \(L("km/s","km/h"))")
                                            .font(.system(size: 13, weight: .medium))
                                    }.padding(.horizontal, 14).padding(.vertical, 10).glassCapsule()
                                }
                            }.padding(.horizontal, 16)
                        }
                    }
                    recordBar.padding(.horizontal, 16).padding(.bottom, 6)
                }
            }
            .navigationTitle(L("Canlı GPS","Live GPS"))
        }
        .task {
            loc.request()
            positions = await store.positions()
        }
        .onChange(of: loc.coordinate?.latitude) { _, _ in
            if !centered, let c = loc.coordinate {
                centered = true
                withAnimation { cam = .region(MKCoordinateRegion(center: c,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))) }
            }
        }
        .confirmationDialog(L("Ne kaydı?","What are you recording?"), isPresented: $showTypePicker, titleVisibility: .visible) {
            ForEach(RIDE_TYPES, id: \.id) { t in
                Button(rideLabel(t.id)) { startRide(t.id) }
            }
        }
        .sheet(item: $genRange) { r in
            GenerateSheet(from: r.from, to: r.to, type: r.type)
        }
    }

    @ViewBuilder var recordBar: some View {
        if tracker.recording {
            HStack(spacing: 12) {
                Circle().fill(.red).frame(width: 11, height: 11)
                // tip menüsü (sonradan değiştirilebilir)
                Menu {
                    ForEach(RIDE_TYPES, id: \.id) { t in
                        Button(rideLabel(t.id)) { tracker.rideType = t.id }
                    }
                } label: {
                    Label(rideLabel(tracker.rideType), systemImage: "chevron.up.chevron.down").font(.system(size: 15, weight: .semibold))
                }
                Spacer()
                Button(L("Bitir","Finish")) {
                    if let r = tracker.endRide() { genRange = GenRange(from: r.from, to: r.to, type: r.type) }
                }.buttonStyle(.glassyProminent()).tint(.red)
            }.padding(14).glassPanel(22)
        } else {
            Button {
                showTypePicker = true
            } label: {
                Label(L("Gezi kaydı başlat","Start recording"), systemImage: "record.circle")
                    .font(.system(size: 16, weight: .semibold)).frame(maxWidth: .infinity)
            }.buttonStyle(.glassyProminent())
        }
    }

    func startRide(_ type: String) {
        Task {
            guard let t = await store.trackerInfo() else { return }
            tracker.startRide(type: type, deviceId: t.id, url: t.url)
        }
    }
}

struct GenRange: Identifiable {
    let id = UUID(); let from: Double; let to: Double; let type: String
}
