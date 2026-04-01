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
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?
    private var isDismissing = false

    let store = ItemStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
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
        isDismissing = false

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
            win.level = .floating
            win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            win.hasShadow = true
            win.becomesKeyOnlyIfNeeded = false
            popupWindow = win
        }

        let winW: CGFloat = 700
        let winH: CGFloat = 120
        let menuBarH = NSStatusBar.system.thickness
        let x = (screen.frame.width - winW) / 2 + screen.frame.minX
        let y = screen.frame.maxY - menuBarH - winH - 4

        popupWindow?.setFrame(NSRect(x: x, y: y, width: winW, height: winH), display: false)
        popupWindow?.orderFrontRegardless()

        // Activate the app so it can receive key events
        NSApp.activate(ignoringOtherApps: true)
        popupWindow?.makeKey()
        popupWindow?.makeFirstResponder(popupWindow?.contentView)

        isPopupVisible = true
        installKeyMonitors()
    }

    private func hidePopup() {
        guard !isDismissing else { return }
        isDismissing = true
        removeKeyMonitors()
        popupWindow?.orderOut(nil)
        isPopupVisible = false
        store.clearCopiedIndex()
        // Deactivate so previous app regains focus
        NSApp.hide(nil)
    }

    private func copyAndDismiss(_ digit: Int) {
        store.copyByIndex(digit)
        // Brief delay to show the green highlight, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.hidePopup()
        }
    }

    private func installKeyMonitors() {
        guard localKeyMonitor == nil else { return }

        // Local monitor for when Clove is active (primary path)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isPopupVisible else { return event }
            return self.handleKeyEvent(event) ? nil : event
        }

        // Global monitor as fallback when another app somehow has focus
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isPopupVisible else { return }
            _ = self.handleKeyEvent(event)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        if let ch = event.characters, ch.count == 1,
           let d = Int(ch), d >= 1 && d <= 9 {
            copyAndDismiss(d)
            return true
        }
        if event.keyCode == 53 { // Escape
            hidePopup()
            return true
        }
        return false
    }

    private func removeKeyMonitors() {
        if let m = localKeyMonitor { NSEvent.removeMonitor(m); localKeyMonitor = nil }
        if let m = globalKeyMonitor { NSEvent.removeMonitor(m); globalKeyMonitor = nil }
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
