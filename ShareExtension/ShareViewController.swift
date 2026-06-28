import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Principal class for the share extension (see Info.plist `NSExtensionPrincipalClass`).
/// It does as little as possible: pull the URL/text out of the share payload, hand them
/// to the tested ``ShareImportParser``, and host the SwiftUI confirm sheet. On save it
/// enqueues the draft into the App Group queue for the app to drain — it never opens the
/// SwiftData/CloudKit store itself.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        Task { await loadAndPresent() }
    }

    private func loadAndPresent() async {
        let payload = await extractSharedContent()
        guard let draft = ShareImportParser().draft(
            url: payload.url,
            text: payload.text,
            title: payload.title
        ) else {
            // Nothing usable was shared — finish without adding anything.
            complete()
            return
        }

        let model = ShareImportModel(
            draft: draft,
            durationProvider: YouTubeDurationFetcher(),
            onSave: { [weak self] finalDraft in
                SharedImportQueue.shared?.enqueue(finalDraft)
                self?.complete()
            },
            onCancel: { [weak self] in self?.cancel() }
        )
        host(ShareConfirmView(model: model))
    }

    // MARK: - Share payload extraction

    private struct Payload { var url: String?; var text: String?; var title: String? }

    /// Pull a URL and/or text out of the share items. Apps are inconsistent: some
    /// attach a `public.url`, some only a `public.plain-text` blob, some both — so we
    /// gather whatever is there and let the parser sort it out.
    private func extractSharedContent() async -> Payload {
        var payload = Payload()
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        for item in items {
            if payload.text == nil, let attributed = item.attributedContentText?.string, !attributed.isEmpty {
                payload.text = attributed
            }
            for provider in item.attachments ?? [] {
                if payload.url == nil, provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    payload.url = await loadURL(from: provider)?.absoluteString
                }
                if payload.text == nil, provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    payload.text = await loadText(from: provider)
                }
            }
        }
        return payload
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                continuation.resume(returning: item as? URL)
            }
        }
    }

    private func loadText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                continuation.resume(returning: item as? String)
            }
        }
    }

    // MARK: - Hosting & completion

    @MainActor
    private func host(_ view: some View) {
        let controller = UIHostingController(rootView: view)
        addChild(controller)
        controller.view.frame = self.view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(controller.view)
        controller.didMove(toParent: self)
    }

    private func complete() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func cancel() {
        extensionContext?.cancelRequest(
            withError: NSError(domain: "com.idkplay.IDKPlay.ShareExtension", code: NSUserCancelledError)
        )
    }
}
