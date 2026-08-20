import Foundation

enum CLI {
    static let listBrowsersFlag = "--list-browsers"

    /// Prints detected browsers (and profiles) as ready-to-paste `[[browsers]]` TOML blocks,
    /// so the config's browser IDs/profiles don't have to be looked up or typed by hand.
    static func listBrowsers() {
        print("# Detected browsers — copy any of these into [[browsers]] in your config.")
        print("# Rename them freely; only \"id\" and \"profile\" need to stay as shown.")
        print("# A browser doesn't need to be listed here to be selectable — this just")
        print("# documents the id/profile values for the ones you want to name or route.")

        for block in BrowserTOML.blocks() {
            print("")
            print(block)
        }
    }
}
