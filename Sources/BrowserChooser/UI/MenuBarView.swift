import SwiftUI

enum MenuBarIcon {
    static func systemImageName(lastError: String?, warnings: [String]) -> String {
        if lastError != nil {
            return "exclamationmark.triangle.fill"
        }
        if !warnings.isEmpty {
            return "exclamationmark.circle.fill"
        }
        return "globe"
    }
}

struct MenuBarView: View {
    let configManager: ConfigManager

    var body: some View {
        if let error = configManager.lastError {
            Label("Config Error", systemImage: "exclamationmark.triangle")
            Text(error)
                .font(.caption)
            Divider()
        }

        if !configManager.warnings.isEmpty {
            Label("Config Warnings", systemImage: "exclamationmark.circle")
            ForEach(configManager.warnings, id: \.self) { warning in
                Text(warning)
                    .font(.caption)
            }
            Divider()
        }

        Button("Open Config…") {
            configManager.openConfigInEditor()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Reload Config") {
            configManager.loadConfig()
        }
        .keyboardShortcut("r", modifiers: .command)

        Button("Add Detected Browsers to Config") {
            configManager.addDetectedBrowsers()
        }

        Divider()

        Button("Quit BrowserChooser") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
