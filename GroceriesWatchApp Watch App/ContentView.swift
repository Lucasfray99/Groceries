import SwiftUI

struct ContentView: View {
    @State private var viewModel: WatchShoppingListViewModel
    @State private var isShowingAddItem = false

    init(shoppingListData: ShoppingListData = WatchShoppingListStore.load()) {
        _viewModel = State(initialValue: WatchShoppingListViewModel(shoppingListData: shoppingListData))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.items) { item in
                        Button {
                            viewModel.toggleItem(item)
                        } label: {
                            WatchShoppingItemRow(
                                item: item,
                                countdown: viewModel.removalCountdowns[item.id]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label(viewModel.remainingItemsText, systemImage: "cart")
                        .textCase(nil)
                }
            }
            .navigationTitle("Groceries")
            .animation(.easeInOut(duration: 0.25), value: viewModel.items.map(\.id))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Item")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh List")
                }
            }
            .sheet(isPresented: $isShowingAddItem) {
                WatchAddItemView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.refresh()
            }
        }
    }
}

private struct WatchAddItemView: View {
    @Bindable var viewModel: WatchShoppingListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var itemName = ""

    private var suggestions: [WatchShoppingItemSuggestion] {
        WatchShoppingItemSuggestion.matches(for: itemName, limit: 10)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Item name", text: $itemName)
                        .textInputAutocapitalization(.words)

                    Button {
                        viewModel.addItem(name: itemName)
                        dismiss()
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Suggestions") {
                    ForEach(suggestions) { suggestion in
                        Button {
                            viewModel.addSuggestion(suggestion)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: suggestion.symbolName)
                                    .frame(width: 22)
                                Text(suggestion.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .animation(.easeInOut(duration: 0.2), value: suggestions.map(\.id))
        }
    }
}

private struct WatchShoppingItemRow: View {
    let item: ShoppingItem
    let countdown: Int?

    private var symbolName: String {
        item.symbolName ?? "cart"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                .font(.headline)
                .foregroundStyle(item.isPurchased ? .green : .secondary)
                .frame(width: 22)

            Image(systemName: symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(item.isPurchased ? .secondary : .accentColor)
                .frame(width: 22)

            Text(item.name)
                .font(.body)
                .lineLimit(2)
                .strikethrough(item.isPurchased)
                .foregroundStyle(item.isPurchased ? .secondary : .primary)

            Spacer(minLength: 0)

            countdownBadge
        }
        .frame(minHeight: 42)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.name)
        .accessibilityValue(accessibilityValue)
    }

    private var countdownBadge: some View {
        Text(countdownText)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: 28)
            .padding(.vertical, 3)
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
    ContentView()
}
