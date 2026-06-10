import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(RemovalDelaySettings.storageKey) private var removalDelaySeconds = RemovalDelaySettings.defaultSeconds

    private let delayOptions = [5, 10, 15, 20, 25, 30]

    var body: some View {
        NavigationStack {
            Form {
                Section("Remove Checked Items After") {
                    Picker("", selection: $removalDelaySeconds) {
                        ForEach(delayOptions, id: \.self) { seconds in
                            Text("\(seconds) seconds")
                                .tag(seconds)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.inline)
                    .accessibilityLabel("Remove checked items after")
                    .onChange(of: removalDelaySeconds) {
                        RemovalDelaySettings.setLocalSeconds(removalDelaySeconds)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
