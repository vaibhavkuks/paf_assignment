//
//  ImageLoader.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/13/25.
//

import UIKit
import SwiftUI
import Combine

/// Errors that can occur during image loading
enum ImageLoadError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidData
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidData:
            return "Failed to decode image data"
        case .cancelled:
            return "Image load was cancelled"
        }
    }
}

/// Manages image loading with cancellation support
/// When scrolling quickly, old requests are cancelled to prioritize visible content
actor ImageLoader {
    
    // MARK: - Singleton
    static let shared = ImageLoader(cache: ImageCache.shared)
    
    // MARK: - Properties
    
    /// URLSession for image downloads (no automatic caching)
    private let session: URLSession
    
    /// Cache reference
    private let cache: ImageCache
    
    /// Tracks in-flight tasks for cancellation
    private var inFlightTasks: [String: Task<UIImage?, Error>] = [:]
    
    /// Priority queue for tracking which URLs should be loaded first
    private var priorityQueue: [String] = []
    
    /// Maximum concurrent downloads
    private let maxConcurrentDownloads = 6
    
    /// Current number of active downloads
    private var activeDownloads = 0
    
    // MARK: - Initialization
    
    init(cache: ImageCache) {
        // Create URLSession without caching
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 15
        configuration.httpMaximumConnectionsPerHost = 6
        
        self.session = URLSession(configuration: configuration)
        self.cache = cache
    }
    
    // MARK: - Public Methods
    
    /// Loads an image from the given URL, using cache if available
    /// Supports cancellation for scroll optimization
    func loadImage(from url: URL) async throws -> UIImage? {
        let key = url.absoluteString
        
        // 1. Check cache first (memory, then disk)
        if let cachedImage = await cache.getImage(forKey: key) {
            return cachedImage
        }
        
        // 2. Check if already loading
        if let existingTask = inFlightTasks[key] {
            return try await existingTask.value
        }
        
        // 3. Create new loading task
        let task = Task<UIImage?, Error> {
            try await downloadImage(from: url)
        }
        
        inFlightTasks[key] = task
        
        do {
            let image = try await task.value
            inFlightTasks.removeValue(forKey: key)
            
            // Cache the downloaded image
            if let image = image {
                await cache.setImage(image, forKey: key)
            }
            
            return image
        } catch {
            inFlightTasks.removeValue(forKey: key)
            throw error
        }
    }
    
    /// Cancels the loading task for a specific URL
    /// Called when an image cell goes off screen
    func cancelLoad(for url: URL) {
        let key = url.absoluteString
        
        if let task = inFlightTasks[key] {
            task.cancel()
            inFlightTasks.removeValue(forKey: key)
        }
    }
    
    /// Cancels all pending image loads
    /// Useful when scrolling quickly to a different section
    func cancelAllLoads() {
        for (_, task) in inFlightTasks {
            task.cancel()
        }
        inFlightTasks.removeAll()
    }
    
    /// Preloads images for upcoming cells (prefetching)
    func preloadImages(for urls: [URL]) {
        for url in urls {
            Task {
                _ = try? await loadImage(from: url)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Downloads an image from the network using basic URLSession
    private func downloadImage(from url: URL) async throws -> UIImage? {
        // Check for cancellation
        try Task.checkCancellation()
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check for cancellation after download
            try Task.checkCancellation()
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ImageLoadError.networkError(URLError(.badServerResponse))
            }
            
            // Decode image on background thread
            guard let image = UIImage(data: data) else {
                throw ImageLoadError.invalidData
            }
            
            return image
            
        } catch is CancellationError {
            throw ImageLoadError.cancelled
        } catch {
            throw ImageLoadError.networkError(error)
        }
    }
}

// MARK: - Observable Image Loader for SwiftUI

/// ObservableObject wrapper for loading images in SwiftUI views
/// Handles loading state and cancellation on disappear
@MainActor
final class AsyncImageLoader: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Properties
    
    private var currentURL: URL?
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Methods
    
    /// Loads an image from the given URL
    func load(from url: URL?) {
        // Cancel any existing load
        cancel()
        
        guard let url = url else {
            self.error = ImageLoadError.invalidURL
            return
        }
        
        currentURL = url
        isLoading = true
        error = nil
        
        loadTask = Task {
            do {
                let loadedImage = try await ImageLoader.shared.loadImage(from: url)
                
                // Only update if this is still the current URL
                if currentURL == url {
                    self.image = loadedImage
                    self.isLoading = false
                }
            } catch is CancellationError {
                // Silently handle cancellation
                if currentURL == url {
                    self.isLoading = false
                }
            } catch {
                if currentURL == url {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Cancels the current loading task
    /// Should be called when the view disappears
    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        
        if let url = currentURL {
            Task {
                await ImageLoader.shared.cancelLoad(for: url)
            }
        }
        
        currentURL = nil
        isLoading = false
    }
}
