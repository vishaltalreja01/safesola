//
//  SplashScreenView.swift
//  safesola
//
//  Created by Foundation 41 on 05/03/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: -5) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 180)
                    
                    Text("SafeSola")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(.appAccent)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    logoOpacity = 1.0
                    logoScale = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
