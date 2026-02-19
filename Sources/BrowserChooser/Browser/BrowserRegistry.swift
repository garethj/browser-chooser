import AppKit
import os

final class BrowserRegistry {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "BrowserRegistry")
    private(set) var browsers: [ResolvedBrowser] = []

    init(detector: BrowserDetector, profileDetector: ProfileDetector, configBrowsers: [BrowserConfig]) {
        let detected = detector.detectBrowsers()
        var result: [ResolvedBrowser] = []
        var coveredIDs = Set<String>()

        // Config browsers first — they take priority
        for cb in configBrowsers {
            let icon = detected.first(where: { $0.bundleID == cb.id })?.icon
                ?? NSWorkspace.shared.icon(forFile: "/Applications")
            icon.size = NSSize(width: 32, height: 32)

            let browser = ResolvedBrowser(
                name: cb.name,
                bundleID: cb.id,
                icon: icon,
                profileDirectory: cb.profile
            )
            result.append(browser)
            coveredIDs.insert(browser.id)
            logger.debug("Added config browser: \(cb.name)")
        }

        // Auto-detected browsers that aren't already covered
        for db in detected {
            let profiles = profileDetector.profiles(forBundleID: db.bundleID)

            if profiles.isEmpty {
                let browser = ResolvedBrowser(name: db.name, bundleID: db.bundleID, icon: db.icon)
                if !coveredIDs.contains(browser.id) {
                    result.append(browser)
                    coveredIDs.insert(browser.id)
                }
            } else {
                for profile in profiles {
                    let browser = ResolvedBrowser(
                        name: "\(db.name) — \(profile.displayName)",
                        bundleID: db.bundleID,
                        icon: db.icon,
                        profileDirectory: profile.directory
                    )
                    if !coveredIDs.contains(browser.id) {
                        result.append(browser)
                        coveredIDs.insert(browser.id)
                    }
                }
            }
        }

        browsers = result
        logger.info("Registry built with \(result.count) browser(s)")
    }

    func browser(named name: String) -> ResolvedBrowser? {
        browsers.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }
}
