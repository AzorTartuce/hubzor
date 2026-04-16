import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isCheckingAuth: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isCheckingAuth = false
            }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    // MARK: - Register

    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            try await createUserDocument(uid: result.user.uid, name: name, email: email)
        } catch {
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - Firestore: create user doc

    private func createUserDocument(uid: String, name: String, email: String) async throws {
        let hubUser = HubzorUser(uid: uid, displayName: name, email: email)
        try db.collection("users").document(uid).setData(from: hubUser)
    }

    // MARK: - Error mapping (PT-BR)

    private func mapError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch AuthErrorCode(rawValue: code) {
        case .emailAlreadyInUse:
            return "Este e-mail já está cadastrado."
        case .invalidEmail:
            return "E-mail inválido."
        case .weakPassword:
            return "Senha fraca. Use pelo menos 6 caracteres."
        case .wrongPassword, .invalidCredential:
            return "E-mail ou senha incorretos."
        case .userNotFound:
            return "Nenhuma conta encontrada com este e-mail."
        case .networkError:
            return "Erro de rede. Verifique sua conexão."
        case .tooManyRequests:
            return "Muitas tentativas. Aguarde alguns minutos."
        default:
            return "Ocorreu um erro. Tente novamente."
        }
    }
}
