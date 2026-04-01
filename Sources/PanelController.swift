import AppKit
import SwiftUI

class PanelController {
    private(set) var panel: NSPanel?
    private let store: ItemStore

    init(store: ItemStore) {
        self.store = store
        build()
    }

    private func build() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 120),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isMovableByWindowBackground = false

        let visual = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 660, height: 120))
        visual.material = .hudWindow
        visual.blendingMode = .behindWindow
        visual.state = .active
        visual.wantsLayer = true
        visual.layer?.cornerRadius = 60
        visual.layer?.masksToBounds = true

        let hosting = NSHostingView(rootView:
            ContentView().environmentObject(store)
        )
        hosting.frame = visual.bounds
        hosting.autoresizingMask = [.width, .height]
        visual.addSubview(hosting)

        panel.contentView = visual
        self.panel = panel
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        guard let panel else { return }
        if panel.isVisible {
            close()
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard let panel, let screen = NSScreen.main else { return }

        // Position panel centered below the menu bar
        let buttonRect = button.window?.convertToScreen(button.frame) ?? .zero
        let panelW: CGFloat = 660
        let panelH: CGFloat = 120
        let x = max(8, min(buttonRect.midX - panelW / 2, screen.frame.width - panelW - 8))
        let y = buttonRect.minY - panelH - 6

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.alphaValue = 0
        panel.orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        // Close when clicking outside
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    func close() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.14
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
            panel.alphaValue = 1
        })
    }
}
