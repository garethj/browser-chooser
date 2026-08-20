import Foundation

/// Generates `[[browsers]]` TOML blocks for browsers (and profiles) detected on this Mac,
/// shared by the `--list-browsers` CLI flag, first-run config bootstrapping, and the
/// "Add Detected Browsers" menu action.
enum BrowserTOML {
    static func blocks(
        detector: BrowserDetector = BrowserDetector(),
        profileDetector: ProfileDetector = ProfileDetector(),
        excludingBundleIDs: Set<String> = []
    ) -> [String] {
        var blocks: [String] = []

        for browser in detector.detectBrowsers() where !excludingBundleIDs.contains(browser.bundleID) {
            let profiles = profileDetector.profiles(forBundleID: browser.bundleID)

            if profiles.isEmpty {
                blocks.append(block(name: browser.name, id: browser.bundleID, profile: nil))
            } else {
                for profile in profiles {
                    blocks.append(block(
                        name: "\(browser.name) — \(profile.displayName)",
                        id: browser.bundleID,
                        profile: profile.directory
                    ))
                }
            }
        }

        return blocks
    }

    private static func block(name: String, id: String, profile: String?) -> String {
        var lines = [
            "[[browsers]]",
            "name = \(tomlString(name))",
            "id = \(tomlString(id))",
        ]
        if let profile {
            lines.append("profile = \(tomlString(profile))")
        }
        return lines.joined(separator: "\n")
    }

    private static func tomlString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
