import SwiftUI

/// A pill showing a tag, optionally with a delete button.
struct TagChip: View {
    let text: String
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(text).font(.caption)
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.accentColor.opacity(0.15)))
    }
}

/// Editable set of tags: wrapping chips plus an "add tag" field.
struct TagInputField: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(text: tag) { remove(tag) }
                    }
                }
            }
            HStack {
                TextField("Add tag", text: $newTag)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(add)
                Button("Add", action: add)
                    .disabled(normalized(newTag).isEmpty)
            }
        }
    }

    private func add() {
        let tag = normalized(newTag)
        guard !tag.isEmpty, !tags.contains(tag) else { newTag = ""; return }
        tags.append(tag)
        newTag = ""
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func normalized(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// Minimal wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? widest : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
