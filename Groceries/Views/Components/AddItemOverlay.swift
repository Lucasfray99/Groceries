import SwiftUI

struct AddItemOverlay: View {
    @Binding var newItemName: String
    @Binding var isShowingAddItemField: Bool
    @Binding var selectedCategory: ShoppingItemCategory
    @FocusState.Binding var isAddItemFieldFocused: Bool

    let suggestions: [ShoppingItemSuggestion]
    let shouldShowManualCategoryPicker: Bool
    let onAddItem: () -> Void
    let onAddSuggestion: (ShoppingItemSuggestion) -> Void
    let onCollapse: () -> Void

    var body: some View {
        Group {
            if isShowingAddItemField {
                expandedAddItemBar
            } else {
                collapsedAddItemButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .animation(.snappy, value: isShowingAddItemField)
    }

    private var expandedAddItemBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            quickSuggestionStrip

            if shouldShowManualCategoryPicker {
                manualCategoryPicker
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                TextField("Add item", text: $newItemName)
                    .autocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(onAddItem)
                    .focused($isAddItemFieldFocused)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(.background, in: Capsule())

                Button(action: onAddItem) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 50, height: 50)
                        .background(Color.accentColor, in: Circle())
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Add item")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var manualCategoryPicker: some View {
        Menu {
            ForEach(ShoppingItemCategory.allCases) { category in
                Button {
                    selectedCategory = category
                } label: {
                    Label(category.rawValue, systemImage: category.symbolName)
                }
            }
        } label: {
            categoryLabel(for: selectedCategory)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.background.opacity(0.86), in: Capsule())
    }

    private func categoryLabel(for category: ShoppingItemCategory) -> some View {
        HStack(spacing: 8) {
            Image(systemName: category.symbolName)
                .frame(width: 18, alignment: .center)
            Text(category.rawValue)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
        }
        .foregroundColor(.accentColor)
    }

    private var quickSuggestionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions) { suggestion in
                    Button {
                        onAddSuggestion(suggestion)
                    } label: {
                        Label(suggestion.name, systemImage: suggestion.symbolName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.background.opacity(0.86), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy, value: suggestions)
    }

    private var collapsedAddItemButton: some View {
        Button {
            isShowingAddItemField = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 54, height: 54)
                .background(Color.accentColor, in: Circle())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        }
        .accessibilityLabel("Show add item field")
    }
}

#Preview {
    @Previewable @State var itemName = ""
    @Previewable @State var isShowing = true
    @Previewable @State var category = ShoppingItemCategory.other
    @Previewable @FocusState var isFocused: Bool

    AddItemOverlay(
        newItemName: $itemName,
        isShowingAddItemField: $isShowing,
        selectedCategory: $category,
        isAddItemFieldFocused: $isFocused,
        suggestions: Array(ShoppingItemSuggestion.catalog.prefix(5)),
        shouldShowManualCategoryPicker: true,
        onAddItem: {},
        onAddSuggestion: { _ in },
        onCollapse: {}
    )
    .padding()
}
