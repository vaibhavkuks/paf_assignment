//
//  ContentView.swift
//  paf_assignment
//
//  Created by Vaibhav Kukreti on 12/12/25.
//

import SwiftUI

/// Main view displaying a scrollable grid of images
/// Dynamically adjusts columns based on screen width
struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = ImageGridViewModel()
    
    /// Minimum cell width for calculating columns
    private let minCellWidth: CGFloat = 100
    
    /// Spacing between cells
    private let spacing: CGFloat = 4
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Main content
                    if viewModel.coverages.isEmpty && viewModel.loadingState == .loading {
                        // Initial loading state
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage, viewModel.coverages.isEmpty {
                        // Error state when no data
                        errorView(message: errorMessage)
                    } else {
                        // Image grid
                        imageGrid(in: geometry)
                    }
                }
            }
            .navigationTitle("Image Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.clearCache()
                            await viewModel.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.loadingState == .loading)
                }
            }
        }
        .navigationViewStyle(.stack)
        .task {
            // Load data when view appears
            await viewModel.fetchCoverages()
        }
    }
    
    // MARK: - Subviews
    
    /// Grid of images with dynamic column count
    @ViewBuilder
    private func imageGrid(in geometry: GeometryProxy) -> some View {
        let columns = calculateColumns(for: geometry.size.width)
        
        ScrollView {
            LazyVGrid(
                columns: columns,
                spacing: spacing
            ) {
                ForEach(viewModel.coverages) { coverage in
                    ImageCell(coverage: coverage)
                        .id(coverage.id)
                }
            }
            .padding(.horizontal, spacing)
            .padding(.vertical, spacing)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    /// Loading indicator view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading images...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Error view with retry button
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to load images")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    await viewModel.fetchCoverages()
                }
            } label: {
                Text("Retry")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the number of columns based on available width
    /// Ensures optimal use of space on different devices
    private func calculateColumns(for width: CGFloat) -> [GridItem] {
        // Calculate how many columns can fit
        let availableWidth = width - (spacing * 2) // Account for horizontal padding
        let columnCount = max(2, Int(availableWidth / minCellWidth))
        
        // Calculate actual cell size to fill the width evenly
        let totalSpacing = spacing * CGFloat(columnCount - 1)
        let cellWidth = (availableWidth - totalSpacing) / CGFloat(columnCount)
        
        // Create grid items with fixed size for smooth scrolling
        return Array(
            repeating: GridItem(.fixed(cellWidth), spacing: spacing),
            count: columnCount
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

