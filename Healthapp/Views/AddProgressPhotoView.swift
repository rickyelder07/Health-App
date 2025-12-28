//
//  AddProgressPhotoView.swift
//  Health App
//
//  View for adding new progress photos
//

import SwiftUI

/// View for capturing or selecting and uploading progress photos
struct AddProgressPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgressPhotoViewModel
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var weight: String = ""
    @State private var notes: String = ""
    @State private var takenAt: Date = Date()
    
    @State private var showingPermissionRequest = false
    @State private var showingPermissionDenied = false
    @State private var permissionType: PermissionRequestView.PermissionType = .camera
    
    @StateObject private var permissionManager = PermissionManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Image Selection
                    VStack(spacing: 16) {
                        if let image = selectedImage {
                            // Image Preview
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            
                            // Change Photo Button
                            Button {
                                selectedImage = nil
                            } label: {
                                Label("Change Photo", systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline)
                            }
                        } else {
                            // Photo Selection Buttons
                            VStack(spacing: 12) {
                                Button {
                                    checkCameraPermissionAndOpen()
                                } label: {
                                    Label("Take Photo", systemImage: "camera.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .cornerRadius(12)
                                }
                                
                                Button {
                                    checkPhotoLibraryPermissionAndOpen()
                                } label: {
                                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Photo Details Form
                    if selectedImage != nil {
                        VStack(spacing: 20) {
                            // Date Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date Taken")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                DatePicker(
                                    "",
                                    selection: $takenAt,
                                    in: ...Date(),
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            }
                            
                            // Weight Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weight (optional)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField("Enter weight", text: $weight)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    Text("lbs")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Notes Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes (optional)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Upload Button
                        Button {
                            uploadPhoto()
                        } label: {
                            if viewModel.isUploading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                    Text("Uploading...")
                                }
                            } else {
                                Label("Save Photo", systemImage: "checkmark.circle.fill")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedImage != nil ? Color.accentColor : Color.gray)
                        .cornerRadius(12)
                        .disabled(selectedImage == nil || viewModel.isUploading)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Add Progress Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isUploading)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imageSource) { image in
                    selectedImage = image
                }
            }
            .sheet(isPresented: $showingPermissionRequest) {
                PermissionRequestView(
                    permissionType: permissionType,
                    onGrant: {
                        showingPermissionRequest = false
                        if permissionType == .camera {
                            showingCamera = true
                        } else {
                            imageSource = .photoLibrary
                            showingImagePicker = true
                        }
                    },
                    onDeny: {
                        showingPermissionRequest = false
                        showingPermissionDenied = true
                    }
                )
            }
            .sheet(isPresented: $showingPermissionDenied) {
                PermissionDeniedView(permissionType: permissionType)
            }
        }
    }
    
    // MARK: - Actions
    
    private func checkCameraPermissionAndOpen() {
        permissionManager.checkCameraPermission()
        
        switch permissionManager.cameraPermissionStatus {
        case .authorized:
            imageSource = .camera
            showingImagePicker = true
        case .denied, .restricted:
            permissionType = .camera
            showingPermissionDenied = true
        case .notDetermined:
            permissionType = .camera
            showingPermissionRequest = true
        }
    }
    
    private func checkPhotoLibraryPermissionAndOpen() {
        permissionManager.checkPhotoLibraryPermission()
        
        switch permissionManager.photoLibraryPermissionStatus {
        case .authorized:
            imageSource = .photoLibrary
            showingImagePicker = true
        case .denied, .restricted:
            permissionType = .photoLibrary
            showingPermissionDenied = true
        case .notDetermined:
            permissionType = .photoLibrary
            showingPermissionRequest = true
        }
    }
    
    private func uploadPhoto() {
        guard let image = selectedImage else { return }
        
        let weightValue = Double(weight)
        let notesValue = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        
        Task {
            let success = await viewModel.uploadPhoto(
                image: image,
                weight: weightValue,
                notes: notesValue,
                takenAt: takenAt
            )
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    AddProgressPhotoView(viewModel: ProgressPhotoViewModel())
}

