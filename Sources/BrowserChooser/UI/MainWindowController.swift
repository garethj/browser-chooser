import AppKit
import SwiftUI

/// Owns the main window. While it's open the app behaves as a regular app
/// (Dock icon, Cmd-Tab); once closed it goes back to being a background agent.
final class MainWindowController: NSObject, NSWindowDelegate {
    private let configManager: ConfigManager
    private var window: NSWindow?

    init(configManager: ConfigManager) {
        self.configManager = configManager
    }

    func show() {
        let window = self.window ?? makeWindow()
        self.window = window
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: MainWindowView(configManager: configManager))
        let window = NSWindow(contentViewController: hosting)
        window.title = "BrowserChooser"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
