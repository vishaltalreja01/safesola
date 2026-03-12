//
//  JsonDecoder.swift
//  safesola_app
//
//  Created by Foundation 13 on 05/03/26.
//

import Foundation

struct OSMResponse: Codable {
    let elements: [OSMElement]
}

struct OSMElement: Codable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let tags: OSMTags?
}

struct OSMTags: Codable {
    let name: String?
    let amenity: String?
    let openingHours: String?
    let phone: String?
    let addrStreet: String?
    let addrHousenumber: String?
    let addrCity: String?
    let addrPostcode: String?
    let dispensing: String?
    let wheelchair: String?
    let website: String?
    let email: String?
    let fax: String?
    let contactPhone: String?
    let contactWhatsapp: String?
    let operatorName: String?
    let description: String?
    let network: String?

    enum CodingKeys: String, CodingKey {
        case name, amenity, phone, dispensing, wheelchair, website, email, fax, description, network
        case openingHours    = "opening_hours"
        case addrStreet      = "addr:street"
        case addrHousenumber = "addr:housenumber"
        case addrCity        = "addr:city"
        case addrPostcode    = "addr:postcode"
        case contactPhone    = "contact:phone"
        case contactWhatsapp = "contact:whatsapp"
        case operatorName    = "operator"
    }
}
