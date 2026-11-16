import Foundation

/// Generates `[[browsers]]` TOML blocks for browsers (and profiles) detected on this Mac,
/// shared by the `--list-browsers` CLI flag, first-run config bootstrapping, and the
/// "Add Detected Browsers" menu action.
enum BrowserTOML {
    static func blocks(
        detector: BrowserDetector = BrowserDetector(),
        profileDetector: ProfileDetector = ProfileDetector(),
        excluding existing: [BrowserConfig] = []
    ) -> [String] {
        var blocks: [String] = []

        for browser in detector.detectBrowsers() {
            let profiles = profileDetector.profiles(forBundleID: browser.bundleID)

            if profiles.isEmpty {
                if !isConfigured(bundleID: browser.bundleID, profile: nil, in: existing) {
                    blocks.append(block(name: browser.name, id: browser.bundleID, profile: nil))
                }
            } else {
                for profile in profiles
                where !isConfigured(bundleID: browser.bundleID, profile: profile.directory, in: existing) {
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

    /// Whether a detected browser/profile is already covered by a config entry. Matching is
    /// per (bundle ID, profile), so a new profile of an already-configured browser still
    /// counts as new. A config entry with no `profile` covers every profile of that browser,
    /// and a detected browser with no profiles is covered by any entry with its bundle ID.
    static func isConfigured(bundleID: String, profile: String?, in existing: [BrowserConfig]) -> Bool {
        existing.contains { entry in
            guard entry.id == bundleID else { return false }
            guard let profile, let entryProfile = entry.profile else { return true }
            return entryProfile == profile
        }
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
