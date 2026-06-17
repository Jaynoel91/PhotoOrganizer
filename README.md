# Photo Organizer

A native SwiftUI iOS app that connects to your Photos library via PhotoKit and uses Apple's on-device Vision framework to automatically tag, group, and search your photos — with no data leaving your device.

## Features

- **Smart Albums** — auto-generated albums from Vision content tags (e.g. "beach", "food", "dog")
- **People** — face detection and clustering using Vision feature-print embeddings; rename any cluster
- **Locations** — photos grouped by reverse-geocoded city/country using Apple's CLGeocoder
- **Search** — full-text search across tags, places, dates, and people names
- **Analysis Cache** — tags and locations are persisted to disk; subsequent launches are instant

Everything runs locally on-device. The only network request is a standard reverse-geocoding lookup through Apple's CLGeocoder (GPS coordinate only — no photo data is sent).

## Requirements

- Xcode 15 or later (tested on Xcode 26.1)
- iOS 16.0+ deployment target
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A real device or Simulator with iOS 16+

## Getting Started

### 1. Clone the repository

```bash
git clone git@github.com:Jaynoel91/PhotoOrganizer.git
cd PhotoOrganizer
```

### 2. Generate the Xcode project

The `.xcodeproj` is generated from `project.yml` using xcodegen. Install it if you haven't already:

```bash
brew install xcodegen
xcodegen generate
```

### 3. Open in Xcode

```bash
open PhotoOrganizer.xcodeproj
```

Select a simulator or your connected device and press **Run** (⌘R).

## Building from the Command Line

### Simulator

```bash
xcodebuild build \
  -project PhotoOrganizer.xcodeproj \
  -scheme PhotoOrganizer \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO
```

### Real device

Replace `YOUR_DEVICE_NAME` with the name of your connected iPhone:

```bash
xcodebuild build \
  -project PhotoOrganizer.xcodeproj \
  -scheme PhotoOrganizer \
  -destination "platform=iOS,name=YOUR_DEVICE_NAME" \
  -allowProvisioningUpdates
```

Then install the built `.app` directly:

```bash
APP=$(find ~/Library/Developer/Xcode/DerivedData/PhotoOrganizer-*/Build/Products/Debug-iphoneos -name "PhotoOrganizer.app" | head -1)
xcrun devicectl device install app --device YOUR_DEVICE_UDID "$APP"
```

> **First-time device trust:** Go to **Settings → General → VPN & Device Management**, tap your developer certificate, and tap **Trust**. This is a one-time step per device.

## Project Structure

```
PhotoOrganizer/
├── project.yml                  # xcodegen project spec
├── App/
│   ├── PhotoOrganizerApp.swift  # @main entry point
│   └── Assets.xcassets/         # App icon (1024×1024 universal)
├── Models/
│   ├── PhotoAsset.swift         # Wraps PHAsset with analysis results
│   └── PersonCluster.swift      # Face cluster with name and representative embedding
├── Services/
│   ├── PhotoLibraryManager.swift  # PhotoKit access, orchestrates analysis
│   ├── ImageAnalyzer.swift        # VNClassifyImageRequest + VNDetectFaceRectanglesRequest
│   ├── FaceClusteringService.swift # Cosine-distance face matching (threshold: 0.62)
│   ├── LocationService.swift      # CLGeocoder reverse-geocoding with cache
│   └── AnalysisCache.swift        # JSON persistence for tags and locations
├── Utilities/
│   └── CropUtility.swift          # Face-region cropping helpers
├── Views/
│   ├── ContentView.swift          # Root tab view
│   ├── AllPhotosGridView.swift    # Paginated photo grid
│   ├── AlbumViews.swift           # Smart album list and detail
│   ├── SmartAlbumsView.swift      # Albums grouped by tag
│   ├── PeopleViews.swift          # People tab and cluster detail
│   ├── PhotoDetailView.swift      # Full-screen photo with metadata
│   ├── SearchView.swift           # Cross-category search
│   ├── StatusViews.swift          # Permission and loading states
│   └── Components.swift           # Shared UI components
└── SupportingFiles/
    └── Info.plist                 # Privacy descriptions, bundle metadata
```

## Configuration

### Signing

`project.yml` is configured for automatic signing with team ID `929Y5D97SU`. To use your own team, update `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen generate`.

### Face clustering threshold

The match threshold is set to `0.62` in `Services/FaceClusteringService.swift`. Increase it if the same person is split into multiple clusters; decrease it if different people are merged together.

### Known limitations

- **Face clusters are session-scoped** — cluster names persist but cluster IDs are re-generated each launch. To persist clusters, extend `AnalysisCache` to serialize `VNFeaturePrintObservation` data.
- **People ≠ Apple's Photos People database** — this is an independent on-device implementation using Vision embeddings, not the private Photos identity graph.
- **Large libraries** — first-launch analysis of 10,000+ photos takes a while; tags and locations are cached afterward.

## License

MIT
