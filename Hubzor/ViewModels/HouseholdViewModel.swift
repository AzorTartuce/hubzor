import Foundation
import Combine
import FirebaseFirestore

@MainActor
class HouseholdViewModel: ObservableObject {
    @Published var householdId: String?
    @Published var householdName: String?
    @Published var inviteCode: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    private var householdListener: ListenerRegistration?

    var userListenerIsNil: Bool { userListener == nil }

    // MARK: - Start listening to user doc

    func startListening(userId: String) {
        isLoading = true
        userListener?.remove()
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let data = snapshot?.data(),
                       let hid = data["householdId"] as? String {
                        self.householdId = hid
                        self.listenToHousehold(id: hid)
                    } else {
                        // User exists but has no household yet
                        self.householdId = nil
                    }
                }
            }
    }

    private func listenToHousehold(id: String) {
        householdListener?.remove()
        householdListener = db.collection("households").document(id)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let data = snapshot?.data() else { return }
                DispatchQueue.main.async {
                    self?.householdName = data["name"] as? String
                    self?.inviteCode = data["inviteCode"] as? String
                }
            }
    }

    func stopListening() {
        userListener?.remove()
        householdListener?.remove()
        userListener = nil
        householdListener = nil
        householdId = nil
        householdName = nil
        inviteCode = nil
    }

    // MARK: - Create household

    func createHousehold(name: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let code = Household.generateInviteCode()
            let household = Household(
                name: name.trimmingCharacters(in: .whitespaces),
                ownerId: userId,
                inviteCode: code
            )
            try await db.collection("households").document(household.id).setData(from: household)
            try await db.collection("users").document(userId).updateData([
                "householdId": household.id
            ])
        } catch {
            errorMessage = "Erro ao criar a casa. Tente novamente."
        }
        isLoading = false
    }

    // MARK: - Join household

    func joinHousehold(code: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let snapshot = try await db.collection("households")
                .whereField("inviteCode", isEqualTo: code.uppercased())
                .getDocuments()

            guard let doc = snapshot.documents.first else {
                errorMessage = "Código inválido. Verifique e tente novamente."
                isLoading = false
                return
            }

            let householdId = doc.documentID
            try await db.collection("users").document(userId).updateData([
                "householdId": householdId
            ])
        } catch {
            errorMessage = "Erro ao entrar na casa. Tente novamente."
        }
        isLoading = false
    }
}
