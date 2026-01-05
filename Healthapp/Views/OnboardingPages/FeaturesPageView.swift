//
//  FeaturesPageView.swift
//  Netfuel
//
//  Features overview page for onboarding
//

import SwiftUI

struct FeaturesPageView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)

                    Text("Track Your Health")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Everything you need in one place")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Features Grid
                VStack(spacing: 24) {
                    FeatureCard(
                        icon: "fork.knife",
                        title: "Food Logging",
                        description: "Search USDA database or create custom foods. Track calories, protein, carbs, and fat.",
                        color: .blue,
                        illustration: "🍎"
                    )

                    FeatureCard(
                        icon: "figure.run",
                        title: "Activity Tracking",
                        description: "Connect Strava to automatically sync your workouts and calculate calories burned.",
                        color: .green,
                        illustration: "🏃"
                    )

                    FeatureCard(
                        icon: "chart.xyaxis.line",
                        title: "Daily Summaries",
                        description: "View your daily calorie intake, macros, and progress towards your goals.",
                        color: .orange,
                        illustration: "📊"
                    )

                    FeatureCard(
                        icon: "camera.fill",
                        title: "Progress Photos",
                        description: "Track your transformation with photos and see your journey over time.",
                        color: .purple,
                        illustration: "📸"
                    )

                    FeatureCard(
                        icon: "calendar",
                        title: "Calendar View",
                        description: "Review your nutrition history and identify patterns in your habits.",
                        color: .red,
                        illustration: "📅"
                    )

                    FeatureCard(
                        icon: "bolt.circle.fill",
                        title: "Quick Actions",
                        description: "Create custom quick-add buttons for frequently logged foods and meals.",
                        color: .yellow,
                        illustration: "⚡"
                    )
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let illustration: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
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

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(illustration)
                        .font(.title3)
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    FeaturesPageView()
}
