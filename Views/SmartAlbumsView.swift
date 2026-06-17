import SwiftUI

struct SmartAlbumsView: View {
    @EnvironmentObject var library: PhotoLibraryManager

    /// Tag albums only show up once there are at least 3 matching photos,
    /// so the list isn't cluttered with one-off classifications.
    private var tagAlbums: [(name: String, photos: [PhotoAsset])] {
        var dict: [String: [PhotoAsset]] = [:]
        for photo in library.photos {
            for tag in photo.tags {
                dict[tag, default: []].append(photo)
            }
        }
        return dict
            .filter { $0.value.count >= 3 }
            .sorted { $0.value.count > $1.value.count }
            .map { (name: $0.key.capitalized, photos: $0.value) }
    }

    private var locationAlbums: [(name: String, photos: [PhotoAsset])] {
        var dict: [String: [PhotoAsset]] = [:]
        for photo in library.photos {
            guard let location = photo.locationName else { continue }
            dict[location, default: []].append(photo)
        }
        return dict
            .sorted { $0.value.count > $1.value.count }
            .map { (name: $0.key, photos: $0.value) }
    }

    private var dateAlbums: [(name: String, photos: [PhotoAsset])] {
        var dict: [String: [PhotoAsset]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        for photo in library.photos {
            guard let date = photo.asset.creationDate else { continue }
            dict[formatter.string(from: date), default: []].append(photo)
        }
        return dict
            .sorted { (lhs, rhs) in
                let lhsDate = lhs.value.first?.asset.creationDate ?? .distantPast
                let rhsDate = rhs.value.first?.asset.creationDate ?? .distantPast
                return lhsDate > rhsDate
            }
            .map { (name: $0.key, photos: $0.value) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !dateAlbums.isEmpty {
                    Section("By Date") {
                        ForEach(dateAlbums, id: \.name) { album in
                            NavigationLink(destination: AlbumDetailView(title: album.name, photos: album.photos)) {
                                AlbumRow(title: album.name, count: album.photos.count, coverAsset: album.photos.first?.asset)
                            }
                        }
                    }
                }
                if !tagAlbums.isEmpty {
                    Section("By Content") {
                        ForEach(tagAlbums, id: \.name) { album in
                            NavigationLink(destination: AlbumDetailView(title: album.name, photos: album.photos)) {
                                AlbumRow(title: album.name, count: album.photos.count, coverAsset: album.photos.first?.asset)
                            }
                        }
                    }
                }
                if !locationAlbums.isEmpty {
                    Section("By Location") {
                        ForEach(locationAlbums, id: \.name) { album in
                            NavigationLink(destination: AlbumDetailView(title: album.name, photos: album.photos)) {
                                AlbumRow(title: album.name, count: album.photos.count, coverAsset: album.photos.first?.asset)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Smart Albums")
            .overlay {
                if dateAlbums.isEmpty && tagAlbums.isEmpty && locationAlbums.isEmpty {
                    ContentUnavailableHint(
                        systemImage: "square.stack",
                        message: "Smart albums appear here once your photos finish analyzing"
                    )
                }
            }
        }
    }
}
