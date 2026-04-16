import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var isRegistering = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirm = false

    var canProceed: Bool {
        if isRegistering {
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
                && email.contains("@")
                && password.count >= 6
                && password == confirmPassword
        }
        return email.contains("@") && !password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ───────────────────────────────────────────
                VStack(spacing: 10) {
                    Image(systemName: "house.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(.purple)
                        .padding(.top, 60)

                    Text("Hubzor")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text(isRegistering ? "Crie sua conta gratuita" : "Bem-vindo de volta!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)

                // ── Form ─────────────────────────────────────────────
                VStack(spacing: 14) {
                    if isRegistering {
                        HubField(icon: "person", placeholder: "Seu nome", text: $name)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    HubField(
                        icon: "envelope",
                        placeholder: "E-mail",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    HubSecureField(
                        placeholder: "Senha",
                        text: $password,
                        show: $showPassword
                    )

                    if isRegistering {
                        HubSecureField(
                            placeholder: "Confirmar senha",
                            text: $confirmPassword,
                            show: $showConfirm
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 24)

                // ── Password hint ─────────────────────────────────────
                if isRegistering && !password.isEmpty && password.count < 6 {
                    Text("A senha deve ter pelo menos 6 caracteres.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .transition(.opacity)
                }

                if isRegistering && !confirmPassword.isEmpty && password != confirmPassword {
                    Text("As senhas não coincidem.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .transition(.opacity)
                }

                // ── Error message ─────────────────────────────────────
                if let error = authVM.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .transition(.opacity)
                }

                // ── Primary Button ────────────────────────────────────
                Button {
                    Task {
                        if isRegistering {
                            await authVM.register(
                                name: name.trimmingCharacters(in: .whitespaces),
                                email: email.trimmingCharacters(in: .whitespaces),
                                password: password
                            )
                        } else {
                            await authVM.signIn(
                                email: email.trimmingCharacters(in: .whitespaces),
                                password: password
                            )
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canProceed ? Color.purple : Color(.systemGray4))
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isRegistering ? "Criar conta" : "Entrar")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(height: 54)
                }
                .disabled(!canProceed || authVM.isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // ── Toggle ────────────────────────────────────────────
                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        isRegistering.toggle()
                        authVM.errorMessage = nil
                        password = ""
                        confirmPassword = ""
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isRegistering ? "Já tenho uma conta" : "Não tenho conta?")
                            .foregroundStyle(.secondary)
                        Text(isRegistering ? "Entrar" : "Criar agora")
                            .fontWeight(.semibold)
                            .foregroundStyle(.purple)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Reusable field components

struct HubField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct HubSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(.purple)
                .frame(width: 20)
            Group {
                if show {
                    TextField(placeholder, text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            Button {
                show.toggle()
            } label: {
                Image(systemName: show ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
