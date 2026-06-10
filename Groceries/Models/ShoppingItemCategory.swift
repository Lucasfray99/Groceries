import Foundation

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
