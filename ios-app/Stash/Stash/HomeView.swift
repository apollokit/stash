import SwiftUI
import Combine
import Auth

enum SavesViewMode: String, CaseIterable {
    case recent = "Recent Saves"
    case folders = "Folders"
}

struct HomeView: View {
    @EnvironmentObject var supabase: SupabaseService

    @State private var saves: [Save] = []
    @State private var folders: [Folder] = []
    @State private var selectedFolder: Folder?

    // View mode for the saves list
    @State private var viewMode: SavesViewMode = .recent
    @State private var browsingFolder: Folder?
    @State private var folderSaves: [Save] = []
    @State private var isLoadingFolderSaves = false

    @State private var url = ""
    @State private var title = ""

    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showFolderPicker = false
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @State private var newFolderColor = "6366F1"

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(hex: "121826")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Save Form
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SAVE A PAGE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .tracking(0.5)

                            TextField("URL", text: $url)
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .padding()
                                .background(Color(hex: "384559"))
                                .cornerRadius(8)
                                .foregroundColor(.white)

                            TextField("Title", text: $title)
                                .padding()
                                .background(Color(hex: "384559"))
                                .cornerRadius(8)
                                .foregroundColor(.white)

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
                                .foregroundColor(.white)
                                .padding()
                                .background(selectedFolder != nil ? Color(hex: "838CF1") : Color(hex: "404249"))
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
                            .tint(Color(hex: "838CF1"))
                            .disabled(isSaving || url.isEmpty || title.isEmpty)
                        }
                        .padding()
                        .background(Color(red: 0.15, green: 0.16, blue: 0.19))
                        .cornerRadius(12)

                    // Saves List with View Mode Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Menu {
                                // Recent Saves option
                                Button(action: {
                                    viewMode = .recent
                                    browsingFolder = nil
                                    folderSaves = []
                                }) {
                                    HStack {
                                        Text("Recent Saves")
                                    }
                                }

                                // Folders submenu
                                Menu {
                                    if folders.isEmpty {
                                        Text("No folders yet")
                                    } else {
                                        ForEach(folders) { folder in
                                            Button(action: {
                                                viewMode = .folders
                                                browsingFolder = folder
                                                Task {
                                                    await loadFolderSaves(folderId: folder.id)
                                                }
                                            }) {
                                                HStack {
                                                    Circle()
                                                        .fill(Color(hex: folder.color))
                                                        .frame(width: 10, height: 10)
                                                    Text(folder.name)
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("Folders")
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    if viewMode == .folders, let folder = browsingFolder {
                                        Circle()
                                            .fill(Color(hex: folder.color))
                                            .frame(width: 8, height: 8)
                                        Text(folder.name.uppercased())
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gray)
                                            .tracking(0.5)
                                    } else {
                                        Text("RECENT SAVES")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gray)
                                            .tracking(0.5)
                                    }
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            Button(action: {
                                Task {
                                    await loadData()
                                    if viewMode == .folders, let folder = browsingFolder {
                                        await loadFolderSaves(folderId: folder.id)
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)

                        if viewMode == .folders {
                            // Folder saves list
                            if let folder = browsingFolder {
                                if isLoadingFolderSaves {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else if folderSaves.isEmpty {
                                    Text("No saves in this folder")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    ForEach(folderSaves) { save in
                                        SaveItemRow(save: save) {
                                            Task {
                                                await loadFolderSaves(folderId: folder.id)
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // Recent saves list
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if saves.isEmpty {
                                Text("No saves yet. Save your first page!")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ForEach(saves) { save in
                                    SaveItemRow(save: save) {
                                        Task {
                                            await loadData()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "121826"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("StashIcon")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .cornerRadius(6)
                        Text("Stash")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showCreateFolder = true }) {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.white)
                        }

                        Menu {
                            if let email = supabase.currentUser?.email {
                                Text(email)
                            }
                            Button(role: .destructive, action: handleSignOut) {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .refreshable {
                await loadData()
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderSelector(currentFolderId: selectedFolder?.id) { folderId in
                    if let folderId = folderId {
                        selectedFolder = folders.first { $0.id == folderId }
                    } else {
                        selectedFolder = nil
                    }
                }
            }
            .sheet(isPresented: $showCreateFolder) {
                NavigationView {
                    Form {
                        Section {
                            TextField("Folder Name", text: $newFolderName)
                        }

                        Section {
                            let colors = ["6366F1", "EC4899", "10B981", "F59E0B", "EF4444", "8B5CF6"]
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                                ForEach(colors, id: \.self) { colorHex in
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: newFolderColor == colorHex ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            newFolderColor = colorHex
                                        }
                                }
                            }
                            .padding(.vertical, 8)
                        } header: {
                            Text("Color")
                        }
                    }
                    .navigationTitle("New Folder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showCreateFolder = false
                                newFolderName = ""
                                newFolderColor = "6366F1"
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Create") {
                                createFolder()
                            }
                            .disabled(newFolderName.isEmpty)
                        }
                    }
                }
            }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
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
            errorMessage = nil  // Clear any previous errors on success
        } catch {
            // Check if this is a cancellation error (can come from different sources)
            let errorDesc = error.localizedDescription.lowercased()
            if errorDesc.contains("cancel") {
                // Refresh was cancelled by user gesture - this is normal, don't show error
                print("Load cancelled by user: \(error)")
            } else {
                errorMessage = "Failed to load: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }

    private func loadFolderSaves(folderId: String) async {
        isLoadingFolderSaves = true
        do {
            folderSaves = try await supabase.getSavesByFolder(folderId: folderId)
        } catch {
            let errorDesc = error.localizedDescription.lowercased()
            if !errorDesc.contains("cancel") {
                errorMessage = "Failed to load folder saves: \(error.localizedDescription)"
            }
        }
        isLoadingFolderSaves = false
    }

    private func handleSave() {
        isSaving = true
        errorMessage = nil

        let savedUrl = url  // Capture before clearing

        Task {
            do {
                let newSave = try await supabase.createSave(
                    url: url,
                    title: title,
                    folderId: selectedFolder?.id
                )
                url = ""
                title = ""
                selectedFolder = nil
                await loadData()

                // Fetch metadata in background (don't block UI)
                Task.detached {
                    await supabase.fetchAndUpdateMetadata(saveId: newSave.id, pageUrl: savedUrl)
                    // Refresh data after metadata is fetched
                    _ = await MainActor.run {
                        Task {
                            await loadData()
                        }
                    }
                }
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

    private func createFolder() {
        Task {
            do {
                _ = try await supabase.createFolder(name: newFolderName, color: newFolderColor)
                showCreateFolder = false
                newFolderName = ""
                newFolderColor = "6366F1"
                await loadData()
            } catch {
                errorMessage = "Failed to create folder: \(error.localizedDescription)"
            }
        }
    }
}
