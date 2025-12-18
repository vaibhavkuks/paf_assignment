//
//  Thumbnail.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/12/25.
//

import Foundation

/// Represents thumbnail metadata from the API response
struct Thumbnail: Decodable, Hashable {
    let id: String
    let version: Int
    let domain: String
    let basePath: String
    let key: String
    let qualities: [Int]
    let aspectRatio: Double
    
    /// Constructs the full image URL using the formula:
    /// imageURL = domain + "/" + basePath + "/0/" + key
    var imageURL: URL? {
        let urlString = "\(domain)/\(basePath)/0/\(key)"
        return URL(string: urlString)
    }
    
    /// Constructs image URL with specific quality
    func imageURL(quality: Int) -> URL? {
        let urlString = "\(domain)/\(basePath)/\(quality)/\(key)"
        return URL(string: urlString)
    }
}
