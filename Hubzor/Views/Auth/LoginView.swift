import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var isRegistering      = false
    @State private var name               = ""
    @State private var email              = ""
    @State private var password           = ""
    @State private var confirmPassword    = ""
    @State private var showPassword       = false
    @State private var showConfirm        = false
    @State private var showForgotPassword = false

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

                // ── Header ───────────────────────────────────────────────
                VStack(spacing: 10) {
                    Image(systemName: "house.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(HubzorTheme.accentGradientDiag)
                        .padding(.top, 60)

                    Text("Hubzor")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(isRegistering ? "Crie sua conta gratuita" : "Bem-vindo de volta!")
                        .font(.subheadline)
                        .foregroundStyle(HubzorTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)

                // ── Form ─────────────────────────────────────────────────
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

                    HubSecureField(placeholder: "Senha", text: $password, show: $showPassword)

                    if isRegistering {
                        HubSecureField(placeholder: "Confirmar senha", text: $confirmPassword, show: $showConfirm)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 24)

                // ── Hints ─────────────────────────────────────────────────
                if isRegistering && !password.isEmpty && password.count < 6 {
                    Text("A senha deve ter pelo menos 6 caracteres.")
                        .font(.caption)
                        .foregroundStyle(HubzorTheme.warning)
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

                // ── Error ─────────────────────────────────────────────────
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

                // ── Primary Button ────────────────────────────────────────
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
                            .fill(canProceed ? AnyShapeStyle(HubzorTheme.accentGradient) : AnyShapeStyle(HubzorTheme.disabled))
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

                // ── Esqueci minha senha (só no modo login) ────────────────
                if !isRegistering {
                    Button {
                        authVM.errorMessage = nil
                        showForgotPassword = true
                    } label: {
                        Text("Esqueci minha senha")
                            .font(.subheadline)
                            .foregroundStyle(HubzorTheme.neonCyan)
                    }
                    .padding(.top, 12)
                }

                // ── Toggle login ↔ cadastro ───────────────────────────────
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
                            .foregroundStyle(HubzorTheme.textSecondary)
                        Text(isRegistering ? "Entrar" : "Criar agora")
                            .fontWeight(.semibold)
                            .foregroundStyle(HubzorTheme.neonPurple)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(HubzorTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet()
                .environmentObject(authVM)
        }
    }
}

// MARK: - Forgot Password Sheet

struct ForgotPasswordSheet: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email      = ""
    @State private var emailSent  = false

    var canSend: Bool { email.contains("@") && !email.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // ── Ícone ──────────────────────────────────────────────
                    ZStack {
                        Circle()
                            .fill(HubzorTheme.neonCyan.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: emailSent ? "checkmark.circle.fill" : "lock.rotation")
                            .font(.system(size: 36))
                            .foregroundStyle(emailSent ? HubzorTheme.success : HubzorTheme.neonCyan)
                    }
                    .padding(.top, 8)
                    .animation(.spring(duration: 0.4), value: emailSent)

                    // ── Texto ──────────────────────────────────────────────
                    VStack(spacing: 10) {
                        Text(emailSent ? "E-mail enviado!" : "Redefinir senha")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text(emailSent
                             ? "Verifique sua caixa de entrada e siga as instruções para criar uma nova senha."
                             : "Digite o e-mail da sua conta e enviaremos um link para você redefinir sua senha.")
                            .font(.subheadline)
                            .foregroundStyle(HubzorTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)

                    if !emailSent {
                        // ── Campo de e-mail ────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            HubField(
                                icon: "envelope",
                                placeholder: "Seu e-mail",
                                text: $email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never
                            )
                        }
                        .padding(.horizontal)

                        // ── Erro ───────────────────────────────────────────
                        if let error = authVM.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .padding(.horizontal)
                            .transition(.opacity)
                        }

                        // ── Botão enviar ───────────────────────────────────
                        Button {
                            Task {
                                let success = await authVM.sendPasswordReset(email: email)
                                if success { withAnimation { emailSent = true } }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(canSend
                                          ? AnyShapeStyle(LinearGradient(
                                                colors: [HubzorTheme.neonCyan, HubzorTheme.neonPurple],
                                                startPoint: .leading, endPoint: .trailing))
                                          : AnyShapeStyle(HubzorTheme.disabled))
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Label("Enviar link de redefinição", systemImage: "paperplane.fill")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 54)
                        }
                        .disabled(!canSend || authVM.isLoading)
                        .padding(.horizontal)

                    } else {
                        // ── Botão fechar após sucesso ──────────────────────
                        Button {
                            authVM.errorMessage = nil
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AnyShapeStyle(HubzorTheme.accentGradient))
                                Text("Fechar")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .frame(height: 54)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 24)
            }
            .background(HubzorTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        authVM.errorMessage = nil
                        dismiss()
                    }
                    .foregroundStyle(HubzorTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - HubField

struct HubField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(HubzorTheme.neonPurple)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(HubzorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(HubzorTheme.neonPurple.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - HubSecureField

struct HubSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(HubzorTheme.neonPurple)
                .frame(width: 20)
            Group {
                if show {
                    TextField(placeholder, text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                } else {
                    SecureField(placeholder, text: $text)
                        .foregroundStyle(.white)
                }
            }
            Button {
                show.toggle()
            } label: {
                Image(systemName: show ? "eye.slash" : "eye")
                    .foregroundStyle(HubzorTheme.textSecondary)
            }
        }
        .padding(16)
        .background(HubzorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(HubzorTheme.neonPurple.opacity(0.25), lineWidth: 1)
        )
    }
}
