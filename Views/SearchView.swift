import SwiftUI

struct SearchView: View {
    @EnvironmentObject var library: PhotoLibraryManager
    @State private var query: String = ""
    @State private var selected: PhotoAsset?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var results: [PhotoAsset] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        return library.photos.filter { photo in
            if photo.tags.contains(where: { $0.lowercased().contains(trimmed) }) {
                return true
            }
            if let location = photo.locationName, location.lowercased().contains(trimmed) {
                return true
            }
            if let date = photo.asset.creationDate,
               dateFormatter.string(from: date).lowercased().contains(trimmed) {
                return true
            }
            let matchesPerson = photo.personClusterIDs.contains { clusterID in
                library.personClusters[clusterID]?.name.lowercased().contains(trimmed) ?? false
            }
            return matchesPerson
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if query.isEmpty {
                    ContentUnavailableHint()
                } else if results.isEmpty {
                    Text("No photos match \"\(query)\"")
                        .foregroundStyle(.secondary)
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(results) { photo in
                            PhotoThumbnailView(asset: photo.asset)
                                .onTapGesture { selected = photo }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Tags, places, dates, people")
            .sheet(item: $selected) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }
}
