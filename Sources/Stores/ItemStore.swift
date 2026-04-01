import Foundation
import AppKit
import Combine

class ItemStore: ObservableObject {
    @Published var items: [CloveItem] = []
    @Published var showCapacityWarning = false
    @Published var pendingItem: CloveItem?
    @Published var maxItems: Int = {
        let stored = UserDefaults.standard.integer(forKey: "clove.maxItems")
        return stored == 0 ? 10 : stored
    }()

    private var cancellables = Set<AnyCancellable>()

    private let storageURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Clove")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("items.json")
    }()

    init() {
        load()
        $maxItems
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "clove.maxItems") }
            .store(in: &cancellables)
    }

    func tryAdd(_ item: CloveItem) {
        // Skip duplicates by content
        guard !items.contains(where: { $0.content == item.content }) else { return }

        if items.count >= maxItems {
            pendingItem = item
            showCapacityWarning = true
        } else {
            append(item)
        }
    }

    func confirmOverride() {
        guard let pending = pendingItem else { return }
        items.removeFirst()
        append(pending)
        pendingItem = nil
        showCapacityWarning = false
    }

    func cancelOverride() {
        pendingItem = nil
        showCapacityWarning = false
    }

    func remove(_ item: CloveItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func clearAll() {
        items.removeAll()
        persist()
    }

    func copyToClipboard(_ item: CloveItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.type {
        case .text:
            pb.setString(item.content, forType: .string)
        case .image:
            if item.content.hasPrefix("/"), let image = NSImage(contentsOfFile: item.content) {
                pb.writeObjects([image])
            } else if let thumb = item.thumbnail {
                pb.writeObjects([thumb])
            }
        case .file:
            if let url = URL(string: "file://" + item.content) {
                pb.writeObjects([url as NSURL])
            }
        }
    }

    private func append(_ item: CloveItem) {
        items.append(item)
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([CloveItem].self, from: data)
        else { return }
        items = decoded
    }
}
