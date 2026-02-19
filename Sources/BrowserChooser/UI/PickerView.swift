import SwiftUI

struct PickerView: View {
    let browsers: [ResolvedBrowser]
    let url: URL
    let selectedIndex: Int
    let onSelect: (ResolvedBrowser) -> Void
    let onDismiss: () -> Void

    @State private var hoveredIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // URL display
            Text(url.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()
                .padding(.horizontal, 8)

            // Browser list
            ForEach(Array(browsers.enumerated()), id: \.element.id) { index, browser in
                BrowserRow(
                    browser: browser,
                    isSelected: hoveredIndex == nil ? index == selectedIndex : index == hoveredIndex,
                    shortcutKey: index < 9 ? "\(index + 1)" : nil
                )
                .onTapGesture {
                    onSelect(browser)
                }
                .onHover { hovering in
                    hoveredIndex = hovering ? index : nil
                }
            }
        }
        .padding(.vertical, 6)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct BrowserRow: View {
    let browser: ResolvedBrowser
    let isSelected: Bool
    let shortcutKey: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: browser.icon)
                .resizable()
                .frame(width: 24, height: 24)

            Text(browser.name)
                .font(.body)
                .lineLimit(1)

            Spacer()

            if let key = shortcutKey {
                Text(key)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : .clear)
        .contentShape(Rectangle())
    }
}
