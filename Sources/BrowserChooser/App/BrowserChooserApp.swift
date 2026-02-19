import SwiftUI

@main
struct BrowserChooserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var configManager = ConfigManager()
    @State private var hasSetupHandler = false

    var body: some Scene {
        MenuBarExtra("BrowserChooser", systemImage: "globe") {
            MenuBarView(configManager: configManager)
                .onAppear {
                    if !hasSetupHandler {
                        setupURLHandler()
                        hasSetupHandler = true
                    }
                }
        }
        .onChange(of: configManager.config) {
            setupURLHandler()
        }
    }

    private func setupURLHandler() {
        let registry = BrowserRegistry(
            detector: BrowserDetector(),
            profileDetector: ProfileDetector(),
            configBrowsers: configManager.config.browsers
        )
        let matcher = URLMatcher()
        let launcher = BrowserLauncher()
        let pickerController = PickerController()

        let handler = URLHandler(
            config: configManager.config,
            registry: registry,
            matcher: matcher,
            launcher: launcher,
            pickerController: pickerController
        )
        appDelegate.urlHandler = handler
        appDelegate.flushPendingURLs()
    }
}
