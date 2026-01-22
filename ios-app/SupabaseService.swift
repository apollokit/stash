import Foundation
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )

        // Listen for auth state changes
        Task {
            for await state in client.auth.authStateChanges {
                if case .signedIn(let session) = state.event {
                    self.currentUser = session.user
                    self.isAuthenticated = true
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
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
        let response = try await client.database
            .from("saves")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Save].self, from: response.data)
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

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let requestData = try encoder.encode(request)

        let response = try await client.database
            .from("saves")
            .insert(requestData)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Save.self, from: response.data)
    }

    // MARK: - Folders

    func getFolders() async throws -> [Folder] {
        let response = try await client.database
            .from("folders")
            .select()
            .order("name", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Folder].self, from: response.data)
    }
}
