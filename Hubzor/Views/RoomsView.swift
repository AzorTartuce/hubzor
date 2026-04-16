import SwiftUI

struct RoomsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddRoom = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.rooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room)
                        } label: {
                            RoomGridCard(room: room)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(HubzorTheme.background.ignoresSafeArea())
            .navigationTitle("Cômodos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddRoom = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(HubzorTheme.neonPurple)
                    }
                }
            }
            .sheet(isPresented: $showAddRoom) {
                RoomFormView()
            }
        }
    }
}

// MARK: - RoomGridCard

struct RoomGridCard: View {
    @EnvironmentObject var viewModel: AppViewModel
    let room: Room

    var pending: Int   { viewModel.pendingTasks(for: room).count }
    var completed: Int { viewModel.completedTasks(for: room).count }
    var total: Int     { pending + completed }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: room.colorHex).opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: room.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: room.colorHex))
                }
                Spacer()
                if pending > 0 {
                    Text("\(pending)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: room.colorHex))
                        .clipShape(Capsule())
                }
            }

            Text(room.name)
                .font(.headline)
                .foregroundStyle(.white)

            if total == 0 {
                Text("Sem tarefas")
                    .font(.caption)
                    .foregroundStyle(HubzorTheme.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(HubzorTheme.cardAlt)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: room.colorHex), HubzorTheme.neonCyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: total > 0
                                        ? geo.size.width * CGFloat(completed) / CGFloat(total)
                                        : 0,
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)

                    Text("\(completed)/\(total) concluídas")
                        .font(.caption)
                        .foregroundStyle(HubzorTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .neonCard(cornerRadius: 20)
    }
}

// MARK: - Room Form

struct RoomFormView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var editingRoom: Room?

    @State private var name: String = ""
    @State private var selectedIcon: String = Room.availableIcons[0]
    @State private var selectedColor: String = Room.availableColors[0]

    private let iconColumns  = Array(repeating: GridItem(.flexible()), count: 6)
    private let colorColumns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section("Nome") {
                    TextField("Ex: Escritório, Varanda...", text: $name)
                }

                Section("Ícone") {
                    LazyVGrid(columns: iconColumns, spacing: 12) {
                        ForEach(Room.availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedIcon == icon
                                              ? Color(hex: selectedColor)
                                              : Color(.systemGray5))
                                        .frame(height: 44)
                                    Image(systemName: icon)
                                        .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Cor") {
                    LazyVGrid(columns: colorColumns, spacing: 12) {
                        ForEach(Room.availableColors, id: \.self) { hex in
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
            .navigationTitle(editingRoom == nil ? "Novo Cômodo" : "Editar Cômodo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .bold()
                }
            }
        }
        .onAppear {
            if let room = editingRoom {
                name = room.name
                selectedIcon = room.icon
                selectedColor = room.colorHex
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var room = editingRoom {
            room.name = trimmed
            room.icon = selectedIcon
            room.colorHex = selectedColor
            viewModel.updateRoom(room)
        } else {
            let room = Room(name: trimmed, icon: selectedIcon, colorHex: selectedColor)
            viewModel.addRoom(room)
        }
        dismiss()
    }
}
