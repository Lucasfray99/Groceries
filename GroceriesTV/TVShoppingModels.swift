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

enum ShoppingItemCategory: String, CaseIterable, Identifiable {
    case dairy = "Dairy"
    case bakery = "Bakery"
    case produce = "Produce"
    case meatAndSeafood = "Meat & Seafood"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case household = "Household"
    case cleaning = "Cleaning Supplies"
    case personalCare = "Personal Care"
    case pets = "Pets"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .dairy:
            "drop"
        case .bakery:
            "takeoutbag.and.cup.and.straw"
        case .produce:
            "leaf"
        case .meatAndSeafood:
            "fork.knife"
        case .pantry:
            "shippingbox"
        case .frozen:
            "snowflake"
        case .household:
            "house"
        case .cleaning:
            "bubbles.and.sparkles"
        case .personalCare:
            "shower"
        case .pets:
            "pawprint"
        case .other:
            "cart"
        }
    }
}

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
        searchableText.contains(searchText)
    }

    private var searchableText: String {
        ([name, category.rawValue] + searchKeywords).joined(separator: " ").localizedLowercase
    }

    static func suggestion(for itemName: String) -> ShoppingItemSuggestion? {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        return catalog.first { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }
            ?? catalog.first { $0.searchableText.contains(trimmedName.localizedLowercase) }
    }

    static func symbolName(for itemName: String) -> String {
        suggestion(for: itemName)?.symbolName ?? fallbackSymbolName
    }

    static func category(for itemName: String) -> ShoppingItemCategory {
        suggestion(for: itemName)?.category ?? fallbackCategory
    }
}

