//
//  StravaConnectionPageView.swift
//  Netfuel
//
//  Strava connection page for onboarding (optional)
//

import SwiftUI

struct StravaConnectionPageView: View {
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    @State private var showingStravaConnection = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)

            // Title
            VStack(spacing: 12) {
                Text("Connect Strava")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Automatically sync your workouts")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Description
            VStack(alignment: .leading, spacing: 16) {
                FeatureBullet(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Auto-sync activities from Strava"
                )

                FeatureBullet(
                    icon: "flame.fill",
                    text: "Automatically calculate calories burned"
                )

                FeatureBullet(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Track exercise alongside nutrition"
                )

                FeatureBullet(
                    icon: "clock.fill",
                    text: "Save time logging workouts"
                )
            }
            .padding(.horizontal, 40)

            Spacer()

            // Connection Status
            if onboardingViewModel.isStravaConnected {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    Text("Strava Connected!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            } else {
                // Connect Button
                Button {
                    showingStravaConnection = true
                } label: {
                    HStack {
                        Image(systemName: "figure.run")
                        Text("Connect Strava")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            // Optional Note
            Text("You can connect Strava later in Settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingStravaConnection) {
            // Placeholder for Strava connection flow
            // In a real implementation, this would show StravaConnectionView
            StravaConnectionPlaceholder(onboardingViewModel: onboardingViewModel)
        }
    }
}

struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

struct StravaConnectionPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var onboardingViewModel: OnboardingViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange.gradient)

                Text("Strava Connection")
                    .font(.title)
                    .fontWeight(.bold)

                Text("In a real implementation, this would connect to Strava. For now, you can skip this step.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    onboardingViewModel.completeStravaConnection()
                    dismiss()
                } label: {
                    Text("Simulate Connection")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Connect Strava")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StravaConnectionPageView(onboardingViewModel: OnboardingViewModel())
}
