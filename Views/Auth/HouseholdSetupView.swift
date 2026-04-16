import SwiftUI

struct HouseholdSetupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var householdVM: HouseholdViewModel

    enum Mode { case choose, create, join }
    @State private var mode: Mode = .choose
    @State private var houseName = ""
    @State private var inviteCode = ""

    var userId: String { authVM.user?.uid ?? "" }
    var displayName: String { authVM.user?.displayName ?? "Morador" }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────
            VStack(spacing: 8) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.purple)
                    .padding(.top, 56)

                Text("Olá, \(displayName.components(separatedBy: " ").first ?? displayName)!")
                    .font(.title2.bold())

                Text("Configure sua casa para começar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 44)

            // ── Content by mode ───────────────────────────────────────
            Group {
                switch mode {
                case .choose:
                    chooseView
                case .create:
                    createView
                case .join:
                    joinView
                }
            }
            .padding(.horizontal, 24)

            // ── Error ─────────────────────────────────────────────────
            if let error = householdVM.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .transition(.opacity)
            }

            Spacer()

            // ── Back / Logout ─────────────────────────────────────────
            HStack {
                if mode != .choose {
                    Button {
                        withAnimation { mode = .choose }
                        householdVM.errorMessage = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Voltar")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                    }
                }
                Spacer()
                Button("Sair") { authVM.signOut() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Mode: Choose

    private var chooseView: some View {
        VStack(spacing: 16) {
            OptionCard(
                icon: "plus.circle.fill",
                iconColor: .purple,
                title: "Criar minha casa",
                subtitle: "Configure uma nova casa e convide os moradores"
            ) {
                withAnimation { mode = .create }
            }

            OptionCard(
                icon: "person.badge.key.fill",
                iconColor: .blue,
                title: "Entrar em uma casa",
                subtitle: "Use o código de convite que recebeu de um morador"
            ) {
                withAnimation { mode = .join }
            }
        }
    }

    // MARK: - Mode: Create

    private var createView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nome da casa")
                    .font(.headline)
                HubField(icon: "house", placeholder: "Ex: Casa da família Silva", text: $houseName)
            }

            Button {
                Task {
                    await householdVM.createHousehold(name: houseName, userId: userId)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(houseName.trimmingCharacters(in: .whitespaces).isEmpty
                              ? Color(.systemGray4) : Color.purple)
                    if householdVM.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Label("Criar casa", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 54)
            }
            .disabled(houseName.trimmingCharacters(in: .whitespaces).isEmpty || householdVM.isLoading)
        }
    }

    // MARK: - Mode: Join

    private var joinView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Código de convite")
                    .font(.headline)

                TextField("XXXXXX", text: $inviteCode)
                    .font(.system(.title2, design: .monospaced).bold())
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: inviteCode) { _, v in
                        inviteCode = String(v.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("O código tem 6 caracteres e é fornecido por quem criou a casa.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await householdVM.joinHousehold(code: inviteCode, userId: userId)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(inviteCode.count == 6 ? Color.blue : Color(.systemGray4))
                    if householdVM.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Label("Entrar na casa", systemImage: "arrow.right.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 54)
            }
            .disabled(inviteCode.count != 6 || householdVM.isLoading)
        }
    }
}

// MARK: - Option Card

struct OptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
