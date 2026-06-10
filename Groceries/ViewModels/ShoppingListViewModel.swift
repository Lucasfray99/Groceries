import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ShoppingListViewModel {
    private(set) var items: [ShoppingItem]
    private(set) var removalCountdowns: [ShoppingItem.ID: Int] = [:]

    @ObservationIgnored private var removalTasks: [ShoppingItem.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var changeObserver: NSObjectProtocol?
    @ObservationIgnored private let store: ShoppingListStore.Type

    init(shoppingListData: ShoppingListData, store: ShoppingListStore.Type = ShoppingListStore.self) {
        self.items = shoppingListData.items
        self.store = store

        changeObserver = NotificationCenter.default.addObserver(
            forName: .shoppingListDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadFromStore()
            }
        }
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }

        for task in removalTasks.values {
            task.cancel()
        }
    }

    var remainingCount: Int {
        items.filter { !$0.isPurchased }.count
    }

    var remainingItemsText: String {
        remainingCount == 1 ? "1 item left" : "\(remainingCount) items left"
    }

    var visibleCategories: [ShoppingItemCategory] {
        ShoppingItemCategory.allCases.filter { visibleCategory in
            items.contains { category(for: $0) == visibleCategory }
        }
    }

    func filteredSuggestions(for itemName: String) -> [ShoppingItemSuggestion] {
        let existingNames = Set(items.map { $0.name.localizedLowercase })
        let searchText = itemName.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase

        return ShoppingItemSuggestion.catalog
            .filter { suggestion in
                !existingNames.contains(suggestion.name.localizedLowercase)
                    && (searchText.isEmpty || suggestion.matches(searchText: searchText))
            }
            .prefix(10)
            .map { $0 }
    }

    func matchedSuggestion(for itemName: String) -> ShoppingItemSuggestion? {
        ShoppingItemSuggestion.suggestion(for: itemName.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func category(for item: ShoppingItem) -> ShoppingItemCategory {
        if let categoryName = item.categoryName,
           let category = ShoppingItemCategory(rawValue: categoryName) {
            return category
        }

        return ShoppingItemSuggestion.category(for: item.name)
    }

    func items(in category: ShoppingItemCategory) -> [ShoppingItem] {
        items.filter { item in
            self.category(for: item) == category
        }
    }

    func addSuggestion(_ suggestion: ShoppingItemSuggestion) {
        items.append(
            ShoppingItem(
                name: suggestion.name,
                symbolName: suggestion.symbolName,
                categoryName: suggestion.category.rawValue
            )
        )
        saveList()
    }

    func addItem(named itemName: String, selectedCategory: ShoppingItemCategory) -> Bool {
        let trimmedItemName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItemName.isEmpty else { return false }

        let matchedSuggestion = ShoppingItemSuggestion.suggestion(for: trimmedItemName)
        let category = matchedSuggestion?.category ?? selectedCategory

        items.append(
            ShoppingItem(
                name: trimmedItemName,
                symbolName: ShoppingItemSuggestion.symbolName(for: trimmedItemName),
                categoryName: category.rawValue
            )
        )
        saveList()
        return true
    }

    func toggleItem(_ item: ShoppingItem, removalDelaySeconds: Int) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        items[index].isPurchased.toggle()
        saveList()

        if items[index].isPurchased {
            startRemovalTimer(for: item.id, delaySeconds: removalDelaySeconds)
        } else {
            cancelRemovalTimer(for: item.id)
        }
    }

    func deleteItems(at offsets: IndexSet, in category: ShoppingItemCategory) {
        let categoryItems = items(in: category)
        let removedIDs = offsets.map { categoryItems[$0].id }

        items.removeAll { item in
            removedIDs.contains(item.id)
        }

        for id in removedIDs {
            cancelRemovalTimer(for: id)
        }

        saveList()
    }

    func startTimersForPurchasedItems(removalDelaySeconds: Int) {
        for item in items where item.isPurchased && removalTasks[item.id] == nil {
            startRemovalTimer(for: item.id, delaySeconds: removalDelaySeconds)
        }
    }

    private func reloadFromStore() {
        let storedItems = store.load().items
        guard storedItems != items else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            items = storedItems
        }
        startTimersForPurchasedItems(removalDelaySeconds: storedRemovalDelaySeconds)

        for itemID in Array(removalTasks.keys) where !items.contains(where: { $0.id == itemID && $0.isPurchased }) {
            cancelRemovalTimer(for: itemID)
        }
    }

    private var storedRemovalDelaySeconds: Int {
        RemovalDelaySettings.currentSeconds
    }

    private func startRemovalTimer(for itemID: ShoppingItem.ID, delaySeconds: Int) {
        cancelRemovalTimer(for: itemID)
        removalCountdowns[itemID] = delaySeconds

        removalTasks[itemID] = Task { @MainActor in
            var secondsRemaining = delaySeconds

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
        store.save(
            ShoppingListData(
                listName: "Shopping List",
                items: items
            )
        )
    }
}
