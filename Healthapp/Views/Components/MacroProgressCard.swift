//
//  MacroProgressCard.swift
//  Netfuel
//
//  Reusable macro progress card component
//

import SwiftUI

/// Reusable card for displaying macro progress
struct MacroProgressCard: View {
    let name: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    let icon: String
    let showPercentage: Bool

    init(
        name: String,
        current: Double,
        target: Double,
        unit: String = "g",
        color: Color,
        icon: String,
        showPercentage: Bool = true
    ) {
        self.name = name
        self.current = current
        self.target = target
        self.unit = unit
        self.color = color
        self.icon = icon
        self.showPercentage = showPercentage
    }

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if showPercentage {
                    Text("\(percentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)

            // Values
            HStack {
                Text(String(format: "%.1f", current))
                    .font(.caption2)
                    .fontWeight(.semibold)

                Text("/")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(String(format: "%.1f \(unit)", target))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MacroProgressCard(
            name: "Protein",
            current: 85,
            target: 150,
            color: .red,
            icon: "flame.fill"
        )

        MacroProgressCard(
            name: "Carbs",
            current: 180,
            target: 200,
            color: .blue,
            icon: "leaf.fill"
        )

        MacroProgressCard(
            name: "Fat",
            current: 72,
            target: 65,
            color: .purple,
            icon: "drop.fill"
        )
    }
    .padding()
}
