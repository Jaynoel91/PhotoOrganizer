import SwiftUI
import Photos
import UIKit

/// Loads a thumbnail UIImage for a PHAsset using PHCachingImageManager.
@MainActor
final class ThumbnailLoader: ObservableObject {
    @Published var image: UIImage?
    private static let manager = PHCachingImageManager()

    func load(asset: PHAsset, size: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        Self.manager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            self?.image = image
        }
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    var size: CGFloat = 110
    @StateObject private var loader = ThumbnailLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(Color.gray.opacity(0.15))
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .onAppear {
            loader.load(asset: asset, size: CGSize(width: size * 2, height: size * 2))
        }
    }
}

/// Wrapping chip layout for displaying content tags.
struct FlowTags: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}

struct ContentUnavailableHint: View {
    var systemImage: String = "magnifyingglass"
    var message: String = "Search by tag, place, date, or a person's name"

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}
