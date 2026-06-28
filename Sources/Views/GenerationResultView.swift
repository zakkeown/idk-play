import SwiftUI

/// Renders an editable generated list as Form sections (preview + reorder/add/delete
/// + actions). The `session` binding is the working copy the user can hand-tune before
/// archiving; `shortfalls` describe the original generation and clear on first edit.
struct GenerationResultView: View {
    @Binding var session: EditableSession
    let shortfalls: [GenerationResult.Shortfall]
    /// Full library pool, used to offer songs not already in the list.
    let libraryCandidates: [SongCandidate]
    /// Called whenever the user hand-edits the list (reorder/add/remove), so the
    /// caller can drop now-stale generation shortfalls.
    var onEdit: () -> Void
    var onRegenerate: () -> Void
    var onSave: () -> Void

    private var addable: [SongCandidate] {
        session.candidatesNotIncluded(from: libraryCandidates)
    }

    var body: some View {
        Section {
            HStack {
                Text("Total")
                Spacer()
                Text(session.totalSeconds.asDurationString)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(LinearGradient.brand)
            }
            Text("\(session.entries.count) song\(session.entries.count == 1 ? "" : "s")")
                .foregroundStyle(.secondary)
        } header: {
            Text("Result")
        }

        if !shortfalls.isEmpty {
            Section {
                ForEach(Array(shortfalls.enumerated()), id: \.offset) { _, issue in
                    Label(issue.message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }
            } footer: {
                Text("This is the best list possible with the current criteria.")
            }
        }

        if !session.entries.isEmpty {
            Section {
                ForEach(session.entries) { candidate in
                    CandidateRow(candidate: candidate)
                }
                .onMove { session.move(fromOffsets: $0, toOffset: $1); onEdit() }
                .onDelete { session.remove(atOffsets: $0); onEdit() }
            } header: {
                HStack {
                    Text("Songs")
                    Spacer()
                    EditButton().font(.callout.weight(.regular)).textCase(nil)
                }
            } footer: {
                Text("Drag to reorder, swipe to remove.")
            }
        }

        if !addable.isEmpty {
            Section {
                Menu {
                    ForEach(addable) { candidate in
                        Button(candidate.title.isEmpty ? "Untitled" : candidate.title) {
                            session.add(candidate)
                            onEdit()
                        }
                    }
                } label: {
                    Label("Add a song", systemImage: "plus.circle")
                }
                .accessibilityIdentifier("addSongToSessionButton")
            }
        }

        Section {
            Button("Regenerate", action: onRegenerate)
            Button("Save to archive", action: onSave)
                .disabled(session.entries.isEmpty)
                .accessibilityIdentifier("saveToArchiveButton")
        }
    }
}

private struct CandidateRow: View {
    let candidate: SongCandidate

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.title.isEmpty ? "Untitled" : candidate.title)
                    .lineLimit(1)
                if !candidate.tags.isEmpty {
                    Text(candidate.tags.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(candidate.durationSeconds.asDurationString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
