import Foundation
import WatchConnectivity

final class PhoneWatchConnectivityController: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchConnectivityController()

    private let session: WCSession?
    private var changeObserver: NSObjectProtocol?
    private var removalTasks: [ShoppingItem.ID: Task<Void, Never>] = [:]

    private override init() {
        session = WCSession.isSupported() ? WCSession.default : nil
        super.init()

        session?.delegate = self
        session?.activate()

        changeObserver = NotificationCenter.default.addObserver(
            forName: .shoppingListDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sendCurrentList()
        }
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    func activate() {
        session?.activate()
        sendCurrentList()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        sendCurrentList()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let action = message[WatchMessageKey.action] as? String else {
            replyHandler(currentListMessage())
            return
        }

        switch action {
        case WatchMessageAction.requestList:
            replyHandler(currentListMessage())
        case WatchMessageAction.setPurchased:
            updatePurchasedState(from: message)
            replyHandler(currentListMessage())
        default:
            replyHandler(currentListMessage())
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard userInfo[WatchMessageKey.action] as? String == WatchMessageAction.setPurchased else { return }
        updatePurchasedState(from: userInfo)
    }

    private func updatePurchasedState(from message: [String: Any]) {
        guard let idString = message[WatchMessageKey.itemID] as? String,
              let itemID = UUID(uuidString: idString),
              let isPurchased = message[WatchMessageKey.isPurchased] as? Bool else { return }

        var shoppingListData = ShoppingListStore.load()
        guard let index = shoppingListData.items.firstIndex(where: { $0.id == itemID }) else { return }

        shoppingListData.items[index].isPurchased = isPurchased
        ShoppingListStore.save(shoppingListData)

        if isPurchased {
            startRemovalTimer(for: itemID)
        } else {
            cancelRemovalTimer(for: itemID)
        }
    }

    private func startRemovalTimer(for itemID: ShoppingItem.ID) {
        cancelRemovalTimer(for: itemID)

        removalTasks[itemID] = Task { [weak self] in
            let delaySeconds = Self.removalDelaySeconds

            do {
                try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
            } catch {
                return
            }

            await MainActor.run {
                self?.removePurchasedItem(with: itemID)
            }
        }
    }

    private func cancelRemovalTimer(for itemID: ShoppingItem.ID) {
        removalTasks[itemID]?.cancel()
        removalTasks[itemID] = nil
    }

    private func removePurchasedItem(with itemID: ShoppingItem.ID) {
        var shoppingListData = ShoppingListStore.load()
        guard let index = shoppingListData.items.firstIndex(where: { $0.id == itemID && $0.isPurchased }) else {
            cancelRemovalTimer(for: itemID)
            return
        }

        shoppingListData.items.remove(at: index)
        cancelRemovalTimer(for: itemID)
        ShoppingListStore.save(shoppingListData)
    }

    private static var removalDelaySeconds: Int {
        RemovalDelaySettings.currentSeconds
    }

    private func sendCurrentList() {
        guard let session, let payload = encodedCurrentList() else { return }

        let message: [String: Any] = [
            WatchMessageKey.payload: payload,
            WatchMessageKey.removalDelaySeconds: Self.removalDelaySeconds
        ]

        if session.activationState == .activated {
            try? session.updateApplicationContext(message)
        }

        if session.isReachable {
            session.sendMessage(
                [
                    WatchMessageKey.action: WatchMessageAction.listDidChange,
                    WatchMessageKey.payload: payload,
                    WatchMessageKey.removalDelaySeconds: Self.removalDelaySeconds
                ],
                replyHandler: nil,
                errorHandler: nil
            )
        }
    }

    private func currentListMessage() -> [String: Any] {
        guard let payload = encodedCurrentList() else { return [:] }
        return [
            WatchMessageKey.payload: payload,
            WatchMessageKey.removalDelaySeconds: Self.removalDelaySeconds
        ]
    }

    private func encodedCurrentList() -> Data? {
        try? JSONEncoder().encode(ShoppingListStore.load())
    }
}
