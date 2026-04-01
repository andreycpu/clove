import SwiftUI
import AppKit

struct ItemCell: View {
    let item: CloveItem
    let index: Int
    @EnvironmentObject var store: ItemStore
    @State private var isHovered = false
    @State private var copied = false

    private var isHighlighted: Bool {
        store.copiedIndex == index
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .bottomTrailing) {
                cellContent
                    .frame(width: 82, height: 82)

                if isHovered && !copied && !isHighlighted {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.green)
                        .clipShape(Circle())
                        .padding(4)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                if copied || isHighlighted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.green.opacity(0.9))
                        .clipShape(Circle())
                        .padding(4)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        isHighlighted ? Color.green.opacity(0.8) :
                        Color.white.opacity(isHovered ? 0.25 : 0.1),
                        lineWidth: isHighlighted ? 2 : 0.5
                    )
            )
            .shadow(
                color: isHighlighted ? .green.opacity(0.4) : .black.opacity(0.15),
                radius: isHighlighted ? 8 : 4,
                x: 0, y: 2
            )
            .scaleEffect(isHighlighted ? 1.05 : 1.0)

            // Number badge
            if index <= 9 {
                Text("\(index)")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(isHighlighted ? .white : .white.opacity(0.85))
                    .frame(width: 16, height: 16)
                    .background(isHighlighted ? Color.green : Color.clear)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(
                                isHighlighted ? Color.green.opacity(0.8) : Color.white.opacity(0.2),
                                lineWidth: 0.5
                            )
                    )
                    .offset(x: -4, y: -4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { doCopy() }
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
        .animation(.easeInOut(duration: 0.12), value: copied)
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
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
                    .frame(width: 82, height: 82)
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

    private func doCopy() {
        store.copyToClipboard(item)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { copied = false }
        }
    }
}
