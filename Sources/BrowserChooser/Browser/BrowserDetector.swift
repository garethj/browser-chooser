import AppKit
import UniformTypeIdentifiers
import os

struct DetectedBrowser {
    let name: String
    let bundleID: String
    let icon: NSImage
    let appURL: URL
}

final class BrowserDetector {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "BrowserDetector")

    func detectBrowsers() -> [DetectedBrowser] {
        let httpsURL = URL(string: "https://example.com")!
        let httpHandlers = Set(NSWorkspace.shared.urlsForApplications(toOpen: httpsURL))

        let htmlHandlers = Set(NSWorkspace.shared.urlsForApplications(toOpen: UTType.html))

        let browserURLs = httpHandlers.intersection(htmlHandlers)
        let selfBundleID = Bundle.main.bundleIdentifier ?? "com.garethj.BrowserChooser"

        var browsers: [DetectedBrowser] = []

        for url in browserURLs {
            guard let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier,
                  bundleID != selfBundleID else {
                continue
            }

            let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent

            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 32, height: 32)

            browsers.append(DetectedBrowser(
                name: name,
                bundleID: bundleID,
                icon: icon,
                appURL: url
            ))

            logger.debug("Detected browser: \(name) (\(bundleID))")
        }

        return browsers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
