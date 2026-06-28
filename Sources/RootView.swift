import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "music.note.list") }
            GenerateView()
                .tabItem { Label("Generate", systemImage: "wand.and.stars") }
            SessionListView()
                .tabItem { Label("Sessions", systemImage: "clock.arrow.circlepath") }
        }
    }
}
