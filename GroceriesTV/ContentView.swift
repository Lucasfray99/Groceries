import SwiftUI

struct ContentView: View {
    @State private var viewModel: ShoppingListViewModel
    @State private var selectedCategory: ShoppingItemCategory = .other
    @State private var isShowingAddItem = false
    @State private var isShowingSettings = false

    init(shoppingListData: ShoppingListData = ShoppingListStore.load()) {
        _viewModel = State(initialValue: ShoppingListViewModel(shoppingListData: shoppingListData))
    }

    private var displayedCategories: [ShoppingItemCategory] {
        let categories = viewModel.visibleCategories
        return categories.isEmpty ? [.other] : categories
    }

    private var selectedItems: [ShoppingItem] {
        viewModel.items(in: selectedCategory)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.08, green: 0.09, blue: 0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 28) {
                    header

                    HStack(alignment: .top, spacing: 36) {
                        categoryRail
                            .frame(width: 360)

                        itemPanel
                    }
                }
                .padding(.horizontal, 72)
                .padding(.vertical, 48)
            }
            .navigationTitle("Groceries")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingAddItem) {
                AddItemView(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .onAppear {
                viewModel.refresh()
                updateSelectedCategoryIfNeeded()
            }
            .onChange(of: viewModel.items.map(\.id)) { _, _ in
                updateSelectedCategoryIfNeeded()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Groceries", systemImage: "cart.fill")
                    .font(.system(size: 56, weight: .bold))

                HStack(spacing: 18) {
                    Text(viewModel.remainingItemsText)
                    Text("\(viewModel.purchasedCount) bought")
                    Text("Removes checked items after \(RemovalDelaySettings.currentSeconds)s")
                }
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 18) {
                Button {
                    isShowingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .frame(minWidth: 190)
                }

                Button {
                    viewModel.refresh()
                } label: {
                    Label("Sync", systemImage: "arrow.clockwise")
                        .frame(minWidth: 150)
                }

                Button {
                    isShowingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                        .frame(minWidth: 180)
                }
                .buttonStyle(.borderedProminent)
            }
            .font(.title3.weight(.semibold))
        }
    }

    private var categoryRail: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Categories")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(displayedCategories) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: category.symbolName)
                                    .frame(width: 34)
                                Text(category.rawValue)
                                Spacer()
                                Text("\(viewModel.items(in: category).count)")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.title3.weight(.semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedCategory == category ? Color.accentColor.opacity(0.24) : Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var itemPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(selectedCategory.rawValue, systemImage: selectedCategory.symbolName)
                    .font(.title.weight(.bold))

                Spacer()

                if viewModel.purchasedCount > 0 {
                    Button {
                        viewModel.clearPurchasedItems()
                    } label: {
                        Label("Clear Bought", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }

            if viewModel.hasItems {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 360, maximum: 520), spacing: 22)
                        ],
                        alignment: .leading,
                        spacing: 22
                    ) {
                        ForEach(selectedItems) { item in
                            ShoppingItemCard(
                                item: item,
                                countdown: viewModel.removalCountdowns[item.id],
                                onToggle: { viewModel.toggleItem(item) },
                                onDelete: { viewModel.delete(item) }
                            )
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: viewModel.items.map(\.id))
                }
            } else {
                ContentUnavailableView(
                    "No Items Yet",
                    systemImage: "cart.badge.plus",
                    description: Text("Add items from the sofa and they will sync to your iPhone and Apple Watch.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func updateSelectedCategoryIfNeeded() {
        let categories = displayedCategories
        guard !categories.contains(selectedCategory), let firstCategory = categories.first else { return }
        selectedCategory = firstCategory
    }
}

private struct ShoppingItemCard: View {
    let item: ShoppingItem
    let countdown: Int?
    let onToggle: () -> Void
    let onDelete: () -> Void

    private var symbolName: String {
        item.symbolName ?? ShoppingItemSuggestion.fallbackSymbolName
    }

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.isPurchased ? .green : .secondary)

                    Image(systemName: symbolName)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(item.isPurchased ? .secondary : .accentColor)

                    Spacer()

                    countdownBadge
                }

                Text(item.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(item.isPurchased ? .secondary : .primary)
                    .strikethrough(item.isPurchased)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(item.categoryName ?? ShoppingItemCategory.other.rawValue)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Delete \(item.name)")
                }
            }
            .padding(22)
            .frame(minHeight: 190)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.card)
    }

    private var countdownBadge: some View {
        Text(countdownText)
            .font(.headline.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: 58)
            .padding(.vertical, 6)
            .background(.quaternary, in: Capsule())
            .opacity(countdown == nil ? 0 : 1)
    }

    private var countdownText: String {
        guard let countdown else { return "30s" }
        return "\(countdown)s"
    }
}

private struct AddItemView: View {
    @Bindable var viewModel: ShoppingListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var itemName = ""
    @State private var selectedCategory: ShoppingItemCategory = .other

    private var suggestions: [ShoppingItemSuggestion] {
        viewModel.filteredSuggestions(for: itemName)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                HStack(spacing: 18) {
                    TextField("Item name", text: $itemName)
                        .font(.title2)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(addTypedItem)

                    Button(action: addTypedItem) {
                        Label("Add", systemImage: "plus.circle.fill")
                            .frame(minWidth: 140)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(ShoppingItemCategory.allCases) { category in
                                CategoryPickerButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggestions")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 16)],
                            alignment: .leading,
                            spacing: 16
                        ) {
                            ForEach(suggestions) { suggestion in
                                Button {
                                    viewModel.addSuggestion(suggestion)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: suggestion.symbolName)
                                            .frame(width: 28)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(suggestion.name)
                                                .font(.headline)
                                            Text(suggestion.category.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 74)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: suggestions.map(\.id))
                }
            }
            .padding(48)
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addTypedItem() {
        guard viewModel.addItem(named: itemName, selectedCategory: selectedCategory) else { return }
        dismiss()
    }
}

private struct CategoryPickerButton: View {
    let category: ShoppingItemCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(category.rawValue, systemImage: category.symbolName)
                .padding(.horizontal, 10)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
    }
}

private struct DelayOptionButton: View {
    let seconds: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(seconds)s")
                .frame(minWidth: 90, minHeight: 64)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDelay = RemovalDelaySettings.currentSeconds

    private let options = [5, 10, 15, 20, 25, 30]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                Text("Remove Checked Items After")
                    .font(.title2.weight(.bold))

                HStack(spacing: 14) {
                    ForEach(options, id: \.self) { seconds in
                        DelayOptionButton(
                            seconds: seconds,
                            isSelected: selectedDelay == seconds
                        ) {
                            selectedDelay = seconds
                            RemovalDelaySettings.setLocalSeconds(seconds)
                        }
                    }
                }

                Spacer()
            }
            .padding(48)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
