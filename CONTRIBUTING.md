# Contributing to Photo Organizer

Thanks for your interest in contributing! This document covers how to set up the project locally, the branching workflow, and guidelines for submitting changes.

## Getting Started

### Prerequisites

- Xcode 15 or later
- iOS 16.0+ simulator or device
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Local setup

1. Fork the repository and clone your fork:
   ```bash
   git clone git@github.com:YOUR_USERNAME/PhotoOrganizer.git
   cd PhotoOrganizer
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open in Xcode and verify it builds:
   ```bash
   open PhotoOrganizer.xcodeproj
   ```

## Workflow

### Branching

- `main` is the stable branch — all releases are tagged here
- Create a feature or fix branch from `main`:
  ```bash
  git checkout -b feature/my-feature
  # or
  git checkout -b fix/issue-description
  ```

### Making changes

- Keep changes focused — one feature or fix per pull request
- Re-run `xcodegen generate` if you modify `project.yml`
- Build for both simulator and device before opening a PR:
  ```bash
  # Simulator (no signing required)
  xcodebuild build \
    -project PhotoOrganizer.xcodeproj \
    -scheme PhotoOrganizer \
    -destination "generic/platform=iOS Simulator" \
    CODE_SIGNING_ALLOWED=NO
  ```

### Committing

Write clear, concise commit messages in the imperative mood:

```
Add persistent face cluster storage across launches
Fix crash when photo library returns zero assets
Improve reverse-geocoding cache hit rate
```

### Opening a pull request

1. Push your branch to your fork:
   ```bash
   git push origin feature/my-feature
   ```
2. Open a PR against `Jaynoel91/PhotoOrganizer:main`
3. Fill in the PR description — what changed, why, and how to test it
4. Ensure the build passes before requesting review

## Areas to Contribute

Here are some well-scoped areas if you're looking for somewhere to start:

- **Persistent face clusters** — serialize `VNFeaturePrintObservation` data in `AnalysisCache` so cluster identities survive app restarts (see `Services/FaceClusteringService.swift`)
- **"Analyze Recent First" toggle** — process the most recent photos before older ones to show results faster on large libraries
- **iCloud Photos support** — handle `PHAsset` instances that aren't yet downloaded locally
- **Share sheet** — add a share button to `PhotoDetailView`
- **Accessibility** — improve VoiceOver labels on photo grids and face cluster views
- **Localization** — the app currently ships English only; UI strings are inline and could be extracted to `Localizable.strings`
- **UI tests** — no UI tests exist yet; XCTest-based snapshot or interaction tests are welcome

## Code Style

- Follow the existing Swift style in each file — no external formatter is enforced
- Prefer `async`/`await` over callback-based concurrency for new code
- Keep `ObservableObject` services free of UI imports (`SwiftUI`-free where possible)
- Add a brief comment above any non-obvious algorithm or threshold value (e.g. the `0.62` cosine distance threshold in `FaceClusteringService`)

## Reporting Issues

Open a [GitHub Issue](https://github.com/Jaynoel91/PhotoOrganizer/issues) with:
- iOS version and device model (or simulator)
- Steps to reproduce
- Expected vs. actual behaviour
- Any relevant console output or crash logs

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
