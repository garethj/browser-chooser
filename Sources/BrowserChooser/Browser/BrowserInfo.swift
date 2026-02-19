import AppKit

struct ResolvedBrowser: Identifiable, Equatable {
    let id: String  // unique key: bundleID or bundleID+profile
    let name: String
    let bundleID: String
    let icon: NSImage
    let profileDirectory: String?

    init(name: String, bundleID: String, icon: NSImage, profileDirectory: String? = nil) {
        self.name = name
        self.bundleID = bundleID
        self.icon = icon
        self.profileDirectory = profileDirectory
        self.id = profileDirectory.map { "\(bundleID)|\($0)" } ?? bundleID
    }
}
