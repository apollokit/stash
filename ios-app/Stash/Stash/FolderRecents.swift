import SwiftUI
import Combine

// MARK: - Folder Recents
/// Tracks when each folder was last used (browsed, or picked as a save destination).
/// Stored locally in UserDefaults only - nothing is synced to the database.
class FolderRecents: ObservableObject {
    private static let defaultsKey = "folderLastUsed"

    @Published private var lastUsed: [String: Date]

    init() {
        let stored = UserDefaults.standard.dictionary(forKey: Self.defaultsKey) as? [String: Double] ?? [:]
        lastUsed = stored.mapValues { Date(timeIntervalSince1970: $0) }
    }

    func touch(_ folderId: String) {
        lastUsed[folderId] = Date()
        persist()
    }

    /// Drops entries for folders that no longer exist.
    func prune(keeping folders: [Folder]) {
        let validIds = Set(folders.map { $0.id })
        let pruned = lastUsed.filter { validIds.contains($0.key) }
        guard pruned.count != lastUsed.count else { return }
        lastUsed = pruned
        persist()
    }

    /// Most recently used first; folders with no usage data follow, A-Z.
    func sorted(_ folders: [Folder]) -> [Folder] {
        folders.sorted { a, b in
            switch (lastUsed[a.id], lastUsed[b.id]) {
            case let (x?, y?): return x > y
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        }
    }

    /// The most recently used folders, ignoring any that have never been used.
    func recentlyUsed(_ folders: [Folder], limit: Int) -> [Folder] {
        Array(sorted(folders).filter { lastUsed[$0.id] != nil }.prefix(limit))
    }

    private func persist() {
        UserDefaults.standard.set(lastUsed.mapValues { $0.timeIntervalSince1970 }, forKey: Self.defaultsKey)
    }
}
