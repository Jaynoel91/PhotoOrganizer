import SwiftUI
import Photos

struct ContentView: View {
    @EnvironmentObject var library: PhotoLibraryManager

    var body: some View {
        Group {
            switch library.authorizationStatus {
            case .authorized, .limited:
                MainTabView()
            case .notDetermined:
                PermissionRequestView()
            default:
                PermissionDeniedView()
            }
        }
        .task {
            if library.authorizationStatus == .notDetermined {
                await library.requestAccess()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var library: PhotoLibraryManager

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                AllPhotosGridView()
                    .tabItem { Label("Library", systemImage: "photo.on.rectangle") }

                SmartAlbumsView()
                    .tabItem { Label("Albums", systemImage: "square.stack") }

                PeopleView()
                    .tabItem { Label("People", systemImage: "person.2") }

                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
            }

            if library.isAnalyzing {
                AnalysisProgressBar(progress: library.analysisProgress)
                    .padding(.bottom, 49) // sit just above the tab bar
            }
        }
        .task {
            library.loadAssets()
            await library.analyzeAll()
        }
    }
}
