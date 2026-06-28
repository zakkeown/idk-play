import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selection = RootView.initialTab

    var body: some View {
        TabView(selection: $selection) {
            LibraryView()
                .tag(0)
                .tabItem { Label("Library", systemImage: "music.note.list") }
            GenerateView()
                .tag(1)
                .tabItem { Label("Generate", systemImage: "wand.and.stars") }
            SessionListView()
                .tag(2)
                .tabItem { Label("Sessions", systemImage: "clock.arrow.circlepath") }
        }
        .task { SampleData.seedIfNeeded(context) }
    }

    /// Optional `--start-tab <library|generate|sessions>` launch arg (for demos/tests).
    static var initialTab: Int {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "--start-tab"), i + 1 < args.count else { return 0 }
        switch args[i + 1] {
        case "generate": return 1
        case "sessions": return 2
        default: return 0
        }
    }
}
