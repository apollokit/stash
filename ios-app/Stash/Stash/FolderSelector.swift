import SwiftUI

struct FolderSelector: View {
    @EnvironmentObject var supabase: SupabaseService
    let currentFolderId: String?
    var onSelect: ((String?) -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @State private var folders: [Folder] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Button(action: {
                            onSelect?(nil)
                            dismiss()
                        }) {
                            HStack {
                                Text("No folder")
                                Spacer()
                                if currentFolderId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(red: 0.39, green: 0.40, blue: 0.95))
                                }
                            }
                        }

                        ForEach(folders) { folder in
                            Button(action: {
                                onSelect?(folder.id)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(hex: folder.color))
                                        .frame(width: 12, height: 12)

                                    Text(folder.name)

                                    Spacer()

                                    if currentFolderId == folder.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color(red: 0.39, green: 0.40, blue: 0.95))
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                do {
                    folders = try await supabase.getFolders()
                } catch {
                    print("Error loading folders: \(error)")
                }
                isLoading = false
            }
        }
    }
}
