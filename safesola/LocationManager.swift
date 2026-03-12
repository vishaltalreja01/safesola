//
//  LocationManager.swift
//  safesola
//
//  Created by Foundation 41 on 05/03/26.
//

import Foundation
import CoreLocation
import MapboxMaps
import SwiftUI
import MapKit

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D?
    var lastLocation: CLLocation?
    var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var viewport: Viewport = .followPuck(zoom: 14, bearing: .heading)
    var currentZoom: CGFloat = 14
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        userLocation = location.coordinate
        currentRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    func mapCameraChanged(center: CLLocationCoordinate2D, zoom: CGFloat) {
        currentZoom = zoom
        // Update currentRegion for the MapKit search manager
        let span = 360.0 / pow(2.0, Double(zoom))
        currentRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
    }

    func zoomIn() {
        currentZoom = min(currentZoom + 1.0, 22.0)
        viewport = .camera(center: currentRegion.center, zoom: currentZoom, bearing: 0, pitch: 0)
    }

    func zoomOut() {
        currentZoom = max(currentZoom - 1.0, 0.0)
        viewport = .camera(center: currentRegion.center, zoom: currentZoom, bearing: 0, pitch: 0)
    }

    func centerOnUser() {
        viewport = .followPuck(zoom: currentZoom > 10 ? currentZoom : 14, bearing: .heading)
        manager.startUpdatingLocation()
    }

    func zoom(by factor: Double) {
        if factor < 1.0 {
            zoomIn()
        } else {
            zoomOut()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .notDetermined:
            // Don't auto-request, let onboarding do it if needed
            break
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

