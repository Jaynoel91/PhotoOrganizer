import SwiftUI
import UIKit

struct PermissionRequestView: View {
    @EnvironmentObject var library: PhotoLibraryManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Photo Organizer needs access to your photo library to build smart albums, detect faces, and tag your photos — all on-device.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Grant Access") {
                Task { await library.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Photo access was denied. Enable it in Settings to use Photo Organizer.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding()
    }
}

struct AnalysisProgressBar: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 4) {
            ProgressView(value: progress)
            Text("Analyzing photos… \(Int(progress * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
