import AppKit
import SwiftUI
import os

final class PickerController {
    private let logger = Logger(subsystem: "com.garethj.BrowserChooser", category: "PickerController")
    private var panel: PickerPanel?
    private var localEventMonitor: Any?

    func show(browsers: [ResolvedBrowser], url: URL, onSelect: @escaping (ResolvedBrowser) -> Void) {
        dismiss()

        guard !browsers.isEmpty else {
            logger.warning("No browsers available to show in picker")
            return
        }

        let pickerView = PickerView(
            browsers: browsers,
            url: url,
            onSelect: { [weak self] browser in
                self?.dismiss()
                onSelect(browser)
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )

        let hostingView = NSHostingView(rootView: pickerView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panelRect = NSRect(origin: .zero, size: hostingView.fittingSize)
        let panel = PickerPanel(contentRect: panelRect)
        panel.contentView = hostingView

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
        panel.orderFrontRegardless()
        panel.makeKey()

        self.panel = panel

        // Fallback keyboard handler in case onKeyPress doesn't fire in NSPanel
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel != nil else { return event }

            switch event.keyCode {
            case 53: // Escape
                self.dismiss()
                return nil
            default:
                return event
            }
        }

        logger.info("Picker shown with \(browsers.count) browser(s)")
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
}
