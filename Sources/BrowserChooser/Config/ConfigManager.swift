import AppKit
import TOMLKit
import os

@Observable
final class ConfigManager {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "ConfigManager")
    private var fileWatcher: FileWatcher?

    private(set) var config: AppConfig = AppConfig()
    private(set) var lastError: String?
    private(set) var warnings: [String] = []

    static let configDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/browser-chooser")
    }()

    static var configFileURL: URL {
        configDirectory.appendingPathComponent("config.toml")
    }

    init() {
        loadConfig()
        startWatching()
    }

    func loadConfig() {
        let url = Self.configFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.info("No config file found, using defaults")
            config = AppConfig()
            lastError = nil
            return
        }

        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            config = try TOMLDecoder().decode(AppConfig.self, from: contents)
            lastError = nil
            logger.info("Config loaded successfully")
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to load config: \(error.localizedDescription)")
        }
    }

    func createDefaultConfigIfNeeded() {
        let dir = Self.configDirectory
        let file = Self.configFileURL

        if FileManager.default.fileExists(atPath: file.path) { return }

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try Self.defaultConfigContents().write(to: file, atomically: true, encoding: .utf8)
            logger.info("Created default config at \(file.path)")
        } catch {
            logger.error("Failed to create default config: \(error.localizedDescription)")
        }
    }

    /// Appends any detected browser (matched by bundle ID) not already referenced in the
    /// config to the end of the file, leaving existing content untouched. Safe to call
    /// repeatedly — already-referenced bundle IDs are skipped every time.
    func addDetectedBrowsers() {
        let file = Self.configFileURL
        guard FileManager.default.fileExists(atPath: file.path) else {
            createDefaultConfigIfNeeded()
            return
        }

        let existingIDs = Set(config.browsers.map(\.id))
        let blocks = BrowserTOML.blocks(excludingBundleIDs: existingIDs)
        guard !blocks.isEmpty else {
            logger.info("No newly detected browsers to add")
            return
        }

        do {
            var contents = try String(contentsOf: file, encoding: .utf8)
            if !contents.hasSuffix("\n") { contents += "\n" }
            contents += "\n# Added by \"Add Detected Browsers\" — rename freely, or delete what you don't need\n"
            contents += blocks.joined(separator: "\n\n") + "\n"
            try contents.write(to: file, atomically: true, encoding: .utf8)
            logger.info("Appended \(blocks.count) detected browser(s) to config")
        } catch {
            logger.error("Failed to append detected browsers: \(error.localizedDescription)")
        }
    }

    func setWarnings(_ warnings: [String]) {
        self.warnings = warnings
    }

    func openConfigInEditor() {
        createDefaultConfigIfNeeded()
        NSWorkspace.shared.open(Self.configFileURL)
    }

    private func startWatching() {
        createDefaultConfigIfNeeded()
        fileWatcher = FileWatcher(path: Self.configFileURL.path) { [weak self] in
            self?.logger.info("Config file changed, reloading...")
            self?.loadConfig()
        }
    }

    static func defaultConfigContents() -> String {
        let detectedBlocks = BrowserTOML.blocks()

        let browsersSection: String
        if detectedBlocks.isEmpty {
            browsersSection = """
            # Override display names or add Chromium profile entries.
            # Uncomment and edit these examples:
            #
            # [[browsers]]
            # name = "Chrome Work"
            # id = "com.google.Chrome"
            # profile = "Default"
            #
            # [[browsers]]
            # name = "Chrome Personal"
            # id = "com.google.Chrome"
            # profile = "Profile 1"
            """
        } else {
            browsersSection = """
            # Browsers detected on this Mac. Rename freely, or delete entries you don't
            # need — a browser doesn't have to be listed here to be selectable.

            \(detectedBlocks.joined(separator: "\n\n"))
            """
        }

        return """
        # BrowserChooser Configuration
        # Docs: https://github.com/garethj/browser-chooser

        [defaults]
        # Default action when no rule matches.
        # Use "ask" to show a picker, or a browser name like "Safari".
        browser = "ask"

        \(browsersSection)

        # Rules are evaluated top-to-bottom; first match wins.
        # Patterns match against the URL host (or host+path if the pattern contains /).
        #
        # Use "pattern" for a single domain or "patterns" for multiple domains:
        #
        # [[rules]]
        # patterns = [
        #     "*.notion.so", "*.github.com",
        #     "*.slack.com",
        # ]
        # browser = "Chrome Work"
        #
        # [[rules]]
        # pattern = "*.google.com"
        # browser = "ask"
        """
    }
}
