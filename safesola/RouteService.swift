import Foundation
import CoreLocation
import Network
import MapboxMaps

@Observable
class RouteService {
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var isRouting: Bool = false
    
    private let monitor = NWPathMonitor()
    private var isConnected: Bool = true
    
    // Replace with actual token or read from Info.plist
    private var mapboxToken: String {
        return MapboxOptions.accessToken
    }
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    func clearRoute() {
        DispatchQueue.main.async {
            self.routeCoordinates = []
            self.isRouting = false
        }
    }
    
    func calculateRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) async {
        DispatchQueue.main.async {
            self.isRouting = true
        }
        
        if isConnected {
            await fetchOnlineRoute(start: start, end: end)
        } else {
            calculateOfflineCurve(start: start, end: end)
        }
    }
    
    private func fetchOnlineRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) async {
        guard !mapboxToken.isEmpty else {
            calculateOfflineCurve(start: start, end: end)
            return
        }
        
        let urlString = "https://api.mapbox.com/directions/v5/mapbox/walking/\(start.longitude),\(start.latitude);\(end.longitude),\(end.latitude)?geometries=geojson&access_token=\(mapboxToken)"
        guard let url = URL(string: urlString) else {
            calculateOfflineCurve(start: start, end: end)
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Basic JSON decoding
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let routes = json["routes"] as? [[String: Any]],
               let firstRoute = routes.first,
               let geometry = firstRoute["geometry"] as? [String: Any],
               let coordinatesMatch = geometry["coordinates"] as? [[Double]] {
                
                let decodedCoords = coordinatesMatch.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
                
                DispatchQueue.main.async {
                    self.routeCoordinates = decodedCoords
                }
            } else {
                // Formatting error
                calculateOfflineCurve(start: start, end: end)
            }
        } catch {
            print("Route fetch error: \(error)")
            calculateOfflineCurve(start: start, end: end)
        }
    }
    
    private func calculateOfflineCurve(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        // Calculate a simple bezier curve or "great circle" arc.
        // We'll generate a point array that curves slightly to represent the offline route.
        let numPoints = 50
        var coords: [CLLocationCoordinate2D] = []
        
        // Let's create a control point perpendicular to the midpoint, to create a nice arc
        let midLat = (start.latitude + end.latitude) / 2.0
        let midLon = (start.longitude + end.longitude) / 2.0
        
        // Vector from start to end
        let dLat = end.latitude - start.latitude
        let dLon = end.longitude - start.longitude
        
        // Perpendicular vector (-dy, dx)
        // Adjust the multiplier for more or less curve severity
        let controlOffsetLat = -dLon * 0.2
        let controlOffsetLon = dLat * 0.2
        
        let controlLat = midLat + controlOffsetLat
        let controlLon = midLon + controlOffsetLon
        
        for i in 0...numPoints {
            let t = Double(i) / Double(numPoints)
            
            // Quadratic Bezier Curve formula
            // P(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
            
            let u = 1.0 - t
            let tt = t * t
            let uu = u * u
            
            let lat = (uu * start.latitude) + (2 * u * t * controlLat) + (tt * end.latitude)
            let lon = (uu * start.longitude) + (2 * u * t * controlLon) + (tt * end.longitude)
            
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        DispatchQueue.main.async {
            self.routeCoordinates = coords
        }
    }
}
