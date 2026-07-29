import Testing
@testable import BrowserChooser

@Suite("BrowserRegistry.validationWarnings")
struct BrowserRegistryValidationTests {
    @Test("Clean config produces no warnings")
    func cleanConfig() {
        let config = AppConfig(
            defaults: DefaultsConfig(browser: "Chrome Work"),
            browsers: [BrowserConfig(name: "Chrome Work", id: "com.google.Chrome", profile: "Default")],
            rules: [RuleConfig(pattern: "*.github.com", browser: "Chrome Work")]
        )

        let warnings = BrowserRegistry.validationWarnings(
            config: config,
            knownBrowserNames: ["chrome work"],
            profilesByBundleID: ["com.google.Chrome": [BrowserProfile(directory: "Default", displayName: "Gareth")]]
        )

        #expect(warnings.isEmpty)
    }

    @Test("Unknown profile directory produces a warning listing available profiles")
    func badProfile() {
        let config = AppConfig(
            browsers: [BrowserConfig(name: "Chrome - Henry Beaufort", id: "com.google.Chrome", profile: "Profile 1")]
        )

        let warnings = BrowserRegistry.validationWarnings(
            config: config,
            knownBrowserNames: ["chrome - henry beaufort"],
            profilesByBundleID: [
                "com.google.Chrome": [
                    BrowserProfile(directory: "Default", displayName: "Gareth"),
                    BrowserProfile(directory: "Profile 2", displayName: "HB"),
                ]
            ]
        )

        #expect(warnings.count == 1)
        #expect(warnings[0].contains("Chrome - Henry Beaufort"))
        #expect(warnings[0].contains("Profile 1"))
        #expect(warnings[0].contains("Profile 2 (HB)"))
    }

    @Test("Profile that can't be verified (unreadable Local State) is skipped")
    func unverifiableProfileSkipped() {
        let config = AppConfig(
            browsers: [BrowserConfig(name: "Safari", id: "com.apple.Safari", profile: "whatever")]
        )

        let warnings = BrowserRegistry.validationWarnings(
            config: config,
            knownBrowserNames: ["safari"],
            profilesByBundleID: [:]
        )

        #expect(warnings.isEmpty)
    }

    @Test("Unknown default browser produces a warning")
    func badDefault() {
        let config = AppConfig(defaults: DefaultsConfig(browser: "Nonexistent"))

        let warnings = BrowserRegistry.validationWarnings(
            config: config,
            knownBrowserNames: [],
            profilesByBundleID: [:]
        )

        #expect(warnings.count == 1)
        #expect(warnings[0].contains("Nonexistent"))
    }

    @Test("'ask' as default browser produces no warning")
    func askDefaultIsFine() {
        let config = AppConfig(defaults: DefaultsConfig(browser: "ask"))

        let warnings = BrowserRegistry.validationWarnings(
            config: config,
            knownBrowserNames: [],
            profilesByBundleID: [:]
        )

        #expect(warnings.isEmpty)
    }

    @Test("Rule with no pattern produces a warning")
    func emptyRulePattern() {
        let config = AppConfig(rules: [RuleConfig(browser: "ask")])

        let warnings = BrowserRegistry.validationWarnings(
            config: config,
            knownBrowserNames: [],
            profilesByBundleID: [:]
        )

        #expect(warnings.count == 1)
        #expect(warnings[0].contains("no pattern"))
    }

    @Test("Rule referencing unknown browser produces a warning")
    func unknownRuleBrowser() {
        let config = AppConfig(rules: [RuleConfig(pattern: "*.example.com", browser: "Nonexistent")])

        let warnings = BrowserRegistry.validationWarnings(
            config: config,
            knownBrowserNames: [],
            profilesByBundleID: [:]
        )

        #expect(warnings.count == 1)
        #expect(warnings[0].contains("Nonexistent"))
        #expect(warnings[0].contains("*.example.com"))
    }
}
