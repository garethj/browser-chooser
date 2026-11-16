import Foundation
import Testing
import TOMLKit
@testable import BrowserChooser

@Suite("ConfigManager.defaultConfigContents")
struct ConfigBootstrapTests {
    @Test("Generated default config is valid, parseable TOML")
    func defaultConfigParses() throws {
        let contents = ConfigManager.defaultConfigContents()
        let config = try TOMLDecoder().decode(AppConfig.self, from: contents)
        #expect(config.defaults.browser == "ask")
    }

    @Test("Detected browser blocks are individually valid TOML browser entries")
    func detectedBlocksParse() throws {
        let blocks = BrowserTOML.blocks()
        for block in blocks {
            let wrapped = """
            [defaults]
            browser = "ask"

            \(block)
            """
            let config = try TOMLDecoder().decode(AppConfig.self, from: wrapped)
            #expect(config.browsers.count == 1)
        }
    }

    @Test("A profile-less config entry omits all of that browser's blocks")
    func excludingBundleIDFiltersBlocks() {
        let all = BrowserTOML.blocks()
        guard let firstID = all.first.flatMap(bundleID(from:)) else { return }

        let filtered = BrowserTOML.blocks(excluding: [BrowserConfig(name: "X", id: firstID)])
        #expect(!filtered.contains { bundleID(from: $0) == firstID })
    }

    @Test("A new profile of an already-configured browser is not treated as configured")
    func newProfileOfConfiguredBrowserIsNew() {
        let existing = [
            BrowserConfig(name: "Firefox Personal", id: "org.mozilla.firefox", profile: "abc.default-release"),
            BrowserConfig(name: "Firefox Work", id: "org.mozilla.firefox", profile: "def.Profile 1"),
        ]
        #expect(BrowserTOML.isConfigured(bundleID: "org.mozilla.firefox", profile: "abc.default-release", in: existing))
        #expect(!BrowserTOML.isConfigured(bundleID: "org.mozilla.firefox", profile: "ghi.Profile 2", in: existing))
        #expect(!BrowserTOML.isConfigured(bundleID: "com.google.Chrome", profile: "Default", in: existing))
    }

    @Test("Profile-less entries and profile-less browsers match on bundle ID alone")
    func profileLessMatching() {
        let existing = [
            BrowserConfig(name: "Firefox", id: "org.mozilla.firefox"),
            BrowserConfig(name: "Chrome Work", id: "com.google.Chrome", profile: "Profile 1"),
        ]
        #expect(BrowserTOML.isConfigured(bundleID: "org.mozilla.firefox", profile: "any.profile", in: existing))
        #expect(BrowserTOML.isConfigured(bundleID: "com.google.Chrome", profile: nil, in: existing))
        #expect(!BrowserTOML.isConfigured(bundleID: "com.apple.Safari", profile: nil, in: existing))
    }

    private func bundleID(from block: String) -> String? {
        for line in block.split(separator: "\n") where line.hasPrefix("id = ") {
            return line.dropFirst("id = ".count).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }
}
