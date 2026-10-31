import SwiftUI

@main
struct BrowserChooserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage(LaunchBehavior.showInMenuBarKey) private var showInMenuBar = true

    init() {
        if CommandLine.arguments.contains(CLI.listBrowsersFlag) {
            CLI.listBrowsers()
            exit(0)
        }
    }

    var body: some Scene {
        MenuBarExtra(isInserted: $showInMenuBar) {
            MenuBarView(
                configManager: appDelegate.configManager,
                onOpenWindow: { appDelegate.showMainWindow() }
            )
        } label: {
            Image(systemName: MenuBarIcon.systemImageName(
                lastError: appDelegate.configManager.lastError,
                warnings: appDelegate.configManager.warnings
            ))
        }
        .onChange(of: appDelegate.configManager.config) {
            appDelegate.rebuildURLHandler()
        }
    }
}
