import SwiftUI

@main
struct BrowserChooserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("BrowserChooser", systemImage: "globe") {
            MenuBarView(configManager: appDelegate.configManager)
        }
        .onChange(of: appDelegate.configManager.config) {
            appDelegate.rebuildURLHandler()
        }
    }
}
