import AppKit
import Foundation

class ClipboardMonitor {
    private let store: ItemStore
    private var timer: Timer?
    private var lastChangeCount: Int

    init(store: ItemStore) {
        self.store = store
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        let t = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            self?.check()
        }
        // tolerance allows OS to batch timer with others - reduces battery wake-ups
        t.tolerance = 0.25
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        let pb = NSPasteboard.general
        let current = pb.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        // Check images FIRST - screenshots put both image and file URL on the pasteboard,
        // so checking text first would capture the URL string instead of the image
        let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png, NSPasteboard.PasteboardType("public.jpeg")]
        for type in imageTypes {
            if let data = pb.data(forType: type),
               let image = NSImage(data: data),
               let thumb = image.cloveThumbnail() {
                // Try to get a display name from file URL if available
                var name = "Screenshot"
                if let urlStr = pb.string(forType: NSPasteboard.PasteboardType("public.file-url")),
                   let url = URL(string: urlStr) {
                    name = url.lastPathComponent
                }
                let item = CloveItem(
                    id: UUID(),
                    type: .image,
                    content: "clipboard:\(UUID().uuidString)",
                    thumbnailData: thumb,
                    timestamp: Date(),
                    displayName: name
                )
                DispatchQueue.main.async { self.store.tryAdd(item) }
                return
            }
        }

        // Text
        if let str = pb.string(forType: .string), !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let truncated = String(str.prefix(10_000))
            let item = CloveItem(
                id: UUID(),
                type: .text,
                content: truncated,
                thumbnailData: nil,
                timestamp: Date(),
                displayName: String(truncated.prefix(60)).replacingOccurrences(of: "\n", with: " ")
            )
            DispatchQueue.main.async { self.store.tryAdd(item) }
            return
        }
    }
}

extension NSImage {
    func cloveThumbnail(maxDimension: CGFloat = 80) -> Data? {
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = NSSize(width: floor(size.width * scale), height: floor(size.height * scale))
        let thumb = NSImage(size: newSize)
        thumb.lockFocus()
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy, fraction: 1.0)
        thumb.unlockFocus()
        return thumb.tiffRepresentation
            .flatMap { NSBitmapImageRep(data: $0) }
            .flatMap { $0.representation(using: .jpeg, properties: [.compressionFactor: 0.75]) }
    }
}
