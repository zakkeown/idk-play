import SwiftUI
import SwiftData

struct SessionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PracticeSession.dateCreated, order: .reverse) private var sessions: [PracticeSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Generate a practice session and save it — it'll be archived here to do again.")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title.isEmpty ? "Session" : session.title)
                                        .lineLimit(1)
                                    Text("\(session.sortedEntries.count) songs · \(session.totalSeconds.asDurationString)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Sessions")
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index])
        }
    }
}
