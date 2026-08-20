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
        let blocks = BrowserTOML.blocks(excludingBundleIDs: [])
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

    @Test("Excluding a bundle ID omits its blocks")
    func excludingBundleIDFiltersBlocks() {
        let all = BrowserTOML.blocks(excludingBundleIDs: [])
        guard let firstID = all.first.flatMap(bundleID(from:)) else { return }

        let filtered = BrowserTOML.blocks(excludingBundleIDs: [firstID])
        #expect(!filtered.contains { bundleID(from: $0) == firstID })
    }

    private func bundleID(from block: String) -> String? {
        for line in block.split(separator: "\n") where line.hasPrefix("id = ") {
            return line.dropFirst("id = ".count).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }
}
