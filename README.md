# PAF Assignment

## Implemented:

- **Dynamic Image Grid**: Responsive grid that automatically adjusts columns based on device screen width
- **Lazy Image Loading**: Images load asynchronously as they come into view
- **Scroll Optimization**: Automatic cancellation of off-screen image loads for smooth scrolling
- **Dual-Layer Caching**: Custom memory and disk cache implementation
- **Error Handling**: Graceful handling of network errors with retry functionality
- **200+ Images**: Loads 200 images from the API

## Architecture

I used MVVM architecture for this application.

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


## API Reference

The app fetches data from:
```
../content/misc/media-coverages?limit=100
```

Image URLs are constructed using:
```
imageURL = domain + "/" + basePath + "/0/" + key
```


## Author

Vaibhav Kukreti
