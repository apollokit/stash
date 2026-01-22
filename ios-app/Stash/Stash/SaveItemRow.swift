import SwiftUI

struct SaveItemRow: View {
    let save: Save

    var body: some View {
        Button(action: { openURL() }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(save.isHighlight ? Color.yellow.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 40, height: 40)

                    Text(save.isHighlight ? "✨" : "📄")
                        .font(.title3)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(save.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let siteName = save.siteName, !siteName.isEmpty {
                            Text(siteName)
                            Text("·")
                        }
                        Text(save.formattedDate)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private func openURL() {
        if let url = URL(string: save.url) {
            UIApplication.shared.open(url)
        }
    }
}
