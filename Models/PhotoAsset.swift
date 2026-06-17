import Foundation
import Photos

/// A lightweight wrapper around PHAsset with cached analysis results
/// (content tags, reverse-geocoded location, and detected faces).
struct PhotoAsset: Identifiable {
    let id: String
    let asset: PHAsset

    var tags: [String] = []
    var locationName: String?
    var faceCount: Int = 0
    var personClusterIDs: [String] = []
}

extension PhotoAsset: Equatable {
    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.id == rhs.id
    }
}

extension PhotoAsset: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
