//
//  ImagePicker.swift
//  Health App
//
//  UIImagePickerController wrapper for SwiftUI
//

import SwiftUI
import UIKit
import Combine
import AVFoundation
import Photos

/// SwiftUI wrapper for UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.editedImage] as? UIImage {
                parent.onImageSelected(image)
            } else if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Permission manager for camera and photo library access
class PermissionManager: ObservableObject {
    @Published var cameraPermissionStatus: PermissionStatus = .notDetermined
    @Published var photoLibraryPermissionStatus: PermissionStatus = .notDetermined
    
    enum PermissionStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }
    
    // MARK: - Camera Permissions
    
    /// Check camera permission status
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        DispatchQueue.main.async {
            switch status {
            case .authorized:
                self.cameraPermissionStatus = .authorized
            case .denied:
                self.cameraPermissionStatus = .denied
            case .restricted:
                self.cameraPermissionStatus = .restricted
            case .notDetermined:
                self.cameraPermissionStatus = .notDetermined
            @unknown default:
                self.cameraPermissionStatus = .notDetermined
            }
        }
    }
    
    /// Request camera permission
    func requestCameraPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // MARK: - Photo Library Permissions
    
    /// Check photo library permission status
    func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        DispatchQueue.main.async {
            switch status {
            case .authorized, .limited:
                self.photoLibraryPermissionStatus = .authorized
            case .denied:
                self.photoLibraryPermissionStatus = .denied
            case .restricted:
                self.photoLibraryPermissionStatus = .restricted
            case .notDetermined:
                self.photoLibraryPermissionStatus = .notDetermined
            @unknown default:
                self.photoLibraryPermissionStatus = .notDetermined
            }
        }
    }
    
    /// Request photo library permission
    func requestPhotoLibraryPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    let granted = status == .authorized || status == .limited
                    self.photoLibraryPermissionStatus = granted ? .authorized : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // MARK: - Permission Checks
    
    /// Check if camera is available
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// Check if photo library is available
    var isPhotoLibraryAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    // MARK: - Open Settings
    
    /// Open app settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

/// Permission request view
struct PermissionRequestView: View {
    let permissionType: PermissionType
    let onGrant: () -> Void
    let onDeny: () -> Void
    
    @StateObject private var permissionManager = PermissionManager()
    
    enum PermissionType {
        case camera
        case photoLibrary
        
        var title: String {
            switch self {
            case .camera: return "Camera Access"
            case .photoLibrary: return "Photo Library Access"
            }
        }
        
        var message: String {
            switch self {
            case .camera:
                return "Allow access to your camera to take progress photos."
            case .photoLibrary:
                return "Allow access to your photo library to select progress photos."
            }
        }
        
        var icon: String {
            switch self {
            case .camera: return "camera.fill"
            case .photoLibrary: return "photo.on.rectangle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: permissionType.icon)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text(permissionType.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(permissionType.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    Task {
                        let granted: Bool
                        switch permissionType {
                        case .camera:
                            granted = await permissionManager.requestCameraPermission()
                        case .photoLibrary:
                            granted = await permissionManager.requestPhotoLibraryPermission()
                        }
                        
                        if granted {
                            onGrant()
                        } else {
                            onDeny()
                        }
                    }
                } label: {
                    Text("Allow Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                
                Button("Not Now") {
                    onDeny()
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

/// Permission denied view
struct PermissionDeniedView: View {
    let permissionType: PermissionRequestView.PermissionType
    @StateObject private var permissionManager = PermissionManager()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Permission Denied")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("To use this feature, please enable \(permissionType.title.lowercased()) in Settings.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                permissionManager.openSettings()
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

#Preview("Camera Permission") {
    PermissionRequestView(
        permissionType: .camera,
        onGrant: {},
        onDeny: {}
    )
}

#Preview("Permission Denied") {
    PermissionDeniedView(permissionType: .camera)
}

