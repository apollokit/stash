import SwiftUI

struct SaveDetailView: View {
    let save: Save
    var onUpdate: (() -> Void)?

    @EnvironmentObject var supabase: SupabaseService
    @Environment(\.dismiss) var dismiss

    @State private var showFolderPicker = false
    @State private var showDeleteConfirmation = false
    @State private var currentFolder: Folder?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hero image
                if let imageUrl = save.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(hex: "384559"))
                                .frame(height: 200)
                                .overlay(ProgressView().tint(.white))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color(hex: "384559"))
                                .frame(height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(save.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Site and date
                    HStack(spacing: 8) {
                        if let faviconURL = save.faviconURL {
                            AsyncImage(url: faviconURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                default:
                                    Image(systemName: "globe")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        if let siteName = save.siteName, !siteName.isEmpty {
                            Text(siteName)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Text("·")
                            .foregroundColor(.gray)

                        Text(save.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // URL
                    Text(save.url)
                        .font(.caption)
                        .foregroundColor(Color(hex: "838CF1"))
                        .lineLimit(2)

                    // Highlight preview
                    if let highlight = save.highlight, !highlight.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HIGHLIGHT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .tracking(0.5)

                            HStack(alignment: .top, spacing: 12) {
                                Rectangle()
                                    .fill(Color.yellow)
                                    .frame(width: 3)

                                Text(highlight)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .italic()
                            }
                            .padding()
                            .background(Color(hex: "FEF3C7").opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }

                    // Excerpt if available
                    if let excerpt = save.excerpt, !excerpt.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EXCERPT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .tracking(0.5)

                            Text(excerpt)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 8)
                    }

                    // Open Link button
                    Button(action: openURL) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Open Link")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "838CF1"))
                    .padding(.top, 16)

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: toggleFavorite) {
                            HStack {
                                Image(systemName: save.isFavorite ? "heart.fill" : "heart")
                                Text(save.isFavorite ? "Unfavorite" : "Favorite")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(save.isFavorite ? .red : .gray)

                        Button(action: { showFolderPicker = true }) {
                            HStack {
                                if let folder = currentFolder {
                                    Circle()
                                        .fill(Color(hex: folder.color))
                                        .frame(width: 10, height: 10)
                                    Text(folder.name)
                                } else {
                                    Image(systemName: "folder")
                                    Text("No folder")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(currentFolder != nil ? Color(hex: currentFolder!.color) : .gray)
                    }

                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .background(Color(hex: "121826"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "121826"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete Save", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSave()
            }
        } message: {
            Text("Are you sure you want to delete this save? This cannot be undone.")
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderSelector(currentFolderId: currentFolder?.id ?? save.folderId) { folderId in
                moveToFolder(folderId)
            }
        }
        .task {
            await loadCurrentFolder()
        }
    }

    private func loadCurrentFolder() async {
        guard let folderId = save.folderId else {
            currentFolder = nil
            return
        }
        do {
            let folders = try await supabase.getFolders()
            currentFolder = folders.first { $0.id == folderId }
        } catch {
            print("Error loading folder: \(error)")
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
                // Update local folder state
                if let folderId = folderId {
                    let folders = try await supabase.getFolders()
                    currentFolder = folders.first { $0.id == folderId }
                } else {
                    currentFolder = nil
                }
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
                dismiss()
            } catch {
                print("Error deleting save: \(error)")
            }
        }
    }
}
