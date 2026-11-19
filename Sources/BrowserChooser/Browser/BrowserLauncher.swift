import AppKit
import os

final class BrowserLauncher {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "BrowserLauncher")

    func launch(url originalURL: URL, browser: ResolvedBrowser) {
        var url = originalURL
        if let container = browser.container, ProfileDetector.isGecko(bundleID: browser.bundleID) {
            if let wrapped = ContainerURL.wrap(originalURL, container: container) {
                url = wrapped
            } else {
                logger.error("Couldn't build container link for \(container); opening without a container")
            }
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleID) else {
            logger.error("Cannot find application for \(browser.bundleID)")
            NSWorkspace.shared.open(originalURL)
            return
        }

        if let profileDir = browser.profileDirectory {
            // Use `open` command for profile-specific launches — NSWorkspace.OpenConfiguration
            // arguments are ignored when the app is already running.
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")

            let profileArgs: [String]
            if let geckoProfilesDir = ProfileDetector.geckoProfilesDirectory(forBundleID: browser.bundleID) {
                // Firefox family: -profile takes an absolute path, not a bare name.
                profileArgs = ["-profile", geckoProfilesDir.appendingPathComponent(profileDir).path]
            } else {
                // Chromium family: --profile-directory takes the profile's bare directory name.
                profileArgs = ["--profile-directory=\(profileDir)"]
            }

            process.arguments = ["-na", appURL.path, "--args"] + profileArgs + [url.absoluteString]
            do {
                try process.run()
                logger.info("Opened \(url.absoluteString) in \(browser.name) via open -na")
            } catch {
                logger.error("Failed to launch via open: \(error.localizedDescription)")
                NSWorkspace.shared.open(originalURL)
            }
        } else {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
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
}
