import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Extract the shared content
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            closeExtension()
            return
        }

        // Try URL first (Safari, Chrome, etc.)
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                guard let self = self,
                      let shareURL = url as? URL else {
                    self?.closeExtension()
                    return
                }

                // Get the title from the extension item
                let pageTitle = extensionItem.attributedContentText?.string ?? shareURL.absoluteString

                // Open the main app with the URL and title
                self.openMainApp(url: shareURL.absoluteString, title: pageTitle)
            }
        }
        // Try plain text (apps that share text with URLs embedded)
        else if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
                guard let self = self else {
                    return
                }

                guard let sharedText = text as? String else {
                    self.closeExtension()
                    return
                }

                // Extract URL from text using regex
                if let extractedURL = self.extractURL(from: sharedText) {
                    // Remove the URL from the text to create a cleaner title
                    let cleanTitle = sharedText.replacingOccurrences(of: extractedURL, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    self.openMainApp(url: extractedURL, title: cleanTitle)
                } else {
                    // No URL found in text, close
                    self.closeExtension()
                }
            }
        }
        else {
            closeExtension()
        }
    }

    private func extractURL(from text: String) -> String? {
        // Regex pattern to match URLs
        let pattern = "(https?://[^\\s]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        guard let urlRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return String(text[urlRange])
    }

    private func openMainApp(url: String, title: String) {
        // URL encode the parameters
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let deepLinkURL = URL(string: "stash://save?url=\(encodedURL)&title=\(encodedTitle)") else {
            closeExtension()
            return
        }

        // Open the main app
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(deepLinkURL, options: [:]) { [weak self] _ in
                    self?.closeExtension()
                }
                return
            }
            responder = responder?.next
        }

        closeExtension()
    }

    private func closeExtension() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
