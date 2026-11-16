import AppKit
import Foundation
import Testing
@testable import BrowserChooser

/// Covers the case where macOS refuses access to a browser's data (seen in practice when
/// BrowserChooser lacks Full Disk Access): it must be reported, not treated as "no profiles".
/// `chmod 000` on a temp folder reproduces the same permission-denied error.
@Suite("Profile access failures")
struct ProfileAccessTests {
    /// A temp Application Support folder; removed (after restoring permissions) on deinit.
    final class TempAppSupport {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("bc-tests-\(UUID().uuidString)")
        var locked: [URL] = []

        func makeFirefoxProfiles(_ names: [String]) throws -> URL {
            let dir = url.appendingPathComponent("Firefox/Profiles")
            for name in names {
                try FileManager.default.createDirectory(
                    at: dir.appendingPathComponent(name), withIntermediateDirectories: true)
            }
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }

        func lock(_ path: URL) throws {
            try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: path.path)
            locked.append(path)
        }

        deinit {
            for path in locked {
                try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: path.path)
            }
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func firefox() -> DetectedBrowser {
        DetectedBrowser(name: "Firefox", bundleID: "org.mozilla.firefox", icon: NSImage(),
                        appURL: URL(fileURLWithPath: "/Applications/Firefox.app"))
    }

    @Test("Readable Firefox profiles are found")
    func readableProfiles() throws {
        let tmp = TempAppSupport()
        _ = try tmp.makeFirefoxProfiles(["abc.default-release", "def.Profile 2"])

        let lookup = ProfileDetector(appSupportDirectory: tmp.url).lookup(forBundleID: "org.mozilla.firefox")
        #expect(lookup.profiles.map(\.directory) == ["abc.default-release", "def.Profile 2"])
    }

    @Test("A missing profile folder means no profiles, not access denied")
    func missingFolder() {
        let tmp = TempAppSupport()
        let lookup = ProfileDetector(appSupportDirectory: tmp.url).lookup(forBundleID: "org.mozilla.firefox")
        #expect(lookup == .found([]))
    }

    @Test("An unreadable Firefox profile folder is reported as access denied")
    func unreadableFirefox() throws {
        let tmp = TempAppSupport()
        let dir = try tmp.makeFirefoxProfiles(["abc.default-release"])
        try tmp.lock(dir)

        let lookup = ProfileDetector(appSupportDirectory: tmp.url).lookup(forBundleID: "org.mozilla.firefox")
        #expect(lookup == .accessDenied(path: dir.path))
    }

    @Test("An unreadable Chrome Local State file is reported as access denied")
    func unreadableChrome() throws {
        let tmp = TempAppSupport()
        let chromeDir = tmp.url.appendingPathComponent("Google/Chrome")
        try FileManager.default.createDirectory(at: chromeDir, withIntermediateDirectories: true)
        let localState = chromeDir.appendingPathComponent("Local State")
        try Data(#"{"profile":{"info_cache":{"Default":{"name":"Me"}}}}"#.utf8).write(to: localState)
        try tmp.lock(localState)

        let lookup = ProfileDetector(appSupportDirectory: tmp.url).lookup(forBundleID: "com.google.Chrome")
        #expect(lookup == .accessDenied(path: localState.path))
    }

    @Test("Add Detected Browsers skips a browser whose profiles can't be read")
    func addDetectedSkipsUnreadable() throws {
        let tmp = TempAppSupport()
        let dir = try tmp.makeFirefoxProfiles(["abc.default-release"])
        try tmp.lock(dir)

        let blocks = BrowserTOML.blocks(
            for: [firefox()], profileDetector: ProfileDetector(appSupportDirectory: tmp.url))
        #expect(blocks.isEmpty)
    }

    @Test("Add Detected Browsers adds a new profile when profiles are readable")
    func addDetectedAddsNewProfile() throws {
        let tmp = TempAppSupport()
        _ = try tmp.makeFirefoxProfiles(["abc.default-release", "def.Profile 2"])

        let blocks = BrowserTOML.blocks(
            for: [firefox()],
            profileDetector: ProfileDetector(appSupportDirectory: tmp.url),
            excluding: [BrowserConfig(name: "Firefox - Personal", id: "org.mozilla.firefox", profile: "abc.default-release")]
        )
        #expect(blocks.count == 1)
        #expect(blocks.first?.contains(#"profile = "def.Profile 2""#) == true)
    }

    @Test("Unreadable browsers produce a single Full Disk Access warning naming them")
    func unreadableWarning() {
        let warnings = BrowserRegistry.validationWarnings(
            config: AppConfig(),
            knownBrowserNames: [],
            profilesByBundleID: [:],
            unreadableProfileBrowsers: ["Firefox", "Google Chrome"]
        )
        #expect(warnings.count == 1)
        #expect(warnings.first?.contains("Firefox, Google Chrome") == true)
        #expect(warnings.first?.contains("Full Disk Access") == true)
    }
}
