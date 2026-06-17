import Foundation
import Photos

@MainActor
final class PhotoLibraryManager: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus
    @Published var photos: [PhotoAsset] = []
    @Published var personClusters: [String: PersonCluster] = [:]
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0

    private let analyzer = ImageAnalyzer()
    private let cache = AnalysisCache()
    private var hasLoaded = false

    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccess() async {
        authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    /// Fetches all image assets from the library. Cheap metadata only —
    /// tags/locations are filled in from cache if available, otherwise
    /// left empty until `analyzeAll()` runs.
    func loadAssets() {
        guard !hasLoaded else { return }
        hasLoaded = true

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)

        var loaded: [PhotoAsset] = []
        loaded.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            var photo = PhotoAsset(id: asset.localIdentifier, asset: asset)
            if let cached = self.cache.entry(for: photo.id) {
                photo.tags = cached.tags
                photo.locationName = cached.locationName
            }
            loaded.append(photo)
        }
        photos = loaded
    }

    /// Runs Vision analysis (tags + faces) across the whole library.
    /// Tags/locations are skipped for assets already in the disk cache;
    /// face detection and clustering always run since people-grouping is
    /// session-scoped (see SETUP.md).
    func analyzeAll() async {
        guard !photos.isEmpty else { return }
        isAnalyzing = true
        defer {
            isAnalyzing = false
            cache.flush()
        }

        let total = photos.count
        for index in photos.indices {
            let id = photos[index].id
            let asset = photos[index].asset
            let alreadyTagged = cache.entry(for: id) != nil

            let result = await analyzer.analyze(asset: asset, skipClassification: alreadyTagged)

            if !alreadyTagged {
                photos[index].tags = result.tags
                if let location = asset.location {
                    photos[index].locationName = await LocationService.shared.name(for: location)
                }
                cache.save(id: id, tags: photos[index].tags, locationName: photos[index].locationName)
            }

            photos[index].faceCount = result.faceCount
            photos[index].personClusterIDs = result.faces.map { $0.clusterID }
            registerClusters(for: photos[index], faces: result.faces)

            analysisProgress = Double(index + 1) / Double(total)
        }
    }

    private func registerClusters(for photo: PhotoAsset, faces: [DetectedFace]) {
        for face in faces {
            if personClusters[face.clusterID] != nil {
                personClusters[face.clusterID]?.photoIDs.insert(photo.id)
            } else {
                personClusters[face.clusterID] = PersonCluster(
                    id: face.clusterID,
                    name: "Person \(personClusters.count + 1)",
                    representativeAssetID: photo.id,
                    representativeFaceBox: face.box,
                    photoIDs: [photo.id]
                )
            }
        }
    }
}
