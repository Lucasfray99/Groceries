import CloudKit
import Foundation

final class CloudKitShoppingListSync {
    static let shared = CloudKitShoppingListSync()

    private let database: CKDatabase
    private let recordID = CKRecord.ID(recordName: "defaultShoppingList")
    private let recordType = "ShoppingList"
    private let payloadField = "payload"
    private var pollingTimer: Timer?

    private init(container: CKContainer = CKContainer(identifier: "iCloud.com.OnlyFrays.Groceries")) {
        database = container.privateCloudDatabase
    }

    func activate() {
        fetchLatest()
        startPolling()
    }

    func fetchLatest() {
        database.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self else { return }

            if self.isMissingRecordError(error) {
                self.seedCloudFromLocalStoreIfNeeded()
                return
            }

            guard error == nil,
                  let payload = record?[self.payloadField] as? Data else { return }

            self.applyCloudPayload(payload)
        }
    }

    func save(_ data: Data) {
        database.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self else { return }

            if let error, !self.isMissingRecordError(error) {
                return
            }

            let record = record ?? CKRecord(recordType: self.recordType, recordID: self.recordID)
            record[self.payloadField] = data as NSData
            self.database.save(record) { _, _ in }
        }
    }

    private func startPolling() {
        guard pollingTimer == nil else { return }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetchLatest()
        }
    }

    private func seedCloudFromLocalStoreIfNeeded() {
        guard let localData = UserDefaults.standard.data(forKey: ShoppingListStore.storageKey) else { return }
        save(localData)
    }

    private func applyCloudPayload(_ payload: Data) {
        DispatchQueue.main.async {
            guard UserDefaults.standard.data(forKey: ShoppingListStore.storageKey) != payload,
                  self.shouldApplyCloudPayload(payload) else { return }

            UserDefaults.standard.set(payload, forKey: ShoppingListStore.storageKey)
            NotificationCenter.default.post(name: .shoppingListDidChange, object: nil)
        }
    }

    private func shouldApplyCloudPayload(_ payload: Data) -> Bool {
        guard let cloudData = try? JSONDecoder().decode(ShoppingListData.self, from: payload) else { return false }
        guard let localPayload = UserDefaults.standard.data(forKey: ShoppingListStore.storageKey),
              let localData = try? JSONDecoder().decode(ShoppingListData.self, from: localPayload) else { return true }

        guard let cloudModified = cloudData.lastModified else { return true }
        guard let localModified = localData.lastModified else { return true }

        return cloudModified > localModified
    }

    private func isMissingRecordError(_ error: Error?) -> Bool {
        guard let cloudError = error as? CKError else { return false }
        return cloudError.code == .unknownItem
    }
}
