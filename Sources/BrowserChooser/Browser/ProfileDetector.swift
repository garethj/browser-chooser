import Foundation
import os

struct ChromiumProfile {
    let directory: String
    let displayName: String
}

final class ProfileDetector {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "ProfileDetector")

    // Chromium-based browsers and their Application Support directory names
    private static let chromiumBrowsers: [String: String] = [
        "com.google.Chrome": "Google/Chrome",
        "com.google.Chrome.canary": "Google/Chrome Canary",
        "com.brave.Browser": "BraveSoftware/Brave-Browser",
        "com.microsoft.edgemac": "Microsoft Edge",
        "com.vivaldi.Vivaldi": "Vivaldi",
        "company.thebrowser.Browser": "Arc/User Data",
    ]

    func profiles(forBundleID bundleID: String) -> [ChromiumProfile] {
        guard let dirName = Self.chromiumBrowsers[bundleID] else { return [] }

        let appSupport = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support")
            .appendingPathComponent(dirName)

        let localState = appSupport.appendingPathComponent("Local State")

        guard let data = try? Data(contentsOf: localState),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileSection = json["profile"] as? [String: Any],
              let infoCache = profileSection["info_cache"] as? [String: Any] else {
            return []
        }

        var profiles: [ChromiumProfile] = []

        for (directory, value) in infoCache {
            guard let info = value as? [String: Any] else { continue }
            let name = info["name"] as? String ?? directory
            profiles.append(ChromiumProfile(directory: directory, displayName: name))
            logger.debug("Found profile '\(name)' (\(directory)) for \(bundleID)")
        }

        return profiles.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
