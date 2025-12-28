//
//  CalendarDayCell.swift
//  Health App
//
//  Reusable calendar day cell component
//

import SwiftUI

/// Calendar day cell with indicators
struct CalendarDayCell: View {
    let date: Date
    let isInCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let indicators: DayIndicators?

    private let calendar = Calendar.current

    var dayNumber: String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    var body: some View {
        VStack(spacing: 4) {
            // Day number
            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(backgroundCircle)

            // Indicator dots
            HStack(spacing: 2) {
                if let indicators = indicators {
                    if indicators.hasDeficit {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                    }

                    if indicators.hasSurplus {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 5, height: 5)
                    }

                    if indicators.hasProgressPhoto {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 5, height: 5)
                    }

                    if indicators.hasActivity {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var textColor: Color {
        if !isInCurrentMonth {
            return .gray.opacity(0.4)
        } else if isSelected {
            return .white
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }

    private var backgroundCircle: some View {
        Group {
            if isSelected {
                Circle()
                    .fill(Color.accentColor)
            } else if isToday {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Today, not selected
        CalendarDayCell(
            date: Date(),
            isInCurrentMonth: true,
            isToday: true,
            isSelected: false,
            indicators: DayIndicators(
                date: Date(),
                hasDeficit: true,
                hasActivity: true
            )
        )

        // Selected day with multiple indicators
        CalendarDayCell(
            date: Date(),
            isInCurrentMonth: true,
            isToday: false,
            isSelected: true,
            indicators: DayIndicators(
                date: Date(),
                hasDeficit: true,
                hasProgressPhoto: true,
                hasActivity: true
            )
        )

        // Day in previous month
        CalendarDayCell(
            date: Date(),
            isInCurrentMonth: false,
            isToday: false,
            isSelected: false,
            indicators: nil
        )
    }
    .padding()
}
