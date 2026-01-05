//
//  ReadyPageView.swift
//  Netfuel
//
//  Final ready page for onboarding
//

import SwiftUI

struct ReadyPageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success Icon with Animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 42, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Ready to start your health journey")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Quick Tips
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Tips to Get Started")
                    .font(.headline)
                    .padding(.bottom, 8)

                TipRow(
                    icon: "fork.knife",
                    number: "1",
                    text: "Log your meals to track calories and macros",
                    color: .blue
                )

                TipRow(
                    icon: "target",
                    number: "2",
                    text: "Set your daily calorie goal in Settings",
                    color: .green
                )

                TipRow(
                    icon: "figure.run",
                    number: "3",
                    text: "Connect Strava to track exercise automatically",
                    color: .orange
                )

                TipRow(
                    icon: "camera.fill",
                    number: "4",
                    text: "Take progress photos to see your transformation",
                    color: .purple
                )
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)

            Spacer()

            // Success message
            VStack(spacing: 12) {
                Text("Your health journey starts now!")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Tap below to start using the app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 20)
        }
        .padding()
    }
}

struct TipRow: View {
    let icon: String
    let number: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Text(number)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            // Text
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

#Preview {
    ReadyPageView()
}
