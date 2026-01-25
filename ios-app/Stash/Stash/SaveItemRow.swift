import SwiftUI

struct SaveItemRow: View {
    let save: Save
    var onUpdate: (() -> Void)?

    @EnvironmentObject var supabase: SupabaseService
    @State private var showFolderPicker = false
    @State private var showDeleteConfirmation = false

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

            Button(action: { showFolderPicker = true }) {
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
            FolderSelector(currentFolderId: save.folderId) { folderId in
                moveToFolder(folderId)
            }
        }
    }

    private func openURL() {
        if let url = URL(string: save.url) {
            UIApplication.shared.open(url)
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
