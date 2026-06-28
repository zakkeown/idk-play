import SwiftUI

/// Renders a ``GenerationResult`` as Form sections (preview + actions).
struct GenerationResultView: View {
    let result: GenerationResult
    var onRegenerate: () -> Void
    var onSave: () -> Void

    var body: some View {
        Section {
            HStack {
                Text("Total")
                Spacer()
                Text(result.totalSeconds.asDurationString)
                    .bold()
                    .monospacedDigit()
            }
            Text("\(result.entries.count) song\(result.entries.count == 1 ? "" : "s")")
                .foregroundStyle(.secondary)
        } header: {
            Text("Result")
        }

        if !result.shortfalls.isEmpty {
            Section {
                ForEach(Array(result.shortfalls.enumerated()), id: \.offset) { _, issue in
                    Label(issue.message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }
            } footer: {
                Text("This is the best list possible with the current criteria.")
            }
        }

        if !result.entries.isEmpty {
            Section("Songs") {
                ForEach(result.entries) { candidate in
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
        }

        Section {
            Button("Regenerate", action: onRegenerate)
            Button("Save to archive", action: onSave)
                .disabled(result.entries.isEmpty)
                .accessibilityIdentifier("saveToArchiveButton")
        }
    }
}
