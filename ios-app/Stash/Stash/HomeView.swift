import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var supabase: SupabaseService

    @State private var saves: [Save] = []
    @State private var folders: [Folder] = []
    @State private var selectedFolder: Folder?

    @State private var url = ""
    @State private var title = ""

    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showFolderPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Save Form
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SAVE A PAGE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .tracking(0.5)

                        TextField("URL", text: $url)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                            .textFieldStyle(.roundedBorder)

                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)

                        Button(action: { showFolderPicker = true }) {
                            HStack {
                                if let folder = selectedFolder {
                                    Circle()
                                        .fill(Color(hex: folder.color))
                                        .frame(width: 12, height: 12)
                                    Text("Save to \"\(folder.name)\"")
                                } else {
                                    Image(systemName: "folder")
                                    Text("Save to folder (optional)")
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button(action: handleSave) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                            } else {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save Page")
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.39, green: 0.40, blue: 0.95))
                        .disabled(isSaving || url.isEmpty || title.isEmpty)
                    }
                    .padding()
                    .background(Color(.systemBackground))

                    Divider()

                    // Recent Saves
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT SAVES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal)

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if saves.isEmpty {
                            Text("No saves yet. Save your first page!")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(saves) { save in
                                SaveItemRow(save: save)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Stash")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if let email = supabase.currentUser?.email {
                            Text(email)
                        }
                        Button(role: .destructive, action: handleSignOut) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable {
                await loadData()
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderSelector(folders: folders, selectedFolder: $selectedFolder)
            }
        }
        .task {
            await loadData()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Parse URL: stash://save?url=...&title=...
        guard url.scheme == "stash",
              url.host == "save",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }

        // Extract URL and title from query parameters
        if let urlParam = queryItems.first(where: { $0.name == "url" })?.value,
           let titleParam = queryItems.first(where: { $0.name == "title" })?.value {
            self.url = urlParam
            self.title = titleParam
        }
    }

    private func loadData() async {
        isLoading = true
        do {
            async let savesRequest = supabase.getRecentSaves()
            async let foldersRequest = supabase.getFolders()

            saves = try await savesRequest
            folders = try await foldersRequest
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func handleSave() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                _ = try await supabase.createSave(
                    url: url,
                    title: title,
                    folderId: selectedFolder?.id
                )
                url = ""
                title = ""
                selectedFolder = nil
                await loadData()
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }

    private func handleSignOut() {
        Task {
            try? await supabase.signOut()
        }
    }
}

// Color extension to parse hex strings
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
