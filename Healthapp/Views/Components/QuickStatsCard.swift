//
//  QuickStatsCard.swift
//  Netfuel
//
//  Reusable quick stats card component
//

import SwiftUI

/// Reusable card for displaying quick stats
struct QuickStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend?
    let subtitle: String?

    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        trend: Trend? = nil,
        subtitle: String? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and title
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if let trend = trend {
                    TrendIndicator(trend: trend)
                }
            }

            // Value
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// Trend direction
    enum Trend {
        case up
        case down
        case neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
}

// MARK: - Trend Indicator

private struct TrendIndicator: View {
    let trend: QuickStatsCard.Trend

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption)
            .foregroundColor(trend.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(trend.color.opacity(0.1))
        .cornerRadius(4)
    }
}

#Preview {
    VStack(spacing: 16) {
        QuickStatsCard(
            title: "Net Calories",
            value: "-520",
            icon: "flame.fill",
            color: .green,
            trend: .down,
            subtitle: "Deficit"
        )

        QuickStatsCard(
            title: "Weight",
            value: "70.5 kg",
            icon: "scalemass",
            color: .blue,
            trend: .down,
            subtitle: "Today"
        )

        QuickStatsCard(
            title: "Exercise",
            value: "450 cal",
            icon: "figure.run",
            color: .orange,
            subtitle: "2 activities"
        )
    }
    .padding()
}
