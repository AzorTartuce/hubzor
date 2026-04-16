import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Bom dia"
        case 12..<18: return "Boa tarde"
        default: return "Boa noite"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: Date()).capitalized
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Header ────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting + " 👋")
                            .font(.title2)
                            .foregroundStyle(HubzorTheme.textSecondary)
                        Text("Hubzor")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text(dateString)
                            .font(.subheadline)
                            .foregroundStyle(HubzorTheme.textSecondary)
                    }
                    .padding(.horizontal)

                    // ── Stats ─────────────────────────────────────────────
                    HStack(spacing: 12) {
                        StatCard(
                            value: "\(viewModel.totalPending)",
                            label: "Pendentes",
                            icon: "clock.fill",
                            color: HubzorTheme.warning
                        )
                        StatCard(
                            value: "\(viewModel.totalCompleted)",
                            label: "Concluídas",
                            icon: "checkmark.circle.fill",
                            color: HubzorTheme.success
                        )
                        StatCard(
                            value: "\(viewModel.pendingShoppingCount)",
                            label: "No mercado",
                            icon: "cart.fill",
                            color: HubzorTheme.neonCyan
                        )
                    }
                    .padding(.horizontal)

                    // ── Rooms overview ────────────────────────────────────
                    if !viewModel.rooms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cômodos")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.rooms) { room in
                                        NavigationLink {
                                            RoomDetailView(room: room)
                                        } label: {
                                            RoomSummaryCard(room: room)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // ── Pending tasks ─────────────────────────────────────
                    if !viewModel.allPendingTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tarefas pendentes")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(viewModel.allPendingTasks.prefix(5)) { task in
                                    HomePendingTaskRow(task: task)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(HubzorTheme.success)
                            Text("Tudo em dia!")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Nenhuma tarefa pendente.")
                                .font(.subheadline)
                                .foregroundStyle(HubzorTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top)
            }
            .background(HubzorTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

// MARK: - StatCard

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(HubzorTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .neonCard(cornerRadius: 16)
    }
}

// MARK: - RoomSummaryCard

struct RoomSummaryCard: View {
    @EnvironmentObject var viewModel: AppViewModel
    let room: Room

    var pending: Int { viewModel.pendingTasks(for: room).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: room.colorHex).opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: room.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: room.colorHex))
            }

            Text(room.name)
                .font(.subheadline.bold())
                .foregroundStyle(.white)

            Text(pending == 0 ? "Em dia ✓" : "\(pending) pendente\(pending > 1 ? "s" : "")")
                .font(.caption)
                .foregroundStyle(pending == 0 ? HubzorTheme.success : HubzorTheme.warning)
        }
        .padding(14)
        .frame(width: 120)
        .neonCard(cornerRadius: 16)
    }
}

// MARK: - HomePendingTaskRow

struct HomePendingTaskRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let task: HouseTask

    var room: Room?         { viewModel.rooms.first { $0.id == task.roomId } }
    var resident: Resident? { viewModel.resident(for: task.assignedResidentId) }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    var body: some View {
        HStack(spacing: 12) {
            if let room {
                ZStack {
                    Circle()
                        .fill(Color(hex: room.colorHex).opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: room.icon)
                        .font(.caption)
                        .foregroundStyle(Color(hex: room.colorHex))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let room {
                        Text(room.name)
                            .font(.caption)
                            .foregroundStyle(HubzorTheme.textSecondary)
                    }
                    if let resident {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(HubzorTheme.textSecondary)
                        Text(resident.emoji + " " + resident.name)
                            .font(.caption)
                            .foregroundStyle(HubzorTheme.textSecondary)
                    }
                }
            }

            Spacer()

            // Horário (se definido) + ícone de prioridade
            VStack(alignment: .trailing, spacing: 4) {
                if let time = task.scheduledTime {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(formatTime(time))
                            .font(.caption.bold())
                    }
                    .foregroundStyle(HubzorTheme.neonCyan)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(HubzorTheme.neonCyan.opacity(0.12))
                    .clipShape(Capsule())
                }

                Image(systemName: task.priority.icon)
                    .foregroundStyle(Color(hex: task.priority.colorHex))
                    .font(.subheadline)
            }
        }
        .padding(12)
        .neonCard(cornerRadius: 12)
    }
}
