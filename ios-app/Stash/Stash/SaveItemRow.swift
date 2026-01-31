import SwiftUI

struct SaveItemRow: View {
    let save: Save
    var onUpdate: (() -> Void)?

    @EnvironmentObject var supabase: SupabaseService
    @State private var showFolderPicker = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationLink(destination: SaveDetailView(save: save, onUpdate: onUpdate)) {
            HStack(spacing: 12) {
                // Icon - favicon or highlight indicator
                ZStack {
                    if save.isHighlight {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Text("✨")
                            .font(.title3)
                    } else if let faviconURL = save.faviconURL {
                        AsyncImage(url: faviconURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            default:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "212936"))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "globe")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "212936"))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "globe")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 40, height: 40)

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

                // Favorite indicator
                if save.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // Thumbnail if image available
                if let imageUrl = save.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        default:
                            EmptyView()
                        }
                    }
                }
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

            Button(action: { openURL() }) {
                Label("Open in Safari", systemImage: "safari")
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
