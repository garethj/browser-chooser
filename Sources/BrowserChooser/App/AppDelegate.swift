import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "AppDelegate")
    let configManager = ConfigManager()
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        rebuildURLHandler()
    }

    func rebuildURLHandler() {
        let registry = BrowserRegistry(
            detector: BrowserDetector(),
            profileDetector: ProfileDetector(),
            configBrowsers: configManager.config.browsers
        )
        let matcher = URLMatcher()
        let launcher = BrowserLauncher()
        let pickerController = PickerController()

        let handler = URLHandler(
            config: configManager.config,
            registry: registry,
            matcher: matcher,
            launcher: launcher,
            pickerController: pickerController
        )
        urlHandler = handler
        flushPendingURLs()
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
            logger.info("URL handler not ready, queueing URL")
            pendingURLs.append(url)
        }
    }

    func flushPendingURLs() {
        guard let handler = urlHandler else { return }
        for url in pendingURLs {
            logger.info("Flushing queued URL: \(url.absoluteString)")
            handler.handle(url: url)
        }
        pendingURLs.removeAll()
    }
}
