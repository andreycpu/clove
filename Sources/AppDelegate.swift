import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipboardMonitor: ClipboardMonitor?
    private var folderWatcher: FolderWatcher?
    private var hotKeyRef: EventHotKeyRef?

    private var statusItem: NSStatusItem!
    private var popupWindow: NSWindow?
    private var isPopupVisible = false

    let store = ItemStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        registerHotKey()

        clipboardMonitor = ClipboardMonitor(store: store)
        clipboardMonitor?.start()
        folderWatcher = FolderWatcher(store: store)
        folderWatcher?.start()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "Clove")
            button.image?.isTemplate = true
            button.action = #selector(togglePopup)
            button.target = self
        }
    }

    @objc func togglePopup() {
        if isPopupVisible {
            hidePopup()
        } else {
            showPopup()
        }
    }

    private func showPopup() {
        guard let screen = NSScreen.main,
              let button = statusItem.button,
              let buttonWindow = button.window else { return }

        if popupWindow == nil {
            let hosting = NSHostingView(rootView: ClovePopupView().environmentObject(store))
            hosting.frame = NSRect(x: 0, y: 0, width: 700, height: 120)

            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 120),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            win.contentView = hosting
            win.backgroundColor = .clear
            win.isOpaque = false
            win.level = .statusBar
            win.collectionBehavior = [.canJoinAllSpaces, .stationary]
            win.hasShadow = true
            popupWindow = win

            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: win,
                queue: .main
            ) { [weak self] _ in
                self?.hidePopup()
            }
        }

        // Position centered at top of screen, just below the menu bar
        let winW: CGFloat = 700
        let winH: CGFloat = 120
        let menuBarH = NSStatusBar.system.thickness
        let x = (screen.frame.width - winW) / 2 + screen.frame.minX
        let y = screen.frame.maxY - menuBarH - winH - 4

        popupWindow?.setFrame(NSRect(x: x, y: y, width: winW, height: winH), display: false)
        popupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isPopupVisible = true
    }

    private func hidePopup() {
        popupWindow?.orderOut(nil)
        isPopupVisible = false
    }

    // Cmd+Shift+V via Carbon RegisterEventHotKey (no Accessibility permission needed)
    private func registerHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userdata) -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                if hkID.id == 1 {
                    DispatchQueue.main.async {
                        (NSApp.delegate as? AppDelegate)?.togglePopup()
                    }
                }
                return noErr
            },
            1, &eventType, nil, nil
        )

        // V = keycode 9, Cmd+Shift
        let modifiers = UInt32(cmdKey | shiftKey)
        let id = EventHotKeyID(signature: FourCharCode(0x434C5654), id: 1) // 'CLVT'
        RegisterEventHotKey(9, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func openSettings() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Clove Settings"
        win.center()
        win.contentView = NSHostingView(rootView: SettingsView().environmentObject(store))
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
