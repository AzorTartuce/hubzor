import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var householdVM: HouseholdViewModel

    init() {
        // Tab bar escura com estilo neon
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(HubzorTheme.cardBackground)

        // Separador sutil
        appearance.shadowColor = UIColor(HubzorTheme.neonPurple.opacity(0.25))

        UITabBar.appearance().standardAppearance    = appearance
        UITabBar.appearance().scrollEdgeAppearance  = appearance
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Início",    systemImage: "house.fill") }

            RoomsView()
                .tabItem { Label("Cômodos",   systemImage: "square.grid.2x2.fill") }

            ShoppingListView()
                .tabItem { Label("Mercado",   systemImage: "cart.fill") }

            ResidentsView()
                .tabItem { Label("Moradores", systemImage: "person.2.fill") }

            HouseholdSettingsView()
                .tabItem { Label("Casa",      systemImage: "gearshape.fill") }
        }
        .tint(HubzorTheme.neonPurple)
    }
}

// MARK: - Household Settings Tab

struct HouseholdSettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var householdVM: HouseholdViewModel
    @State private var showCopied        = false
    @State private var showLogoutConfirm  = false
    @State private var showDeleteAccount  = false
    @State private var showChangePassword = false

    var body: some View {
        NavigationStack {
            List {

                // ── Casa ─────────────────────────────────────────────────────
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(HubzorTheme.neonPurple.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: "house.fill")
                                .font(.title3)
                                .foregroundStyle(HubzorTheme.neonPurple)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(householdVM.householdName ?? "Minha Casa")
                                .font(.headline)
                            Text("Casa ativa")
                                .font(.caption)
                                .foregroundStyle(HubzorTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(HubzorTheme.cardBackground)
                }

                // ── Código de convite ─────────────────────────────────────────
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Código de convite")
                            .font(.subheadline.bold())
                        HStack {
                            Text(householdVM.inviteCode ?? "------")
                                .font(.system(.title2, design: .monospaced).bold())
                                .foregroundStyle(HubzorTheme.neonPurple)
                                .tracking(6)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = householdVM.inviteCode
                                withAnimation { showCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { showCopied = false }
                                }
                            } label: {
                                Label(
                                    showCopied ? "Copiado!" : "Copiar",
                                    systemImage: showCopied ? "checkmark.circle.fill" : "doc.on.doc"
                                )
                                .font(.caption.bold())
                                .foregroundStyle(showCopied ? HubzorTheme.success : HubzorTheme.neonPurple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    (showCopied ? HubzorTheme.success : HubzorTheme.neonPurple).opacity(0.12)
                                )
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        Text("Compartilhe este código para que outros moradores entrem na sua casa.")
                            .font(.caption)
                            .foregroundStyle(HubzorTheme.textSecondary)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(HubzorTheme.cardBackground)
                } header: {
                    Text("Convite")
                }

                // ── Conta ─────────────────────────────────────────────────────
                Section("Conta") {
                    if let user = authVM.user {
                        LabeledContent("E-mail", value: user.email ?? "-")
                            .listRowBackground(HubzorTheme.cardBackground)
                        LabeledContent("Nome", value: user.displayName ?? "-")
                            .listRowBackground(HubzorTheme.cardBackground)
                    }
                    Button {
                        showChangePassword = true
                    } label: {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(HubzorTheme.neonCyan)
                            Text("Trocar senha")
                                .foregroundStyle(.white)
                        }
                    }
                    .listRowBackground(HubzorTheme.cardBackground)
                }

                // ── Sair / Excluir ────────────────────────────────────────────
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sair da conta")
                        }
                    }
                    .listRowBackground(HubzorTheme.cardBackground)

                    Button(role: .destructive) {
                        showDeleteAccount = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus")
                            Text("Excluir minha conta")
                        }
                    }
                    .listRowBackground(HubzorTheme.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(HubzorTheme.background)
            .navigationTitle("Minha Casa")
            .confirmationDialog("Sair da conta?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Sair", role: .destructive) { authVM.signOut() }
            } message: {
                Text("Você precisará fazer login novamente.")
            }
            .sheet(isPresented: $showDeleteAccount) {
                DeleteAccountSheet()
                    .environmentObject(authVM)
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet()
                    .environmentObject(authVM)
            }
        }
    }
}

// MARK: - Delete Account Sheet

struct DeleteAccountSheet: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var password = ""
    @State private var showPassword = false

    var canConfirm: Bool { password.count >= 6 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // ── Ícone de aviso ─────────────────────────────────────
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 8)

                    // ── Texto explicativo ──────────────────────────────────
                    VStack(spacing: 10) {
                        Text("Excluir conta")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text("Esta ação é **permanente e irreversível**. Seu perfil será removido do Hubzor. Os dados da casa (cômodos, tarefas, listas) **não serão apagados** — outros moradores continuarão tendo acesso.")
                            .font(.subheadline)
                            .foregroundStyle(HubzorTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)

                    // ── Campo de senha (reautenticação) ───────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirme sua senha para continuar")
                            .font(.caption.bold())
                            .foregroundStyle(HubzorTheme.textSecondary)
                            .padding(.horizontal, 4)

                        HubSecureField(
                            placeholder: "Sua senha atual",
                            text: $password,
                            show: $showPassword
                        )
                    }
                    .padding(.horizontal)

                    // ── Erro ──────────────────────────────────────────────
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

                    // ── Botão de exclusão ─────────────────────────────────
                    Button {
                        Task {
                            await authVM.deleteAccount(password: password)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canConfirm
                                      ? AnyShapeStyle(LinearGradient(
                                            colors: [Color(hex: "EF4444"), Color(hex: "B91C1C")],
                                            startPoint: .leading, endPoint: .trailing))
                                      : AnyShapeStyle(HubzorTheme.disabled))
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Excluir permanentemente", systemImage: "trash.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(height: 54)
                    }
                    .disabled(!canConfirm || authVM.isLoading)
                    .padding(.horizontal)
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

