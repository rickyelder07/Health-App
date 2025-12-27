//
//  CalendarView.swift
//  Health App
//
//  Calendar view for viewing daily summaries
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar picker
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    // Selected date summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Summary for \(selectedDate.formatted(date: .long, time: .omitted))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("No data available for this date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
}

