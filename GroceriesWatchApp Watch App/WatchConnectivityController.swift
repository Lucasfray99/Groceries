import Foundation
import WatchConnectivity

final class WatchConnectivityController: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityController()

    private let session: WCSession?

    private override init() {
        session = WCSession.isSupported() ? WCSession.default : nil
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func activate() {
        session?.activate()
        requestLatestList()
    }

    func requestLatestList() {
        guard let session else { return }

        if let payload = session.receivedApplicationContext[WatchMessageKey.payload] as? Data {
            saveList(from: payload)
        }

        guard session.isReachable else { return }

        session.sendMessage(
            [WatchMessageKey.action: WatchMessageAction.requestList],
            replyHandler: { [weak self] reply in
                self?.saveList(from: reply)
            },
            errorHandler: nil
        )
    }

    func setPurchased(itemID: ShoppingItem.ID, isPurchased: Bool) {
        guard let session else { return }

        let message: [String: Any] = [
            WatchMessageKey.action: WatchMessageAction.setPurchased,
            WatchMessageKey.itemID: itemID.uuidString,
            WatchMessageKey.isPurchased: isPurchased
        ]

        if session.isReachable {
            session.sendMessage(
                message,
                replyHandler: { [weak self] reply in
                    self?.saveList(from: reply)
                },
                errorHandler: nil
            )
        } else {
            session.transferUserInfo(message)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        requestLatestList()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        saveList(from: applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        saveList(from: message)
    }

    private func saveList(from message: [String: Any]) {
        if let removalDelaySeconds = message[WatchMessageKey.removalDelaySeconds] as? Int {
            UserDefaults.standard.set(removalDelaySeconds, forKey: "removalDelaySeconds")
        }

        guard let payload = message[WatchMessageKey.payload] as? Data else { return }
        saveList(from: payload)
    }

    private func saveList(from payload: Data) {
        guard let shoppingListData = try? JSONDecoder().decode(ShoppingListData.self, from: payload) else { return }

        DispatchQueue.main.async {
            WatchShoppingListStore.save(shoppingListData)
        }
    }
}
