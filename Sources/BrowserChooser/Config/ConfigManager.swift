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
            try Self.defaultConfigContents.write(to: file, atomically: true, encoding: .utf8)
            logger.info("Created default config at \(file.path)")
        } catch {
            logger.error("Failed to create default config: \(error.localizedDescription)")
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

    static let defaultConfigContents = """
    # BrowserChooser Configuration
    # Docs: https://github.com/garethj/browser-chooser

    [defaults]
    # Default action when no rule matches.
    # Use "ask" to show a picker, or a browser name like "Safari".
    browser = "ask"

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
