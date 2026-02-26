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

    @Test("Rule with patterns array decodes correctly")
    func patternsArray() throws {
        let toml = """
        [defaults]
        browser = "ask"

        [[rules]]
        patterns = ["*.notion.so", "*.hibob.com", "*.okta.com"]
        browser = "Chrome Work"
        """

        let config = try TOMLDecoder().decode(AppConfig.self, from: toml)

        #expect(config.rules.count == 1)
        #expect(config.rules[0].pattern == nil)
        #expect(config.rules[0].patterns == ["*.notion.so", "*.hibob.com", "*.okta.com"])
        #expect(config.rules[0].allPatterns == ["*.notion.so", "*.hibob.com", "*.okta.com"])
    }

    @Test("Rule with singular pattern returns it from allPatterns")
    func singularPatternAllPatterns() throws {
        let toml = """
        [defaults]
        browser = "ask"

        [[rules]]
        pattern = "*.github.com"
        browser = "Safari"
        """

        let config = try TOMLDecoder().decode(AppConfig.self, from: toml)

        #expect(config.rules[0].allPatterns == ["*.github.com"])
    }

    @Test("Rule with neither pattern nor patterns returns empty allPatterns")
    func noPatternReturnsEmpty() {
        let rule = RuleConfig(browser: "Safari")
        #expect(rule.allPatterns.isEmpty)
    }

    @Test("Mixed singular and array rules decode together")
    func mixedRules() throws {
        let toml = """
        [defaults]
        browser = "ask"

        [[rules]]
        pattern = "*.github.com"
        browser = "Safari"

        [[rules]]
        patterns = ["*.notion.so", "*.hibob.com"]
        browser = "Chrome Work"

        [[rules]]
        pattern = "*.google.com"
        browser = "ask"
        """

        let config = try TOMLDecoder().decode(AppConfig.self, from: toml)

        #expect(config.rules.count == 3)
        #expect(config.rules[0].allPatterns == ["*.github.com"])
        #expect(config.rules[1].allPatterns == ["*.notion.so", "*.hibob.com"])
        #expect(config.rules[2].allPatterns == ["*.google.com"])
    }
}
