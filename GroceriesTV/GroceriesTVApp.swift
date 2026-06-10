import SwiftUI

@main
struct GroceriesTVApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        CloudKitShoppingListSync.shared.activate()
        ICloudSettingsSync.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    CloudKitShoppingListSync.shared.fetchLatest()
                    ICloudSettingsSync.shared.activate()
                }
        }
    }
}
