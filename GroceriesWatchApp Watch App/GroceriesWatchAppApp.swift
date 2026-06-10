import SwiftUI

@main
struct GroceriesWatchApp_Watch_AppApp: App {
    init() {
        WatchCloudKitShoppingListSync.shared.activate()
        WatchConnectivityController.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
