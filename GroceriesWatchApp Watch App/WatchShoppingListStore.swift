import Foundation

struct WatchShoppingListStore {
    static let storageKey = "watchShoppingListData"

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

    static func save(_ shoppingListData: ShoppingListData, syncsToCloudKit: Bool = true) {
        do {
            var syncedShoppingListData = shoppingListData
            if syncsToCloudKit {
                syncedShoppingListData.lastModified = Date()
            }

            let data = try JSONEncoder().encode(syncedShoppingListData)
            UserDefaults.standard.set(data, forKey: storageKey)

            if syncsToCloudKit {
                WatchCloudKitShoppingListSync.shared.save(data)
            }

            NotificationCenter.default.post(name: .watchShoppingListDidChange, object: nil)
        } catch {
            assertionFailure("Failed to save watch shopping list data: \(error)")
        }
    }
}
