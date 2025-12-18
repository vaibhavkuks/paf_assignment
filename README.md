# PAF Assignment - iOS Image Grid Application

A native iOS application that efficiently loads and displays images in a scrollable grid using SwiftUI. Built without any third-party image loading libraries, implementing custom caching and network management from scratch.

## 📱 Features

- **Dynamic Image Grid**: Responsive grid that automatically adjusts columns based on device screen width
- **Lazy Image Loading**: Images load asynchronously as they come into view
- **Scroll Optimization**: Automatic cancellation of off-screen image loads for smooth scrolling
- **Dual-Layer Caching**: Custom memory and disk cache implementation
- **Error Handling**: Graceful handling of network errors with retry functionality
- **Pull to Refresh**: Refresh data with pull-down gesture
- **200+ Images**: Loads at least 200 images from the API

## 🏗️ Architecture

The application follows **MVVM (Model-View-ViewModel)** architecture pattern:

```
paf_assignment/
├── App/
│   └── paf_assignmentApp.swift      # App entry point
├── DataModels/
│   ├── Coverage.swift               # Coverage data model
│   └── Thumbnail.swift              # Thumbnail data model with URL builder
├── Cache/
│   └── ImageCache.swift             # Memory + Disk cache implementation
├── Networking/
│   ├── APIClient.swift              # API service for fetching coverages
│   └── ImageLoader.swift            # Async image loader with cancellation
├── ViewModels/
│   └── ImageGridViewModel.swift     # Main view model for the grid
└── Views/
    ├── ContentView.swift            # Main grid view
    └── ImageCell.swift              # Individual image cell
```

## 🔧 Technical Implementation

### Image Loading Strategy

1. **Cache-First Approach**: 
   - Check memory cache → disk cache → network
   - When reading from disk, memory cache is updated

2. **Cancellation Support**:
   - When scrolling quickly from page 1 to page 10, page 1 image loads are cancelled
   - Uses `Task` cancellation with `onDisappear` lifecycle

3. **No Lag Scrolling**:
   - Fixed-size grid items prevent layout recalculation
   - `LazyVGrid` only renders visible cells
   - Background image decoding

### Caching Implementation

- **Memory Cache**: Uses `NSCache` with automatic memory management
  - 100MB limit
  - 200 item count limit
  - Automatic eviction under memory pressure

- **Disk Cache**: File-based persistence in Caches directory
  - 500MB limit
  - LRU (Least Recently Used) cleanup
  - SHA256 hashed filenames

### Network Layer

- Built using basic `URLSession` APIs (no `AsyncImage` or high-level Apple APIs)
- Custom `URLSessionConfiguration` without automatic caching
- Proper error handling with custom error types

## 📋 Requirements

- **iOS**: 15.0+
- **Xcode**: 15.0+ (Latest stable version)
- **Swift**: 5.9+

## 🚀 How to Run

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd paf_assignment
   ```

2. **Open in Xcode**
   ```bash
   open paf_assignment.xcodeproj
   ```

3. **Select a simulator or device**
   - Choose any iOS 15+ simulator (iPhone or iPad)
   - Or connect a physical device

4. **Build and Run**
   - Press `Cmd + R` or click the Play button
   - Wait for the app to build and launch

5. **No additional setup required**
   - No CocoaPods, SPM, or Carthage dependencies
   - No API keys or configuration needed

## 📖 API Reference

The app fetches data from:
```
https://acharyaprashant.org/api/v2/content/misc/media-coverages?limit=100
```

Image URLs are constructed using:
```
imageURL = domain + "/" + basePath + "/0/" + key
```

## ✅ Evaluation Criteria Met

| Criteria | Implementation |
|----------|----------------|
| Lazy image loading | ✅ `LazyVGrid` + `onAppear` loading |
| Scroll cancellation | ✅ `onDisappear` cancels in-flight requests |
| No scrolling lag | ✅ Fixed-size cells, background loading |
| Memory cache | ✅ `NSCache` with limits |
| Disk cache | ✅ File-based with LRU cleanup |
| Memory → Disk fallback | ✅ Automatic cache hierarchy |
| Disk → Memory update | ✅ Memory updated on disk read |
| Native Swift/SwiftUI | ✅ Pure SwiftUI, no third-party libs |
| MVVM Architecture | ✅ Clear separation of concerns |
| 200+ Images | ✅ Pagination support |

## 🎨 UI Features

- Clean, minimal design
- Loading indicators for each cell
- Error state with tap-to-retry
- Pull-to-refresh functionality
- Adaptive grid (2-6+ columns based on screen)

## 📝 Notes

- All networking uses basic `URLSession` APIs without Apple's automatic caching
- No use of `AsyncImage` or similar high-level APIs
- Image cache is thread-safe using Swift Actors
- The app supports both iPhone and iPad with responsive layout

## 👤 Author

Vaibhav Kukreti

## 📄 License

This project is created as an assignment submission.
