//
//  ProgressPhotoGalleryView.swift
//  Health App
//
//  Grid view for progress photo gallery
//

import SwiftUI

/// Main gallery view for progress photos
struct ProgressPhotoGalleryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProgressPhotoViewModel()
    
    @State private var showingAddPhoto = false
    @State private var showingFilters = false
    @State private var selectedPhoto: ProgressPhoto?
    @State private var showingComparison = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.photos.isEmpty {
                    // Loading state
                    ProgressView("Loading photos...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else if viewModel.photos.isEmpty {
                    // Empty state
                    EmptyPhotoGalleryView(onAddPhoto: {
                        showingAddPhoto = true
                    })
                    
                } else {
                    // Photo grid
                    ScrollView {
                        VStack(spacing: 16) {
                            // Comparison mode banner
                            if !viewModel.selectedPhotos.isEmpty {
                                ComparisonBanner(
                                    selectedCount: viewModel.selectedPhotos.count,
                                    onClear: {
                                        viewModel.clearSelection()
                                    },
                                    onCompare: {
                                        showingComparison = true
                                    }
                                )
                            }
                            
                            // Photo grid
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(viewModel.filteredPhotos) { photo in
                                    PhotoGridItem(
                                        photo: photo,
                                        isSelected: viewModel.isSelected(photo),
                                        onTap: {
                                            if viewModel.selectedPhotos.isEmpty {
                                                selectedPhoto = photo
                                            } else {
                                                viewModel.togglePhotoSelection(photo)
                                            }
                                        },
                                        onLongPress: {
                                            viewModel.togglePhotoSelection(photo)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await viewModel.refreshPhotos()
                    }
                }
            }
            .navigationTitle("Progress Photos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPhoto = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddPhoto) {
                AddProgressPhotoView(viewModel: viewModel)
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(
                    viewModel: viewModel, photo: photo
                )
            }
            .sheet(isPresented: $showingComparison) {
                if viewModel.selectedPhotos.count == 2 {
                    PhotoComparisonView(
                        photos: viewModel.selectedPhotos,
                        onDismiss: {
                            viewModel.clearSelection()
                        }
                    )
                }
            }
            .sheet(isPresented: $showingFilters) {
                PhotoFiltersView(viewModel: viewModel)
            }
            .task {
                if let userId = appState.currentUser?.id {
                    viewModel.setUser(userId: userId)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearMessages() } }
            )) {
                Button("OK") {
                    viewModel.clearMessages()
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
        }
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let photo: ProgressPhoto
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack(alignment: .topTrailing) {
                // Photo thumbnail
                AsyncImage(url: URL(string: photo.thumbnailUrl ?? photo.photoUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
                
                // Info overlay
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(photo.takenAt, style: .date)
                                .font(.caption2)
                                .fontWeight(.semibold)
                            
                            if let weight = photo.weight {
                                Text("\(String(format: "%.1f", weight)) lbs")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        
                        Spacer()
                    }
                }
                .padding(6)
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
        )
    }
}

// MARK: - Comparison Banner

struct ComparisonBanner: View {
    let selectedCount: Int
    let onClear: () -> Void
    let onCompare: () -> Void
    
    var body: some View {
        HStack {
            Text("\(selectedCount) photo\(selectedCount == 1 ? "" : "s") selected")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button("Clear", action: onClear)
                .font(.subheadline)
            
            if selectedCount == 2 {
                Button {
                    onCompare()
                } label: {
                    Text("Compare")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Empty State

struct EmptyPhotoGalleryView: View {
    let onAddPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Progress Photos Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Take your first progress photo to start tracking your fitness journey.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            
            Button {
                onAddPhoto()
            } label: {
                Label("Add Photo", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
    }
}

// MARK: - Filters View

struct PhotoFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgressPhotoViewModel
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var filterEnabled: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Filter by Date Range", isOn: $filterEnabled)
                }
                
                if filterEnabled {
                    Section("Date Range") {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                    }
                }
                
                Section {
                    Text("\(viewModel.filteredPhotos.count) photo\(viewModel.filteredPhotos.count == 1 ? "" : "s") match filters")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if filterEnabled {
                            viewModel.applyDateFilter(start: startDate, end: endDate)
                        } else {
                            viewModel.clearFilters()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProgressPhotoGalleryView()
        .environmentObject(AppState())
}

