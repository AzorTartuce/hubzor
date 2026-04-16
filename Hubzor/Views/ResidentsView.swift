import SwiftUI

struct ResidentsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddResident = false
    @State private var residentToEdit: Resident?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.residents.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 56))
                            .foregroundStyle(HubzorTheme.textSecondary)
                        Text("Nenhum morador")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Adicione os moradores da casa para atribuir tarefas e itens do mercado.")
                            .font(.subheadline)
                            .foregroundStyle(HubzorTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button {
                            showAddResident = true
                        } label: {
                            Label("Adicionar morador", systemImage: "person.badge.plus")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .foregroundStyle(.white)
                                .background(HubzorTheme.accentGradient)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.residents) { resident in
                            Button {
                                residentToEdit = resident
                            } label: {
                                ResidentRow(resident: resident)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(HubzorTheme.cardBackground)
                            .listRowSeparatorTint(HubzorTheme.neonPurple.opacity(0.12))
                        }
                        .onDelete { offsets in
                            offsets.forEach { idx in
                                viewModel.deleteResident(viewModel.residents[idx])
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(HubzorTheme.background)
                }
            }
            .background(HubzorTheme.background.ignoresSafeArea())
            .navigationTitle("Moradores")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddResident = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(HubzorTheme.neonPurple)
                    }
                }
            }
            .sheet(isPresented: $showAddResident) {
                ResidentFormView()
            }
            .sheet(item: $residentToEdit) { resident in
                ResidentFormView(editingResident: resident)
            }
        }
    }
}

// MARK: - Resident Row

struct ResidentRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let resident: Resident

    var pendingCount: Int { viewModel.tasks(for: resident).count }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: resident.colorHex).opacity(0.2))
                    .frame(width: 52, height: 52)
                Text(resident.emoji)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(resident.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                if pendingCount > 0 {
                    Text("\(pendingCount) tarefa\(pendingCount > 1 ? "s" : "") pendente\(pendingCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundStyle(Color(hex: resident.colorHex))
                } else {
                    Text("Sem tarefas pendentes")
                        .font(.caption)
                        .foregroundStyle(HubzorTheme.textSecondary)
                }
            }

            Spacer()

            Circle()
                .fill(Color(hex: resident.colorHex))
                .frame(width: 12, height: 12)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(HubzorTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Resident Form

struct ResidentFormView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var editingResident: Resident?

    @State private var name: String = ""
    @State private var selectedEmoji: String = Resident.availableEmojis[0]
    @State private var selectedColor: String = Resident.availableColors[0]

    private let emojiColumns  = Array(repeating: GridItem(.flexible()), count: 6)
    private let colorColumns  = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: selectedColor).opacity(0.2))
                                    .frame(width: 72, height: 72)
                                Text(selectedEmoji)
                                    .font(.system(size: 36))
                            }
                            if !name.isEmpty {
                                Text(name)
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: selectedColor))
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("Nome") {
                    TextField("Nome do morador", text: $name)
                }

                Section("Emoji") {
                    LazyVGrid(columns: emojiColumns, spacing: 10) {
                        ForEach(Resident.availableEmojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedEmoji == emoji
                                              ? Color(hex: selectedColor).opacity(0.2)
                                              : Color(.systemGray6))
                                        .frame(width: 44, height: 44)
                                    if selectedEmoji == emoji {
                                        Circle()
                                            .strokeBorder(Color(hex: selectedColor), lineWidth: 2)
                                            .frame(width: 44, height: 44)
                                    }
                                    Text(emoji).font(.title3)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Cor") {
                    LazyVGrid(columns: colorColumns, spacing: 12) {
                        ForEach(Resident.availableColors, id: \.self) { hex in
                            Button {
                                selectedColor = hex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 36, height: 36)
                                    if selectedColor == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(editingResident == nil ? "Novo Morador" : "Editar Morador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let resident = editingResident {
                name = resident.name
                selectedEmoji = resident.emoji
                selectedColor = resident.colorHex
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var resident = editingResident {
            resident.name = trimmed
            resident.emoji = selectedEmoji
            resident.colorHex = selectedColor
            viewModel.updateResident(resident)
        } else {
            let resident = Resident(name: trimmed, emoji: selectedEmoji, colorHex: selectedColor)
            viewModel.addResident(resident)
        }
        dismiss()
    }
}
