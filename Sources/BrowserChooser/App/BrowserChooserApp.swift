import SwiftUI

@main
struct BrowserChooserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(configManager: appDelegate.configManager)
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
