import Vision
import Foundation

/// Groups detected faces into clusters of "the same person" using Vision's
/// on-device feature-print embeddings. There is no per-identity ground
/// truth here — it's nearest-neighbor matching against representative
/// embeddings seen so far in this session.
///
/// Tune `matchThreshold` if you find people being split into multiple
/// clusters (raise it) or different people being merged (lower it).
actor FaceClusteringService {
    static let shared = FaceClusteringService()

    private struct ClusterRecord {
        let id: String
        var representativePrint: VNFeaturePrintObservation
    }

    private var clusters: [ClusterRecord] = []
    private let matchThreshold: Float = 0.62

    func assignCluster(to featurePrint: VNFeaturePrintObservation) -> String {
        for cluster in clusters {
            var distance: Float = 0
            do {
                try featurePrint.computeDistance(&distance, to: cluster.representativePrint)
            } catch {
                continue
            }
            if distance < matchThreshold {
                return cluster.id
            }
        }

        let newID = UUID().uuidString
        clusters.append(ClusterRecord(id: newID, representativePrint: featurePrint))
        return newID
    }

    /// Clears all known clusters. Call this if the user wants to re-run
    /// face grouping from scratch (e.g. exposed as a "Reset People" action).
    func reset() {
        clusters.removeAll()
    }
}
