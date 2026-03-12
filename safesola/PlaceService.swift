//
//  PlaceService.swift
//  safesola
//
//  Created by Foundation 41 on 06/03/26.
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Category

enum PlaceCategory: String, CaseIterable, Identifiable {
    case pharmacies      = "Pharmacies"
    case busStops        = "Bus Stops"
    case hospitals       = "Hospitals"
    case police          = "Police"
    case railwayStation  = "Train Stations"

    var id: String { rawValue }

    var jsonFileName: String {
        switch self {
        case .pharmacies:     return "pharmacies"
        case .busStops:       return "bus_stops"
        case .hospitals:      return "hospital"
        case .police:         return "police"
        case .railwayStation: return "railway_station"
        }
    }

    var icon: String {
        switch self {
        case .pharmacies:     return "cross.circle"
        case .busStops:       return "bus"
        case .hospitals:      return "cross.case"
        case .police:         return "shield.fill"
        case .railwayStation: return "tram.fill"
        }
    }

    var pinIcon: String {
        switch self {
        case .pharmacies:     return "cross.circle.fill"
        case .busStops:       return "bus.fill"
        case .hospitals:      return "cross.case.fill"
        case .police:         return "shield.fill"
        case .railwayStation: return "tram.fill"
        }
    }

    var color: Color {
        switch self {
        case .pharmacies:     return .green
        case .busStops:       return .orange
        case .hospitals:      return .red
        case .police:         return .appAccent
        case .railwayStation: return .purple
        }
    }

    var defaultLabel: String {
        switch self {
        case .pharmacies:     return "Pharmacy"
        case .busStops:       return "Bus Stop"
        case .hospitals:      return "Hospital"
        case .police:         return "Police Station"
        case .railwayStation: return "Train Station"
        }
    }
}

// MARK: - Place Model

struct Place: Identifiable {
    let id: Int
    let osmId: Int
    let category: PlaceCategory
    let name: String
    let coordinate: CLLocationCoordinate2D

    // Contact / detail fields (all optional — populated when available in JSON)
    let phone: String?
    let website: String?
    let email: String?
    let address: String?
    let openingHours: String?
    let operatorName: String?
    let description: String?
    let network: String?         // for transit
    let wheelchair: String?      // "yes" / "no" / "limited"
    let dispensing: Bool         // pharmacies

    var displayName: String {
        if !name.isEmpty { return name }
        if let op = operatorName, !op.isEmpty { return op }
        return "\(category.defaultLabel) #\(osmId)"
    }

    var wheelchairAccessible: Bool { wheelchair == "yes" }
    var wheelchairLimited: Bool    { wheelchair == "limited" }
}

// MARK: - PlaceService

@Observable
class PlaceService {

    // Loaded places per category
    private var cache: [PlaceCategory: [Place]] = [:]

    /// Returns loaded places for a category (empty if not yet loaded)
    func places(for category: PlaceCategory) -> [Place] {
        cache[category] ?? []
    }

    /// Load places from the bundled JSON for the given category.
    /// Returns immediately if already loaded (idempotent).
    func load(category: PlaceCategory) {
        guard cache[category] == nil else { return }

        guard let url = Bundle.main.url(forResource: category.jsonFileName,
                                        withExtension: "json") else {
            print("PlaceService: \(category.jsonFileName).json not found in bundle")
            cache[category] = []
            return
        }

        do {
            let data  = try Data(contentsOf: url)
            let resp  = try JSONDecoder().decode(OSMResponse.self, from: data)

            let places: [Place] = resp.elements.compactMap { el -> Place? in
                guard el.type == "node",
                      let lat = el.lat,
                      let lon = el.lon else { return nil }

                // Pharmacies without a name are not useful — skip them
                if category == .pharmacies,
                   let name = el.tags?.name, name.isEmpty { return nil }
                if category == .pharmacies, el.tags?.name == nil { return nil }

                let t = el.tags

                // Build address
                var addrParts: [String] = []
                if let s = t?.addrStreet      { addrParts.append(s) }
                if let n = t?.addrHousenumber { addrParts.append(n) }
                if let c = t?.addrCity        { addrParts.append(c) }
                if let p = t?.addrPostcode    { addrParts.append(p) }

                return Place(
                    id: el.id,
                    osmId: el.id,
                    category: category,
                    name: t?.name ?? "",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    phone: t?.phone ?? t?.contactPhone,
                    website: t?.website,
                    email: t?.email,
                    address: addrParts.isEmpty ? nil : addrParts.joined(separator: ", "),
                    openingHours: t?.openingHours,
                    operatorName: t?.operatorName,
                    description: t?.description,
                    network: t?.network,
                    wheelchair: t?.wheelchair,
                    dispensing: t?.dispensing == "yes"
                )
            }

            cache[category] = places
            print("PlaceService: Loaded \(places.count) \(category.rawValue)")
        } catch {
            print("PlaceService: Error loading \(category.jsonFileName): \(error)")
            cache[category] = []
        }
    }

    /// Convenience – clear and reload a category
    func reload(category: PlaceCategory) {
        cache.removeValue(forKey: category)
        load(category: category)
    }
}
