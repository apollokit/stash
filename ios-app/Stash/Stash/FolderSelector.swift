import SwiftUI

struct FolderSelector: View {
    @EnvironmentObject var supabase: SupabaseService
    @EnvironmentObject var recents: FolderRecents
    let currentFolderId: String?
    /// Show a "No folder" row (for choosing a save destination, as opposed to browsing)
    var allowsNoFolder = true
    var title = "Select Folder"
    /// Folders the caller has already loaded; skips the fetch when provided
    var initialFolders: [Folder]? = nil
    var onSelect: ((String?) -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @State private var loadedFolders: [Folder]?
    @State private var searchText = ""

    private let recentLimit = 6

    private var folders: [Folder]? {
        loadedFolders ?? initialFolders
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationView {
            Group {
                if let folders = folders {
                    folderList(folders)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search folders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                guard initialFolders == nil else { return }
                do {
                    loadedFolders = try await supabase.getFolders()
                } catch {
                    print("Error loading folders: \(error)")
                    loadedFolders = []
                }
            }
        }
    }

    @ViewBuilder
    private func folderList(_ folders: [Folder]) -> some View {
        List {
            if trimmedSearch.isEmpty {
                if allowsNoFolder {
                    Section {
                        Button(action: { select(nil) }) {
                            HStack {
                                Text("No folder")
                                Spacer()
                                if currentFolderId == nil {
                                    checkmark
                                }
                            }
                        }
                    }
                }

                let recent = recents.recentlyUsed(folders, limit: recentLimit)
                if !recent.isEmpty {
                    Section("Recent") {
                        ForEach(recent) { folder in
                            folderRow(folder)
                        }
                    }
                }

                Section("All Folders") {
                    ForEach(alphabetical(folders)) { folder in
                        folderRow(folder)
                    }
                }
            } else {
                let matches = recents.sorted(folders.filter { $0.name.localizedCaseInsensitiveContains(trimmedSearch) })
                if matches.isEmpty {
                    Text("No matching folders")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(matches) { folder in
                        folderRow(folder)
                    }
                }
            }
        }
    }

    private func folderRow(_ folder: Folder) -> some View {
        Button(action: { select(folder.id) }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: folder.color))
                    .frame(width: 12, height: 12)

                Text(folder.name)

                Spacer()

                if currentFolderId == folder.id {
                    checkmark
                }
            }
        }
        .foregroundColor(.primary)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark")
            .foregroundColor(Color(red: 0.39, green: 0.40, blue: 0.95))
    }

    private func alphabetical(_ folders: [Folder]) -> [Folder] {
        folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func select(_ folderId: String?) {
        if let folderId = folderId {
            recents.touch(folderId)
        }
        onSelect?(folderId)
        dismiss()
    }
}
