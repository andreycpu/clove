import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private var clipboardMonitor: ClipboardMonitor?
    private var folderWatcher: FolderWatcher?

    let store = ItemStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        panelController = PanelController(store: store)
        startMonitors()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.image = NSImage(systemSymbolName: "bag.fill", accessibilityDescription: "Knapsack")?
            .withSymbolConfiguration(config)
        button.action = #selector(togglePanel)
        button.target = self
    }

    private func startMonitors() {
        clipboardMonitor = ClipboardMonitor(store: store)
        clipboardMonitor?.start()

        folderWatcher = FolderWatcher(store: store)
        folderWatcher?.start()
    }

    @objc private func togglePanel() {
        guard let button = statusItem?.button else { return }
        panelController?.toggle(relativeTo: button)
    }
}
