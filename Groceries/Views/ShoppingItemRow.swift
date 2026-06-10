import SwiftUI

struct ShoppingItemRow: View {
    let item: ShoppingItem
    let countdown: Int?
    let onToggle: () -> Void

    private var itemSymbolName: String {
        item.symbolName ?? ShoppingItemSuggestion.symbolName(for: item.name)
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isPurchased ? .green : .secondary)
                    .frame(width: 28)

                Image(systemName: itemSymbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(item.isPurchased ? .secondary : .accentColor)
                    .frame(width: 24)

                Text(item.name)
                    .foregroundStyle(item.isPurchased ? .secondary : .primary)
                    .strikethrough(item.isPurchased)

                Spacer()

                countdownBadge
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .accessibilityValue(accessibilityValue)
    }

    private var countdownBadge: some View {
        Text(countdownText)
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: 34)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
            .opacity(countdown == nil ? 0 : 1)
    }

    private var countdownText: String {
        guard let countdown else { return "30s" }

        return "\(countdown)s"
    }

    private var accessibilityValue: String {
        if let countdown {
            return "Purchased. Removes in \(countdown) seconds"
        }

        return item.isPurchased ? "Purchased" : "Needed"
    }
}

#Preview {
    ShoppingItemRow(
        item: ShoppingItem(name: "Apples", symbolName: "apple.logo", isPurchased: true),
        countdown: 15,
        onToggle: {}
    )
    .padding()
}
