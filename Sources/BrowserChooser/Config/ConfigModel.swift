import Foundation

struct AppConfig: Equatable, Codable {
    var defaults: DefaultsConfig
    var browsers: [BrowserConfig]
    var rules: [RuleConfig]

    init(defaults: DefaultsConfig = DefaultsConfig(), browsers: [BrowserConfig] = [], rules: [RuleConfig] = []) {
        self.defaults = defaults
        self.browsers = browsers
        self.rules = rules
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaults = try container.decodeIfPresent(DefaultsConfig.self, forKey: .defaults) ?? DefaultsConfig()
        browsers = try container.decodeIfPresent([BrowserConfig].self, forKey: .browsers) ?? []
        rules = try container.decodeIfPresent([RuleConfig].self, forKey: .rules) ?? []
    }
}

struct DefaultsConfig: Codable, Equatable {
    var browser: String

    init(browser: String = "ask") {
        self.browser = browser
    }
}

struct BrowserConfig: Codable, Equatable {
    var name: String
    var id: String
    var profile: String?
}

struct RuleConfig: Codable, Equatable {
    var pattern: String?
    var patterns: [String]?
    var browser: String

    var allPatterns: [String] {
        if let patterns { return patterns }
        if let pattern { return [pattern] }
        return []
    }
}
