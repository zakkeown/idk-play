import SwiftUI

/// Replay view for an archived session. Tapping a song opens its link in the
/// system's native handler (YouTube app via universal link, else Safari).
struct SessionDetailView: View {
    @Environment(\.openURL) private var openURL
    let session: PracticeSession

    var body: some View {
        List {
            Section {
                ForEach(session.sortedEntries) { entry in
                    Button {
                        if let url = entry.url { openURL(url) }
                    } label: {
                        SessionEntryRow(entry: entry)
                    }
                    .tint(.primary)
                    .disabled(entry.url == nil)
                }
            } header: {
                Text("\(session.sortedEntries.count) songs · \(session.totalSeconds.asDurationString)")
            } footer: {
                Text("Tap a song to open its link.")
            }
        }
        .navigationTitle(session.title.isEmpty ? "Session" : session.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SessionEntryRow: View {
    let entry: SessionEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .lineLimit(1)
                if !entry.tags.isEmpty {
                    Text(entry.tags.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(entry.durationSeconds.asDurationString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Image(systemName: "arrow.up.forward.app")
                .foregroundStyle(entry.url == nil ? Color.secondary : Color.accentColor)
        }
    }
}
