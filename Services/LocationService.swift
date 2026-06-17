import CoreLocation

/// Turns a photo's embedded GPS coordinate into a human-readable place name
/// ("San Francisco, United States"). Uses Apple's on-device/Apple Maps
/// reverse geocoder — no third-party network calls. Results are cached by
/// rounded coordinate so revisiting the same neighborhood doesn't re-hit
/// the geocoder for every photo.
actor LocationService {
    static let shared = LocationService()

    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:]

    func name(for location: CLLocation) async -> String? {
        let key = roundedKey(for: location)
        if let cached = cache[key] {
            return cached
        }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            let parts = [placemark.locality, placemark.country].compactMap { $0 }
            let name = parts.joined(separator: ", ")
            guard !name.isEmpty else { return nil }
            cache[key] = name
            return name
        } catch {
            return nil
        }
    }

    private func roundedKey(for location: CLLocation) -> String {
        let lat = (location.coordinate.latitude * 100).rounded() / 100
        let lon = (location.coordinate.longitude * 100).rounded() / 100
        return "\(lat),\(lon)"
    }
}
