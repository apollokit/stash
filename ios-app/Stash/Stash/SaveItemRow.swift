import SwiftUI

struct SaveItemRow: View {
    let save: Save
    var onUpdate: (() -> Void)?

    @EnvironmentObject var supabase: SupabaseService
    @State private var showFolderPicker = false
    @State private var showDeleteConfirmation = false
    @State private var folders: [Folder] = []

    var body: some View {
        Button(action: { openURL() }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(save.isHighlight ? Color.yellow.opacity(0.2) : Color(hex: "212936"))
                        .frame(width: 40, height: 40)

                    Text(save.isHighlight ? "✨" : "📄")
                        .font(.title3)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(save.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        if let siteName = save.siteName, !siteName.isEmpty {
                            Text(siteName)
                            Text("·")
                        }
                        Text(save.formattedDate)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()
            .background(Color(hex: "212936"))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: { toggleFavorite() }) {
                Label(
                    save.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: save.isFavorite ? "heart.fill" : "heart"
                )
            }

            Button(action: {
                Task {
                    print("📁 [SaveItemRow] Button tapped, loading folders...")
                    await loadFolders()
                    print("📁 [SaveItemRow] Folders loaded: \(folders.count)")
                    showFolderPicker = true
                    print("📁 [SaveItemRow] Sheet will open")
                }
            }) {
                Label("Move to folder", systemImage: "folder")
            }

            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Save", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSave()
            }
        } message: {
            Text("Are you sure you want to delete this save? This cannot be undone.")
        }
        .sheet(isPresented: $showFolderPicker) {
            // NOTE: Known issue - folders array is empty on first open due to SwiftUI timing
            // Works correctly on second open. Folders are loaded but sheet content evaluates before state updates.
            let _ = print("📁 [SaveItemRow] Sheet building with folders count: \(folders.count)")
            FolderSelector(
                folders: folders,
                selectedFolder: .constant(folders.first { $0.id == save.folderId })
            ) { folderId in
                moveToFolder(folderId)
            }
        }
    }

    private func openURL() {
        if let url = URL(string: save.url) {
            UIApplication.shared.open(url)
        }
    }

    private func loadFolders() async {
        print("📁 [SaveItemRow] loadFolders() starting...")
        do {
            let loadedFolders = try await supabase.getFolders()
            print("📁 [SaveItemRow] API returned \(loadedFolders.count) folders")
            folders = loadedFolders
            print("📁 [SaveItemRow] State updated, folders.count = \(folders.count)")
        } catch {
            print("📁 [SaveItemRow] Error loading folders: \(error)")
        }
    }

    private func toggleFavorite() {
        Task {
            do {
                try await supabase.toggleFavorite(saveId: save.id, currentValue: save.isFavorite)
                onUpdate?()
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }

    private func moveToFolder(_ folderId: String?) {
        Task {
            do {
                try await supabase.moveSaveToFolder(saveId: save.id, folderId: folderId)
                onUpdate?()
            } catch {
                print("Error moving to folder: \(error)")
            }
        }
    }

    private func deleteSave() {
        Task {
            do {
                try await supabase.deleteSave(id: save.id)
                onUpdate?()
            } catch {
                print("Error deleting save: \(error)")
            }
        }
    }
}
