import SwiftUI
import AppKit

struct ItemCell: View {
    let item: CloveItem
    @EnvironmentObject var store: ItemStore
    @State private var isHovered = false
    @State private var copied = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            cellContent
                .frame(width: 80, height: 80)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )

            if isHovered {
                copyButton
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Copy") { doCopy() }
            if item.type == .file || item.type == .image, item.content.hasPrefix("/") {
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.content)])
                }
            }
            Divider()
            Button("Remove", role: .destructive) { store.remove(item) }
        }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }

    @ViewBuilder
    private var cellContent: some View {
        switch item.type {
        case .text:
            Text(item.displayName)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.primary)
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .multilineTextAlignment(.leading)

        case .image:
            if let thumb = item.thumbnail {
                Image(nsImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .file:
            VStack(spacing: 5) {
                if let thumb = item.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                }
                Text(item.displayName)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 72)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var copyButton: some View {
        Button(action: doCopy) {
            ZStack {
                Circle()
                    .fill(copied ? Color.green.opacity(0.9) : Color.green)
                    .frame(width: 22, height: 22)
                Image(systemName: copied ? "checkmark" : "doc.on.doc.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .padding(4)
    }

    private func doCopy() {
        store.copyToClipboard(item)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { copied = false }
        }
    }
}
