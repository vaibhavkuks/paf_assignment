//
//  ImageCell.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/13/25.
//

import SwiftUI

/// Individual cell in the image grid
/// Handles lazy loading and cancellation when scrolling off screen
struct ImageCell: View {
    
    // MARK: - Properties
    
    let coverage: Coverage
    
    /// Image loader that manages async loading and cancellation
    @StateObject private var imageLoader = AsyncImageLoader()
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                // Content based on loading state
                if let image = imageLoader.image {
                    // Loaded image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else if imageLoader.isLoading {
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(0.8)
                } else if imageLoader.error != nil {
                    // Error state with retry option
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                        
                        Text("Could not load")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        loadImage()
                    }
                } else {
                    // Placeholder icon
                    Image(systemName: "photo")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.system(size: 24))
                }
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .cornerRadius(4)
        .onAppear {
            loadImage()
        }
        .onDisappear {
            // Cancel loading when cell goes off screen
            // This is key for scroll performance optimization
            imageLoader.cancel()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadImage() {
        imageLoader.load(from: coverage.thumbnail.imageURL)
    }
}

// MARK: - Preview

#Preview {
    let thumbnail = Thumbnail(
        id: "test-id",
        version: 1,
        domain: "https://cimg.acharyaprashant.org",
        basePath: "images/img-test",
        key: "image.jpg",
        qualities: [10, 20, 30, 40],
        aspectRatio: 1
    )
    
    let coverage = Coverage(
        id: "coverage-test",
        title: "Test Coverage",
        language: "english",
        thumbnail: thumbnail,
        mediaType: 0,
        coverageURL: nil,
        publishedAt: "2025-01-01",
        publishedBy: "Test Publisher",
        description: "Test description"
    )
    
    return ImageCell(coverage: coverage)
        .frame(width: 150, height: 150)
        .padding()
}
