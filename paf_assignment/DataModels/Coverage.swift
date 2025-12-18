//
//  Coverage.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/12/25.
//

import Foundation

/// Represents a coverage item from the API response
struct Coverage: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let language: String?
    let thumbnail: Thumbnail
    let mediaType: Int?
    let coverageURL: String?
    let publishedAt: String?
    let publishedBy: String?
    let description: String?
    
    /// Unique identifier for caching purposes based on thumbnail
    var cacheKey: String {
        thumbnail.id
    }
}
