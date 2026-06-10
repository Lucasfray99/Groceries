import Foundation

struct ShoppingListStore {
    static let storageKey = "shoppingListData"

    static func load() -> ShoppingListData {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(ShoppingListData.self, from: data)
        } catch {
            return .empty
        }
    }

    static func save(
        _ shoppingListData: ShoppingListData,
        postsChangeNotification: Bool = true,
        syncsToCloudKit: Bool = true
    ) {
        do {
            var syncedShoppingListData = shoppingListData
            if syncsToCloudKit {
                syncedShoppingListData.lastModified = Date()
            }

            let data = try JSONEncoder().encode(syncedShoppingListData)
            UserDefaults.standard.set(data, forKey: storageKey)

            if syncsToCloudKit {
                CloudKitShoppingListSync.shared.save(data)
            }

            if postsChangeNotification {
                NotificationCenter.default.post(name: .shoppingListDidChange, object: nil)
            }
        } catch {
            assertionFailure("Failed to save tvOS shopping list data: \(error)")
        }
    }
}

enum RemovalDelaySettings {
    static let storageKey = "removalDelaySeconds"
    static let defaultSeconds = 15

    static var currentSeconds: Int {
        let storedDelay = UserDefaults.standard.integer(forKey: storageKey)
        return storedDelay == 0 ? defaultSeconds : storedDelay
    }

    static func setLocalSeconds(_ seconds: Int, syncsToICloud: Bool = true) {
        UserDefaults.standard.set(seconds, forKey: storageKey)
        NotificationCenter.default.post(name: .removalDelayDidChange, object: nil)

        if syncsToICloud {
            ICloudSettingsSync.shared.saveRemovalDelay(seconds)
        }
    }
}