// MARK: - Change Password Sheet

struct ChangePasswordSheet: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var currentPassword     = ""
    @State private var newPassword         = ""
    @State private var confirmNewPassword  = ""
    @State private var showCurrent         = false
    @State private var showNew             = false
    @State private var showConfirm         = false
    @State private var didSucceed          = false

    var passwordsMatch: Bool  { newPassword == confirmNewPassword }
    var newIsStrong: Bool     { newPassword.count >= 6 }
    var isDifferent: Bool     { newPassword != currentPassword }
    var canSave: Bool {
        !currentPassword.isEmpty && newIsStrong && passwordsMatch && isDifferent
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // ── Ícone ──────────────────────────────────────────────
                    ZStack {
                        Circle()
                            .fill(HubzorTheme.neonPurple.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: didSucceed ? "checkmark.circle.fill" : "key.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(didSucceed ? HubzorTheme.success : HubzorTheme.neonPurple)
                    }
                    .padding(.top, 8)
                    .animation(.spring(duration: 0.4), value: didSucceed)

                    // ── Título ─────────────────────────────────────────────
                    VStack(spacing: 10) {
                        Text(didSucceed ? "Senha alterada!" : "Trocar senha")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text(didSucceed
                             ? "Sua senha foi atualizada com sucesso."
                             : "Digite sua senha atual e escolha uma nova senha com pelo menos 6 caracteres.")
                            .font(.subheadline)
                            .foregroundStyle(HubzorTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)

                    if !didSucceed {
                        VStack(spacing: 14) {

                            // ── Senha atual ────────────────────────────────
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Senha atual")
                                    .font(.caption.bold())
                                    .foregroundStyle(HubzorTheme.textSecondary)
                                    .padding(.horizontal, 4)
                                HubSecureField(
                                    placeholder: "Sua senha atual",
                                    text: $currentPassword,
                                    show: $showCurrent
                                )
                            }

                            // ── Nova senha ─────────────────────────────────
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Nova senha")
                                    .font(.caption.bold())
                                    .foregroundStyle(HubzorTheme.textSecondary)
                                    .padding(.horizontal, 4)
                                HubSecureField(
                                    placeholder: "Nova senha (mín. 6 caracteres)",
                                    text: $newPassword,
                                    show: $showNew
                                )
                                // Força da senha
                                if !newPassword.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: newIsStrong ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .font(.caption)
                                        Text(newIsStrong ? "Tamanho OK" : "Mínimo 6 caracteres")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(newIsStrong ? HubzorTheme.success : .red)
                                    .padding(.horizontal, 4)
                                    .transition(.opacity)
                                }
                                if !newPassword.isEmpty && !isDifferent {
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle.fill").font(.caption)
                                        Text("A nova senha deve ser diferente da atual")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 4)
                                    .transition(.opacity)
                                }
                            }

                            // ── Confirmar nova senha ───────────────────────
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirmar nova senha")
                                    .font(.caption.bold())
                                    .foregroundStyle(HubzorTheme.textSecondary)
                                    .padding(.horizontal, 4)
                                HubSecureField(
                                    placeholder: "Repita a nova senha",
                                    text: $confirmNewPassword,
                                    show: $showConfirm
                                )
                                if !confirmNewPassword.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .font(.caption)
                                        Text(passwordsMatch ? "Senhas coincidem" : "Senhas não coincidem")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(passwordsMatch ? HubzorTheme.success : .red)
                                    .padding(.horizontal, 4)
                                    .transition(.opacity)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.2), value: newPassword)
                        .animation(.easeInOut(duration: 0.2), value: confirmNewPassword)

                        // ── Erro do Firebase ───────────────────────────────
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

                        // ── Botão salvar ───────────────────────────────────
                        Button {
                            Task {
                                let success = await authVM.updatePassword(
                                    current: currentPassword,
                                    new: newPassword
                                )
                                if success { withAnimation { didSucceed = true } }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(canSave
                                          ? AnyShapeStyle(HubzorTheme.accentGradient)
                                          : AnyShapeStyle(HubzorTheme.disabled))
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Label("Salvar nova senha", systemImage: "checkmark.circle.fill")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 54)
                        }
                        .disabled(!canSave || authVM.isLoading)
                        .padding(.horizontal)

                    } else {
                        // ── Fechar após sucesso ────────────────────────────
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
