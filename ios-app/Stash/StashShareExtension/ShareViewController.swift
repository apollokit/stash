import UIKit
import Social
import UniformTypeIdentifiers
import LinkPresentation
import os.log

class ShareViewController: UIViewController {

    private let logger = Logger(subsystem: "com.stash.shareextension", category: "ShareViewController")

    override func viewDidLoad() {
        super.viewDidLoad()

        logger.info("ShareViewController viewDidLoad started")

        // Extract the shared content
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            logger.error("No extension item found")
            closeExtension()
            return
        }

        logger.info("Extension item found with \(extensionItem.attachments?.count ?? 0) attachments")

        // Check all attachments
        guard let attachments = extensionItem.attachments, !attachments.isEmpty else {
            logger.error("No attachments found")
            closeExtension()
            return
        }

        // Log all attachments and their type identifiers
        for (index, itemProvider) in attachments.enumerated() {
            logger.info("Attachment \(index) type identifiers:")
            for identifier in itemProvider.registeredTypeIdentifiers {
                logger.info("  - \(identifier)")
            }
        }

        // Try to find an attachment with URL
        if let urlProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            logger.info("Found attachment with URL type identifier")
            handleURLShare(itemProvider: urlProvider, extensionItem: extensionItem)
        }
        // Try plain text as fallback
        else if let textProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            logger.info("Found attachment with plain text type identifier")
            handleTextShare(itemProvider: textProvider)
        }
        else {
            logger.error("No supported type identifier found in any attachment")
            closeExtension()
        }
    }

    private func handleURLShare(itemProvider: NSItemProvider, extensionItem: NSExtensionItem) {
        logger.info("handleURLShare: Loading URL item")

        itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("handleURLShare: Error loading URL - \(error.localizedDescription)")
                self.closeExtension()
                return
            }

            self.logger.info("handleURLShare: Item loaded, type: \(String(describing: type(of: url)))")

            guard let shareURL = url as? URL else {
                self.logger.error("handleURLShare: Item is not a URL, got: \(String(describing: url))")
                self.closeExtension()
                return
            }

            self.logger.info("handleURLShare: URL extracted: \(shareURL.absoluteString)")

            // Get the title from the extension item
            let pageTitle = extensionItem.attributedContentText?.string ?? shareURL.absoluteString
            self.logger.info("handleURLShare: Title: \(pageTitle)")

            // Open the main app with the URL and title
            self.openMainApp(url: shareURL.absoluteString, title: pageTitle)
        }
    }

    private func handleTextShare(itemProvider: NSItemProvider) {
        logger.info("handleTextShare: Loading text item")

        itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("handleTextShare: Error loading text - \(error.localizedDescription)")
                self.closeExtension()
                return
            }

            self.logger.info("handleTextShare: Item loaded, type: \(String(describing: type(of: text)))")

            guard let sharedText = text as? String else {
                self.logger.error("handleTextShare: Item is not a String")
                self.closeExtension()
                return
            }

            self.logger.info("handleTextShare: Text content: \(sharedText)")

            // Extract URL from text using regex
            if let extractedURL = self.extractURL(from: sharedText) {
                self.logger.info("handleTextShare: Extracted URL: \(extractedURL)")
                // Remove the URL from the text to create a cleaner title
                let cleanTitle = sharedText.replacingOccurrences(of: extractedURL, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                self.logger.info("handleTextShare: Clean title: \(cleanTitle)")
                self.openMainApp(url: extractedURL, title: cleanTitle)
            } else {
                self.logger.error("handleTextShare: No URL found in text")
                self.closeExtension()
            }
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
        logger.info("openMainApp: URL=\(url), Title=\(title)")

        // URL encode the parameters
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let deepLinkURL = URL(string: "stash://save?url=\(encodedURL)&title=\(encodedTitle)") else {
            logger.error("openMainApp: Failed to create deep link URL")
            closeExtension()
            return
        }

        logger.info("openMainApp: Deep link created: \(deepLinkURL.absoluteString)")

        // Open the main app
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                logger.info("openMainApp: Found UIApplication, opening deep link")
                application.open(deepLinkURL, options: [:]) { [weak self] success in
                    self?.logger.info("openMainApp: Deep link opened, success=\(success)")
                    self?.closeExtension()
                }
                return
            }
            responder = responder?.next
        }

        logger.error("openMainApp: Could not find UIApplication in responder chain")
        closeExtension()
    }

    private func closeExtension() {
        logger.info("closeExtension: Closing share extension")
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
