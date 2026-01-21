import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Extract shared content
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        // Check for URL
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                guard let self = self,
                      let shareURL = url as? URL else {
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    return
                }

                // Get page title if available
                let title = extensionItem.attributedContentText?.string ?? shareURL.absoluteString

                // Create deep link to open main app
                self.openMainApp(url: shareURL.absoluteString, title: title)
            }
        } else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    private func openMainApp(url: String, title: String) {
        // Create deep link URL with shared content
        let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let deepLink = "stash://save?url=\(encodedURL)&title=\(encodedTitle)"

        guard let url = URL(string: deepLink) else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        // Open main app
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:]) { [weak self] success in
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }
                return
            }
            responder = responder?.next
        }

        // Fallback: complete the request
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