extension ShoppingItemSuggestion {
    static let catalog: [ShoppingItemSuggestion] = [
        item("Milk", "drop", .dairy),
        item("Eggs", "circle.grid.2x2", .dairy),
        item("Butter", "cube", .dairy),
        item("Cheese", "cube.fill", .dairy),
        item("Yogurt", "cup.and.saucer", .dairy),
        item("Cream", "drop.fill", .dairy),
        item("Sour Cream", "cup.and.saucer.fill", .dairy),
        item("Cottage Cheese", "cube", .dairy),
        item("Cream Cheese", "cube.fill", .dairy),
        item("Mozzarella", "circle.grid.2x2", .dairy),
        item("Parmesan", "triangle", .dairy),
        item("Oat Milk", "leaf", .dairy, ["Milk"]),
        item("Bread", "takeoutbag.and.cup.and.straw", .bakery),
        item("Bagels", "circle", .bakery),
        item("Tortillas", "circle.dashed", .bakery),
        item("Buns", "circle.fill", .bakery),
        item("Croissants", "moon", .bakery),
        item("Pita Bread", "circle", .bakery),
        item("Apples", "apple.logo", .produce),
        item("Bananas", "leaf", .produce),
        item("Oranges", "circle.fill", .produce),
        item("Berries", "circle.grid.cross", .produce),
        item("Grapes", "circle.grid.3x3", .produce),
        item("Lemons", "circle", .produce),
        item("Limes", "circle", .produce),
        item("Potatoes", "circle.hexagongrid", .produce),
        item("Sweet Potatoes", "circle.hexagongrid.fill", .produce),
        item("Onions", "circle.dotted", .produce),
        item("Garlic", "circle.dotted.circle", .produce),
        item("Tomatoes", "circle.fill", .produce),
        item("Lettuce", "leaf", .produce),
        item("Spinach", "leaf.fill", .produce),
        item("Carrots", "carrot", .produce),
        item("Broccoli", "leaf.circle", .produce),
        item("Cucumber", "capsule", .produce),
        item("Peppers", "circle.grid.cross", .produce),
        item("Avocados", "circle", .produce),
        item("Mushrooms", "circle.dotted", .produce),
        item("Chicken", "fork.knife", .meatAndSeafood),
        item("Ground Beef", "fork.knife.circle", .meatAndSeafood),
        item("Steak", "flame", .meatAndSeafood),
        item("Bacon", "flame", .meatAndSeafood),
        item("Ham", "fork.knife", .meatAndSeafood),
        item("Sausages", "fork.knife.circle", .meatAndSeafood),
        item("Salmon", "fish", .meatAndSeafood),
        item("Tuna", "fish.circle", .meatAndSeafood),
        item("Shrimp", "fish", .meatAndSeafood),
        item("Rice", "shippingbox", .pantry),
        item("Pasta", "takeoutbag.and.cup.and.straw", .pantry),
        item("Noodles", "takeoutbag.and.cup.and.straw.fill", .pantry),
        item("Flour", "shippingbox.fill", .pantry),
        item("Sugar", "cube", .pantry),
        item("Brown Sugar", "cube.fill", .pantry),
        item("Coffee", "cup.and.saucer", .pantry),
        item("Tea", "mug", .pantry),
        item("Cereal", "rectangle.grid.2x2", .pantry),
        item("Oats", "leaf", .pantry),
        item("Peanut Butter", "circle.hexagongrid.fill", .pantry),
        item("Jam", "cylinder", .pantry),
        item("Honey", "drop", .pantry),
        item("Olive Oil", "drop.fill", .pantry),
        item("Vegetable Oil", "drop", .pantry),
        item("Vinegar", "drop", .pantry),
        item("Salt", "sparkles", .pantry),
        item("Pepper", "sparkle", .pantry),
        item("Canned Beans", "cylinder", .pantry),
        item("Canned Tomatoes", "cylinder.fill", .pantry),
        item("Soup", "takeoutbag.and.cup.and.straw", .pantry),
        item("Crackers", "square.grid.3x3", .pantry),
        item("Chips", "bag", .pantry),
        item("Chocolate", "birthday.cake", .pantry),
        item("Cookies", "circle.grid.2x2", .pantry),
        item("Ketchup", "drop.fill", .pantry),
        item("Mustard", "drop", .pantry),
        item("Mayonnaise", "drop", .pantry),
        item("Soy Sauce", "drop", .pantry),
        item("Stock Cubes", "cube", .pantry),
        item("Ice Cream", "snowflake", .frozen),
        item("Frozen Vegetables", "snowflake.circle", .frozen),
        item("Frozen Pizza", "snowflake", .frozen),
        item("Frozen Berries", "snowflake.circle.fill", .frozen),
        item("Fries", "snowflake", .frozen, ["Frozen Potatoes"]),
        item("Toilet Paper", "toilet", .household),
        item("Paper Towels", "scroll", .household),
        item("Tissues", "shippingbox", .household),
        item("Trash Bags", "trash", .household),
        item("Batteries", "battery.100percent", .household),
        item("Light Bulbs", "lightbulb", .household),
        item("Foil", "rectangle.stack", .household),
        item("Plastic Wrap", "rectangle.on.rectangle", .household),
        item("Parchment Paper", "doc.text", .household),
        item("Freezer Bags", "bag", .household),
        item("Napkins", "square.stack", .household),
        item("Matches", "flame", .household),
        item("Dish Soap", "bubbles.and.sparkles", .cleaning),
        item("Laundry Detergent", "washer", .cleaning),
        item("Cleaning Spray", "sparkles", .cleaning),
        item("Sponges", "sparkles.rectangle.stack", .cleaning),
        item("Dishwasher Tablets", "washer", .cleaning, ["Dishwasher Pods"]),
        item("Bleach", "drop.triangle", .cleaning),
        item("Glass Cleaner", "sparkles", .cleaning),
        item("Floor Cleaner", "house", .cleaning),
        item("Fabric Softener", "washer", .cleaning),
        item("Shampoo", "shower", .personalCare),
        item("Conditioner", "shower.fill", .personalCare),
        item("Toothpaste", "mouth", .personalCare),
        item("Toothbrushes", "mouth", .personalCare),
        item("Hand Soap", "hands.sparkles", .personalCare),
        item("Body Wash", "shower", .personalCare),
        item("Deodorant", "figure.arms.open", .personalCare),
        item("Wet Wipes", "hands.sparkles", .personalCare),
        item("Razor Blades", "scissors", .personalCare, ["Shave", "Shaving", "Shaver"]),
        item("Shaving Cream", "bubbles.and.sparkles", .personalCare, ["Shave"]),
        item("Shaving Foam", "bubbles.and.sparkles", .personalCare, ["Shave"]),
        item("Cotton Swabs", "circle.grid.cross", .personalCare),
        item("Cotton Pads", "circle.grid.2x2", .personalCare),
        item("Painkillers", "pills", .personalCare, ["Medicine"]),
        item("Cat Litter", "cat", .pets),
        item("Cat Food", "cat", .pets),
        item("Dog Food", "dog", .pets),
        item("Pet Treats", "pawprint", .pets),
        item("Pet Shampoo", "shower", .pets),
        item("Pet Waste Bags", "bag", .pets),
        item("Fish Food", "fish", .pets),
        item("Bird Seed", "bird", .pets),
        item("Rabbit Food", "hare", .pets),
        item("Turtle Food", "tortoise", .pets),
        item("Pet Brush", "scissors", .pets),
        item("Flea Treatment", "cross.case", .pets),
        item("Pet Medicine", "pills", .pets),
        item("Pet Bedding", "house", .pets)
    ]

    private static func item(
        _ name: String,
        _ symbolName: String,
        _ category: ShoppingItemCategory,
        _ searchKeywords: [String] = []
    ) -> ShoppingItemSuggestion {
        ShoppingItemSuggestion(
            name: name,
            symbolName: symbolName,
            category: category,
            searchKeywords: searchKeywords
        )
    }
}

extension Notification.Name {
    static let shoppingListDidChange = Notification.Name("shoppingListDidChange")
    static let removalDelayDidChange = Notification.Name("removalDelayDidChange")
}
