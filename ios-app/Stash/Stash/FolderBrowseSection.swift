import SwiftUI

// MARK: - Folder Browse Section
/// Collapsible card for switching what the home saves list shows. Collapsed, it shows the
/// current selection; expanded, it shows chips for Recent Saves and the most recently used folders.
struct FolderBrowseSection: View {
    /// All folders, ordered by recent use
    let folders: [Folder]
    /// The folder being browsed, or nil for Recent Saves
    let browsingFolder: Folder?
    let isExpanded: Bool
    let onToggle: () -> Void
    let onRefresh: () -> Void
    let onSelectRecent: () -> Void
    let onSelectFolder: (Folder) -> Void
    let onShowMore: () -> Void

    private let maxChips = 15

    /// The top folders by recency, always including the folder currently being browsed.
    private var chipFolders: [Folder] {
        var chips = Array(folders.prefix(maxChips))
        if let current = browsingFolder,
           folders.contains(where: { $0.id == current.id }),
           !chips.contains(where: { $0.id == current.id }) {
            chips.insert(current, at: 0)
            chips.removeLast()
        }
        return chips
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - tap to toggle
            HStack {
                HStack(spacing: 6) {
                    Text("BROWSE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .tracking(0.5)
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if let folder = browsingFolder {
                        Circle()
                            .fill(Color(hex: folder.color))
                            .frame(width: 8, height: 8)
                        Text(folder.name.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .tracking(0.5)
                            .lineLimit(1)
                    } else {
                        Text("RECENT SAVES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .tracking(0.5)
                    }
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)

            if isExpanded {
                FlowLayout(spacing: 8) {
                    BrowseChip(
                        title: "Recent Saves",
                        systemImage: "clock",
                        isSelected: browsingFolder == nil,
                        onTap: onSelectRecent
                    )

                    ForEach(chipFolders) { folder in
                        FolderFilterChip(
                            folder: folder,
                            isSelected: browsingFolder?.id == folder.id
                        ) {
                            onSelectFolder(folder)
                        }
                    }

                    if folders.count > chipFolders.count {
                        BrowseChip(
                            title: "+\(folders.count - chipFolders.count) more",
                            onTap: onShowMore
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.15, green: 0.16, blue: 0.19))
        .cornerRadius(12)
    }
}

// MARK: - Browse Chip
/// Capsule chip matching FolderFilterChip, for entries that aren't a folder.
private struct BrowseChip: View {
    let title: String
    var systemImage: String? = nil
    var isSelected = false
    let onTap: () -> Void

    private let accent = Color(hex: "838CF1")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? accent.opacity(0.3) : Color(hex: "384559"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accent : Color.clear, lineWidth: 1)
            )
        }
        .foregroundColor(.white)
    }
}
