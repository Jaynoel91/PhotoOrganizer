import SwiftUI

struct PhotoDetailView: View {
    let photo: PhotoAsset
    @StateObject private var loader = ThumbnailLoader()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Group {
                    if let image = loader.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .cornerRadius(12)

                if let date = photo.asset.creationDate {
                    Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                }
                if let location = photo.locationName {
                    Label(location, systemImage: "mappin.and.ellipse")
                }
                if photo.faceCount > 0 {
                    Label("\(photo.faceCount) face\(photo.faceCount == 1 ? "" : "s")", systemImage: "person.2")
                }
                if !photo.tags.isEmpty {
                    Text("Tags")
                        .font(.headline)
                    FlowTags(tags: photo.tags)
                }
            }
            .padding()
        }
        .onAppear {
            loader.load(asset: photo.asset, size: CGSize(width: 1200, height: 1200))
        }
    }
}
