import SwiftUI
import AppKit

struct ClovePopupView: View {
    @EnvironmentObject var store: ItemStore
    @State private var warningPulse = false

    var body: some View {
        ZStack {
            // Frosted glass background
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            if store.showCapacityWarning {
                capacityWarning
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                mainContent
            }
        }
        .frame(width: 700, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    store.showCapacityWarning
                        ? Color.red.opacity(warningPulse ? 0.85 : 0.2)
                        : Color.white.opacity(0.1),
                    lineWidth: store.showCapacityWarning ? 1.5 : 0.5
                )
                .animation(
                    store.showCapacityWarning
                        ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        : .default,
                    value: warningPulse
                )
        )
        .animation(.easeInOut(duration: 0.2), value: store.showCapacityWarning)
        .onChange(of: store.showCapacityWarning) { showing in
            warningPulse = showing
        }
    }

    private var mainContent: some View {
        HStack(spacing: 0) {
            // Settings button on the left
            VStack(spacing: 8) {
                Button(action: {
                    (NSApp.delegate as? AppDelegate)?.openSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)

                Button(action: { store.clearAll() }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 32, height: 28)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 16)

            // Items
            if store.items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Copy something to get started")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(store.items.reversed().enumerated()), id: \.element.id) { index, item in
                            ItemCell(item: item, index: index + 1)
                                .environmentObject(store)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                }
            }
        }
    }

    private var capacityWarning: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Storage Full")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
                Text("Replace the oldest item to make room?")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                PillButton("Cancel", color: .secondary.opacity(0.2)) {
                    store.cancelOverride()
                }
                PillButton("Replace", color: .red.opacity(0.75)) {
                    store.confirmOverride()
                }
                PillButton("Settings", color: .blue.opacity(0.6)) {
                    store.cancelOverride()
                    (NSApp.delegate as? AppDelegate)?.openSettings()
                }
            }
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - Supporting views

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct PillButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    init(_ title: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
