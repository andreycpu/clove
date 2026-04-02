import Foundation
import AppKit

class FolderWatcher {
    private let store: ItemStore
    private var sources: [DispatchSourceFileSystemObject] = []
    private var knownFiles: Set<String> = []

    private let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "webp", "tiff"]
    private let ignoredExtensions: Set<String> = ["ds_store", "localized", "part", "crdownload", "download"]

    private lazy var watchedDirs: [URL] = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Downloads")
        ]
    }()

    init(store: ItemStore) {
        self.store = store
    }

    func start() {
        // Snapshot existing files so we don't ingest them on first launch
        for dir in watchedDirs {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
                contents.forEach { knownFiles.insert(dir.appendingPathComponent($0).path) }
            }
            watch(dir)
        }
    }

    func stop() {
        sources.forEach { $0.cancel() }
        sources.removeAll()
    }

    private func watch(_ url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            self?.scanForNew(in: url)
        }

        source.setCancelHandler { close(fd) }
        source.resume()
        sources.append(source)
    }

    private func scanForNew(in dir: URL) {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }

        for filename in contents {
            let path = dir.appendingPathComponent(filename).path
            guard !knownFiles.contains(path) else { continue }
            knownFiles.insert(path)

            let ext = (filename as NSString).pathExtension.lowercased()
            guard !ignoredExtensions.contains(ext), !filename.hasPrefix(".") else { continue }

            // Wait 1s to ensure file is fully written before reading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.ingest(path: path, filename: filename, ext: ext)
            }
        }
    }

    private func ingest(path: String, filename: String, ext: String) {
        // Skip symlinks to avoid reading unintended files
        let fm = FileManager.default
        if let attrs = try? fm.attributesOfItem(atPath: path),
           let fileType = attrs[.type] as? FileAttributeType,
           fileType == .typeSymbolicLink {
            return
        }

        // Verify the file is still inside the watched directory
        let resolvedPath = (path as NSString).resolvingSymlinksInPath
        let inWatchedDir = watchedDirs.contains { resolvedPath.hasPrefix($0.path) }
        guard inWatchedDir else { return }

        if imageExtensions.contains(ext) {
            guard let image = NSImage(contentsOfFile: path),
                  let thumb = image.cloveThumbnail() else { return }
            let item = CloveItem(
                id: UUID(),
                type: .image,
                content: path,
                thumbnailData: thumb,
                timestamp: Date(),
                displayName: filename
            )
            store.tryAdd(item)
        } else {
            // Generic file - use system icon as thumbnail
            let icon = NSWorkspace.shared.icon(forFile: path)
            let thumb = icon.cloveThumbnail(maxDimension: 60)
            let item = CloveItem(
                id: UUID(),
                type: .file,
                content: path,
                thumbnailData: thumb,
                timestamp: Date(),
                displayName: filename
            )
            store.tryAdd(item)
        }
    }
}
