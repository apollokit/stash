import SwiftUI
import PhotosUI

struct CommentsSection: View {
    let saveId: String

    @EnvironmentObject var supabase: SupabaseService

    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var sortAscending = true
    @State private var newCommentText = ""
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isSubmitting = false
    @State private var commentToDelete: Comment?
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var fullScreenImageUrl: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with sort toggle
            HStack {
                Text("COMMENTS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .tracking(0.5)

                Spacer()

                Button(action: {
                    sortAscending.toggle()
                    comments.reverse()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: sortAscending ? "arrow.down" : "arrow.up")
                        Text(sortAscending ? "Oldest first" : "Newest first")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }

            // Comments list
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if comments.isEmpty {
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(comments) { comment in
                        CommentRow(
                            comment: comment,
                            onDelete: {
                                commentToDelete = comment
                                showDeleteConfirmation = true
                            },
                            onImageTap: { url in
                                fullScreenImageUrl = url
                            }
                        )
                    }
                }
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // New comment input
            VStack(spacing: 12) {
                // Selected image preview
                if let image = selectedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)

                        Button(action: {
                            selectedImage = nil
                            selectedPhotoItem = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(8)
                    }
                }

                HStack(spacing: 12) {
                    // Image picker
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "384559"))
                            .cornerRadius(8)
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                            }
                        }
                    }

                    // Text field
                    TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                        .padding(12)
                        .background(Color(hex: "384559"))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .lineLimit(1...5)

                    // Submit button
                    Button(action: submitComment) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 36, height: 36)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(newCommentText.isEmpty && selectedImage == nil ? .gray : Color(hex: "838CF1"))
                        }
                    }
                    .disabled(isSubmitting || (newCommentText.isEmpty && selectedImage == nil))
                }
            }
        }
        .alert("Delete Comment", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                commentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let comment = commentToDelete {
                    deleteComment(comment)
                }
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
        .task {
            await loadComments()
        }
        .fullScreenCover(isPresented: Binding(
            get: { fullScreenImageUrl != nil },
            set: { if !$0 { fullScreenImageUrl = nil } }
        )) {
            if let url = fullScreenImageUrl {
                ZoomableImageView(url: url) {
                    fullScreenImageUrl = nil
                }
            }
        }
    }

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await supabase.getComments(saveId: saveId, ascending: sortAscending)
        } catch {
            print("Error loading comments: \(error)")
        }
        isLoading = false
    }

    private func submitComment() {
        guard !newCommentText.isEmpty || selectedImage != nil else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                var imageUrl: String?

                // Upload image if selected
                if let image = selectedImage,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    imageUrl = try await supabase.uploadCommentImage(imageData: imageData, saveId: saveId)
                }

                // Create comment
                _ = try await supabase.createComment(
                    saveId: saveId,
                    content: newCommentText,
                    imageUrl: imageUrl
                )

                // Reset form
                newCommentText = ""
                selectedImage = nil
                selectedPhotoItem = nil

                // Reload comments
                await loadComments()
            } catch {
                errorMessage = "Failed to add comment: \(error.localizedDescription)"
            }
            isSubmitting = false
        }
    }

    private func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await supabase.deleteComment(id: comment.id)
                await loadComments()
            } catch {
                errorMessage = "Failed to delete: \(error.localizedDescription)"
            }
            commentToDelete = nil
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let onDelete: () -> Void
    let onImageTap: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content with clickable URLs
            Text(attributedContent)
                .font(.body)
                .foregroundColor(.white)

            // Image if present
            if let imageUrl = comment.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(hex: "384559"))
                            .frame(height: 150)
                            .overlay(ProgressView().tint(.white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                            .onTapGesture {
                                onImageTap(url)
                            }
                    case .failure:
                        Rectangle()
                            .fill(Color(hex: "384559"))
                            .frame(height: 100)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Footer with date and delete
            HStack {
                Text(comment.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(hex: "212936"))
        .cornerRadius(12)
    }

    private var attributedContent: AttributedString {
        var attributedString = AttributedString(comment.content)

        // Find URLs and make them clickable
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(comment.content.startIndex..., in: comment.content)

        detector?.enumerateMatches(in: comment.content, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let urlRange = Range(match.range, in: comment.content),
                  let url = match.url else { return }

            if let attrRange = Range(urlRange, in: attributedString) {
                attributedString[attrRange].foregroundColor = Color(hex: "838CF1")
                attributedString[attrRange].link = url
                attributedString[attrRange].underlineStyle = .single
            }
        }

        return attributedString
    }
}

struct ZoomableImageView: View {
    let url: URL
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showHelp = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                        }
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            // Top buttons
            VStack {
                HStack {
                    Button(action: { showHelp = true }) {
                        Image(systemName: "questionmark")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding()
                Spacer()
            }
        }
        .alert("Image Controls", isPresented: $showHelp) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Pinch with two fingers to zoom in and out.\n\nDrag to pan when zoomed in.\n\nDouble-tap to toggle zoom.")
        }
        .tint(Color(hex: "838CF1"))
    }
}
