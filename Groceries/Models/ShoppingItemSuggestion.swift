import Foundation

struct ShoppingItemSuggestion: Identifiable, Equatable {
    let name: String
    let symbolName: String
    let category: ShoppingItemCategory
    let searchKeywords: [String]

    init(
        name: String,
        symbolName: String,
        category: ShoppingItemCategory,
        searchKeywords: [String] = []
    ) {
        self.name = name
        self.symbolName = symbolName
        self.category = category
        self.searchKeywords = searchKeywords
    }

    var id: String { name }

    static let fallbackSymbolName = "cart"
    static let fallbackCategory: ShoppingItemCategory = .other

    func matches(searchText: String) -> Bool {
        name.localizedLowercase.contains(searchText)
            || searchKeywords.contains { $0.localizedLowercase.contains(searchText) }
    }

    static func suggestion(for itemName: String) -> ShoppingItemSuggestion? {
        catalog.first {
            $0.name.localizedCaseInsensitiveCompare(itemName) == .orderedSame
        }
    }

    static func symbolName(for itemName: String) -> String {
        suggestion(for: itemName)?.symbolName ?? fallbackSymbolName
    }

    static func category(for itemName: String) -> ShoppingItemCategory {
        suggestion(for: itemName)?.category ?? fallbackCategory
    }
}
