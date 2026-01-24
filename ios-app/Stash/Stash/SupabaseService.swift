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
}
