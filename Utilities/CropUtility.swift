import CoreGraphics

enum CropUtility {
    /// Crops `cgImage` using a Vision-style normalized rect (origin at the
    /// bottom-left, values 0...1) and returns the resulting CGImage.
    static func crop(cgImage: CGImage, normalizedRect: CGRect) -> CGImage? {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let rect = CGRect(
            x: normalizedRect.origin.x * width,
            y: (1 - normalizedRect.origin.y - normalizedRect.height) * height,
            width: normalizedRect.width * width,
            height: normalizedRect.height * height
        ).integral

        // Clamp to image bounds defensively — Vision boxes can occasionally
        // extend a pixel or two past the edge due to rounding.
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let clamped = rect.intersection(bounds)
        guard !clamped.isEmpty else { return nil }

        return cgImage.cropping(to: clamped)
    }
}
