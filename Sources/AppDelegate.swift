import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipboardMonitor: ClipboardMonitor?
    private var folderWatcher: FolderWatcher?
    private var hotKeyRef: EventHotKeyRef?

    private var statusItem: NSStatusItem!
    private var popupWindow: NSPanel?
    private var isPopupVisible = false

    let store = ItemStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        // Defer hotkey registration until after run loop is fully started
        DispatchQueue.main.async { self.registerHotKey() }
        clipboardMonitor = ClipboardMonitor(store: store)
        clipboardMonitor?.start()
        folderWatcher = FolderWatcher(store: store)
        folderWatcher?.start()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            if let img = NSImage(named: "MenuBarIcon") {
                img.size = NSSize(width: 18, height: 18)
                img.isTemplate = true
                button.image = img
            } else {
                button.image = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "Clove")
                button.image?.isTemplate = true
            }
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
        guard let screen = NSScreen.main else { return }

        if popupWindow == nil {
            let hosting = NSHostingView(rootView: ClovePopupView().environmentObject(store))
            let winW: CGFloat = 700
            let winH: CGFloat = 120
            hosting.frame = NSRect(x: 0, y: 0, width: winW, height: winH)

            let win = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            win.contentView = hosting
            win.backgroundColor = .clear
            win.isOpaque = false
            win.level = .statusBar
            win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            win.hasShadow = true
            win.becomesKeyOnlyIfNeeded = false
            popupWindow = win

            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: win,
                queue: .main
            ) { [weak self] _ in
                // Small delay prevents immediate re-hide when focus transitions during show
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    guard let self = self, self.isPopupVisible else { return }
                    self.hidePopup()
                }
            }
        }

        let winW: CGFloat = 700
        let winH: CGFloat = 120
        let menuBarH = NSStatusBar.system.thickness
        let x = (screen.frame.width - winW) / 2 + screen.frame.minX
        let y = screen.frame.maxY - menuBarH - winH - 4

        popupWindow?.setFrame(NSRect(x: x, y: y, width: winW, height: winH), display: false)
        popupWindow?.orderFrontRegardless()
        popupWindow?.makeKey()
        isPopupVisible = true
    }

    private func hidePopup() {
        popupWindow?.orderOut(nil)
        isPopupVisible = false
    }

    private func registerHotKey() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let event = event, let userData = userData else { return noErr }
                var hkID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                guard err == noErr, hkID.id == 1 else { return noErr }
                let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { delegate.togglePopup() }
                return noErr
            },
            1, &eventSpec, selfPtr, nil
        )

        // V = keycode 9, Cmd+Shift
        let modifiers = UInt32(cmdKey | shiftKey)
        let hkID = EventHotKeyID(signature: FourCharCode(0x434C5654), id: 1)
        RegisterEventHotKey(9, modifiers, hkID, GetApplicationEventTarget(), 0, &hotKeyRef)
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
