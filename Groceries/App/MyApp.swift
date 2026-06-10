import SwiftUI
import Playgrounds

@main struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        CloudKitShoppingListSync.shared.activate()
        ICloudSettingsSync.shared.activate()
        PhoneWatchConnectivityController.shared.activate()
    }
    
    func joe() {
        let mama = "gottem"
        
        print(mama)
    }

    var body: some Scene {
        WindowGroup {
            ShoppingListView()
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }

            CloudKitShoppingListSync.shared.fetchLatest()
            ICloudSettingsSync.shared.activate()
        }
    }
}
