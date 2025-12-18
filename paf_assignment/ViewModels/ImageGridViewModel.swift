//
//  ImageGridViewModel.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/14/25.
//

import Foundation
import Combine

/// States for the image grid loading
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

/// ViewModel for the image grid following MVVM architecture
/// Handles data fetching, state management, and business logic
@MainActor
final class ImageGridViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// List of coverage items to display
    @Published private(set) var coverages: [Coverage] = []
    
    /// Current loading state
    @Published private(set) var loadingState: LoadingState = .idle
    
    /// Error message if loading fails
    @Published private(set) var errorMessage: String?
    
    // MARK: - Properties
    
    /// API client for fetching data
    private let apiClient: APIClientProtocol
    
    /// Minimum number of images to load
    private let minimumImages = 200
    
    // MARK: - Initialization
    
    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    /// Fetches coverage data from the API
    func fetchCoverages() async {
        // Don't fetch if already loading
        guard loadingState != .loading else { return }
        
        loadingState = .loading
        errorMessage = nil
        
        do {
            let fetchedCoverages = try await apiClient.fetchCoverages()
            
            // Filter out items without valid thumbnail URLs
            let validCoverages = fetchedCoverages.filter { $0.thumbnail.imageURL != nil }
            
            self.coverages = validCoverages
            self.loadingState = .loaded
            
            print("Loaded \(validCoverages.count) coverage items")
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.loadingState = .error(error.localizedDescription)
            print("Error fetching coverages: \(error)")
        }
    }
    
    /// Refreshes the data (pull to refresh)
    func refresh() async {
        await fetchCoverages()
    }
    
    /// Clears all cached images
    func clearCache() async {
        await ImageCache.shared.clearCache()
    }
    
    /// Returns the image URL for a coverage item
    func imageURL(for coverage: Coverage) -> URL? {
        coverage.thumbnail.imageURL
    }
}

// MARK: - Preview Support

extension ImageGridViewModel {
    /// Creates a mock view model for previews
    static var preview: ImageGridViewModel {
        let viewModel = ImageGridViewModel()
        // Add mock data for previews
        return viewModel
    }
}
