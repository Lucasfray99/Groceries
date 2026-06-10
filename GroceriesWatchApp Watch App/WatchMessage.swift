import Foundation

enum WatchMessageKey {
    static let action = "action"
    static let payload = "payload"
    static let itemID = "itemID"
    static let isPurchased = "isPurchased"
    static let removalDelaySeconds = "removalDelaySeconds"
}

enum WatchMessageAction {
    static let requestList = "requestList"
    static let listDidChange = "listDidChange"
    static let setPurchased = "setPurchased"
}
