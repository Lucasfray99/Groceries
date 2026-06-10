import Foundation

struct ShoppingItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var symbolName: String?
    var categoryName: String?
    var isPurchased: Bool

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String? = nil,
        categoryName: String? = nil,
        isPurchased: Bool = false
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.categoryName = categoryName
        self.isPurchased = isPurchased
    }
}
