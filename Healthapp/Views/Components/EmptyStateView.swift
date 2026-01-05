//
//  EmptyStateView.swift
//  Netfuel
//
//  Reusable empty state components
//

import SwiftUI

// MARK: - Generic Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.gray.gradient)
                .accessibilityHidden(true)

            // Title and Message
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action Button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .simultaneousGesture(
                    TapGesture().onEnded { _ in
                        HapticFeedback.light()
                    }
                )
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Specific Empty States

struct NoFoodLogsEmptyState: View {
    var onAddFood: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "fork.knife.circle",
            title: "No Food Logged",
            message: "Start tracking your nutrition by logging your first meal.",
            actionTitle: "Log Food",
            action: onAddFood
        )
    }
}

struct NoActivitiesEmptyState: View {
    var onConnect: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "figure.run.circle",
            title: "No Activities",
            message: "Connect Strava to automatically sync your workouts and track calories burned.",
            actionTitle: "Connect Strava",
            action: onConnect
        )
    }
}

struct NoProgressPhotosEmptyState: View {
    var onAddPhoto: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "camera.circle",
            title: "No Progress Photos",
            message: "Take your first progress photo to track your transformation journey.",
            actionTitle: "Add Photo",
            action: onAddPhoto
        )
    }
}

struct NoCustomFoodsEmptyState: View {
    var onCreateFood: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "plus.circle",
            title: "No Custom Foods",
            message: "Create custom foods for items you log frequently.",
            actionTitle: "Create Food",
            action: onCreateFood
        )
    }
}

struct NoCustomMealsEmptyState: View {
    var onCreateMeal: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "fork.knife",
            title: "No Custom Meals",
            message: "Save combinations of foods as meals for quick logging.",
            actionTitle: "Create Meal",
            action: onCreateMeal
        )
    }
}

struct NoSearchResultsView: View {
    var searchTerm: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No Results")
                .font(.headline)

            Text("No results found for \"\(searchTerm)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Try a different search term")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No results found for \(searchTerm)")
    }
}

struct NoInternetConnectionView: View {
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("No Internet Connection")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Please check your internet connection and try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: 300)
                .frame(height: 50)
                .background(Color.orange)
                .cornerRadius(12)
            }
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    HapticFeedback.light()
                }
            )
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No internet connection")
    }
}

#Preview("No Food Logs") {
    NoFoodLogsEmptyState(onAddFood: {})
}

#Preview("No Activities") {
    NoActivitiesEmptyState(onConnect: {})
}

#Preview("No Progress Photos") {
    NoProgressPhotosEmptyState(onAddPhoto: {})
}

#Preview("No Search Results") {
    NoSearchResultsView(searchTerm: "Pizza")
}

#Preview("No Internet") {
    NoInternetConnectionView(onRetry: {})
}
