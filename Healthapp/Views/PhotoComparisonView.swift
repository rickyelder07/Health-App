//
//  PhotoComparisonView.swift
//  Health App
//
//  Side-by-side photo comparison view
//

import SwiftUI

/// View for comparing two progress photos side-by-side
struct PhotoComparisonView: View {
    let photos: [ProgressPhoto]
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private var photo1: ProgressPhoto {
        photos[0]
    }
    
    private var photo2: ProgressPhoto {
        photos[1]
    }
    
    private var olderPhoto: ProgressPhoto {
        photo1.takenAt < photo2.takenAt ? photo1 : photo2
    }
    
    private var newerPhoto: ProgressPhoto {
        photo1.takenAt > photo2.takenAt ? photo1 : photo2
    }
    
    private var weightDifference: Double? {
        guard let weight1 = photo1.weight, let weight2 = photo2.weight else {
            return nil
        }
        return photo2.takenAt > photo1.takenAt ? weight2 - weight1 : weight1 - weight2
    }
    
    private var timeDifference: String {
        let interval = abs(photo2.takenAt.timeIntervalSince(photo1.takenAt))
        let days = Int(interval / 86400)
        
        if days < 7 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = days / 30
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary card
                    VStack(spacing: 16) {
                        Text("Progress Comparison")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 32) {
                            // Time difference
                            VStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                Text(timeDifference)
                                    .font(.headline)
                                Text("apart")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Weight difference
                            if let weightDiff = weightDifference {
                                VStack(spacing: 4) {
                                    Image(systemName: weightDiff < 0 ? "arrow.down.circle.fill" : weightDiff > 0 ? "arrow.up.circle.fill" : "equal.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(weightDiff < 0 ? .green : weightDiff > 0 ? .orange : .secondary)
                                    Text("\(abs(weightDiff), specifier: "%.1f") lbs")
                                        .font(.headline)
                                    Text(weightDiff < 0 ? "lost" : weightDiff > 0 ? "gained" : "no change")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Side-by-side comparison
                    HStack(spacing: 8) {
                        // Before photo
                        PhotoComparisonCard(
                            photo: olderPhoto,
                            label: "Before",
                            color: .blue
                        )
                        
                        // After photo
                        PhotoComparisonCard(
                            photo: newerPhoto,
                            label: "After",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Detailed information
                    VStack(spacing: 16) {
                        DetailedPhotoInfo(
                            title: "Before",
                            photo: olderPhoto,
                            color: .blue
                        )
                        
                        Divider()
                        
                        DetailedPhotoInfo(
                            title: "After",
                            photo: newerPhoto,
                            color: .green
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Share comparison
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - Photo Comparison Card

struct PhotoComparisonCard: View {
    let photo: ProgressPhoto
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Label
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            // Photo
            AsyncImage(url: URL(string: photo.photoUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 250)
                        .overlay(
                            ProgressView()
                        )
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 2)
            )
            
            // Date
            Text(photo.takenAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Detailed Photo Info

struct DetailedPhotoInfo: View {
    let title: String
    let photo: ProgressPhoto
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text(photo.formattedDate)
                        .font(.subheadline)
                }
                
                if let weight = photo.weight {
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text("\(String(format: "%.1f", weight)) lbs")
                            .font(.subheadline)
                    }
                }
                
                if let notes = photo.notes, !notes.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    
    return PhotoComparisonView(
        photos: [
            ProgressPhoto(
                id: UUID(),
                userId: UUID(),
                photoUrl: "https://via.placeholder.com/400",
                thumbnailUrl: nil,
                weight: 190.5,
                notes: "Starting weight",
                takenAt: threeMonthsAgo,
                createdAt: threeMonthsAgo,
                updatedAt: threeMonthsAgo
            ),
            ProgressPhoto(
                id: UUID(),
                userId: UUID(),
                photoUrl: "https://via.placeholder.com/400",
                thumbnailUrl: nil,
                weight: 180.0,
                notes: "After 3 months of training",
                takenAt: Date(),
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        onDismiss: {}
    )
}

