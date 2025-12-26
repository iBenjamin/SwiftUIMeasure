# SwiftUIMeasure

A debug tool for measuring distances between SwiftUI views at runtime.

## Features

- Tap to select two views and see the edge-to-edge distance
- Works on iOS and macOS
- Zero overhead in Release builds (`#if DEBUG`)
- Auto-generated view IDs based on source location

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/SwiftUIMeasure.git", from: "1.0.0")
]
```

## Usage

```swift
import SwiftUIMeasure

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello")
                .measurable()  // Mark as measurable

            Text("World")
                .measurable()
        }
        .measureOverlay()  // Enable measurement overlay
    }
}
```

### Activation

| Platform | Trigger |
|----------|---------|
| iOS Simulator | Press `M` key |
| iOS Device | Shake |
| macOS | Press `M` key |

### With Toggle Control

```swift
@State private var showMeasure = false

var body: some View {
    ContentView()
        .measureOverlay(isEnabled: $showMeasure)
}
```

## How It Works

1. `.measurable()` marks views and reports their frames via `PreferenceKey`
2. `.measureOverlay()` defines a coordinate space and draws the measurement UI
3. Tap two views to see horizontal/vertical edge distances
4. All code is compiled out in Release builds

## License

MIT
