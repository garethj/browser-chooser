import Foundation

/// Builds links for the "Open external links in a container" Firefox extension,
/// which opens `ext+container:name=<container>&url=<url>` in the named
/// Multi-Account Containers container.
enum ContainerURL {
    /// Characters that pass through a query value unescaped. Everything else,
    /// including `&`, `=`, `?` and `#`, is percent-encoded so the wrapped URL
    /// and the container name survive intact.
    private static let unreserved = CharacterSet(charactersIn:
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    static func wrap(_ url: URL, container: String) -> URL? {
        guard let name = container.addingPercentEncoding(withAllowedCharacters: unreserved),
              let target = url.absoluteString.addingPercentEncoding(withAllowedCharacters: unreserved)
        else { return nil }
        return URL(string: "ext+container:name=\(name)&url=\(target)")
    }
}
