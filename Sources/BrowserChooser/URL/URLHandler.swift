import Foundation
import os

final class URLHandler {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "URLHandler")
    private let config: AppConfig
    private let registry: BrowserRegistry
    private let matcher: URLMatcher
    private let launcher: BrowserLauncher
    private let pickerController: PickerController

    init(config: AppConfig, registry: BrowserRegistry, matcher: URLMatcher, launcher: BrowserLauncher, pickerController: PickerController) {
        self.config = config
        self.registry = registry
        self.matcher = matcher
        self.launcher = launcher
        self.pickerController = pickerController
    }

    func handle(url: URL) {
        // Evaluate rules top-to-bottom
        for rule in config.rules {
            for pattern in rule.allPatterns {
                if matcher.matches(url: url, pattern: pattern) {
                    logger.info("Rule matched: \(pattern) → \(rule.browser)")
                    route(url: url, browserName: rule.browser)
                    return
                }
            }
        }

        // No rule matched — use default
        logger.info("No rule matched, using default: \(self.config.defaults.browser)")
        route(url: url, browserName: config.defaults.browser)
    }

    private func route(url: URL, browserName: String) {
        if browserName.lowercased() == "ask" {
            showPicker(for: url)
        } else if let browser = registry.browser(named: browserName) {
            launcher.launch(url: url, browser: browser)
        } else {
            logger.warning("Browser '\(browserName)' not found, showing picker")
            showPicker(for: url)
        }
    }

    private func showPicker(for url: URL) {
        pickerController.show(browsers: registry.browsers, url: url) { [launcher] browser in
            launcher.launch(url: url, browser: browser)
        }
    }
}
