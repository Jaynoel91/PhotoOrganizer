import SwiftUI
import Photos
import UIKit

struct PeopleView: View {
    @EnvironmentObject var library: PhotoLibraryManager

    private var clusters: [PersonCluster] {
        library.personClusters.values.sorted { $0.photoIDs.count > $1.photoIDs.count }
    }

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if clusters.isEmpty {
                    ContentUnavailableHint(
                        systemImage: "person.2",
                        message: "People appear here as your photos finish analyzing"
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(clusters) { cluster in
                            NavigationLink(destination: PersonDetailView(clusterID: cluster.id)) {
                                VStack(spacing: 6) {
                                    FaceThumbnailView(cluster: cluster)
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                    Text(cluster.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Text("\(cluster.photoIDs.count) photos")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("People")
        }
    }
}

/// Loads the representative asset and crops it to the stored face box.
struct FaceThumbnailView: View {
    let cluster: PersonCluster
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle().fill(Color.gray.opacity(0.15))
            }
        }
        .task { await loadFace() }
    }

    private func loadFace() async {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [cluster.representativeAssetID], options: nil)
        guard let asset = fetchResult.firstObject else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let fullImage: UIImage? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 600, height: 600),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }

        guard let cgImage = fullImage?.cgImage,
              let cropped = CropUtility.crop(cgImage: cgImage, normalizedRect: cluster.representativeFaceBox) else { return }
        image = UIImage(cgImage: cropped)
    }
}

struct PersonDetailView: View {
    @EnvironmentObject var library: PhotoLibraryManager
    let clusterID: String
    @State private var selected: PhotoAsset?
    @State private var showRename = false
    @State private var newName = ""

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    private var cluster: PersonCluster? { library.personClusters[clusterID] }
    private var photos: [PhotoAsset] {
        guard let cluster else { return [] }
        return library.photos.filter { cluster.photoIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos) { photo in
                    PhotoThumbnailView(asset: photo.asset)
                        .onTapGesture { selected = photo }
                }
            }
        }
        .navigationTitle(cluster?.name ?? "Person")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Rename") {
                    newName = cluster?.name ?? ""
                    showRename = true
                }
            }
        }
        .alert("Rename Person", isPresented: $showRename) {
            TextField("Name", text: $newName)
            Button("Save") { library.personClusters[clusterID]?.name = newName }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $selected) { photo in
            PhotoDetailView(photo: photo)
        }
    }
}
