import SwiftUI

struct FolderSelector: View {
    let folders: [Folder]
    @Binding var selectedFolder: Folder?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedFolder = nil
                    dismiss()
                }) {
                    HStack {
                        Text("No folder")
                        Spacer()
                        if selectedFolder == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(red: 0.39, green: 0.40, blue: 0.95))
                        }
                    }
                }

                ForEach(folders) { folder in
                    Button(action: {
                        selectedFolder = folder
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: folder.color))
                                .frame(width: 12, height: 12)

                            Text(folder.name)

                            Spacer()

                            if selectedFolder?.id == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(red: 0.39, green: 0.40, blue: 0.95))
                            }
                        }
                    }
                    .foregroundColor(.primary)
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
        }
    }
}
