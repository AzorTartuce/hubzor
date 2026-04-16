import SwiftUI

struct RoomDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let room: Room

    @State private var showAddTask = false
    @State private var taskToEdit: HouseTask?
    @State private var showEditRoom = false

    var body: some View {
        let pending   = viewModel.pendingTasks(for: room)
        let completed = viewModel.completedTasks(for: room)

        ScrollView {
            VStack(spacing: 16) {

                // Room header
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: room.colorHex).opacity(0.2))
                            .frame(width: 60, height: 60)
                        Image(systemName: room.icon)
                            .font(.title)
                            .foregroundStyle(Color(hex: room.colorHex))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(room.name)
                            .font(.title2.bold())
                        Text(
                            "\(pending.count) pendente\(pending.count != 1 ? "s" : "") • \(completed.count) concluída\(completed.count != 1 ? "s" : "")"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                // Pending tasks
                if !pending.isEmpty {
                    TaskSection(
                        title: "A fazer",
                        icon: "clock",
                        color: .orange,
                        tasks: pending,
                        onToggle: { viewModel.toggleTask($0) },
                        onEdit:   { taskToEdit = $0 },
                        onDelete: { viewModel.deleteTask($0) }
                    )
                }

                // Completed tasks
                if !completed.isEmpty {
                    TaskSection(
                        title: "Concluídas",
                        icon: "checkmark.circle",
                        color: .green,
                        tasks: completed,
                        onToggle: { viewModel.toggleTask($0) },
                        onEdit:   { taskToEdit = $0 },
                        onDelete: { viewModel.deleteTask($0) }
                    )
                }

                if pending.isEmpty && completed.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("Nenhuma tarefa ainda")
                            .font(.headline)
                        Text("Toque em + para adicionar a primeira tarefa.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                }

                Spacer(minLength: 32)
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button { showEditRoom = true } label: {
                        Image(systemName: "pencil")
                    }
                    Button { showAddTask = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            TaskFormView(roomId: room.id)
        }
        .sheet(item: $taskToEdit) { task in
            TaskFormView(editingTask: task)
        }
        .sheet(isPresented: $showEditRoom) {
            RoomFormView(editingRoom: room)
        }
    }
}

// MARK: - Task Section

struct TaskSection: View {
    let title: String
    let icon: String
    let color: Color
    let tasks: [HouseTask]
    let onToggle: (HouseTask) -> Void
    let onEdit: (HouseTask) -> Void
    let onDelete: (HouseTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    TaskRow(
                        task: task,
                        onToggle: { onToggle(task) },
                        onEdit:   { onEdit(task) },
                        onDelete: { onDelete(task) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let task: HouseTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var resident: Resident? { viewModel.resident(for: task.assignedResidentId) }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : Color(.systemGray3))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.bold())
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Image(systemName: task.priority.icon)
                        .font(.caption2)
                        .foregroundStyle(Color(hex: task.priority.colorHex))
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let resident {
                        Text("•").font(.caption).foregroundStyle(.secondary)
                        Text(resident.emoji + " " + resident.name)
                            .font(.caption)
                            .foregroundStyle(Color(hex: resident.colorHex))
                    }
                }

                if !task.note.isEmpty {
                    Text(task.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Excluir", systemImage: "trash")
            }
            Button { onEdit() } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading) {
            Button { onToggle() } label: {
                Label(
                    task.isCompleted ? "Reabrir" : "Concluir",
                    systemImage: task.isCompleted ? "arrow.uturn.left" : "checkmark"
                )
            }
            .tint(task.isCompleted ? .orange : .green)
        }
    }
}

// MARK: - Task Form (String IDs)

struct TaskFormView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var roomId: String?
    var editingTask: HouseTask?

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var selectedRoomId: String?
    @State private var selectedResidentId: String?
    @State private var priority: HouseTask.Priority = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Tarefa") {
                    TextField("O que precisa ser feito?", text: $title)
                    TextField("Observação (opcional)", text: $note, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Cômodo") {
                    Picker("Cômodo", selection: $selectedRoomId) {
                        Text("Nenhum").tag(String?.none)
                        ForEach(viewModel.rooms) { room in
                            Label(room.name, systemImage: room.icon)
                                .tag(String?.some(room.id))
                        }
                    }
                }

                Section("Prioridade") {
                    Picker("Prioridade", selection: $priority) {
                        ForEach(HouseTask.Priority.allCases, id: \.self) { p in
                            HStack {
                                Image(systemName: p.icon).foregroundStyle(Color(hex: p.colorHex))
                                Text(p.rawValue)
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Responsável") {
                    Picker("Morador", selection: $selectedResidentId) {
                        Text("Ninguém").tag(String?.none)
                        ForEach(viewModel.residents) { resident in
                            Text(resident.emoji + " " + resident.name)
                                .tag(String?.some(resident.id))
                        }
                    }
                }
            }
            .navigationTitle(editingTask == nil ? "Nova Tarefa" : "Editar Tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedRoomId == nil)
                }
            }
        }
        .onAppear {
            if let task = editingTask {
                title = task.title
                note = task.note
                selectedRoomId = task.roomId
                selectedResidentId = task.assignedResidentId
                priority = task.priority
            } else {
                selectedRoomId = roomId
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let rId = selectedRoomId else { return }

        if var task = editingTask {
            task.title = trimmed
            task.note = note
            task.roomId = rId
            task.assignedResidentId = selectedResidentId
            task.priority = priority
            viewModel.updateTask(task)
        } else {
            let task = HouseTask(
                title: trimmed,
                roomId: rId,
                assignedResidentId: selectedResidentId,
                note: note,
                priority: priority
            )
            viewModel.addTask(task)
        }
        dismiss()
    }
}
