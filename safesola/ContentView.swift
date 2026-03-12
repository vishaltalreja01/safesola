//
//  ContentView.swift
//  safesola
//
//  Created by Foundation 41 on 04/03/26.
//

import SwiftUI
import MapKit
import MapboxMaps

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var placeService    = PlaceService()
    @State private var crimeService    = CrimeService()
    @State private var routeService    = RouteService()
    @State private var routedPlace: Place? = nil
    @State private var drawerHeight: CGFloat = 350
    @GestureState private var dragOffset: CGFloat = 0

    @State private var activeCategory: PlaceCategory? = nil
    @State private var selectedPlace: Place?          = nil
    @State private var showCrimeHeatmap: Bool         = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        TabView {
            Tab("Map", systemImage: "map.fill") {
                ZStack {
                    // ── Map ──────────────────────────────────────────────────
                    MapboxMaps.Map(viewport: $locationManager.viewport) {
                        Puck2D(bearing: .heading)
                            .showsAccuracyRing(true)

                        // Annotations for the active category
                        if let cat = activeCategory {
                            ForEvery(placeService.places(for: cat), id: \.id) { place in
                                if !routeService.isRouting || place.id == routedPlace?.id {
                                    MapViewAnnotation(coordinate: place.coordinate) {
                                        PlacePin(place: place) {
                                            selectedPlace = place
                                        }
                                    }
                                    .allowOverlap(cat == .busStops ? false : true)
                                }
                            }
                        }

                        // Route Line Layer
                        if !routeService.routeCoordinates.isEmpty {
                            PolylineAnnotation(lineCoordinates: routeService.routeCoordinates)
                                .lineColor(StyleColor(.appAccent))
                                .lineWidth(5.0)
                        }

                        // UK Crime Heatmap Layer
                        if showCrimeHeatmap && !crimeService.featureCollection.features.isEmpty {
                            GeoJSONSource(id: "crimes-source")
                                .data(.featureCollection(crimeService.featureCollection))

                            HeatmapLayer(id: "crimes-heat", source: "crimes-source")
                                .heatmapWeight(1.0)
                                .heatmapRadius(25.0)
                                .heatmapOpacity(0.7)
                                .heatmapColor(
                                    Exp(.interpolate) {
                                        Exp(.linear)
                                        Exp(.heatmapDensity)
                                        0.0; "rgba(0, 0, 0, 0)"
                                        0.2; "rgba(0, 255, 0, 0.5)"
                                        0.5; "rgba(255, 255, 0, 0.8)"
                                        1.0; "rgba(255, 0, 0, 0.9)"
                                    }
                                )
                        }
                    }
                    .mapStyle(.standard)
                    .ornamentOptions(OrnamentOptions(
                        scaleBar: ScaleBarViewOptions(position: .topLeft, margins: CGPoint(x: 74, y: 8)),
                        logo: LogoViewOptions(
                            position: .bottomLeft,
                            margins: CGPoint(x: 8, y: routeService.isRouting ? 12 : max(100, drawerHeight - dragOffset) + 12)
                        ),
                        attributionButton: AttributionButtonOptions(
                            position: .bottomRight,
                            margins: CGPoint(x: 0, y: 2000)
                        )
                    ))
                    .onCameraChanged { cameraChanged in
                        let center = cameraChanged.cameraState.center
                        let zoom = cameraChanged.cameraState.zoom
                        locationManager.mapCameraChanged(center: center, zoom: zoom)
                    }

                    // ── Zoom + Location Controls ─────────────────────────────
                    VStack {
                        HStack {
                            VStack(spacing: 8) {
                                mapControlButton(icon: "plus") {
                                    locationManager.zoomIn()
                                }
                                mapControlButton(icon: "minus") {
                                    locationManager.zoomOut()
                                }
                                mapControlButton(icon: "location.fill", tint: .appAccent) {
                                    locationManager.centerOnUser()
                                }
                                
                                if routeService.isRouting {
                                    mapControlButton(icon: "xmark", tint: .red) {
                                        routeService.clearRoute()
                                        routedPlace = nil
                                    }
                                }
                                
                                // Crime Heatmap Toggle
                                mapControlButton(icon: showCrimeHeatmap ? "flame.fill" : "flame",
                                                 tint: showCrimeHeatmap ? .red : .primary) {
                                    showCrimeHeatmap.toggle()
                                    if showCrimeHeatmap {
                                        crimeService.loadNaplesCrimes()
                                    } else {
                                        crimeService.clear()
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.leading, 15)
                        .padding(.top, 15)
                        Spacer()
                    }

                    // ── OSM Attribution ──────────────────────────────────────
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Link("© OpenStreetMap", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.regularMaterial)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 2)
                        }
                        .padding(.trailing, 15)
                        .padding(.bottom, routeService.isRouting ? 30 : (drawerHeight - dragOffset) + 15)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: drawerHeight)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)

                    // ── Bottom Drawer ────────────────────────────────────────
                    if !routeService.isRouting {
                        VStack {
                            Spacer()
                            VStack(spacing: 0) {
                                // Handle
                                Capsule()
                                    .fill(Color.gray.opacity(0.4))
                                    .frame(width: 40, height: 5)
                                    .padding(.top, 10)

                                Text("What are you looking for?")
                                    .font(.headline)
                                    .padding(.top, 8)
                                    .padding(.bottom, 12)

                                ScrollView {
                                    VStack(spacing: 10) {
                                        ForEach(PlaceCategory.allCases) { category in
                                            CategoryButton(
                                                title: category.rawValue,
                                                icon: category.icon,
                                                color: category.color,
                                                isActive: activeCategory == category
                                            ) {
                                                if activeCategory == category {
                                                    activeCategory = nil  // tap again to deselect
                                                } else {
                                                    activeCategory = category
                                                    placeService.load(category: category)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 20)
                                }
                            }
                            .frame(height: max(100, drawerHeight - dragOffset))
                            .background(Color(UIColor.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                            .edgesIgnoringSafeArea(.bottom)
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        state = value.translation.height
                                    }
                                    .onEnded { value in
                                        let newHeight = drawerHeight - value.translation.height
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            drawerHeight = newHeight > 500 ? 650
                                                         : newHeight > 250 ? 350
                                                         : 150
                                        }
                                    }
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: drawerHeight)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .sheet(item: $selectedPlace) { place in
                    PlaceDetailSheet(place: place, selectedPlace: $selectedPlace, routedPlace: $routedPlace, routeService: routeService, locationManager: locationManager)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            Tab("SafeList", systemImage: "checklist") {
                ChecklistView()
            }
            Tab("SOS", systemImage: "exclamationmark.triangle.fill") {
                SOSView(locationManager: locationManager)
            }
        }
        .fullScreenCover(isPresented: .init(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView(locationManager: locationManager)
        }
    }

    // MARK: - Helper: map control button
    @ViewBuilder
    private func mapControlButton(icon: String,
                                   tint: Color = .primary,
                                   action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 36, height: 36)
                .foregroundColor(tint)
                .background(.regularMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Place Pin

struct PlacePin: View {
    let place: Place
    let onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(place.category.color)
                        .frame(width: 32, height: 32)
                        .shadow(color: place.category.color.opacity(0.4), radius: 4, x: 0, y: 2)
                    Image(systemName: place.category.pinIcon)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                Triangle()
                    .fill(place.category.color)
                    .frame(width: 10, height: 6)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.88 : 1.0)
        .animation(.spring(response: 0.2), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Place Detail Sheet

struct PlaceDetailSheet: View {
    let place: Place
    @Binding var selectedPlace: Place?
    @Binding var routedPlace: Place?
    var routeService: RouteService
    var locationManager: LocationManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Header ───────────────────────────────────────────────
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(place.category.color.opacity(0.15))
                                .frame(width: 60, height: 60)
                            Image(systemName: place.category.pinIcon)
                                .foregroundColor(place.category.color)
                                .font(.system(size: 28))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(place.operatorName ?? place.category.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.top, 8)

                    Divider()

                    // ── Detail rows ──────────────────────────────────────────
                    VStack(spacing: 16) {

                        if let desc = place.description {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Description", systemImage: "info.circle.fill")
                                    .font(.caption).foregroundColor(.secondary)
                                Text(desc)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let net = place.network {
                            DetailRow(icon: "network",
                                      iconColor: place.category.color,
                                      label: "Network", value: net)
                        }

                        if let address = place.address {
                            DetailRow(icon: "mappin.circle.fill", iconColor: .red,
                                      label: "Address", value: address)
                        }

                        if let hours = place.openingHours {
                            DetailRow(icon: "clock.fill", iconColor: .orange,
                                      label: "Opening Hours", value: hours)
                        }

                        if let phone = place.phone {
                            Button {
                                let digits = phone.filter { $0.isNumber || $0 == "+" }
                                if let url = URL(string: "tel://\(digits)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                DetailRow(icon: "phone.fill", iconColor: .green,
                                          label: "Phone", value: phone)
                            }
                            .buttonStyle(.plain)
                        }

                        if let email = place.email {
                            Button {
                                let first = email.components(separatedBy: ";").first ?? email
                                if let url = URL(string: "mailto:\(first.trimmingCharacters(in: .whitespaces))") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                DetailRow(icon: "envelope.fill", iconColor: .appAccent,
                                          label: "Email", value: email)
                            }
                            .buttonStyle(.plain)
                        }

                        if let website = place.website {
                            Button {
                                let urlStr = website.hasPrefix("http") ? website : "https://\(website)"
                                if let url = URL(string: urlStr) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                DetailRow(icon: "globe", iconColor: .indigo,
                                          label: "Website", value: website)
                            }
                            .buttonStyle(.plain)
                        }

                        // Badges
                        let badges = badges(for: place)
                        if !badges.isEmpty {
                            HStack(spacing: 10) {
                                ForEach(badges, id: \.0) { (label, color) in
                                    BadgeView(label: label, color: color)
                                }
                            }
                        }
                    }

                    // ── Directions ───────────────────────────────────────────
                    Button {
                        if let location = locationManager.userLocation {
                            Task {
                                await routeService.calculateRoute(start: location, end: place.coordinate)
                                routedPlace = place
                                selectedPlace = nil
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Get Directions").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(place.category.color)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .padding(.top, 8)

                    // OSM footer
                    Text("OSM Node #\(place.osmId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func badges(for place: Place) -> [(String, Color)] {
        var result: [(String, Color)] = []
        if place.dispensing {
            result.append(("Dispensing", .appAccent))
        }
        if place.wheelchairAccessible {
            result.append(("♿ Wheelchair", .purple))
        } else if place.wheelchairLimited {
            result.append(("♿ Limited", .orange))
        }
        return result
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let title: String
    let icon: String
    var color: Color = .appAccent
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.white.opacity(0.25) : color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isActive ? .white : color)
                }

                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isActive ? .white : .primary)

                Spacer()

                Image(systemName: isActive ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundColor(isActive ? .white.opacity(0.8) : color)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isActive
                    ? color
                    : Color(UIColor.secondarySystemGroupedBackground)
            )
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Onboarding Helpers

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appAccent)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
    }
}

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let subtitle: String
    let primaryTitle: String
    let secondaryTitle: String?
    var isDownloading: Bool = false
    var progress: Double = 0.0
    let onPrimary: () -> Void
    let onSecondary: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle().fill(Color.appAccent.opacity(0.10)).frame(width: 170, height: 170)
                Circle().fill(Color.appAccent.opacity(0.90)).frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 38)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if isDownloading {
                    VStack(spacing: 8) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .appAccent))
                            .padding(.horizontal)
                        Text("Downloading: \(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 50)
                    .padding(.bottom, 12)
                } else {
                    PrimaryButton(title: primaryTitle, systemImage: "chevron.right", action: onPrimary)

                    if let secondaryTitle {
                        Button(secondaryTitle) { onSecondary?() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    var locationManager: LocationManager
    @State private var offlineManager = OfflineMapManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page = 0
    @State private var showSOSSetup = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.appAccent : Color.gray.opacity(0.35))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 6)

            ZStack {
                if page == 0 {
                    OnboardingPageView(
                        icon: "map.fill",
                        title: "Today you can use this app to travel safely in Naples.",
                        subtitle: "We are working to add new destinations.",
                        primaryTitle: "Continue",
                        secondaryTitle: nil,
                        onPrimary: { withAnimation { page = 1 } },
                        onSecondary: nil
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if page == 1 {
                    OnboardingPageView(
                        icon: "shield.fill",
                        title: "Travel safer, anywhere in Naples",
                        subtitle: "",
                        primaryTitle: "Continue",
                        secondaryTitle: nil,
                        onPrimary: { withAnimation { page = 2 } },
                        onSecondary: nil
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if page == 2 {
                    OnboardingPageView(
                        icon: offlineManager.isFinished ? "checkmark.circle.fill" : "wifi.slash",
                        title: offlineManager.isFinished ? "Downloaded Successfully!" : "Works offline",
                        subtitle: offlineManager.isFinished ? "Naples map is now available offline." : "Download Naples maps for navigation even without signal. Your safety never depends on Wi-Fi.",
                        primaryTitle: offlineManager.isFinished ? "Continue" : "Enable Offline Maps",
                        secondaryTitle: offlineManager.isFinished ? nil : "Skip for now",
                        isDownloading: offlineManager.isDownloading,
                        progress: offlineManager.progress,
                        onPrimary: {
                            if offlineManager.isFinished {
                                withAnimation { page = 3 }
                            } else {
                                offlineManager.downloadNaples()
                            }
                        },
                        onSecondary: { withAnimation { page = 3 } }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if page == 3 {
                    OnboardingPageView(
                        icon: "location.fill",
                        title: "Allow Location Access",
                        subtitle: "We use your location to show nearby safe places and enable SOS alerts.",
                        primaryTitle: "Allow While Using App",
                        secondaryTitle: "Don’t Allow",
                        onPrimary: {
                            locationManager.manager.requestWhenInUseAuthorization()
                        },
                        onSecondary: {
                            withAnimation { page = 4 }
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if page == 4 {
                    OnboardingPageView(
                        icon: "phone.fill",
                        title: "SOS & Trusted contacts",
                        subtitle: "Set up emergency contacts & location sharing. One tap sends your location to people you trust.",
                        primaryTitle: "Set up now",
                        secondaryTitle: "Skip for now",
                        onPrimary: {
                            showSOSSetup = true
                        },
                        onSecondary: finish
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .onChange(of: locationManager.authorizationStatus) { _, newStatus in
                // Only auto-advance if we're on the location screen
                guard page == 3 else { return }

                if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways ||
                    newStatus == .denied || newStatus == .restricted {
                    page = 4
                }
            }
            .onChange(of: offlineManager.isFinished) { _, finished in
                if finished {
                    // Auto-advance after giving them a moment to see the checkmark
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if page == 2 {
                            page = 3
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showSOSSetup, onDismiss: finish) {
            TrustedContactsView()
        }
    }

    private func finish() {
        hasCompletedOnboarding = true
    }
}

