import SwiftUI

struct ShoppingListView: View {
    @AppStorage(RemovalDelaySettings.storageKey) private var removalDelaySeconds = RemovalDelaySettings.defaultSeconds

    @State private var viewModel: ShoppingListViewModel
    @State private var newItemName = ""
    @State private var isShowingAddItemField = false
    @State private var isShowingSettings = false
    @State private var selectedCategory: ShoppingItemCategory = .other

    @FocusState private var isAddItemFieldFocused: Bool

    init(shoppingListData: ShoppingListData = ShoppingListStore.load()) {
        _viewModel = State(initialValue: ShoppingListViewModel(shoppingListData: shoppingListData))
    }

    private var trimmedNewItemName: String {
        newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matchedTypedSuggestion: ShoppingItemSuggestion? {
        viewModel.matchedSuggestion(for: trimmedNewItemName)
    }

    private var shouldShowManualCategoryPicker: Bool {
        !trimmedNewItemName.isEmpty && matchedTypedSuggestion == nil
    }

    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle("Shopping List")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isShowingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                            .disabled(viewModel.items.isEmpty)
                    }
                }
                .overlay {
                    if isShowingAddItemField {
                        Color.black.opacity(0.16)
                            .ignoresSafeArea()
                            .onTapGesture(perform: collapseAddItemField)
                            .transition(.opacity)
                    }
                }
                .overlay(alignment: .bottom) {
                    AddItemOverlay(
                        newItemName: $newItemName,
                        isShowingAddItemField: $isShowingAddItemField,
                        selectedCategory: $selectedCategory,
                        isAddItemFieldFocused: $isAddItemFieldFocused,
                        suggestions: viewModel.filteredSuggestions(for: newItemName),
                        shouldShowManualCategoryPicker: shouldShowManualCategoryPicker,
                        onAddItem: addItemAndCollapse,
                        onAddSuggestion: addSuggestion,
                        onCollapse: collapseAddItemField
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                }
                .onChange(of: isShowingAddItemField) {
                    if isShowingAddItemField {
                        isAddItemFieldFocused = true
                    }
                }
                .onAppear {
                    viewModel.startTimersForPurchasedItems(removalDelaySeconds: removalDelaySeconds)
                }
        }
    }

    private var listContent: some View {
        List {
            if viewModel.items.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "basket",
                        description: Text("Tap the add button to start your list.")
                    )
                } header: {
                    Label(viewModel.remainingItemsText, systemImage: "cart")
                        .font(.subheadline.weight(.medium))
                        .textCase(nil)
                }
            } else {
                ForEach(viewModel.visibleCategories) { category in
                    Section {
                        ForEach(viewModel.items(in: category)) { item in
                            ShoppingItemRow(
                                item: item,
                                countdown: viewModel.removalCountdowns[item.id],
                                onToggle: {
                                    viewModel.toggleItem(item, removalDelaySeconds: removalDelaySeconds)
                                }
                            )
                        }
                        .onDelete { offsets in
                            viewModel.deleteItems(at: offsets, in: category)
                        }
                    } header: {
                        Label(category.rawValue, systemImage: category.symbolName)
                            .textCase(nil)
                    }
                }
            }
        }
        .blur(radius: isShowingAddItemField ? 4 : 0)
        .disabled(isShowingAddItemField)
        .animation(.easeInOut(duration: 0.18), value: isShowingAddItemField)
        .animation(.easeInOut(duration: 0.25), value: viewModel.items.map(\.id))
    }

    private func addItemAndCollapse() {
        let didAddItem = viewModel.addItem(named: newItemName, selectedCategory: selectedCategory)
        guard didAddItem else { return }

        newItemName = ""
        collapseAddItemField()
    }

    private func addSuggestion(_ suggestion: ShoppingItemSuggestion) {
        viewModel.addSuggestion(suggestion)
        newItemName = ""
        collapseAddItemField()
    }

    private func collapseAddItemField() {
        isShowingAddItemField = false
        isAddItemFieldFocused = false
        selectedCategory = .other
    }
}

#Preview {
    ShoppingListView(shoppingListData: .sample)
}
