import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "music.note.list") }
            GenerateView()
                .tabItem { Label("Generate", systemImage: "wand.and.stars") }
            SessionListView()
                .tabItem { Label("Sessions", systemImage: "clock.arrow.circlepath") }
        }
        // Pull in anything the Share Extension queued while we were away.
        .onAppear { drainPendingImports(into: context) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { drainPendingImports(into: context) }
        }
    }
}
