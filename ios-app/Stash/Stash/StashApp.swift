import SwiftUI
import Combine

@main
struct StashApp: App {
    @StateObject private var supabase = SupabaseService.shared
    @StateObject private var folderRecents = FolderRecents()

    var body: some Scene {
        WindowGroup {
            Group {
                if supabase.isAuthenticated {
                    HomeView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(supabase)
            .environmentObject(folderRecents)
        }
    }
}
