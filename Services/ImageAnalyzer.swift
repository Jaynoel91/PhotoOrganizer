import Vision
import Photos
import UIKit

/// One detected face, paired with the person-cluster ID it was matched to.
struct DetectedFace {
    let clusterID: String
    let box: CGRect // Vision-normalized, bottom-left origin
}

struct AnalysisResult {
    var tags: [String] = []
    var faceCount: Int = 0
    var faces: [DetectedFace] = []
}

/// Runs on-device Vision requests against a single PHAsset: image
/// classification (for content tags / smart albums) and face detection
/// (for the People tab). Everything here runs locally — no photo data
/// ever leaves the device.
final class ImageAnalyzer {
    /// - Parameter skipClassification: pass `true` when tags for this asset
    ///   are already cached, to avoid redundant Vision classification work.
    ///   Face detection still runs every time since clustering is session-scoped.
    func analyze(asset: PHAsset, skipClassification: Bool) async -> AnalysisResult {
        guard let image = await Self.loadAnalysisImage(asset: asset),
              let cgImage = image.cgImage else {
            return AnalysisResult()
        }

        var result = AnalysisResult()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)

        let faceRequest = VNDetectFaceRectanglesRequest()
        let classifyRequest = VNClassifyImageRequest()
        var requests: [VNRequest] = [faceRequest]
        if !skipClassification {
            requests.append(classifyRequest)
        }

        do {
            try handler.perform(requests)
        } catch {
            return result
        }

        if !skipClassification, let observations = classifyRequest.results {
            result.tags = observations
                .filter { $0.confidence > 0.25 }
                .sorted { $0.confidence > $1.confidence }
                .prefix(5)
                .map { $0.identifier.replacingOccurrences(of: "_", with: " ") }
        }

        if let faceObservations = faceRequest.results {
            result.faceCount = faceObservations.count
            for face in faceObservations {
                if let cropped = CropUtility.crop(cgImage: cgImage, normalizedRect: face.boundingBox),
                   let print = await Self.featurePrint(for: cropped) {
                    let clusterID = await FaceClusteringService.shared.assignCluster(to: print)
                    result.faces.append(DetectedFace(clusterID: clusterID, box: face.boundingBox))
                }
            }
        }

        return result
    }

    /// Loads a downscaled image suitable for analysis (Vision doesn't need
    /// full resolution, and this keeps memory/CPU use reasonable across a
    /// large library).
    private static func loadAnalysisImage(asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 800, height: 800),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    private static func featurePrint(for cgImage: CGImage) async -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        do {
            try handler.perform([request])
            return request.results?.first
        } catch {
            return nil
        }
    }
}
