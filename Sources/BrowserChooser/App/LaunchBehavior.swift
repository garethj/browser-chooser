import Foundation

/// Decides whether a fresh launch should open the main window.
///
/// A launch caused by a link click (or an HTML file open) should stay silent and just
/// route the URL. A plain launch (Finder, Spotlight, `open -a`) should show the window.
/// The login LaunchAgent passes `--background` so starting at login stays silent too.
enum LaunchBehavior {
    static let backgroundFlag = "--background"
    static let showInMenuBarKey = "showInMenuBar"

    static func shouldShowWindowOnLaunch(
        arguments: [String],
        launchIsDefault: Bool,
        receivedURLDuringLaunch: Bool
    ) -> Bool {
        if arguments.contains(backgroundFlag) { return false }
        if receivedURLDuringLaunch { return false }
        return launchIsDefault
    }
}
