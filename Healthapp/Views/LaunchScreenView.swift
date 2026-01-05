//
//  LaunchScreenView.swift
//  Netfuel
//
//  Launch screen matching app branding
//

import SwiftUI

/// Launch screen shown while app initializes
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background color matching app theme
            Color(hex: "#1A2332")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App logo/icon
                // Replace this with your actual logo image
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)

                // App name
                Text("Netfuel")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Tagline
                Text("Fuel Your Fitness")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
