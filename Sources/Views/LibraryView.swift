import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query private var songs: [Song]

    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var showingAdd = false
    @State private var editing: Song?

    private var filtered: [Song] {
        songs.filter { song in
            let matchesText = searchText.isEmpty
                || song.title.localizedCaseInsensitiveContains(searchText)
            let matchesTag = selectedTag == nil || song.tags.contains(selectedTag!)
            return matchesText && matchesTag
        }
        .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if songs.isEmpty {
                    ContentUnavailableView(
                        "No songs yet",
                        systemImage: "music.note",
                        description: Text("Add links to YouTube, Ultimate Guitar, or anything else you practice with.")
                    )
                } else {
                    List {
                        if !songs.distinctTags.isEmpty {
                            tagFilterBar
                        }
                        ForEach(filtered) { song in
                            Button { editing = song } label: {
                                SongRow(song: song)
                            }
                            .tint(.primary)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search titles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("addSongButton")
                }
            }
            .sheet(isPresented: $showingAdd) { SongEditView(song: nil) }
            .sheet(item: $editing) { song in SongEditView(song: song) }
        }
    }

    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(songs.distinctTags, id: \.self) { tag in
                    Button {
                        selectedTag = (selectedTag == tag) ? nil : tag
                    } label: {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(
                                    selectedTag == tag
                                        ? Color.accentColor
                                        : Color.accentColor.opacity(0.15)
                                )
                            )
                            .foregroundStyle(selectedTag == tag ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filtered[index])
        }
    }
}

private struct SongRow: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(song.title.isEmpty ? "Untitled" : song.title)
                    .lineLimit(1)
                Spacer()
                Text(song.durationSeconds.asDurationString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            if !song.tags.isEmpty {
                Text(song.tags.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
