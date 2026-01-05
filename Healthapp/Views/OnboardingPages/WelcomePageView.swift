//
//  WelcomePageView.swift
//  Netfuel
//
//  Welcome screen for onboarding
//

import SwiftUI

struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon/Logo
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .red.opacity(0.3), radius: 20, x: 0, y: 10)

            // Title
            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("Health Tracker")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Description
            Text("Your personal calorie and fitness companion")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Features list
            VStack(spacing: 20) {
                FeatureRow(icon: "chart.bar.fill", title: "Track Nutrition", color: .blue)
                FeatureRow(icon: "figure.run", title: "Log Exercise", color: .green)
                FeatureRow(icon: "camera.fill", title: "Progress Photos", color: .purple)
                FeatureRow(icon: "target", title: "Reach Your Goals", color: .orange)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    WelcomePageView()
}
