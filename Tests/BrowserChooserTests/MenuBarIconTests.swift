import Testing
@testable import BrowserChooser

@Suite("MenuBarIcon.systemImageName")
struct MenuBarIconTests {
    @Test("Clean config shows the globe icon")
    func cleanConfig() {
        let name = MenuBarIcon.systemImageName(lastError: nil, warnings: [])
        #expect(name == "globe")
    }

    @Test("Config error shows the triangle icon")
    func configError() {
        let name = MenuBarIcon.systemImageName(lastError: "Malformed TOML", warnings: [])
        #expect(name == "exclamationmark.triangle.fill")
    }

    @Test("Warnings with no error show the circle icon")
    func warningsOnly() {
        let name = MenuBarIcon.systemImageName(lastError: nil, warnings: ["Unknown browser \"Chrome Work\""])
        #expect(name == "exclamationmark.circle.fill")
    }

    @Test("Error takes precedence over warnings")
    func errorTakesPrecedence() {
        let name = MenuBarIcon.systemImageName(
            lastError: "Malformed TOML",
            warnings: ["Unknown browser \"Chrome Work\""]
        )
        #expect(name == "exclamationmark.triangle.fill")
    }
}
