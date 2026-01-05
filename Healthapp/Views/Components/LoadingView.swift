//
//  LoadingView.swift
//  Netfuel
//
//  Reusable loading state components
//

import SwiftUI

// MARK: - Standard Loading View

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading content")
    }
}

// MARK: - Shimmer Loading View

struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGray6)

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.6),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.3)
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                .animation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: isAnimating
                )
            }
        }
        .onAppear {
            isAnimating = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Skeleton Components

struct SkeletonRectangle: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8

    var body: some View {
        ShimmerView()
            .frame(height: height)
            .cornerRadius(cornerRadius)
    }
}

struct SkeletonCircle: View {
    var diameter: CGFloat = 50

    var body: some View {
        ShimmerView()
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SkeletonCircle(diameter: 50)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonRectangle(height: 16)
                        .frame(width: 150)
                    SkeletonRectangle(height: 14)
                        .frame(width: 100)
                }
            }

            SkeletonRectangle(height: 60)
            SkeletonRectangle(height: 40)
                .frame(width: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .accessibilityHidden(true)
    }
}

// MARK: - Food Log Skeleton

struct FoodLogSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 12) {
                    SkeletonCircle(diameter: 40)

                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonRectangle(height: 16)
                            .frame(maxWidth: .infinity)
                        SkeletonRectangle(height: 14)
                            .frame(width: 120)
                    }

                    SkeletonRectangle(height: 30)
                        .frame(width: 60)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .accessibilityLabel("Loading food logs")
    }
}

// MARK: - List Loading View

struct ListLoadingView: View {
    var count: Int = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<count, id: \.self) { _ in
                    HStack(spacing: 12) {
                        SkeletonCircle(diameter: 50)

                        VStack(alignment: .leading, spacing: 8) {
                            SkeletonRectangle(height: 16)
                            SkeletonRectangle(height: 14)
                                .frame(width: 150)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .accessibilityLabel("Loading list")
    }
}

// MARK: - Progress Upload View

struct ProgressUploadView: View {
    var progress: Double
    var fileName: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.blue)

            HStack {
                Image(systemName: "photo")
                    .foregroundColor(.blue)

                Text(fileName)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Uploading \(fileName), \(Int(progress * 100)) percent complete")
    }
}

#Preview("Loading View") {
    LoadingView()
}

#Preview("Shimmer") {
    SkeletonRectangle(height: 50)
        .padding()
}

#Preview("Skeleton Card") {
    SkeletonCard()
        .padding()
}

#Preview("Food Log Skeleton") {
    FoodLogSkeleton()
        .padding()
}

#Preview("Progress Upload") {
    ProgressUploadView(progress: 0.65, fileName: "progress_photo.jpg")
        .padding()
}
