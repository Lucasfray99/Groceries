import Foundation

final class ICloudSettingsSync {
    static let shared = ICloudSettingsSync()

    private let cloudStore = NSUbiquitousKeyValueStore.default
    private var changeObserver: NSObjectProtocol?

    private init() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak self] notification in
            self?.handleExternalChange(notification)
        }
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    func activate() {
        cloudStore.synchronize()
        mergeInitialRemovalDelay()
    }

    func saveRemovalDelay(_ seconds: Int) {
        cloudStore.set(Int64(seconds), forKey: RemovalDelaySettings.storageKey)
        cloudStore.synchronize()
    }

    private func mergeInitialRemovalDelay() {
        let cloudDelay = Int(cloudStore.longLong(forKey: RemovalDelaySettings.storageKey))

        if cloudDelay > 0 {
            RemovalDelaySettings.setLocalSeconds(cloudDelay, syncsToICloud: false)
            return
        }

        saveRemovalDelay(RemovalDelaySettings.currentSeconds)
    }

    private func handleExternalChange(_ notification: Notification) {
        guard changedKeys(from: notification).contains(RemovalDelaySettings.storageKey) else { return }

        let cloudDelay = Int(cloudStore.longLong(forKey: RemovalDelaySettings.storageKey))
        guard cloudDelay > 0 else { return }

        RemovalDelaySettings.setLocalSeconds(cloudDelay, syncsToICloud: false)
    }

    private func changedKeys(from notification: Notification) -> [String] {
        notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
    }
}
