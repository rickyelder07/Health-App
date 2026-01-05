//
//  ImageCache.swift
//  Netfuel
//
//  Image caching utility with memory and disk persistence
//

import UIKit
import Foundation

/// Thread-safe image cache manager with memory and disk caching
class ImageCache {

    // MARK: - Singleton

    static let shared = ImageCache()

    // MARK: - Properties

    /// In-memory cache for quick access
    private let memoryCache = NSCache<NSString, UIImage>()

    /// Serial queue for thread-safe disk operations
    private let diskCacheQueue = DispatchQueue(label: "com.netfuel.imageCache", qos: .utility)

    /// Disk cache directory
    private let diskCacheURL: URL

    /// Maximum memory cache size (in count of images)
    private let memoryCapacity = 100

    /// Maximum disk cache size (in bytes) - 100 MB
    private let diskCapacity = 100 * 1024 * 1024

    // MARK: - Initialization

    private init() {
        // Configure memory cache
        memoryCache.countLimit = memoryCapacity
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB

        // Set up disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Clean up old cache on init
        cleanUpDiskCacheIfNeeded()

        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Get image from cache (checks memory first, then disk)
    /// - Parameter url: Image URL string
    /// - Returns: Cached UIImage if available
    func image(forKey key: String) -> UIImage? {
        let cacheKey = NSString(string: sanitizedKey(from: key))

        // Check memory cache first
        if let image = memoryCache.object(forKey: cacheKey) {
            return image
        }

        // Check disk cache
        if let image = loadImageFromDisk(forKey: key) {
            // Store in memory for quick access next time
            memoryCache.setObject(image, forKey: cacheKey)
            return image
        }

        return nil
    }

    /// Store image in cache (both memory and disk)
    /// - Parameters:
    ///   - image: UIImage to cache
    ///   - key: Cache key (typically the URL string)
    func setImage(_ image: UIImage, forKey key: String) {
        let cacheKey = NSString(string: sanitizedKey(from: key))

        // Store in memory cache
        memoryCache.setObject(image, forKey: cacheKey)

        // Store on disk asynchronously
        diskCacheQueue.async { [weak self] in
            self?.saveImageToDisk(image, forKey: key)
        }
    }

    /// Remove image from cache
    /// - Parameter key: Cache key to remove
    func removeImage(forKey key: String) {
        let cacheKey = NSString(string: sanitizedKey(from: key))

        // Remove from memory
        memoryCache.removeObject(forKey: cacheKey)

        // Remove from disk
        diskCacheQueue.async { [weak self] in
            self?.removeImageFromDisk(forKey: key)
        }
    }

    /// Clear all cached images (memory and disk)
    func clearAll() {
        clearMemoryCache()
        clearDiskCache()
    }

    /// Clear memory cache only (disk cache remains)
    @objc func clearMemoryCache() {
        memoryCache.removeAllObjects()
        print("🧹 ImageCache: Memory cache cleared")
    }

    /// Clear disk cache only (memory cache remains)
    func clearDiskCache() {
        diskCacheQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                try FileManager.default.removeItem(at: self.diskCacheURL)
                try FileManager.default.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
                print("🧹 ImageCache: Disk cache cleared")
            } catch {
                print("❌ ImageCache: Failed to clear disk cache: \(error)")
            }
        }
    }

    /// Get current disk cache size in bytes
    func diskCacheSize() -> Int {
        var size = 0

        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])

            for file in files {
                let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                size += fileSize
            }
        } catch {
            print("❌ ImageCache: Failed to calculate disk cache size: \(error)")
        }

        return size
    }

    // MARK: - Private Methods

    /// Load image from disk cache
    private func loadImageFromDisk(forKey key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(sanitizedKey(from: key))

        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    /// Save image to disk cache
    private func saveImageToDisk(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        let fileURL = diskCacheURL.appendingPathComponent(sanitizedKey(from: key))

        do {
            try data.write(to: fileURL)
        } catch {
            print("❌ ImageCache: Failed to save image to disk: \(error)")
        }
    }

    /// Remove image from disk cache
    private func removeImageFromDisk(forKey key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(sanitizedKey(from: key))
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Clean up disk cache if it exceeds size limit
    private func cleanUpDiskCacheIfNeeded() {
        diskCacheQueue.async { [weak self] in
            guard let self = self else { return }

            let currentSize = self.diskCacheSize()

            if currentSize > self.diskCapacity {
                // Delete oldest files first
                do {
                    let files = try FileManager.default.contentsOfDirectory(
                        at: self.diskCacheURL,
                        includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
                    )

                    // Sort by modification date (oldest first)
                    let sortedFiles = files.sorted { url1, url2 in
                        let date1 = try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                        let date2 = try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                        return (date1 ?? Date.distantPast) < (date2 ?? Date.distantPast)
                    }

                    var freedSize = 0
                    let targetSize = self.diskCapacity * 3 / 4 // Free up to 75% capacity

                    for file in sortedFiles {
                        if currentSize - freedSize <= targetSize {
                            break
                        }

                        let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize
                        try? FileManager.default.removeItem(at: file)
                        freedSize += fileSize ?? 0
                    }

                    print("🧹 ImageCache: Cleaned up \(freedSize / 1024 / 1024) MB")
                } catch {
                    print("❌ ImageCache: Failed to clean up disk cache: \(error)")
                }
            }
        }
    }

    /// Sanitize URL string to create valid filename
    private func sanitizedKey(from key: String) -> String {
        // Create hash of the key for consistent filename
        // Using simple hash instead of MD5 to avoid CommonCrypto dependency
        var hasher = Hasher()
        hasher.combine(key)
        let hashValue = abs(hasher.finalize())
        return String(hashValue, radix: 16)
    }
}

// MARK: - AsyncImage Extension with Cache

extension ImageCache {
    /// Load image asynchronously from URL with caching
    /// - Parameters:
    ///   - urlString: Image URL string
    ///   - completion: Completion handler with UIImage or nil
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = image(forKey: urlString) {
            completion(cachedImage)
            return
        }

        // Download image
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // Cache the image
            self.setImage(image, forKey: urlString)

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// Cached async image view for SwiftUI
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard !isLoading else { return }
        isLoading = true

        ImageCache.shared.loadImage(from: url) { loadedImage in
            self.image = loadedImage
            self.isLoading = false
        }
    }
}

// MARK: - Convenience Initializer

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: String) {
        self.init(
            url: url,
            content: { $0.resizable() },
            placeholder: { ProgressView() }
        )
    }
}
