//
//  APIClient.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/14/25.
//

import Foundation

/// Errors that can occur during API operations
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        }
    }
}

/// Protocol for API operations - allows for testing with mock implementations
protocol APIClientProtocol {
    func fetchCoverages() async throws -> [Coverage]
}

/// API Client using basic URLSession APIs for network operations
/// No high-level caching or automatic optimization - everything is manual
final class APIClient: APIClientProtocol {
    
    // MARK: - Properties
    
    /// Base URL for the API
    private let baseURL = "https://acharyaprashant.org/api/v2/content/misc/media-coverages"
    
    /// Query parameters
    private let limitParam = "limit"
    private let defaultLimit = 100
    
    /// URLSession configured without automatic caching
    private let session: URLSession
    
    // MARK: - Initialization
    
    init() {
        // Create a custom URLSession configuration without caching
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Public Methods
    
    /// Fetches coverage items from the API
    /// Returns at least 200 images by making multiple requests if needed
    func fetchCoverages() async throws -> [Coverage] {
        var allCoverages: [Coverage] = []
        var offset = 0
        let targetCount = 200
        
        // Keep fetching until we have at least 200 items
        while allCoverages.count < targetCount {
            let coverages = try await fetchCoveragesPage(limit: defaultLimit, offset: offset)
            
            // If no more data, break
            if coverages.isEmpty {
                break
            }
            
            allCoverages.append(contentsOf: coverages)
            offset += coverages.count
            
            // Safety check to prevent infinite loops
            if offset > 1000 {
                break
            }
        }
        
        return allCoverages
    }
    
    /// Fetches a single page of coverage items
    func fetchCoveragesPage(limit: Int, offset: Int) async throws -> [Coverage] {
        // Build URL with query parameters
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: limitParam, value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Perform request using basic URLSession dataTask
        let (data, response) = try await performRequest(request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode response
        do {
            let decoder = JSONDecoder()
            let coverages = try decoder.decode([Coverage].self, from: data)
            return coverages
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Performs a network request using basic URLSession APIs
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            // Using basic async/await with URLSession
            let (data, response) = try await session.data(for: request)
            return (data, response)
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

