import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ItemStore
    @State private var sliderValue: Double = 10

    var body: some View {
        Form {
            Section("Storage Limit") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Maximum items")
                        Spacer()
                        Text("\(Int(sliderValue))")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .frame(width: 32, alignment: .trailing)
                    }

                    Slider(value: $sliderValue, in: 5...50, step: 1)
                        .tint(.green)
                        .onChange(of: sliderValue) { new in
                            store.maxItems = Int(new)
                        }

                    Text("Images are stored as compressed thumbnails (~5-15 KB each). Text is stored as plain strings.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Section("Monitored Locations") {
                Label("Clipboard (text + images)", systemImage: "doc.on.clipboard")
                Label("Desktop (screenshots)", systemImage: "desktopcomputer")
                Label("Downloads folder", systemImage: "arrow.down.circle")
            }

            Section {
                Button("Clear All Items", role: .destructive) {
                    store.clearAll()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 340)
        .onAppear {
            sliderValue = Double(store.maxItems)
        }
    }
}
