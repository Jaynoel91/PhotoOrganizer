import SwiftUI
import Photos

struct AlbumRow: View {
    let title: String
    let count: Int
    let coverAsset: PHAsset?

    var body: some View {
        HStack(spacing: 12) {
            if let coverAsset {
                PhotoThumbnailView(asset: coverAsset, size: 50)
                    .cornerRadius(8)
            }
            VStack(alignment: .leading) {
                Text(title).font(.body)
                Text("\(count) photo\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AlbumDetailView: View {
    let title: String
    let photos: [PhotoAsset]
    @State private var selected: PhotoAsset?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos) { photo in
                    PhotoThumbnailView(asset: photo.asset)
                        .onTapGesture { selected = photo }
                }
            }
        }
        .navigationTitle(title)
        .sheet(item: $selected) { photo in
            PhotoDetailView(photo: photo)
        }
    }
}
