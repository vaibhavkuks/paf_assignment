//
//  CoverageRepository.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/14/25.
//

import Foundation

/// Protocol defining the coverage data repository
protocol CoverageRepositoryProtocol {
    func getCoverages() async throws -> [Coverage]
}

/// Repository for managing coverage data
/// Acts as a single source of truth, abstracting data sources from ViewModels
final class CoverageRepository: CoverageRepositoryProtocol {
    
    // MARK: - Properties
    
    private let apiClient: APIClientProtocol
    
    // MARK: - Initialization
    
    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    /// Fetches coverages from the API
    func getCoverages() async throws -> [Coverage] {
        try await apiClient.fetchCoverages()
    }
}
