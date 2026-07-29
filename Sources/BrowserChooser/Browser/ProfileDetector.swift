import Foundation
import os

struct BrowserProfile {
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

    // Gecko-based (Firefox family) browsers and their Application Support directory names
    private static let geckoBrowsers: [String: String] = [
        "org.mozilla.firefox": "Firefox",
        "org.mozilla.firefoxdeveloperedition": "Firefox Developer Edition",
        "org.mozilla.nightly": "Firefox Nightly",
    ]

    /// The `Profiles` directory for a Gecko-based browser, e.g.
    /// `~/Library/Application Support/Firefox/Profiles`. `nil` for non-Gecko bundle IDs.
    /// Exposed statically so `BrowserLauncher` can resolve `-profile <path>` without
    /// needing a `ProfileDetector` instance.
    static func geckoProfilesDirectory(forBundleID bundleID: String) -> URL? {
        guard let dirName = geckoBrowsers[bundleID] else { return nil }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support")
            .appendingPathComponent(dirName)
            .appendingPathComponent("Profiles")
    }

    func profiles(forBundleID bundleID: String) -> [BrowserProfile] {
        if Self.chromiumBrowsers[bundleID] != nil {
            return chromiumProfiles(forBundleID: bundleID)
        }
        if Self.geckoBrowsers[bundleID] != nil {
            return geckoProfiles(forBundleID: bundleID)
        }
        return []
    }

    private func chromiumProfiles(forBundleID bundleID: String) -> [BrowserProfile] {
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

        var profiles: [BrowserProfile] = []

        for (directory, value) in infoCache {
            guard let info = value as? [String: Any] else { continue }
            let name = info["name"] as? String ?? directory
            profiles.append(BrowserProfile(directory: directory, displayName: name))
            logger.debug("Found profile '\(name)' (\(directory)) for \(bundleID)")
        }

        return profiles.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private func geckoProfiles(forBundleID bundleID: String) -> [BrowserProfile] {
        guard let profilesDir = Self.geckoProfilesDirectory(forBundleID: bundleID) else { return [] }

        let profilesIni = profilesDir.deletingLastPathComponent().appendingPathComponent("profiles.ini")
        let names = (try? String(contentsOf: profilesIni, encoding: .utf8)).map(Self.parseProfilesIni) ?? [:]

        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: profilesDir, includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return []
        }

        var profiles: [BrowserProfile] = []

        for entry in entries {
            guard (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            let directory = entry.lastPathComponent
            // Profiles created via Firefox's newer multi-profile panel aren't registered
            // in profiles.ini (only in a separate SQLite "Profile Groups" store), so they
            // fall back to their raw folder name here.
            let name = names[directory] ?? directory
            profiles.append(BrowserProfile(directory: directory, displayName: name))
            logger.debug("Found profile '\(name)' (\(directory)) for \(bundleID)")
        }

        return profiles.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// Parses Firefox's `profiles.ini` format into `[folder name: display name]`.
    static func parseProfilesIni(_ content: String) -> [String: String] {
        var result: [String: String] = [:]
        var currentPath: String?
        var currentName: String?

        func flush() {
            if let path = currentPath, let name = currentName {
                result[path] = name
            }
            currentPath = nil
            currentName = nil
        }

        for rawLine in content.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                flush()
            } else if line.hasPrefix("Name=") {
                currentName = String(line.dropFirst("Name=".count))
            } else if line.hasPrefix("Path=") {
                currentPath = String(line.dropFirst("Path=".count)).components(separatedBy: "/").last
            }
        }
        flush()

        return result
    }
}
