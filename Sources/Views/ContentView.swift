import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ItemStore
    @State private var warningPulse = false

    var body: some View {
        ZStack {
            mainContent

            if store.showCapacityWarning {
                capacityWarning
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .frame(width: 660, height: 120)
        .animation(.easeInOut(duration: 0.2), value: store.showCapacityWarning)
    }

    private var mainContent: some View {
        Group {
            if store.items.isEmpty {
                Text("Copy something, take a screenshot, or download a file")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.items.reversed()) { item in
                            ItemCell(item: item)
                                .environmentObject(store)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
        }
        .overlay(
            // Red border pulse when at capacity warning
            RoundedRectangle(cornerRadius: 60)
                .stroke(
                    store.showCapacityWarning ? Color.red.opacity(warningPulse ? 0.9 : 0.3) : .clear,
                    lineWidth: 2
                )
                .animation(
                    store.showCapacityWarning
                        ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        : .default,
                    value: warningPulse
                )
        )
        .onChange(of: store.showCapacityWarning) { _, showing in
            warningPulse = showing
        }
    }

    private var capacityWarning: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 60))

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
                    PillButton("Cancel", color: .secondary.opacity(0.25)) {
                        store.cancelOverride()
                    }
                    PillButton("Replace", color: .red.opacity(0.75)) {
                        store.confirmOverride()
                    }
                    PillButton("Settings", color: Color.blue.opacity(0.6)) {
                        store.cancelOverride()
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(width: 660, height: 120)
    }
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
