import Foundation
import Combine
import FirebaseFirestore

class AppViewModel: ObservableObject {
    @Published var residents: [Resident] = []
    @Published var rooms: [Room] = []
    @Published var tasks: [HouseTask] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var loadError: String?

    private(set) var householdId: String = ""
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var isSeeding = false

    // MARK: - Setup

    func configure(householdId: String) {
        stopListeners()
        self.householdId = householdId
        loadError = nil
        guard !householdId.isEmpty else { return }
        attachListeners()
    }

    func reset() {
        stopListeners()
        householdId = ""
        residents = []
        rooms = []
        tasks = []
        shoppingItems = []
        loadError = nil
        isSeeding = false
    }

    // MARK: - Listeners

    private func attachListeners() {
        guard !householdId.isEmpty else { return }

        // Residents
        let l1 = col("residents").addSnapshotListener { [weak self] snap, error in
            if let error {
                print("❌ [Residents] \(error.localizedDescription)")
                DispatchQueue.main.async { self?.loadError = error.localizedDescription }
                return
            }
            DispatchQueue.main.async {
                self?.residents = snap?.documents.compactMap { try? $0.data(as: Resident.self) } ?? []
            }
        }

        // Rooms
        let l2 = col("rooms").addSnapshotListener { [weak self] snap, error in
            if let error {
                print("❌ [Rooms] \(error.localizedDescription)")
                DispatchQueue.main.async { self?.loadError = error.localizedDescription }
                return
            }
            DispatchQueue.main.async {
                let decoded = snap?.documents.compactMap { try? $0.data(as: Room.self) } ?? []
                self?.rooms = decoded
                if decoded.isEmpty {
                    self?.seedDefaultRoomsIfNeeded()
                }
            }
        }

        // Tasks
        let l3 = col("tasks")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                if let error {
                    print("❌ [Tasks] \(error.localizedDescription)")
                    return
                }
                DispatchQueue.main.async {
                    self?.tasks = snap?.documents.compactMap { try? $0.data(as: HouseTask.self) } ?? []
                }
            }

        // Shopping
        let l4 = col("shoppingItems").addSnapshotListener { [weak self] snap, error in
            if let error {
                print("❌ [Shopping] \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self?.shoppingItems = snap?.documents.compactMap {
                    try? $0.data(as: ShoppingItem.self)
                } ?? []
            }
        }

        listeners = [l1, l2, l3, l4]
    }

    private func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    private func col(_ name: String) -> CollectionReference {
        db.collection("households").document(householdId).collection(name)
    }

    // MARK: - Seed default rooms (only once per configure)

    private func seedDefaultRoomsIfNeeded() {
        guard !isSeeding, !householdId.isEmpty else { return }
        isSeeding = true

        let currentHouseholdId = householdId
        Task {
            do {
                for room in Room.defaultRooms {
                    try await db
                        .collection("households")
                        .document(currentHouseholdId)
                        .collection("rooms")
                        .document(room.id)
                        .setData(from: room)
                }
                print("✅ Cômodos padrão criados com sucesso.")
            } catch {
                print("❌ [SeedRooms] \(error.localizedDescription)")
                await MainActor.run { self.isSeeding = false }
            }
        }
    }

    // MARK: - Residents

    func addResident(_ resident: Resident) {
        try? col("residents").document(resident.id).setData(from: resident)
    }

    func deleteResident(_ resident: Resident) {
        col("residents").document(resident.id).delete()
        tasks.filter { $0.assignedResidentId == resident.id }.forEach {
            var t = $0; t.assignedResidentId = nil; updateTask(t)
        }
        shoppingItems.filter { $0.addedByResidentId == resident.id }.forEach {
            var i = $0; i.addedByResidentId = nil; updateShoppingItem(i)
        }
    }

    func updateResident(_ resident: Resident) {
        try? col("residents").document(resident.id).setData(from: resident)
    }

    func resident(for id: String?) -> Resident? {
        guard let id else { return nil }
        return residents.first { $0.id == id }
    }

    // MARK: - Rooms

    func addRoom(_ room: Room) {
        try? col("rooms").document(room.id).setData(from: room)
    }

    func deleteRoom(_ room: Room) {
        col("rooms").document(room.id).delete()
        tasks.filter { $0.roomId == room.id }.forEach { deleteTask($0) }
    }

    func updateRoom(_ room: Room) {
        try? col("rooms").document(room.id).setData(from: room)
    }

    // MARK: - Tasks

    func addTask(_ task: HouseTask) {
        try? col("tasks").document(task.id).setData(from: task)
    }

    func deleteTask(_ task: HouseTask) {
        col("tasks").document(task.id).delete()
    }

    func toggleTask(_ task: HouseTask) {
        var t = task
        if t.isCompleted { t.reopen() } else { t.complete() }
        try? col("tasks").document(t.id).setData(from: t)
    }

    func updateTask(_ task: HouseTask) {
        try? col("tasks").document(task.id).setData(from: task)
    }

    func tasks(for room: Room) -> [HouseTask] {
        tasks.filter { $0.roomId == room.id }
    }

    func pendingTasks(for room: Room) -> [HouseTask] {
        tasks(for: room).filter { !$0.isCompleted }
    }

    func completedTasks(for room: Room) -> [HouseTask] {
        tasks(for: room).filter { $0.isCompleted }
    }

    func tasks(for resident: Resident) -> [HouseTask] {
        tasks.filter { $0.assignedResidentId == resident.id && !$0.isCompleted }
    }

    var allPendingTasks: [HouseTask] { tasks.filter { !$0.isCompleted } }
    var totalPending: Int            { tasks.filter { !$0.isCompleted }.count }
    var totalCompleted: Int          { tasks.filter { $0.isCompleted }.count }

    // MARK: - Shopping

    func addShoppingItem(_ item: ShoppingItem) {
        try? col("shoppingItems").document(item.id).setData(from: item)
    }

    func deleteShoppingItem(_ item: ShoppingItem) {
        col("shoppingItems").document(item.id).delete()
    }

    func toggleShoppingItem(_ item: ShoppingItem) {
        var i = item; i.isChecked.toggle()
        try? col("shoppingItems").document(i.id).setData(from: i)
    }

    func updateShoppingItem(_ item: ShoppingItem) {
        try? col("shoppingItems").document(item.id).setData(from: item)
    }

    func clearCheckedItems() {
        shoppingItems.filter { $0.isChecked }.forEach { deleteShoppingItem($0) }
    }

    var pendingShoppingCount: Int { shoppingItems.filter { !$0.isChecked }.count }
}
