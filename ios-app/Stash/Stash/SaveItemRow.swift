import SwiftUI

struct SaveItemRow: View {
    let save: Save

    var body: some View {
        Button(action: { openURL() }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(save.isHighlight ? Color.yellow.opacity(0.2) : Color(hex: "212936"))
                        .frame(width: 40, height: 40)

                    Text(save.isHighlight ? "✨" : "📄")
                        .font(.title3)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(save.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        if let siteName = save.siteName, !siteName.isEmpty {
                            Text(siteName)
                            Text("·")
                        }
                        Text(save.formattedDate)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()
            .background(Color(hex: "212936"))
            .cornerRadius(12)
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
