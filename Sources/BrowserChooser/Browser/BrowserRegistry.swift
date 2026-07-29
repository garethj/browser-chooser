import AppKit
import os

final class BrowserRegistry {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "BrowserRegistry")
    private(set) var browsers: [ResolvedBrowser] = []

    init(detector: BrowserDetector, profileDetector: ProfileDetector, configBrowsers: [BrowserConfig]) {
        let detected = detector.detectBrowsers()
        var result: [ResolvedBrowser] = []

        // Track which bundle IDs have config overrides — suppress auto-detection for those
        let configuredBundleIDs = Set(configBrowsers.map(\.id))

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
            logger.debug("Added config browser: \(cb.name)")
        }

        // Auto-detected browsers — skip any bundle ID that has config entries
        for db in detected {
            if configuredBundleIDs.contains(db.bundleID) {
                logger.debug("Skipping auto-detected \(db.bundleID) — overridden by config")
                continue
            }

            let profiles = profileDetector.profiles(forBundleID: db.bundleID)

            if profiles.isEmpty {
                result.append(ResolvedBrowser(name: db.name, bundleID: db.bundleID, icon: db.icon))
            } else {
                for profile in profiles {
                    result.append(ResolvedBrowser(
                        name: "\(db.name) — \(profile.displayName)",
                        bundleID: db.bundleID,
                        icon: db.icon,
                        profileDirectory: profile.directory
                    ))
                }
            }
        }

        browsers = result
        logger.info("Registry built with \(result.count) browser(s)")
    }

    func browser(named name: String) -> ResolvedBrowser? {
        browsers.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    static func validationWarnings(
        config: AppConfig,
        knownBrowserNames: Set<String>,
        profilesByBundleID: [String: [BrowserProfile]]
    ) -> [String] {
        var warnings: [String] = []

        for cb in config.browsers {
            guard let profile = cb.profile,
                  let profiles = profilesByBundleID[cb.id],
                  !profiles.isEmpty,
                  !profiles.contains(where: { $0.directory == profile }) else { continue }

            let available = profiles.map { "\($0.directory) (\($0.displayName))" }.joined(separator: ", ")
            warnings.append("Browser '\(cb.name)' references profile '\(profile)', which doesn't exist. Available profiles: \(available).")
        }

        if config.defaults.browser.lowercased() != "ask",
           !knownBrowserNames.contains(config.defaults.browser.lowercased()) {
            warnings.append("Default browser '\(config.defaults.browser)' does not match any configured or detected browser.")
        }

        for rule in config.rules {
            if rule.allPatterns.isEmpty {
                warnings.append("A rule has no pattern set and will never match (browser: '\(rule.browser)').")
            } else if rule.browser.lowercased() != "ask",
                      !knownBrowserNames.contains(rule.browser.lowercased()) {
                warnings.append("Rule for pattern(s) \(rule.allPatterns.joined(separator: ", ")) references unknown browser '\(rule.browser)'.")
            }
        }

        return warnings
    }
}
