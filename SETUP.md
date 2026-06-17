# Photo Organizer — Setup Guide

A native SwiftUI iOS app that connects to your real Photos library via
PhotoKit, then uses Apple's on-device Vision framework to:

- **Tag content automatically** (e.g. "dog", "beach", "food") and turn
  recurring tags into Smart Albums
- **Group photos by month/year** and by reverse-geocoded **location**
- **Detect and cluster faces** into a People tab (rename any cluster)
- **Search** across tags, places, dates, and person names

Everything runs locally on-device — no photo data or images are sent
anywhere except a standard reverse-geocoding lookup through Apple's own
geocoder (which sends only the GPS coordinate, not the photo).

## 1. Create the Xcode project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Product Name: `PhotoOrganizer`, Interface: **SwiftUI**, Language: **Swift**
4. Set the deployment target to **iOS 16.0** or later (the app uses
   `NavigationStack`, `.searchable`, and async/await PhotoKit APIs)

## 2. Add the provided files

Delete the default `ContentView.swift` Xcode generated, then drag the
`App`, `Models`, `Services`, `Utilities`, and `Views` folders from this
download into your Xcode project navigator. Make sure **"Copy items if
needed"** is checked and your app target is selected.

Delete the auto-generated `PhotoOrganizerApp.swift` if Xcode created one
for you — use the one provided here as the single `@main` entry point.

## 3. Add required Info.plist / Privacy entries

In your target's **Info** tab (or `Info.plist`), add:

| Key | Value |
|---|---|
| Privacy - Photo Library Usage Description | "Photo Organizer analyzes your photos on-device to build smart albums and find faces." |
| Privacy - Photo Library Additions Usage Description | "Used if you ever save edits back to your library." |

These are required — without them, the app will crash immediately when
it requests access.

## 4. Build & run

Run on a real device for the most realistic library, or the Simulator
(which ships with a small bundled set of sample photos under
Settings → bundled photos, or you can drag images into the Simulator's
Photos app). Vision and face detection work fine in Simulator.

The first launch will:
1. Ask for photo library permission
2. Load all image assets
3. Run Vision analysis across your library (you'll see a progress bar)
   — this can take a while for large libraries; tags and locations are
   cached to disk afterward, so subsequent launches are fast.

## How it works

- **`Services/PhotoLibraryManager.swift`** — the `ObservableObject` that
  owns PhotoKit access, the photo array, and orchestrates analysis.
- **`Services/ImageAnalyzer.swift`** — runs `VNClassifyImageRequest`
  (content tags) and `VNDetectFaceRectanglesRequest` (faces) per photo.
- **`Services/FaceClusteringService.swift`** — matches detected faces to
  existing "people" using Vision feature-print embeddings and a cosine
  distance threshold (`matchThreshold`, currently `0.62`). This is a
  heuristic, not Apple's private People database — tune the threshold in
  this file if people are split into too many clusters (raise it) or
  different people are merged (lower it).
- **`Services/LocationService.swift`** — reverse-geocodes each photo's
  embedded GPS coordinate into a city/country name, with caching.
- **`Services/AnalysisCache.swift`** — persists tags/locations to a JSON
  file in the app's Documents directory so they don't need to be
  recomputed on every launch.

### Known limitations (by design, for a first version)

- **Face clustering is session-scoped.** Cluster *names* you assign
  persist for the life of the cluster `id`, but cluster IDs themselves
  aren't currently saved across launches, so re-grouping happens fresh
  each session. To persist clusters permanently, you'd extend
  `AnalysisCache` to also serialize each cluster's representative
  `VNFeaturePrintObservation` (it's `NSSecureCoding`-compliant) and feed
  those back into `FaceClusteringService` on launch.
- **"People" here means visually similar faces, not Apple's identity
  graph** — there's no public API for the real Photos People database,
  so this is a from-scratch on-device implementation.
- Large libraries (10,000+ photos) will take a while on first analysis;
  consider adding a "Analyze Recent First" toggle if that matters to you.

### If you hit Swift concurrency errors

Newer Xcode versions can default new projects to the strict Swift 6
concurrency model, which may flag passing `PHAsset`/`UIImage` across
`await` boundaries. If you see concurrency errors, go to your target's
**Build Settings → Swift Language Version** and set it to **Swift 5** —
the app's logic doesn't need Swift 6's strict checking.
