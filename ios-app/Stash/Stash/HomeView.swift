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

    // View mode for the saves list (persisted)
    @AppStorage("savesViewMode") private var savedViewMode: String = "recent"
    @AppStorage("browsingFolderId") private var savedFolderId: String = ""
    @State private var viewMode: SavesViewMode = .recent
    @State private var browsingFolder: Folder?
    @State private var folderSaves: [Save] = []
    @State private var isLoadingFolderSaves = false

    @State private var url = ""
    @State private var title = ""
    @State private var isSaveFormExpanded = false

    // Search state
    @State private var searchQuery = ""
    @State private var searchUrlFilter = ""
    @State private var isSearching = false
    @State private var searchResults: [Save] = []
    @State private var hasSearched = false
    @State private var isSearchOptionsExpanded = false
    @State private var searchStartDate: Date?
    @State private var searchEndDate: Date?
    @State private var searchFolderIds: Set<String> = []
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var showSearchHelp = false

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
                        // Save Form (collapsible)
                        VStack(alignment: .leading, spacing: 12) {
                            // Header - tap to toggle
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSaveFormExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text("SAVE A PAGE")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                        .tracking(0.5)
                                    Spacer()
                                    Image(systemName: isSaveFormExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            if isSaveFormExpanded {
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
                        }
                        .padding()
                        .background(Color(red: 0.15, green: 0.16, blue: 0.19))
                        .cornerRadius(12)

                        // Search Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Header with help button
                            HStack {
                                Text("SEARCH SAVES")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                    .tracking(0.5)

                                Button(action: { showSearchHelp = true }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()
                            }

                            // Main search bar (FTS)
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search titles, content, comments...", text: $searchQuery)
                                    .foregroundColor(.white)
                                    .onSubmit {
                                        performSearch()
                                    }
                                if !searchQuery.isEmpty {
                                    Button(action: { searchQuery = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(hex: "384559"))
                            .cornerRadius(8)

                            // Search options toggle
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSearchOptionsExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text("MORE FILTERS")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                        .tracking(0.5)
                                    Spacer()
                                    Image(systemName: isSearchOptionsExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            if isSearchOptionsExpanded {
                                VStack(alignment: .leading, spacing: 16) {
                                    // URL filter (ILIKE)
                                    HStack {
                                        Image(systemName: "link")
                                            .foregroundColor(.gray)
                                        TextField("e.g. economist.com", text: $searchUrlFilter)
                                            .foregroundColor(.white)
                                            .autocapitalization(.none)
                                        if !searchUrlFilter.isEmpty {
                                            Button(action: { searchUrlFilter = "" }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(hex: "384559"))
                                    .cornerRadius(8)

                                    Divider().background(Color.gray.opacity(0.3))

                                    // Date filters
                                    HStack(spacing: 12) {
                                        // Start date
                                        Button(action: { showStartDatePicker = true }) {
                                            HStack {
                                                Image(systemName: "calendar")
                                                if let date = searchStartDate {
                                                    Text(date, style: .date)
                                                } else {
                                                    Text("Start date")
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(searchStartDate != nil ? .white : .gray)
                                            .padding(10)
                                            .frame(maxWidth: .infinity)
                                            .background(Color(hex: "384559"))
                                            .cornerRadius(6)
                                        }

                                        // End date
                                        Button(action: { showEndDatePicker = true }) {
                                            HStack {
                                                Image(systemName: "calendar")
                                                if let date = searchEndDate {
                                                    Text(date, style: .date)
                                                } else {
                                                    Text("End date")
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(searchEndDate != nil ? .white : .gray)
                                            .padding(10)
                                            .frame(maxWidth: .infinity)
                                            .background(Color(hex: "384559"))
                                            .cornerRadius(6)
                                        }
                                    }

                                    // Clear dates button
                                    if searchStartDate != nil || searchEndDate != nil {
                                        Button(action: {
                                            searchStartDate = nil
                                            searchEndDate = nil
                                        }) {
                                            Text("Clear dates")
                                                .font(.caption)
                                                .foregroundColor(Color(hex: "838CF1"))
                                        }
                                    }

                                    Divider().background(Color.gray.opacity(0.3))

                                    // Folder filter
                                    Text("Folders:")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    if folders.isEmpty {
                                        Text("No folders")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    } else {
                                        FlowLayout(spacing: 8) {
                                            ForEach(folders) { folder in
                                                FolderFilterChip(
                                                    folder: folder,
                                                    isSelected: searchFolderIds.contains(folder.id)
                                                ) {
                                                    if searchFolderIds.contains(folder.id) {
                                                        searchFolderIds.remove(folder.id)
                                                    } else {
                                                        searchFolderIds.insert(folder.id)
                                                    }
                                                }
                                            }
                                        }

                                        if !searchFolderIds.isEmpty {
                                            Button(action: { searchFolderIds.removeAll() }) {
                                                Text("Clear folder filter")
                                                    .font(.caption)
                                                    .foregroundColor(Color(hex: "838CF1"))
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }

                            // Search button
                            Button(action: performSearch) {
                                if isSearching {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                } else {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                        Text("Search")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "838CF1"))
                            .disabled(isSearching || (searchQuery.isEmpty && searchUrlFilter.isEmpty))
                        }
                        .padding()
                        .background(Color(red: 0.15, green: 0.16, blue: 0.19))
                        .cornerRadius(12)
                        .alert("How Search Works", isPresented: $showSearchHelp) {
                            Button("Got it", role: .cancel) {}
                        } message: {
                            Text("Main search uses full-text search across titles, excerpts, content, highlights, and comments. Multiple words are matched with AND logic (e.g., \"economist 2025\" finds saves containing both words).\n\nURL filter uses exact phrase matching within URLs.")
                        }
                        .tint(Color(hex: "838CF1"))

                    // Search Results or Saves List
                    if hasSearched && !isSearching {
                        // Search Results
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("SEARCH RESULTS")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                    .tracking(0.5)

                                Text("(\(searchResults.count))")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Spacer()

                                Button(action: clearSearch) {
                                    Text("Clear")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "838CF1"))
                                }
                            }
                            .padding(.horizontal)

                            if searchResults.isEmpty {
                                Text("No results found")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ForEach(searchResults) { save in
                                    SaveItemRow(save: save) {
                                        performSearch()
                                    }
                                }
                            }
                        }
                    } else {
                    // Saves List with View Mode Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Menu {
                                // Recent Saves option
                                Button(action: {
                                    viewMode = .recent
                                    savedViewMode = "recent"
                                    savedFolderId = ""
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
                                                savedViewMode = "folders"
                                                savedFolderId = folder.id
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
                    } // End else (search results vs saves list)
                }
                .padding(.vertical)
            }
            .sheet(isPresented: $showStartDatePicker) {
                DatePickerSheet(
                    title: "Start Date",
                    selectedDate: $searchStartDate,
                    isPresented: $showStartDatePicker
                )
            }
            .sheet(isPresented: $showEndDatePicker) {
                DatePickerSheet(
                    title: "End Date",
                    selectedDate: $searchEndDate,
                    isPresented: $showEndDatePicker
                )
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
            // Restore saved view mode
            if savedViewMode == "folders" && !savedFolderId.isEmpty {
                if let folder = folders.first(where: { $0.id == savedFolderId }) {
                    viewMode = .folders
                    browsingFolder = folder
                    await loadFolderSaves(folderId: folder.id)
                }
            }
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
            // Expand the save form when coming from share extension
            withAnimation {
                isSaveFormExpanded = true
            }
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

    private func performSearch() {
        guard !searchQuery.isEmpty || !searchUrlFilter.isEmpty else { return }
        isSearching = true

        Task {
            do {
                let options = SupabaseService.SearchOptions(
                    urlFilter: searchUrlFilter.isEmpty ? nil : searchUrlFilter,
                    startDate: searchStartDate,
                    endDate: searchEndDate,
                    folderIds: searchFolderIds.isEmpty ? nil : Array(searchFolderIds)
                )
                searchResults = try await supabase.searchSaves(query: searchQuery, options: options)
                hasSearched = true
            } catch {
                errorMessage = "Search failed: \(error.localizedDescription)"
            }
            isSearching = false
        }
    }

    private func clearSearch() {
        searchQuery = ""
        searchUrlFilter = ""
        searchResults = []
        hasSearched = false
        searchStartDate = nil
        searchEndDate = nil
        searchFolderIds.removeAll()
    }
}

// MARK: - Helper Views

struct FolderFilterChip: View {
    let folder: Folder
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: folder.color))
                    .frame(width: 8, height: 8)
                Text(folder.name)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: folder.color).opacity(0.3) : Color(hex: "384559"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: folder.color) : Color.clear, lineWidth: 1)
            )
        }
        .foregroundColor(.white)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

struct DatePickerSheet: View {
    let title: String
    @Binding var selectedDate: Date?
    @Binding var isPresented: Bool

    @State private var tempDate = Date()

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    title,
                    selection: $tempDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selectedDate = nil
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedDate = tempDate
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            if let date = selectedDate {
                tempDate = date
            }
        }
    }
}
