import SwiftUI

struct AllPhotosGridView: View {
    @EnvironmentObject var library: PhotoLibraryManager
    @State private var selected: PhotoAsset?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(library.photos) { photo in
                        PhotoThumbnailView(asset: photo.asset)
                            .onTapGesture { selected = photo }
                    }
                }
            }
            .navigationTitle("Library (\(library.photos.count))")
            .sheet(item: $selected) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }
}
