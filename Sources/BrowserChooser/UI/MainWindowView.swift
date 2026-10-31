import SwiftUI

struct MainWindowView: View {
    let configManager: ConfigManager
    @AppStorage(LaunchBehavior.showInMenuBarKey) private var showInMenuBar = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            status

            VStack(alignment: .leading, spacing: 8) {
                Button("Open Config…") { configManager.openConfigInEditor() }
                Button("Reload Config") { configManager.loadConfig() }
                Button("Add Detected Browsers to Config") { configManager.addDetectedBrowsers() }
            }

            Divider()

            Toggle("Show in menu bar", isOn: $showInMenuBar)
            Text("BrowserChooser keeps running in the background to route links after you close this window. Open the app again to bring the window back.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button("Quit BrowserChooser") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    @ViewBuilder
    private var status: some View {
        if let error = configManager.lastError {
            VStack(alignment: .leading, spacing: 4) {
                Label("Config Error", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(error).font(.caption).textSelection(.enabled)
            }
        } else if !configManager.warnings.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Label("Config Warnings", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                ForEach(configManager.warnings, id: \.self) { warning in
                    Text(warning).font(.caption).textSelection(.enabled)
                }
            }
        } else {
            Label("Config loaded", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}
