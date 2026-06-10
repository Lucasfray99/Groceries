import Foundation

extension Notification.Name {
    static let shoppingListDidChange = Notification.Name("shoppingListDidChange")
}

struct ShoppingListData: Codable, Equatable {
    var listName: String
    var items: [ShoppingItem]
    var lastModified: Date?

    static let sample = ShoppingListData(
        listName: "Weekly Groceries",
        items: [
            ShoppingItem(name: "Milk"),
            ShoppingItem(name: "Eggs"),
            ShoppingItem(name: "Bread"),
            ShoppingItem(name: "Apples")
        ]
    )
}

struct ShoppingListStore {
    static let storageKey = "shoppingListData"

    static func load() -> ShoppingListData {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return .sample
        }

        do {
            return try JSONDecoder().decode(ShoppingListData.self, from: data)
        } catch {
            return .sample
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
            assertionFailure("Failed to save shopping list data: \(error)")
        }
    }
}
