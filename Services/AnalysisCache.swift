import Foundation

struct CachedEntry: Codable {
    var tags: [String]
    var locationName: String?
}

/// Persists content tags and location names to a JSON file in the app's
/// Documents directory, keyed by PHAsset.localIdentifier. Face detection
/// and person clustering are intentionally NOT cached here — see
/// SETUP.md for why people-clustering is session-scoped.
final class AnalysisCache {
    private let fileURL: URL
    private var store: [String: CachedEntry] = [:]
    private var dirtyCount = 0

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("photo_analysis_cache.json")
        load()
    }

    func entry(for id: String) -> CachedEntry? {
        store[id]
    }

    func save(id: String, tags: [String], locationName: String?) {
        store[id] = CachedEntry(tags: tags, locationName: locationName)
        dirtyCount += 1
        if dirtyCount >= 25 {
            persist()
            dirtyCount = 0
        }
    }

    /// Force a write to disk. Call after a batch analysis pass completes.
    func flush() {
        persist()
        dirtyCount = 0
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: CachedEntry].self, from: data)
        else { return }
        store = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(store) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
