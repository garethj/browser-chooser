import AppKit
import SwiftUI
import os

final class PickerController {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "PickerController")
    private var panel: PickerPanel?
    private var localEventMonitor: Any?
    private var selectedIndex = 0
    private var browsers: [ResolvedBrowser] = []
    private var onSelectCallback: ((ResolvedBrowser) -> Void)?
    private var hostingView: NSHostingView<PickerView>?

    func show(browsers: [ResolvedBrowser], url: URL, onSelect: @escaping (ResolvedBrowser) -> Void) {
        dismiss()

        guard !browsers.isEmpty else {
            logger.warning("No browsers available to show in picker")
            return
        }

        self.browsers = browsers
        self.onSelectCallback = onSelect
        self.selectedIndex = 0

        let pickerView = PickerView(
            browsers: browsers,
            url: url,
            selectedIndex: selectedIndex,
            onSelect: { [weak self] browser in
                self?.selectBrowser(browser)
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )

        let hosting = NSHostingView(rootView: pickerView)
        hosting.setFrameSize(hosting.fittingSize)
        self.hostingView = hosting

        let panelRect = NSRect(origin: .zero, size: hosting.fittingSize)
        let panel = PickerPanel(contentRect: panelRect)
        panel.contentView = hosting

        // Position near cursor
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero

        var origin = NSPoint(
            x: mouseLocation.x - panelRect.width / 2,
            y: mouseLocation.y - panelRect.height
        )

        // Keep on screen
        origin.x = max(screenFrame.minX, min(origin.x, screenFrame.maxX - panelRect.width))
        origin.y = max(screenFrame.minY, min(origin.y, screenFrame.maxY - panelRect.height))

        panel.setFrameOrigin(origin)

        // Activate the app so it receives keyboard events.
        NSApp.activate()
        panel.orderFrontRegardless()
        panel.makeKey()

        self.panel = panel

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel != nil else { return event }
            return self.handleKeyEvent(event)
        }

        logger.info("Picker shown with \(browsers.count) browser(s)")
    }

    private func selectBrowser(_ browser: ResolvedBrowser) {
        let callback = onSelectCallback
        dismiss()
        callback?(browser)
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        switch event.keyCode {
        case 53: // Escape
            dismiss()
            return nil
        case 126: // Up arrow
            selectedIndex = max(0, selectedIndex - 1)
            updateSelection()
            return nil
        case 125: // Down arrow
            selectedIndex = min(browsers.count - 1, selectedIndex + 1)
            updateSelection()
            return nil
        case 36, 76: // Return, Numpad Enter
            if browsers.indices.contains(selectedIndex) {
                selectBrowser(browsers[selectedIndex])
            }
            return nil
        default:
            // Number keys 1-9
            if let chars = event.charactersIgnoringModifiers,
               let digit = Int(chars), digit >= 1, digit <= browsers.count {
                selectBrowser(browsers[digit - 1])
                return nil
            }
            return event
        }
    }

    private func updateSelection() {
        guard let hosting = hostingView else { return }
        hosting.rootView = PickerView(
            browsers: browsers,
            url: hosting.rootView.url,
            selectedIndex: selectedIndex,
            onSelect: hosting.rootView.onSelect,
            onDismiss: hosting.rootView.onDismiss
        )
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
        browsers = []
        onSelectCallback = nil

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
}
