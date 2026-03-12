//
//  safesolaApp.swift
//  safesola
//
//  Created by Foundation 41 on 04/03/26.
//

import SwiftUI
import MapboxMaps

@main
struct safesolaApp: App {
    init() {
        // TODO: Replace with your actual Mapbox access token
        MapboxOptions.accessToken = "pk.eyJ1IjoidmlzaGFsdGFscmVqYTAwMCIsImEiOiJjbW1kem82anQwOGt2MnJzNXljd2hsbWx6In0.AnxwYlayOWS__NIQ6QDJhA"
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}
