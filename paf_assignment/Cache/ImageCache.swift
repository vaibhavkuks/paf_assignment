//
//  ImageCache.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/14/25.
//

import UIKit

/// Protocol defining cache operations for images
protocol ImageCacheProtocol: Sendable {
    func getImage(forKey key: String) async -> UIImage?
    func setImage(_ image: UIImage, forKey key: String) async
    func removeImage(forKey key: String) async
    func clearCache() async
}

/// Thread-safe image cache with both memory and disk storage
/// Memory cache is checked first, then disk cache
/// When reading from disk, memory cache is updated
actor ImageCache: ImageCacheProtocol {
    
    // MARK: - Singleton
    static let shared = ImageCache()
    
    // MARK: - Properties
    
    /// In-memory cache using NSCache for automatic memory management
    private let memoryCache: NSCache<NSString, UIImage>
    
    /// Directory URL for disk cache
    private let diskCacheURL: URL
    
    /// Maximum memory cache cost (in bytes) - 100MB
    private let maxMemoryCacheSize: Int = 100 * 1024 * 1024
    
    /// Maximum number of items in memory cache
    private let maxMemoryCacheCount: Int = 200
    
    /// Maximum disk cache size (in bytes) - 500MB
    private let maxDiskCacheSize: Int = 500 * 1024 * 1024
    
    // MARK: - Initialization
    
    init() {
        // Setup memory cache
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 100 * 1024 * 1024
        cache.countLimit = 200
        self.memoryCache = cache
        
        // Setup disk cache directory
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cacheURL = cacheDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        self.diskCacheURL = cacheURL
        
        // Create disk cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Public Methods
    
    /// Retrieves an image from cache (memory first, then disk)
    /// When reading from disk, updates memory cache
    func getImage(forKey key: String) async -> UIImage? {
        let cacheKey = sanitizedKey(key)
        
        // 1. Check memory cache first
        if let memoryImage = memoryCache.object(forKey: cacheKey as NSString) {
            return memoryImage
        }
        
        // 2. Check disk cache
        if let diskImage = await loadFromDisk(forKey: cacheKey) {
            // Update memory cache when reading from disk
            let cost = diskImage.jpegData(compressionQuality: 1.0)?.count ?? 0
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString, cost: cost)
            return diskImage
        }
        
        return nil
    }
    
    /// Stores an image in both memory and disk cache
    func setImage(_ image: UIImage, forKey key: String) async {
        let cacheKey = sanitizedKey(key)
        
        // 1. Store in memory cache
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        memoryCache.setObject(image, forKey: cacheKey as NSString, cost: cost)
        
        // 2. Store in disk cache
        await saveToDisk(image, forKey: cacheKey)
    }
    
    /// Removes an image from both memory and disk cache
    func removeImage(forKey key: String) async {
        let cacheKey = sanitizedKey(key)
        let fileManager = FileManager.default
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: cacheKey as NSString)
        
        // Remove from disk cache
        let fileURL = diskCacheURL.appendingPathComponent(cacheKey)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// Clears all cached images from both memory and disk
    func clearCache() async {
        let fileManager = FileManager.default
        
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    /// Checks if image exists in memory cache (for debugging)
    func isInMemoryCache(forKey key: String) -> Bool {
        let cacheKey = sanitizedKey(key)
        return memoryCache.object(forKey: cacheKey as NSString) != nil
    }
    
    /// Checks if image exists in disk cache (for debugging)
    func isInDiskCache(forKey key: String) -> Bool {
        let cacheKey = sanitizedKey(key)
        let fileURL = diskCacheURL.appendingPathComponent(cacheKey)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Private Methods
    
    /// Sanitizes the cache key to be a valid filename
    private func sanitizedKey(_ key: String) -> String {
        // Create a hash of the URL to use as filename
        let data = Data(key.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Loads an image from disk cache
    private func loadFromDisk(forKey key: String) async -> UIImage? {
        let fileManager = FileManager.default
        let fileURL = diskCacheURL.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // Update file access date for LRU management
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
        
        return image
    }
    
    /// Saves an image to disk cache
    private func saveToDisk(_ image: UIImage, forKey key: String) async {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        
        // Use JPEG for smaller file size (adjust quality as needed)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save image to disk: \(error)")
        }
        
        // Cleanup old files if cache is too large
        await cleanupDiskCacheIfNeeded()
    }
    
    /// Removes oldest files if disk cache exceeds size limit
    private func cleanupDiskCacheIfNeeded() async {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: diskCacheURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        var files: [(url: URL, date: Date, size: Int)] = []
        var totalSize = 0
        
        while let fileURL = enumerator.nextObject() as? URL {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modDate = attributes[.modificationDate] as? Date,
                  let size = attributes[.size] as? Int else {
                continue
            }
            
            files.append((fileURL, modDate, size))
            totalSize += size
        }
        
        // If under limit, no cleanup needed
        guard totalSize > maxDiskCacheSize else { return }
        
        // Sort by modification date (oldest first)
        files.sort { $0.date < $1.date }
        
        // Remove oldest files until under limit
        for file in files {
            guard totalSize > maxDiskCacheSize / 2 else { break }
            
            try? fileManager.removeItem(at: file.url)
            totalSize -= file.size
        }
    }
}

// MARK: - CommonCrypto Import for SHA256
import CommonCrypto
