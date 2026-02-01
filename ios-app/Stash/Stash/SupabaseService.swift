import Foundation
import Supabase
import Combine

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey,
            options: .init(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        // Listen for auth state changes
        Task {
            for await (event, session) in client.auth.authStateChanges {
                switch event {
                case .signedIn:
                    if let session = session {
                        self.currentUser = session.user
                        self.isAuthenticated = true
                    }
                case .signedOut:
                    self.currentUser = nil
                    self.isAuthenticated = false
                default:
                    break
                }
            }
        }

        // Check initial session
        Task {
            await checkSession()
        }
    }

    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Saves

    func getRecentSaves(limit: Int = 20) async throws -> [Save] {
        let response: [Save] = try await client
            .from("saves")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }

    func getSavesByFolder(folderId: String) async throws -> [Save] {
        let response: [Save] = try await client
            .from("saves")
            .select()
            .eq("folder_id", value: folderId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func createSave(url: String, title: String, content: String? = nil, folderId: String? = nil) async throws -> Save {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Extract site name from URL
        let siteName = URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? ""

        let request = CreateSaveRequest(
            userId: user.id.uuidString,
            url: url,
            title: title,
            content: content,
            siteName: siteName,
            folderId: folderId,
            source: "ios"
        )

        let response: Save = try await client
            .from("saves")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func deleteSave(id: String) async throws {
        try await client
            .from("saves")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func toggleFavorite(saveId: String, currentValue: Bool) async throws {
        try await client
            .from("saves")
            .update(["is_favorite": !currentValue])
            .eq("id", value: saveId)
            .execute()
    }

    func moveSaveToFolder(saveId: String, folderId: String?) async throws {
        let update: [String: AnyJSON] = ["folder_id": folderId.map { .string($0) } ?? .null]
        try await client
            .from("saves")
            .update(update)
            .eq("id", value: saveId)
            .execute()
    }

    func updateSaveImageUrl(saveId: String, imageUrl: String) async throws {
        try await client
            .from("saves")
            .update(["image_url": imageUrl])
            .eq("id", value: saveId)
            .execute()
    }

    func updateSaveTitle(saveId: String, title: String) async throws {
        try await client
            .from("saves")
            .update(["title": title])
            .eq("id", value: saveId)
            .execute()
    }

    // MARK: - Metadata Fetching

    func fetchAndUpdateMetadata(saveId: String, pageUrl: String) async {
        guard let url = URL(string: pageUrl) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return }

            if let imageUrl = extractOGImage(from: html) {
                try await updateSaveImageUrl(saveId: saveId, imageUrl: imageUrl)
            }
        } catch {
            print("Error fetching metadata: \(error)")
        }
    }

    private func extractOGImage(from html: String) -> String? {
        // Look for og:image meta tag
        // Pattern: <meta property="og:image" content="...">
        let patterns = [
            #"<meta[^>]+property=[\"']og:image[\"'][^>]+content=[\"']([^\"']+)[\"']"#,
            #"<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']og:image[\"']"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }

        return nil
    }

    // MARK: - Folders

    func getFolders() async throws -> [Folder] {
        let response: [Folder] = try await client
            .from("folders")
            .select()
            .order("name", ascending: true)
            .execute()
            .value

        return response
    }

    func createFolder(name: String, color: String) async throws -> Folder {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let request: [String: AnyJSON] = [
            "user_id": .string(user.id.uuidString),
            "name": .string(name),
            "color": .string(color)
        ]

        let response: Folder = try await client
            .from("folders")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Comments

    func getComments(saveId: String, ascending: Bool = true) async throws -> [Comment] {
        let response: [Comment] = try await client
            .from("comments")
            .select()
            .eq("save_id", value: saveId)
            .order("created_at", ascending: ascending)
            .execute()
            .value

        return response
    }

    func createComment(saveId: String, content: String, imageUrl: String? = nil) async throws -> Comment {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let request = CreateCommentRequest(
            userId: user.id.uuidString,
            saveId: saveId,
            content: content,
            imageUrl: imageUrl
        )

        let response: Comment = try await client
            .from("comments")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func deleteComment(id: String) async throws {
        try await client
            .from("comments")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func uploadCommentImage(imageData: Data, saveId: String) async throws -> String {
        guard let user = currentUser else {
            throw NSError(domain: "SupabaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let fileName = "\(user.id.uuidString)/\(saveId)/\(UUID().uuidString).jpg"

        try await client.storage
            .from("comment-images")
            .upload(
                fileName,
                data: imageData,
                options: .init(contentType: "image/jpeg")
            )

        let publicURL = try client.storage
            .from("comment-images")
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }
}
