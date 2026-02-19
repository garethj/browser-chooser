import Testing
import TOMLKit
@testable import BrowserChooser

@Suite("ConfigModel")
struct ConfigModelTests {
    @Test("Full config decodes correctly")
    func fullDecode() throws {
        let toml = """
        [defaults]
        browser = "Safari"

        [[browsers]]
        name = "Chrome Work"
        id = "com.google.Chrome"
        profile = "Default"

        [[browsers]]
        name = "Firefox"
        id = "org.mozilla.firefox"

        [[rules]]
        pattern = "*.github.com"
        browser = "Chrome Work"

        [[rules]]
        pattern = "*.example.com"
        browser = "ask"
        """

        let config = try TOMLDecoder().decode(AppConfig.self, from: toml)

        #expect(config.defaults.browser == "Safari")
        #expect(config.browsers.count == 2)
        #expect(config.browsers[0].name == "Chrome Work")
        #expect(config.browsers[0].id == "com.google.Chrome")
        #expect(config.browsers[0].profile == "Default")
        #expect(config.browsers[1].profile == nil)
        #expect(config.rules.count == 2)
        #expect(config.rules[0].pattern == "*.github.com")
        #expect(config.rules[1].browser == "ask")
    }

    @Test("Minimal config with only defaults")
    func minimalConfig() throws {
        let toml = """
        [defaults]
        browser = "ask"
        """

        let config = try TOMLDecoder().decode(AppConfig.self, from: toml)

        #expect(config.defaults.browser == "ask")
        #expect(config.browsers.isEmpty)
        #expect(config.rules.isEmpty)
    }

    @Test("Missing optional profile field")
    func missingOptionalProfile() throws {
        let toml = """
        [defaults]
        browser = "ask"

        [[browsers]]
        name = "Safari"
        id = "com.apple.Safari"
        """

        let config = try TOMLDecoder().decode(AppConfig.self, from: toml)

        #expect(config.browsers.count == 1)
        #expect(config.browsers[0].profile == nil)
    }

    @Test("Malformed TOML throws error")
    func malformedInput() {
        let badToml = """
        [defaults
        browser = "ask"
        """

        #expect(throws: (any Error).self) {
            try TOMLDecoder().decode(AppConfig.self, from: badToml)
        }
    }

    @Test("AppConfig default initializer")
    func defaultInit() {
        let config = AppConfig()

        #expect(config.defaults.browser == "ask")
        #expect(config.browsers.isEmpty)
        #expect(config.rules.isEmpty)
    }

    @Test("Config equatable conformance")
    func equatable() throws {
        let toml = """
        [defaults]
        browser = "Safari"
        """

        let config1 = try TOMLDecoder().decode(AppConfig.self, from: toml)
        let config2 = try TOMLDecoder().decode(AppConfig.self, from: toml)

        #expect(config1 == config2)
    }
}
