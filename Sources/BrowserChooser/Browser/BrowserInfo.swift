import AppKit

struct ResolvedBrowser: Identifiable, Equatable {
    let id: String  // unique key: bundleID, plus profile and container when set
    let name: String
    let bundleID: String
    let icon: NSImage
    let profileDirectory: String?
    let container: String?

    init(name: String, bundleID: String, icon: NSImage, profileDirectory: String? = nil, container: String? = nil) {
        self.name = name
        self.bundleID = bundleID
        self.icon = icon
        self.profileDirectory = profileDirectory
        self.container = container
        self.id = [bundleID, profileDirectory, container.map { "container:\($0)" }]
            .compactMap { $0 }
            .joined(separator: "|")
    }
}
