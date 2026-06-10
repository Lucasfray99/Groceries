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

struct ShoppingListData: Codable, Equatable {
    var listName: String
    var items: [ShoppingItem]
    var lastModified: Date?

    static let empty = ShoppingListData(
        listName: "Shopping List",
        items: []
    )
}

struct WatchShoppingItemSuggestion: Identifiable, Equatable {
    let name: String
    let symbolName: String
    let categoryName: String
    let searchKeywords: [String]

    var id: String { name }

    var searchableText: String {
        ([name, categoryName] + searchKeywords).joined(separator: " ").localizedLowercase
    }
}

extension WatchShoppingItemSuggestion {
    static let catalog: [WatchShoppingItemSuggestion] = [
        item("Milk", "drop", "Dairy"),
        item("Eggs", "circle.grid.2x2", "Dairy"),
        item("Butter", "cube", "Dairy"),
        item("Cheese", "cube.fill", "Dairy"),
        item("Yogurt", "cup.and.saucer", "Dairy"),
        item("Cream", "drop.fill", "Dairy"),
        item("Sour Cream", "cup.and.saucer.fill", "Dairy"),
        item("Cottage Cheese", "cube", "Dairy"),
        item("Cream Cheese", "cube.fill", "Dairy"),
        item("Mozzarella", "circle.grid.2x2", "Dairy"),
        item("Parmesan", "triangle", "Dairy"),
        item("Oat Milk", "leaf", "Dairy", ["Milk"]),
        item("Bread", "takeoutbag.and.cup.and.straw", "Bakery"),
        item("Bagels", "circle", "Bakery"),
        item("Tortillas", "circle.dashed", "Bakery"),
        item("Buns", "circle.fill", "Bakery"),
        item("Croissants", "moon", "Bakery"),
        item("Pita Bread", "circle", "Bakery"),
        item("Apples", "apple.logo", "Produce"),
        item("Bananas", "leaf", "Produce"),
        item("Oranges", "circle.fill", "Produce"),
        item("Berries", "circle.grid.cross", "Produce"),
        item("Grapes", "circle.grid.3x3", "Produce"),
        item("Lemons", "circle", "Produce"),
        item("Limes", "circle", "Produce"),
        item("Potatoes", "circle.hexagongrid", "Produce"),
        item("Sweet Potatoes", "circle.hexagongrid.fill", "Produce"),
        item("Onions", "circle.dotted", "Produce"),
        item("Garlic", "circle.dotted.circle", "Produce"),
        item("Tomatoes", "circle.fill", "Produce"),
        item("Lettuce", "leaf", "Produce"),
        item("Spinach", "leaf.fill", "Produce"),
        item("Carrots", "carrot", "Produce"),
        item("Broccoli", "leaf.circle", "Produce"),
        item("Cucumber", "capsule", "Produce"),
        item("Peppers", "circle.grid.cross", "Produce"),
        item("Avocados", "circle", "Produce"),
        item("Mushrooms", "circle.dotted", "Produce"),
        item("Chicken", "fork.knife", "Meat & Seafood"),
        item("Ground Beef", "fork.knife.circle", "Meat & Seafood"),
        item("Steak", "flame", "Meat & Seafood"),
        item("Bacon", "flame", "Meat & Seafood"),
        item("Ham", "fork.knife", "Meat & Seafood"),
        item("Sausages", "fork.knife.circle", "Meat & Seafood"),
        item("Salmon", "fish", "Meat & Seafood"),
        item("Tuna", "fish.circle", "Meat & Seafood"),
        item("Shrimp", "fish", "Meat & Seafood"),
        item("Rice", "shippingbox", "Pantry"),
        item("Pasta", "takeoutbag.and.cup.and.straw", "Pantry"),
        item("Noodles", "takeoutbag.and.cup.and.straw.fill", "Pantry"),
        item("Flour", "shippingbox.fill", "Pantry"),
        item("Sugar", "cube", "Pantry"),
        item("Brown Sugar", "cube.fill", "Pantry"),
        item("Coffee", "cup.and.saucer", "Pantry"),
        item("Tea", "mug", "Pantry"),
        item("Cereal", "rectangle.grid.2x2", "Pantry"),
        item("Oats", "leaf", "Pantry"),
        item("Peanut Butter", "circle.hexagongrid.fill", "Pantry"),
        item("Jam", "cylinder", "Pantry"),
        item("Honey", "drop", "Pantry"),
        item("Olive Oil", "drop.fill", "Pantry"),
        item("Vegetable Oil", "drop", "Pantry"),
        item("Vinegar", "drop", "Pantry"),
        item("Salt", "sparkles", "Pantry"),
        item("Pepper", "sparkle", "Pantry"),
        item("Canned Beans", "cylinder", "Pantry"),
        item("Canned Tomatoes", "cylinder.fill", "Pantry"),
        item("Soup", "takeoutbag.and.cup.and.straw", "Pantry"),
        item("Crackers", "square.grid.3x3", "Pantry"),
        item("Chips", "bag", "Pantry"),
        item("Chocolate", "birthday.cake", "Pantry"),
        item("Cookies", "circle.grid.2x2", "Pantry"),
        item("Ketchup", "drop.fill", "Pantry"),
        item("Mustard", "drop", "Pantry"),
        item("Mayonnaise", "drop", "Pantry"),
        item("Soy Sauce", "drop", "Pantry"),
        item("Stock Cubes", "cube", "Pantry"),
        item("Ice Cream", "snowflake", "Frozen"),
        item("Frozen Vegetables", "snowflake.circle", "Frozen"),
        item("Frozen Pizza", "snowflake", "Frozen"),
        item("Frozen Berries", "snowflake.circle.fill", "Frozen"),
        item("Fries", "snowflake", "Frozen", ["Frozen Potatoes"]),
        item("Toilet Paper", "toilet", "Household"),
        item("Paper Towels", "scroll", "Household"),
        item("Tissues", "shippingbox", "Household"),
        item("Trash Bags", "trash", "Household"),
        item("Batteries", "battery.100percent", "Household"),
        item("Light Bulbs", "lightbulb", "Household"),
        item("Foil", "rectangle.stack", "Household"),
        item("Plastic Wrap", "rectangle.on.rectangle", "Household"),
        item("Parchment Paper", "doc.text", "Household"),
        item("Freezer Bags", "bag", "Household"),
        item("Napkins", "square.stack", "Household"),
        item("Matches", "flame", "Household"),
        item("Dish Soap", "bubbles.and.sparkles", "Cleaning Supplies"),
        item("Laundry Detergent", "washer", "Cleaning Supplies"),
        item("Cleaning Spray", "sparkles", "Cleaning Supplies"),
        item("Sponges", "sparkles.rectangle.stack", "Cleaning Supplies"),
        item("Dishwasher Tablets", "washer", "Cleaning Supplies", ["Dishwasher Pods"]),
        item("Bleach", "drop.triangle", "Cleaning Supplies"),
        item("Glass Cleaner", "sparkles", "Cleaning Supplies"),
        item("Floor Cleaner", "house", "Cleaning Supplies"),
        item("Fabric Softener", "washer", "Cleaning Supplies"),
        item("Shampoo", "shower", "Personal Care"),
        item("Conditioner", "shower.fill", "Personal Care"),
        item("Toothpaste", "mouth", "Personal Care"),
        item("Toothbrushes", "mouth", "Personal Care"),
        item("Hand Soap", "hands.sparkles", "Personal Care"),
        item("Body Wash", "shower", "Personal Care"),
        item("Deodorant", "figure.arms.open", "Personal Care"),
        item("Wet Wipes", "hands.sparkles", "Personal Care"),
        item("Razor Blades", "scissors", "Personal Care", ["Shave", "Shaving", "Shaver"]),
        item("Shaving Cream", "bubbles.and.sparkles", "Personal Care", ["Shave"]),
        item("Shaving Foam", "bubbles.and.sparkles", "Personal Care", ["Shave"]),
        item("Cotton Swabs", "circle.grid.cross", "Personal Care"),
        item("Cotton Pads", "circle.grid.2x2", "Personal Care"),
        item("Painkillers", "pills", "Personal Care", ["Medicine"]),
        item("Cat Litter", "cat", "Pets"),
        item("Cat Food", "cat", "Pets"),
        item("Dog Food", "dog", "Pets"),
        item("Pet Treats", "pawprint", "Pets"),
        item("Pet Shampoo", "shower", "Pets"),
        item("Pet Waste Bags", "bag", "Pets"),
        item("Fish Food", "fish", "Pets"),
        item("Bird Seed", "bird", "Pets"),
        item("Rabbit Food", "hare", "Pets"),
        item("Turtle Food", "tortoise", "Pets"),
        item("Pet Brush", "scissors", "Pets"),
        item("Flea Treatment", "cross.case", "Pets"),
        item("Pet Medicine", "pills", "Pets"),
        item("Pet Bedding", "house", "Pets")
    ]

    static func matches(for query: String, limit: Int = 8) -> [WatchShoppingItemSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return Array(catalog.prefix(limit))
        }

        let normalizedQuery = trimmedQuery.localizedLowercase
        return catalog
            .filter { $0.searchableText.contains(normalizedQuery) }
            .prefix(limit)
            .map { $0 }
    }

    static func bestMatch(for itemName: String) -> WatchShoppingItemSuggestion? {
        let normalizedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
        return catalog.first { $0.name.localizedLowercase == normalizedName }
            ?? catalog.first { $0.searchableText.contains(normalizedName) }
    }

    private static func item(
        _ name: String,
        _ symbolName: String,
        _ categoryName: String,
        _ searchKeywords: [String] = []
    ) -> WatchShoppingItemSuggestion {
        WatchShoppingItemSuggestion(
            name: name,
            symbolName: symbolName,
            categoryName: categoryName,
            searchKeywords: searchKeywords
        )
    }
}

extension Notification.Name {
    static let watchShoppingListDidChange = Notification.Name("watchShoppingListDidChange")
}
