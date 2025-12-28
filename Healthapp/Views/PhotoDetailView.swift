//
//  PhotoDetailView.swift
//  Health App
//
//  Full screen photo detail view
//

import SwiftUI

/// Full screen view for progress photo details
struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgressPhotoViewModel
    
    let photo: ProgressPhoto
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Full size photo
                    AsyncImage(url: URL(string: photo.photoUrl)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 400)
                                .overlay(
                                    ProgressView()
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                        case .failure:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 400)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("Failed to load image")
                                            .foregroundColor(.secondary)
                                    }
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    // Photo information
                    VStack(spacing: 20) {
                        // Date
                        InfoRow(
                            icon: "calendar",
                            title: "Date Taken",
                            value: photo.formattedDate
                        )
                        
                        // Weight
                        if let weight = photo.weight {
                            InfoRow(
                                icon: "scalemass",
                                title: "Weight",
                                value: "\(String(format: "%.1f", weight)) lbs"
                            )
                        }
                        
                        // Notes
                        if let notes = photo.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.accentColor)
                                        .frame(width: 24)
                                    Text("Notes")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Details", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Photo", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditPhotoDetailsView(
                    photo: photo,
                    viewModel: viewModel
                )
            }
            .alert("Delete Photo", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePhoto()
                }
            } message: {
                Text("Are you sure you want to delete this progress photo? This action cannot be undone.")
            }
        }
    }
    
    private func deletePhoto() {
        Task {
            let success = await viewModel.deletePhoto(photo)
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Edit Photo Details View

struct EditPhotoDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgressPhotoViewModel
    
    let photo: ProgressPhoto
    
    @State private var weight: String
    @State private var notes: String
    
    init(photo: ProgressPhoto, viewModel: ProgressPhotoViewModel) {
        self.photo = photo
        self.viewModel = viewModel
        _weight = State(initialValue: photo.weight.map { String(format: "%.1f", $0) } ?? "")
        _notes = State(initialValue: photo.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Weight") {
                    HStack {
                        TextField("Enter weight", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 120)
                }
            }
            .navigationTitle("Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
    
    private func saveChanges() {
        let weightValue = Double(weight)
        let notesValue = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        
        Task {
            let success = await viewModel.updatePhoto(
                photoId: photo.id,
                weight: weightValue,
                notes: notesValue
            )
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    PhotoDetailView(
        viewModel: ProgressPhotoViewModel(),
        photo: ProgressPhoto(
            id: UUID(),
            userId: UUID(),
            photoUrl: "https://via.placeholder.com/400",
            thumbnailUrl: nil,
            weight: 180.5,
            notes: "Feeling great after 3 months of training!",
            takenAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}

