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

        // Log all available metadata from the extension item
        logger.info("=== Extension Item Metadata ===")
        if let title = extensionItem.attributedTitle?.string {
            logger.info("attributedTitle: \(title)")
        } else {
            logger.info("attributedTitle: nil")
        }

        if let contentText = extensionItem.attributedContentText?.string {
            logger.info("attributedContentText: \(contentText)")
        } else {
            logger.info("attributedContentText: nil")
        }

        if let userInfo = extensionItem.userInfo {
            logger.info("userInfo keys: \(Array(userInfo.keys))")
            for (key, value) in userInfo {
                logger.info("  userInfo[\(key)]: \(String(describing: value))")
            }
        } else {
            logger.info("userInfo: nil")
        }
        logger.info("=== End Metadata ===")

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

            // Check if this attachment has URL type
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                logger.info("  -> Attachment \(index) HAS URL type")
            }
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                logger.info("  -> Attachment \(index) HAS plain text type")
            }
        }

        // Check if we have BOTH URL and text attachments (Safari text selection case)
        let urlProviders = attachments.filter { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }
        let textProviders = attachments.filter { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }

        logger.info("Found \(urlProviders.count) URL providers and \(textProviders.count) text providers")

        // If we have both URL and text, this is likely a highlight share
        if urlProviders.count > 0 && textProviders.count > 0 {
            logger.info("Have both URL and text - treating as highlight share")
            handleHighlightShare(urlProvider: urlProviders[0], textProvider: textProviders[0], extensionItem: extensionItem)
        }
        // Try to find an attachment with URL
        else if let urlProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            logger.info("Found attachment with URL type identifier only")
            handleURLShare(itemProvider: urlProvider, extensionItem: extensionItem)
        }
        // Try plain text as fallback
        else if let textProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            logger.info("Found attachment with plain text type identifier only")
            handleTextShare(itemProvider: textProvider, extensionItem: extensionItem)
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

            // Try to get title and highlight from extension item metadata
            var pageTitle = ""
            var highlightText: String? = nil

            // Check attributedContentText, but only use it if it's not just the URL
            if let contentText = extensionItem.attributedContentText?.string,
               !contentText.isEmpty,
               contentText != shareURL.absoluteString,
               !contentText.starts(with: "http://") && !contentText.starts(with: "https://") {
                pageTitle = contentText
                self.logger.info("handleURLShare: Using attributedContentText as title: \(pageTitle)")
            } else {
                self.logger.info("handleURLShare: No useful title found, leaving empty for user to fill")
            }

            // Check for highlighted text in attachments
            if let attachments = extensionItem.attachments,
               let textProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
                self.logger.info("handleURLShare: Found plain text attachment, checking for highlight")

                textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (text, error) in
                    if let highlightedText = text as? String,
                       !highlightedText.isEmpty,
                       highlightedText != shareURL.absoluteString {
                        highlightText = highlightedText
                        self.logger.info("handleURLShare: Extracted highlight: \(highlightedText)")
                    }

                    // Open the main app with the URL, title, and highlight
                    self.openMainApp(url: shareURL.absoluteString, title: pageTitle, highlight: highlightText)
                }
            } else {
                // No highlight found, just open with URL and title
                self.openMainApp(url: shareURL.absoluteString, title: pageTitle, highlight: nil)
            }
        }
    }

    private func handleHighlightShare(urlProvider: NSItemProvider, textProvider: NSItemProvider, extensionItem: NSExtensionItem) {
        logger.info("handleHighlightShare: Loading both URL and text items")

        // Load URL first
        urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("handleHighlightShare: Error loading URL - \(error.localizedDescription)")
                self.closeExtension()
                return
            }

            guard let shareURL = url as? URL else {
                self.logger.error("handleHighlightShare: Item is not a URL, got: \(String(describing: url))")
                self.closeExtension()
                return
            }

            self.logger.info("handleHighlightShare: URL extracted: \(shareURL.absoluteString)")

            // Now load the highlighted text
            textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (text, textError) in
                if let textError = textError {
                    self.logger.error("handleHighlightShare: Error loading text - \(textError.localizedDescription)")
                    self.closeExtension()
                    return
                }

                guard let highlightText = text as? String, !highlightText.isEmpty else {
                    self.logger.error("handleHighlightShare: Failed to extract highlight text")
                    self.closeExtension()
                    return
                }

                self.logger.info("handleHighlightShare: Highlight extracted: \(highlightText)")

                // Open main app with URL and highlight (no title for highlight shares)
                self.openMainApp(url: shareURL.absoluteString, title: "", highlight: highlightText)
            }
        }
    }

    private func handleTextShare(itemProvider: NSItemProvider, extensionItem: NSExtensionItem) {
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

            // First, try to extract URL from the text itself using regex
            if let extractedURL = self.extractURL(from: sharedText) {
                self.logger.info("handleTextShare: Extracted URL from text: \(extractedURL)")
                let cleanTitle = sharedText.replacingOccurrences(of: extractedURL, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                self.logger.info("handleTextShare: Clean title: \(cleanTitle)")
                self.openMainApp(url: extractedURL, title: cleanTitle, highlight: nil)
                return
            }

            // If no URL in text, check if there's a URL attachment (Safari shares both when text is selected)
            self.logger.info("handleTextShare: No URL in text, checking for URL attachment")

            if let attachments = extensionItem.attachments,
               let urlProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
                self.logger.info("handleTextShare: Found URL attachment")

                urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (urlItem, urlError) in
                    if let pageURL = urlItem as? URL {
                        self.logger.info("handleTextShare: Extracted page URL: \(pageURL.absoluteString)")
                        // The shared text is the highlight, no title
                        self.openMainApp(url: pageURL.absoluteString, title: "", highlight: sharedText)
                    } else {
                        self.logger.error("handleTextShare: Failed to load URL attachment")
                        self.closeExtension()
                    }
                }
            } else {
                // Check if URL is in userInfo (Safari JavaScript preprocessing results)
                self.logger.info("handleTextShare: No URL attachment, checking userInfo")

                if let userInfo = extensionItem.userInfo as? [String: Any] {
                    self.logger.info("handleTextShare: userInfo keys: \(Array(userInfo.keys))")

                    // Try various keys that might contain the URL
                    let possibleKeys = [
                        "NSExtensionJavaScriptPreprocessingResultsKey",
                        "URL",
                        "public.url",
                        "com.apple.UIKit.NSExtensionItemUserInfoIsContentManagedKey"
                    ]

                    for key in possibleKeys {
                        if let value = userInfo[key] {
                            self.logger.info("handleTextShare: Found userInfo[\(key)]: \(String(describing: value))")
                        }
                    }
                }

                self.logger.error("handleTextShare: No URL found in text, attachments, or userInfo")
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

    private func openMainApp(url: String, title: String, highlight: String?) {
        logger.info("openMainApp: URL=\(url), Title=\(title), Highlight=\(highlight ?? "nil")")

        // URL encode the parameters
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            logger.error("openMainApp: Failed to encode URL or title")
            closeExtension()
            return
        }

        // Build deep link URL with optional highlight
        var deepLinkString = "stash://save?url=\(encodedURL)&title=\(encodedTitle)"
        if let highlight = highlight,
           let encodedHighlight = highlight.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            deepLinkString += "&highlight=\(encodedHighlight)"
            logger.info("openMainApp: Including highlight in deep link")
        }

        guard let deepLinkURL = URL(string: deepLinkString) else {
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
