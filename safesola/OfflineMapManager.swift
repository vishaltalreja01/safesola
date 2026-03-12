import Foundation
import MapboxMaps
import SwiftUI
import CoreLocation

@Observable
class OfflineMapManager {
    var progress: Double = 0.0
    var isDownloading = false
    var isFinished = false
    var errorMsg: String?

    func downloadNaples() {
        guard !isDownloading else { return }

        isDownloading = true
        progress = 0.0
        errorMsg = nil

        let tileStore = TileStore.default
        let offlineManager = OfflineManager()

        let options = TilesetDescriptorOptions(
            styleURI: .standard,
            zoomRange: 10...16,
            tilesets: nil
        )
        let descriptor = offlineManager.createTilesetDescriptor(for: options)

        // Build a closed polygon ring for Naples bounding box
        let sw = CLLocationCoordinate2D(latitude: 40.75, longitude: 14.10)
        let ne = CLLocationCoordinate2D(latitude: 40.95, longitude: 14.35)
        let nw = CLLocationCoordinate2D(latitude: ne.latitude, longitude: sw.longitude)
        let se = CLLocationCoordinate2D(latitude: sw.latitude, longitude: ne.longitude)
        let ring: [CLLocationCoordinate2D] = [sw, se, ne, nw, sw] // closed ring

        let polygon = Polygon([ring])
        let geometry = Geometry.polygon(polygon)

        guard let tileRegionOptions = TileRegionLoadOptions(
            geometry: geometry,
            descriptors: [descriptor],
            acceptExpired: true
        ) else {
            isDownloading = false
            errorMsg = "Failed to create tile region options"
            return
        }

        let regionId = "naples-offline"

        let _ = tileStore.loadTileRegion(
            forId: regionId,
            loadOptions: tileRegionOptions,
            progress: { progress in
                DispatchQueue.main.async {
                    if progress.requiredResourceCount > 0 {
                        self.progress = Double(progress.completedResourceCount) / Double(progress.requiredResourceCount)
                    }
                }
            }
        ) { result in
            DispatchQueue.main.async {
                self.isDownloading = false
                switch result {
                case .success(let region):
                    self.isFinished = true
                    print("Offline region loaded: \(region.id)")
                case .failure(let error):
                    self.errorMsg = error.localizedDescription
                    print("Offline region error: \(error)")
                }
            }
        }
    }
}
