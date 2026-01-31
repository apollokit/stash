import Foundation

// MARK: - Save Model
struct Save: Codable, Identifiable {
    let id: String
    let userId: String
    let url: String
    let title: String
    let content: String?
    let excerpt: String?
    let highlight: String?
    let siteName: String?
    let author: String?
    let publishedAt: String?
    let imageUrl: String?
    let folderId: String?
    let isFavorite: Bool
    let source: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case url
        case title
        case content
        case excerpt
        case highlight
        case siteName = "site_name"
        case author
        case publishedAt = "published_at"
        case imageUrl = "image_url"
        case folderId = "folder_id"
        case isFavorite = "is_favorite"
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isHighlight: Bool {
        highlight != nil
    }

    var displayTitle: String {
        if !title.isEmpty {
            return title
        } else if let highlight = highlight, !highlight.isEmpty {
            return String(highlight.prefix(50))
        } else {
            return "Untitled"
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }

    var faviconURL: URL? {
        guard let siteName = siteName, !siteName.isEmpty else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(siteName)&sz=64")
    }
}

// MARK: - Folder Model
struct Folder: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let color: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case color
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Create Save Request
struct CreateSaveRequest: Codable {
    let userId: String
    let url: String
    let title: String
    let content: String?
    let siteName: String
    let folderId: String?
    let source: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case url
        case title
        case content
        case siteName = "site_name"
        case folderId = "folder_id"
        case source
    }
}
