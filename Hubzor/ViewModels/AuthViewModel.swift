import Foundation
import Combine
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

    // MARK: - Delete Account

    /// Exclui permanentemente a conta do usuário.
    /// Fluxo: reautentica com senha → apaga doc no Firestore → apaga conta no Auth.
    func deleteAccount(password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            guard let user = Auth.auth().currentUser,
                  let email = user.email else {
                errorMessage = "Usuário não encontrado. Faça login novamente."
                isLoading = false
                return
            }

            // 1. Reautentica (Firebase exige para operações sensíveis)
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user.reauthenticate(with: credential)

            // 2. Remove documento do Firestore
            try await db.collection("users").document(user.uid).delete()

            // 3. Exclui a conta no Firebase Auth
            //    Isso dispara o listener de estado e navega automaticamente para o Login.
            try await user.delete()

        } catch {
            errorMessage = mapError(error)
        }

        isLoading = false
    }

    // MARK: - Esqueci minha senha

    /// Envia e-mail de redefinição de senha via Firebase.
    /// Retorna `true` se o e-mail foi enviado com sucesso.
    @discardableResult
    func sendPasswordReset(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespaces))
            isLoading = false
            return true
        } catch {
            errorMessage = mapError(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Trocar senha

    /// Reautentica com a senha atual e define a nova senha.
    /// Retorna `true` se a troca foi bem-sucedida.
    @discardableResult
    func updatePassword(current: String, new: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            guard let user = Auth.auth().currentUser,
                  let email = user.email else {
                errorMessage = "Usuário não encontrado. Faça login novamente."
                isLoading = false
                return false
            }
            // Reautentica antes de trocar a senha (exigido pelo Firebase)
            let credential = EmailAuthProvider.credential(withEmail: email, password: current)
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: new)
            isLoading = false
            return true
        } catch {
            errorMessage = mapError(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Firestore: create user doc

    private func createUserDocument(uid: String, name: String, email: String) async throws {
        let hubUser = HubzorUser(uid: uid, displayName: name, email: email)
        try await db.collection("users").document(uid).setData(from: hubUser)
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
        case .requiresRecentLogin:
            return "Senha incorreta ou sessão expirada. Tente novamente."
        default:
            return "Ocorreu um erro. Tente novamente."
        }
    }
}
