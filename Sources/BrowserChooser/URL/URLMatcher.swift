import Foundation

struct URLMatcher {
    /// Match a URL against a glob pattern.
    /// - If the pattern contains `/`, match against host + path.
    /// - Otherwise, match against host only.
    /// - Matching is case-insensitive.
    func matches(url: URL, pattern: String) -> Bool {
        guard let host = url.host?.lowercased() else { return false }

        let target: String
        let matchPattern = pattern.lowercased()

        if matchPattern.contains("/") {
            let path = url.path
            target = host + path
        } else {
            target = host
        }

        return fnmatch(matchPattern, target, FNM_CASEFOLD) == 0
    }
}
