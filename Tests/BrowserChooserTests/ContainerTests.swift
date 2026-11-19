import AppKit
import Testing
import TOMLKit
@testable import BrowserChooser

@Suite("Firefox containers")
struct ContainerTests {
    @Test("Wraps a URL in an ext+container link")
    func wrapsSimpleURL() throws {
        let url = try #require(URL(string: "https://example.com"))
        let wrapped = ContainerURL.wrap(url, container: "CPR")
        #expect(wrapped?.absoluteString == "ext+container:name=CPR&url=https%3A%2F%2Fexample.com")
    }

    @Test("Percent-encodes query, fragment and container name so they survive the wrap")
    func encodesSpecialCharacters() throws {
        let url = try #require(URL(string: "https://example.com/a b?x=1&y=2#top"))
        let wrapped = try #require(ContainerURL.wrap(url, container: "Win ACC&Co"))
        let string = wrapped.absoluteString

        #expect(string.hasPrefix("ext+container:name=Win%20ACC%26Co&url="))
        // The only raw & and = are the extension's own separators.
        #expect(string.filter { $0 == "&" }.count == 1)
        #expect(string.filter { $0 == "=" }.count == 2)

        let query = String(string.dropFirst("ext+container:".count))
        let params = Dictionary(uniqueKeysWithValues: query.split(separator: "&").map {
            let parts = $0.split(separator: "=", maxSplits: 1)
            return (String(parts[0]), String(parts[1]).removingPercentEncoding!)
        })
        #expect(params["name"] == "Win ACC&Co")
        #expect(params["url"] == url.absoluteString)
    }

    @Test("Config decodes the container field")
    func decodesContainer() throws {
        let toml = """
        [[browsers]]
        name = "Firefox CPR"
        id = "org.mozilla.firefox"
        container = "CPR"

        [[browsers]]
        name = "Firefox"
        id = "org.mozilla.firefox"
        """
        let config = try TOMLDecoder().decode(AppConfig.self, from: toml)
        #expect(config.browsers[0].container == "CPR")
        #expect(config.browsers[1].container == nil)
    }

    @Test("Container entries get distinct IDs from plain and profile entries")
    func distinctIDs() {
        let icon = NSImage()
        let plain = ResolvedBrowser(name: "Firefox", bundleID: "org.mozilla.firefox", icon: icon)
        let cpr = ResolvedBrowser(name: "Firefox CPR", bundleID: "org.mozilla.firefox", icon: icon, container: "CPR")
        let hb = ResolvedBrowser(name: "Firefox HB", bundleID: "org.mozilla.firefox", icon: icon, container: "HB")
        #expect(Set([plain.id, cpr.id, hb.id]).count == 3)
    }

    @Test("Container on a non-Firefox browser produces a warning")
    func warnsForNonGecko() {
        let config = AppConfig(browsers: [
            BrowserConfig(name: "Chrome CPR", id: "com.google.Chrome", container: "CPR"),
            BrowserConfig(name: "Firefox CPR", id: "org.mozilla.firefox", container: "CPR"),
        ])
        let warnings = BrowserRegistry.validationWarnings(
            config: config,
            knownBrowserNames: ["chrome cpr", "firefox cpr"],
            profilesByBundleID: [:]
        )
        #expect(warnings.count == 1)
        #expect(warnings.first?.contains("Chrome CPR") == true)
    }
}
