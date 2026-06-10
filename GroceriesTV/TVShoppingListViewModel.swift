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
    @ObservationIgnored private var settingsObserver: NSObjectProtocol?

    init(shoppingListData: ShoppingListData) {
        items = shoppingListData.items

        changeObserver = NotificationCenter.default.addObserver(
            forName: .shoppingListDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadFromStore()
            }
        }

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .removalDelayDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.restartPurchasedItemTimers()
            }
        }

        startTimersForPurchasedItems()
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }

        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }

        for task in removalTasks.values {
            task.cancel()
        }
    }

    var remainingCount: Int {
        items.filter { !$0.isPurchased }.count
    }

    var purchasedCount: Int {
        items.filter(\.isPurchased).count
    }

    var remainingItemsText: String {
        remainingCount == 1 ? "1 item left" : "\(remainingCount) items left"
    }

    var visibleCategories: [ShoppingItemCategory] {
        ShoppingItemCategory.allCases.filter { category in
            items.contains { self.category(for: $0) == category }
        }
    }

    var hasItems: Bool {
        !items.isEmpty
    }

    func refresh() {
        CloudKitShoppingListSync.shared.fetchLatest()
        ICloudSettingsSync.shared.activate()
    }

    func filteredSuggestions(for itemName: String) -> [ShoppingItemSuggestion] {
        let existingNames = Set(items.map { $0.name.localizedLowercase })
        let searchText = itemName.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase

        return ShoppingItemSuggestion.catalog
            .filter { suggestion in
                !existingNames.contains(suggestion.name.localizedLowercase)
                    && (searchText.isEmpty || suggestion.matches(searchText: searchText))
            }
            .prefix(18)
            .map { $0 }
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
        addItem(
            name: suggestion.name,
            symbolName: suggestion.symbolName,
            category: suggestion.category
        )
    }

    @discardableResult
    func addItem(named itemName: String, selectedCategory: ShoppingItemCategory) -> Bool {
        let trimmedItemName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItemName.isEmpty else { return false }

        if let suggestion = ShoppingItemSuggestion.suggestion(for: trimmedItemName) {
            addSuggestion(suggestion)
            return true
        }

        addItem(
            name: trimmedItemName,
            symbolName: ShoppingItemSuggestion.fallbackSymbolName,
            category: selectedCategory
        )
        return true
    }

    func toggleItem(_ item: ShoppingItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        items[index].isPurchased.toggle()
        saveList()

        if items[index].isPurchased {
            startRemovalTimer(for: item.id)
        } else {
            cancelRemovalTimer(for: item.id)
        }
    }

    func delete(_ item: ShoppingItem) {
        guard items.contains(where: { $0.id == item.id }) else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            items.removeAll { $0.id == item.id }
        }
        cancelRemovalTimer(for: item.id)
        saveList()
    }

    func clearPurchasedItems() {
        let purchasedIDs = Set(items.filter(\.isPurchased).map(\.id))
        guard !purchasedIDs.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            items.removeAll { purchasedIDs.contains($0.id) }
        }

        for itemID in purchasedIDs {
            cancelRemovalTimer(for: itemID)
        }

        saveList()
    }

    func startTimersForPurchasedItems() {
        for item in items where item.isPurchased && removalTasks[item.id] == nil {
            startRemovalTimer(for: item.id)
        }
    }

    private func addItem(name: String, symbolName: String, category: ShoppingItemCategory) {
        guard !items.contains(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            items.append(
                ShoppingItem(
                    name: name,
                    symbolName: symbolName,
                    categoryName: category.rawValue
                )
            )
        }
        saveList()
    }

    private func reloadFromStore() {
        let storedItems = ShoppingListStore.load().items
        guard storedItems != items else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            items = storedItems
        }
        startTimersForPurchasedItems()

        for itemID in Array(removalTasks.keys) where !items.contains(where: { $0.id == itemID && $0.isPurchased }) {
            cancelRemovalTimer(for: itemID)
        }
    }

    private func restartPurchasedItemTimers() {
        for itemID in Array(removalTasks.keys) {
            cancelRemovalTimer(for: itemID)
        }

        startTimersForPurchasedItems()
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
        ShoppingListStore.save(
            ShoppingListData(
                listName: "Shopping List",
                items: items
            )
        )
    }

    private var removalDelaySeconds: Int {
        RemovalDelaySettings.currentSeconds
    }
}
