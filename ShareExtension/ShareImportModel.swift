import Foundation

/// State for the share confirm sheet: the editable draft fields plus the in-flight
/// YouTube length lookup. Built from a parsed ``SongDraft``; produces an updated
/// draft on save. All mutation is on the main actor (it's bound straight to UI).
@MainActor
final class ShareImportModel: ObservableObject {
    @Published var title: String
    @Published var seconds: Int
    @Published var tags: [String]
    @Published var isFetchingLength = false

    let urlString: String
    let source: LinkSource

    private let draftID: UUID
    private let durationProvider: YouTubeDurationProviding
    private let onSaveDraft: (SongDraft) -> Void
    let onCancel: () -> Void

    init(
        draft: SongDraft,
        durationProvider: YouTubeDurationProviding,
        onSave: @escaping (SongDraft) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.draftID = draft.id
        self.title = draft.title
        self.seconds = draft.durationSeconds
        self.tags = draft.tags
        self.urlString = draft.urlString
        self.source = LinkSource(urlString: draft.urlString) ?? .web
        self.durationProvider = durationProvider
        self.onSaveDraft = onSave
        self.onCancel = onCancel
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// If this is a YouTube link with no length yet, fetch it in the background and
    /// fill it in (without clobbering a length the user has started typing).
    func fetchLengthIfNeeded() {
        guard seconds == 0, source == .youtube, let id = YouTube.videoID(from: urlString) else { return }
        isFetchingLength = true
        Task {
            let fetched = await durationProvider.durationSeconds(forVideoID: id)
            if let fetched, seconds == 0 { seconds = fetched }
            isFetchingLength = false
        }
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    func save() {
        onSaveDraft(SongDraft(
            id: draftID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            urlString: urlString,
            durationSeconds: seconds,
            tags: tags
        ))
    }
}
