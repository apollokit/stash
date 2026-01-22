import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Extract the shared URL
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            closeExtension()
            return
        }

        // Check if it's a URL
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
        } else {
            closeExtension()
        }
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
