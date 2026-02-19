import Foundation
import Testing
@testable import BrowserChooser

@Suite("URLMatcher")
struct URLMatcherTests {
    let matcher = URLMatcher()

    private func url(_ string: String) -> URL {
        URL(string: string)!
    }

    @Test("Exact host match")
    func exactHost() {
        #expect(matcher.matches(url: url("https://github.com/foo"), pattern: "github.com"))
    }

    @Test("Wildcard subdomain match")
    func wildcardSubdomain() {
        #expect(matcher.matches(url: url("https://docs.google.com/doc"), pattern: "*.google.com"))
    }

    @Test("Wildcard does not match bare domain")
    func wildcardNoBareDomain() {
        #expect(!matcher.matches(url: url("https://google.com/search"), pattern: "*.google.com"))
    }

    @Test("Pattern with path")
    func pathPattern() {
        #expect(matcher.matches(url: url("https://github.com/org/repo"), pattern: "github.com/org/*"))
    }

    @Test("Path pattern non-match")
    func pathPatternNonMatch() {
        #expect(!matcher.matches(url: url("https://github.com/other/repo"), pattern: "github.com/org/*"))
    }

    @Test("Case insensitive matching")
    func caseInsensitive() {
        #expect(matcher.matches(url: url("https://GitHub.COM/foo"), pattern: "github.com"))
        #expect(matcher.matches(url: url("https://github.com/foo"), pattern: "GitHub.COM"))
    }

    @Test("Non-matching host")
    func nonMatch() {
        #expect(!matcher.matches(url: url("https://example.com"), pattern: "github.com"))
    }

    @Test("Question mark wildcard")
    func questionMark() {
        #expect(matcher.matches(url: url("https://a1.example.com"), pattern: "a?.example.com"))
        #expect(!matcher.matches(url: url("https://abc.example.com"), pattern: "a?.example.com"))
    }

    @Test("Character class")
    func characterClass() {
        #expect(matcher.matches(url: url("https://dev.example.com"), pattern: "[dp]ev.example.com"))
        #expect(!matcher.matches(url: url("https://xev.example.com"), pattern: "[dp]ev.example.com"))
    }

    @Test("URL without host returns false")
    func noHost() {
        #expect(!matcher.matches(url: url("file:///tmp/test"), pattern: "*.com"))
    }
}
