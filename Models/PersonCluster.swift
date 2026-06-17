import CoreGraphics

/// Represents a cluster of faces that the app believes belong to the same
/// person, built purely on-device using Vision feature-print similarity.
/// This is a heuristic, not Apple's private "People" database, so it may
/// occasionally split one person into two clusters or merge two similar-
/// looking people. Users can rename clusters; renames are session-scoped
/// (see SETUP.md for notes on persistence).
struct PersonCluster: Identifiable {
    let id: String
    var name: String
    var representativeAssetID: String
    var representativeFaceBox: CGRect
    var photoIDs: Set<String>
}
