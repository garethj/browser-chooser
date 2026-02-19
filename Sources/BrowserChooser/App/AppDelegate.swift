import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "AppDelegate")
    var urlHandler: URLHandler?
    private var pendingURLs: [URL] = []

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            logger.error("Received invalid URL event")
            return
        }
        logger.info("Received URL: \(urlString)")

        if let handler = urlHandler {
            handler.handle(url: url)
        } else {
            // URL arrived before handler was set up — queue it
            logger.info("URL handler not ready, queueing URL")
            pendingURLs.append(url)
        }
    }

    /// Called by the app when the URL handler is ready; flushes any queued URLs.
    func flushPendingURLs() {
        guard let handler = urlHandler else { return }
        for url in pendingURLs {
            logger.info("Flushing queued URL: \(url.absoluteString)")
            handler.handle(url: url)
        }
        pendingURLs.removeAll()
    }
}
