import SwiftUI
import SwiftData

@main
struct IDKPlayApp: App {
    let container: ModelContainer = IDKPlayApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    /// Build the store backed by CloudKit, falling back to a local-only store when
    /// CloudKit isn't available (e.g. the simulator here, with no signed-in iCloud
    /// account or provisioned container). Real cross-device sync activates once the
    /// app is built with a signing team that has the iCloud capability.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Song.self, PracticeSession.self, SessionEntry.self])

        // UI tests pass `-uitest-ephemeral-store` so each run starts from an empty,
        // in-memory library — the simulator otherwise persists data across launches,
        // making count-based assertions flaky.
        if ProcessInfo.processInfo.arguments.contains("-uitest-ephemeral-store") {
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: memory)
        }

        do {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: cloud)
        } catch {
            print("⚠️ CloudKit store unavailable (\(error)); using local-only store.")
            do {
                let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                return try ModelContainer(for: schema, configurations: local)
            } catch {
                fatalError("Failed to create local ModelContainer: \(error)")
            }
        }
    }
}
