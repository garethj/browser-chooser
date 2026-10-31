import Testing
@testable import BrowserChooser

@Suite("LaunchBehavior.shouldShowWindowOnLaunch")
struct LaunchBehaviorTests {
    private let app = "/Applications/BrowserChooser.app/Contents/MacOS/BrowserChooser"

    @Test("Plain launch shows the window")
    func plainLaunch() {
        #expect(LaunchBehavior.shouldShowWindowOnLaunch(
            arguments: [app], launchIsDefault: true, receivedURLDuringLaunch: false))
    }

    @Test("Launch caused by a link click stays silent")
    func urlLaunch() {
        #expect(!LaunchBehavior.shouldShowWindowOnLaunch(
            arguments: [app], launchIsDefault: true, receivedURLDuringLaunch: true))
    }

    @Test("Non-default launch (file open, state restore) stays silent")
    func nonDefaultLaunch() {
        #expect(!LaunchBehavior.shouldShowWindowOnLaunch(
            arguments: [app], launchIsDefault: false, receivedURLDuringLaunch: false))
    }

    @Test("Login item launch with --background stays silent")
    func backgroundLaunch() {
        #expect(!LaunchBehavior.shouldShowWindowOnLaunch(
            arguments: [app, LaunchBehavior.backgroundFlag], launchIsDefault: true, receivedURLDuringLaunch: false))
    }
}
