import AppKit
import os

final class BrowserLauncher {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "BrowserLauncher")

    func launch(url: URL, browser: ResolvedBrowser) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleID) else {
            logger.error("Cannot find application for \(browser.bundleID)")
            // Fall back to system default
            NSWorkspace.shared.open(url)
            return
        }

        let config = NSWorkspace.OpenConfiguration()

        if let profileDir = browser.profileDirectory {
            config.arguments = ["--profile-directory=\(profileDir)"]
        }

        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
            configuration: config
        ) { [logger] app, error in
            if let error {
                logger.error("Failed to open URL: \(error.localizedDescription)")
            } else {
                logger.info("Opened \(url.absoluteString) in \(browser.name) (pid: \(app?.processIdentifier ?? -1))")
            }
        }
    }
}
