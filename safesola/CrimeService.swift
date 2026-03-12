//
//  CrimeService.swift
//  safesola
//
//  Created by Foundation 41 on 08/03/26.
//

import Foundation
import CoreLocation
import MapboxMaps
import SwiftUI

// MARK: - Models

struct NaplesCrime: Codable, Identifiable {
    let name: String
    let lat: Double
    let lng: Double
    let crimeCount: Int
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name, lat, lng
        case crimeCount = "crime_count"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

@Observable
class CrimeService {
    var featureCollection = FeatureCollection(features: [])
    var isLoading = false
    
    func loadNaplesCrimes() {
        isLoading = true
        defer { isLoading = false }
        
        let decoder = JSONDecoder()
        var crimes: [NaplesCrime] = []
        
        // Try to load from "crime.json" in bundle
        if let url = Bundle.main.url(forResource: "crime", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? decoder.decode([NaplesCrime].self, from: data) {
            crimes = decoded
        } else {
            // Fallback if crime.json is not successfully linked in the Xcode target
            let jsonString = """
            [
              { "name": "Porto - Zona Industriale", "lat": 40.8465, "lng": 14.2820, "crime_count": 6 },
              { "name": "Arenella - Medaglie d'Oro", "lat": 40.8520, "lng": 14.2250, "crime_count": 4 },
              { "name": "Secondigliano - Miano", "lat": 40.8885, "lng": 14.2515, "crime_count": 2 },
              { "name": "Casavatore - Casoria", "lat": 40.9030, "lng": 14.2750, "crime_count": 2 },
              { "name": "Chiaiano Metro", "lat": 40.8845, "lng": 14.2120, "crime_count": 2 },
              { "name": "Quarto Flegreo", "lat": 40.8760, "lng": 14.1350, "crime_count": 2 },
              { "name": "Agnano Terme", "lat": 40.8285, "lng": 14.1685, "crime_count": 2 },
              { "name": "San Giovanni a Teduccio", "lat": 40.8380, "lng": 14.3020, "crime_count": 2 },
              { "name": "Fuorigrotta - Stadio", "lat": 40.8250, "lng": 14.1950, "crime_count": 1 },
              { "name": "Bagnoli", "lat": 40.8150, "lng": 14.1700, "crime_count": 1 }
            ]
            """
            if let data = jsonString.data(using: .utf8),
               let decoded = try? decoder.decode([NaplesCrime].self, from: data) {
                crimes = decoded
            }
        }
        
        // Map to GeoJSON features.
        // Duplicate the point based on `crime_count` so the basic heatmap density
        // correctly displays higher intensity in areas with more crime count.
        var features: [Feature] = []
        for crime in crimes {
            var props: JSONObject = [:]
            props["name"] = .string(crime.name)
            
            var baseFeature = Feature(geometry: .point(Point(crime.coordinate)))
            baseFeature.properties = props
            
            for _ in 0..<crime.crimeCount {
                features.append(baseFeature)
            }
        }
        
        self.featureCollection = FeatureCollection(features: features)
        print("CrimeService: Loaded Naples crimes. Generating \(features.count) heatmap points.")
    }
    
    func clear() {
        featureCollection = FeatureCollection(features: [])
    }
}
