//
//  MacroProgressView.swift
//  Netfuel
//
//  Reusable component for displaying macro progress bars
//

import SwiftUI

/// Reusable progress view for macronutrients
struct MacroProgressView: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    let icon: String
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    private var isExceeded: Bool {
        current > target
    }
    
    private var statusColor: Color {
        if isExceeded {
            return .red
        } else if progress >= 0.9 {
            return .green
        } else {
            return color
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(String(format: "%.0f", current))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                    
                    Text("/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.0f", target))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

/// Compact horizontal macro display
struct MacroSummaryCard: View {
    let calories: Int
    let caloriesTarget: Int
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbsTarget: Double
    let fat: Double
    let fatTarget: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Calories (main display)
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(calories)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("/ \(caloriesTarget)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("cal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: Double(calories), total: Double(caloriesTarget))
                    .tint(calories > caloriesTarget ? .red : .orange)
            }
            
            Divider()
            
            // Macros
            VStack(spacing: 12) {
                MacroProgressView(
                    title: "Protein",
                    current: protein,
                    target: proteinTarget,
                    unit: "g",
                    color: .red,
                    icon: "flame.fill"
                )
                
                MacroProgressView(
                    title: "Carbs",
                    current: carbs,
                    target: carbsTarget,
                    unit: "g",
                    color: .blue,
                    icon: "leaf.fill"
                )
                
                MacroProgressView(
                    title: "Fat",
                    current: fat,
                    target: fatTarget,
                    unit: "g",
                    color: .purple,
                    icon: "drop.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

/// Compact inline macro display
struct InlineMacroView: View {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    var body: some View {
        HStack(spacing: 12) {
            MacroBadge(icon: "flame.fill", value: "\(calories)", unit: "cal", color: .orange)
            MacroBadge(icon: "p.circle.fill", value: String(format: "%.0f", protein), unit: "g", color: .red)
            MacroBadge(icon: "c.circle.fill", value: String(format: "%.0f", carbs), unit: "g", color: .blue)
            MacroBadge(icon: "f.circle.fill", value: String(format: "%.0f", fat), unit: "g", color: .purple)
        }
    }
}

/// Individual macro badge
struct MacroBadge: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Macro Progress") {
    VStack(spacing: 20) {
        MacroProgressView(
            title: "Protein",
            current: 85,
            target: 150,
            unit: "g",
            color: .red,
            icon: "flame.fill"
        )
        
        MacroProgressView(
            title: "Carbs",
            current: 180,
            target: 200,
            unit: "g",
            color: .blue,
            icon: "leaf.fill"
        )
        
        MacroProgressView(
            title: "Fat",
            current: 72,
            target: 65,
            unit: "g",
            color: .purple,
            icon: "drop.fill"
        )
    }
    .padding()
}

#Preview("Macro Summary Card") {
    MacroSummaryCard(
        calories: 1650,
        caloriesTarget: 2200,
        protein: 85,
        proteinTarget: 150,
        carbs: 180,
        carbsTarget: 200,
        fat: 72,
        fatTarget: 65
    )
    .padding()
}

#Preview("Inline Macro View") {
    InlineMacroView(
        calories: 450,
        protein: 25,
        carbs: 42,
        fat: 18
    )
    .padding()
}

