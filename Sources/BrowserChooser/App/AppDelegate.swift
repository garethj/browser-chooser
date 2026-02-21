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
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleOpenDocumentEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEOpenDocuments)
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

    @objc private func handleOpenDocumentEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let listDescriptor = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else {
            logger.error("Received invalid open document event")
            return
        }

        let count = listDescriptor.numberOfItems
        guard count > 0 else { return }

        for i in 1...count {
            guard let itemDescriptor = listDescriptor.atIndex(i),
                  let urlData = itemDescriptor.coerce(toDescriptorType: typeFileURL)?.data,
                  let urlString = String(data: urlData, encoding: .utf8),
                  let url = URL(string: urlString) else {
                logger.warning("Could not extract file URL from descriptor at index \(i)")
                continue
            }

            logger.info("Received file: \(url.path)")
            if let handler = urlHandler {
                handler.handle(url: url)
            } else {
                logger.info("URL handler not ready, queueing file URL")
                pendingURLs.append(url)
            }
        }
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
