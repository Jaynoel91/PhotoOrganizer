import SwiftUI

@main
struct PhotoOrganizerApp: App {
    @StateObject private var library = PhotoLibraryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
        }
    }
}
