import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddItem = false
    @State private var showClearConfirm = false
    @State private var searchText = ""
    @State private var selectedCategory: ShoppingItem.Category? = nil

    var filteredItems: [ShoppingItem] {
        viewModel.shoppingItems.filter { item in
            let matchSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText)
            let matchCategory = selectedCategory == nil || item.category == selectedCategory
            return matchSearch && matchCategory
        }
    }

    var groupedItems: [(ShoppingItem.Category, [ShoppingItem])] {
        ShoppingItem.Category.allCases.compactMap { cat in
            let items = filteredItems.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    var checkedCount: Int { viewModel.shoppingItems.filter { $0.isChecked }.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Search bar ────────────────────────────────────────────
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(HubzorTheme.textSecondary)
                    TextField("Buscar item...", text: $searchText)
                        .foregroundStyle(.white)
                }
                .padding(10)
                .background(HubzorTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(HubzorTheme.neonPurple.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.vertical, 8)

                // ── Category filter ───────────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: "Todos",
                            icon: "cart",
                            isSelected: selectedCategory == nil,
                            color: HubzorTheme.neonPurple
                        ) { selectedCategory = nil }

                        ForEach(ShoppingItem.Category.allCases, id: \.self) { cat in
                            let count = viewModel.shoppingItems.filter { $0.category == cat && !$0.isChecked }.count
                            if count > 0 || selectedCategory == cat {
                                FilterChip(
                                    label: cat.rawValue.components(separatedBy: " ").first ?? cat.rawValue,
                                    icon: cat.icon,
                                    isSelected: selectedCategory == cat,
                                    color: Color(hex: cat.colorHex)
                                ) {
                                    selectedCategory = (selectedCategory == cat) ? nil : cat
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // ── Empty state ───────────────────────────────────────────
                if viewModel.shoppingItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 52))
                            .foregroundStyle(HubzorTheme.neonPurple.opacity(0.7))
                        Text("Lista vazia")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Adicione itens para a sua próxima compra.")
                            .font(.subheadline)
                            .foregroundStyle(HubzorTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    Spacer()
                } else {
                    List {
                        ForEach(groupedItems, id: \.0) { category, items in
                            Section {
                                ForEach(items) { item in
                                    ShoppingItemRow(item: item)
                                        .listRowBackground(HubzorTheme.cardBackground)
                                        .listRowSeparatorTint(HubzorTheme.neonPurple.opacity(0.12))
                                }
                                .onDelete { offsets in
                                    offsets.forEach { idx in
                                        viewModel.deleteShoppingItem(items[idx])
                                    }
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(hex: category.colorHex))
                                    Text(category.rawValue)
                                        .foregroundStyle(HubzorTheme.textSecondary)
                                }
                            }
                        }

                        if checkedCount > 0 {
                            Section {
                                Button(role: .destructive) {
                                    showClearConfirm = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Remover \(checkedCount) item\(checkedCount > 1 ? "ns" : "") marcado\(checkedCount > 1 ? "s" : "")")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .listRowBackground(HubzorTheme.cardBackground)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(HubzorTheme.background)
                }
            }
            .background(HubzorTheme.background.ignoresSafeArea())
            .navigationTitle("Mercado")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(HubzorTheme.neonPurple)
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                ShoppingItemFormView()
            }
            .confirmationDialog(
                "Remover itens marcados?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Remover \(checkedCount) item\(checkedCount > 1 ? "ns" : "")", role: .destructive) {
                    viewModel.clearCheckedItems()
                }
            }
        }
    }
}

// MARK: - Shopping Item Row

struct ShoppingItemRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let item: ShoppingItem

    var resident: Resident? { viewModel.resident(for: item.addedByResidentId) }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.toggleShoppingItem(item)
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? HubzorTheme.success : HubzorTheme.cardAlt)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? HubzorTheme.textSecondary : .white)

                HStack(spacing: 4) {
                    if !item.quantity.isEmpty || !item.unit.isEmpty {
                        Text("\(item.quantity)\(item.unit.isEmpty ? "" : " " + item.unit)")
                            .font(.caption)
                            .foregroundStyle(HubzorTheme.textSecondary)
                    }
                    if let resident {
                        if !item.quantity.isEmpty {
                            Text("•").font(.caption).foregroundStyle(HubzorTheme.textSecondary)
                        }
                        Text(resident.emoji + " " + resident.name)
                            .font(.caption)
                            .foregroundStyle(Color(hex: resident.colorHex))
                    }
                    if !item.note.isEmpty {
                        Text("•").font(.caption).foregroundStyle(HubzorTheme.textSecondary)
                        Text(item.note)
                            .font(.caption)
                            .foregroundStyle(HubzorTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption)
                Text(label).font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? color
                    : HubzorTheme.cardBackground
            )
            .foregroundStyle(isSelected ? .white : HubzorTheme.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : HubzorTheme.neonPurple.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shopping Item Form

struct ShoppingItemFormView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var quantity: String = "1"
    @State private var unit: String = ""
    @State private var note: String = ""
    @State private var category: ShoppingItem.Category = .outros
    @State private var selectedResidentId: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Nome do produto", text: $name)
                    HStack {
                        TextField("Qtd.", text: $quantity)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Divider()
                        TextField("Unidade (kg, L, cx...)", text: $unit)
                    }
                    TextField("Observação (opcional)", text: $note)
                }

                Section("Categoria") {
                    Picker("Categoria", selection: $category) {
                        ForEach(ShoppingItem.Category.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                if !viewModel.residents.isEmpty {
                    Section("Quem pediu?") {
                        Picker("Morador", selection: $selectedResidentId) {
                            Text("Ninguém").tag(String?.none)
                            ForEach(viewModel.residents) { resident in
                                Text(resident.emoji + " " + resident.name)
                                    .tag(String?.some(resident.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Novo Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adicionar") { save() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = ShoppingItem(
            name: trimmed,
            quantity: quantity.isEmpty ? "1" : quantity,
            unit: unit,
            category: category,
            addedByResidentId: selectedResidentId,
            note: note
        )
        viewModel.addShoppingItem(item)
        dismiss()
    }
}
