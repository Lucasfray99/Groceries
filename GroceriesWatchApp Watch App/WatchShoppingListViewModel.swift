import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class WatchShoppingListViewModel {
    private(set) var items: [ShoppingItem]
    private(set) var removalCountdowns: [ShoppingItem.ID: Int] = [:]

    @ObservationIgnored private var removalTasks: [ShoppingItem.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var changeObserver: NSObjectProtocol?

    init(shoppingListData: ShoppingListData) {
        items = shoppingListData.items

        changeObserver = NotificationCenter.default.addObserver(
            forName: .watchShoppingListDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadFromStore()
            }
        }

        startTimersForPurchasedItems()
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }

        for task in removalTasks.values {
            task.cancel()
        }
    }

    var remainingItemsText: String {
        let remainingCount = items.filter { !$0.isPurchased }.count
        return remainingCount == 1 ? "1 item left" : "\(remainingCount) items left"
    }

    func refresh() {
        WatchCloudKitShoppingListSync.shared.fetchLatest()
        WatchConnectivityController.shared.requestLatestList()
    }

    func toggleItem(_ item: ShoppingItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        items[index].isPurchased.toggle()
        saveList()
        WatchConnectivityController.shared.setPurchased(itemID: item.id, isPurchased: items[index].isPurchased)

        if items[index].isPurchased {
            startRemovalTimer(for: item.id)
        } else {
            cancelRemovalTimer(for: item.id)
        }
    }

    func addSuggestion(_ suggestion: WatchShoppingItemSuggestion) {
        addItem(
            name: suggestion.name,
            symbolName: suggestion.symbolName,
            categoryName: suggestion.categoryName
        )
    }

    func addItem(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let suggestion = WatchShoppingItemSuggestion.bestMatch(for: trimmedName) {
            addSuggestion(suggestion)
        } else {
            addItem(name: trimmedName, symbolName: "cart", categoryName: "Other")
        }
    }

    private func addItem(name: String, symbolName: String, categoryName: String) {
        guard !items.contains(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            items.append(
                ShoppingItem(
                    name: name,
                    symbolName: symbolName,
                    categoryName: categoryName
                )
            )
        }
        saveList()
    }

    private func reloadFromStore() {
        let storedItems = WatchShoppingListStore.load().items
        guard storedItems != items else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            items = storedItems
        }
        startTimersForPurchasedItems()

        for itemID in Array(removalTasks.keys) where !items.contains(where: { $0.id == itemID && $0.isPurchased }) {
            cancelRemovalTimer(for: itemID)
        }
    }

    private func startTimersForPurchasedItems() {
        for item in items where item.isPurchased && removalTasks[item.id] == nil {
            startRemovalTimer(for: item.id)
        }
    }

    private func startRemovalTimer(for itemID: ShoppingItem.ID) {
        cancelRemovalTimer(for: itemID)
        removalCountdowns[itemID] = removalDelaySeconds

        removalTasks[itemID] = Task { @MainActor in
            var secondsRemaining = removalDelaySeconds

            while secondsRemaining > 0 {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }

                secondsRemaining -= 1

                guard let index = items.firstIndex(where: { $0.id == itemID }), items[index].isPurchased else {
                    cancelRemovalTimer(for: itemID)
                    return
                }

                if secondsRemaining == 0 {
                    _ = withAnimation(.easeInOut(duration: 0.25)) {
                        items.remove(at: index)
                    }
                    removalCountdowns[itemID] = nil
                    removalTasks[itemID] = nil
                    saveList()
                } else {
                    removalCountdowns[itemID] = secondsRemaining
                }
            }
        }
    }

    private func cancelRemovalTimer(for itemID: ShoppingItem.ID) {
        removalTasks[itemID]?.cancel()
        removalTasks[itemID] = nil
        removalCountdowns[itemID] = nil
    }

    private func saveList() {
        WatchShoppingListStore.save(ShoppingListData(listName: "Shopping List", items: items))
    }

    private var removalDelaySeconds: Int {
        WatchRemovalDelaySettings.currentSeconds
    }
}
