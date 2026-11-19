import Foundation
import os

struct BrowserProfile: Equatable {
    let directory: String
    let displayName: String
}

/// Result of looking up a browser's profiles. `accessDenied` means the browser's data
/// exists but couldn't be read — typically macOS privacy protection, fixed by granting
/// BrowserChooser Full Disk Access — so the profile list is unknown, not empty.
enum ProfileLookup: Equatable {
    case found([BrowserProfile])
    case accessDenied(path: String)

    var profiles: [BrowserProfile] {
        if case .found(let profiles) = self { return profiles }
        return []
    }
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

    static func isGecko(bundleID: String) -> Bool {
        geckoBrowsers[bundleID] != nil
    }

    static let defaultAppSupportDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support")

    /// Where browsers keep their data. Overridable so tests can point it at a temp folder.
    let appSupportDirectory: URL

    init(appSupportDirectory: URL = ProfileDetector.defaultAppSupportDirectory) {
        self.appSupportDirectory = appSupportDirectory
    }

    /// The `Profiles` directory for a Gecko-based browser, e.g.
    /// `~/Library/Application Support/Firefox/Profiles`. `nil` for non-Gecko bundle IDs.
    /// Exposed statically so `BrowserLauncher` can resolve `-profile <path>` without
    /// needing a `ProfileDetector` instance.
    static func geckoProfilesDirectory(
        forBundleID bundleID: String,
        in appSupport: URL = ProfileDetector.defaultAppSupportDirectory
    ) -> URL? {
        guard let dirName = geckoBrowsers[bundleID] else { return nil }
        return appSupport
            .appendingPathComponent(dirName)
            .appendingPathComponent("Profiles")
    }

    /// Profiles for a browser, or `[]` if it has none or they can't be read.
    /// Use `lookup(forBundleID:)` when "can't be read" needs telling apart from "none".
    func profiles(forBundleID bundleID: String) -> [BrowserProfile] {
        lookup(forBundleID: bundleID).profiles
    }

    func lookup(forBundleID bundleID: String) -> ProfileLookup {
        if Self.chromiumBrowsers[bundleID] != nil {
            return chromiumProfiles(forBundleID: bundleID)
        }
        if Self.geckoBrowsers[bundleID] != nil {
            return geckoProfiles(forBundleID: bundleID)
        }
        return .found([])
    }

    /// Whether a read failure means access was refused (e.g. macOS privacy protection
    /// blocking another app's data), as opposed to the file simply not existing.
    static func isAccessDenied(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain {
            return nsError.code == NSFileReadNoPermissionError
        }
        if nsError.domain == NSPOSIXErrorDomain {
            return nsError.code == Int(EPERM) || nsError.code == Int(EACCES)
        }
        return false
    }

    private func failure(_ error: Error, path: URL, bundleID: String) -> ProfileLookup {
        logger.error("Can't read \(path.path, privacy: .public) for \(bundleID, privacy: .public): \(error.localizedDescription, privacy: .public)")
        return Self.isAccessDenied(error) ? .accessDenied(path: path.path) : .found([])
    }

    private func chromiumProfiles(forBundleID bundleID: String) -> ProfileLookup {
        guard let dirName = Self.chromiumBrowsers[bundleID] else { return .found([]) }

        let localState = appSupportDirectory
            .appendingPathComponent(dirName)
            .appendingPathComponent("Local State")

        let data: Data
        do {
            data = try Data(contentsOf: localState)
        } catch {
            return failure(error, path: localState, bundleID: bundleID)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileSection = json["profile"] as? [String: Any],
              let infoCache = profileSection["info_cache"] as? [String: Any] else {
            return .found([])
        }

        var profiles: [BrowserProfile] = []

        for (directory, value) in infoCache {
            guard let info = value as? [String: Any] else { continue }
            let name = info["name"] as? String ?? directory
            profiles.append(BrowserProfile(directory: directory, displayName: name))
            logger.debug("Found profile '\(name)' (\(directory)) for \(bundleID)")
        }

        return .found(profiles.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending })
    }

    private func geckoProfiles(forBundleID bundleID: String) -> ProfileLookup {
        guard let profilesDir = Self.geckoProfilesDirectory(forBundleID: bundleID, in: appSupportDirectory) else {
            return .found([])
        }

        let profilesIni = profilesDir.deletingLastPathComponent().appendingPathComponent("profiles.ini")
        let names = (try? String(contentsOf: profilesIni, encoding: .utf8)).map(Self.parseProfilesIni) ?? [:]

        let entries: [URL]
        do {
            entries = try FileManager.default.contentsOfDirectory(
                at: profilesDir, includingPropertiesForKeys: [.isDirectoryKey]
            )
        } catch {
            return failure(error, path: profilesDir, bundleID: bundleID)
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

        return .found(profiles.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending })
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
