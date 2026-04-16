import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var householdVM: HouseholdViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Início", systemImage: "house.fill") }

            RoomsView()
                .tabItem { Label("Cômodos", systemImage: "square.grid.2x2.fill") }

            ShoppingListView()
                .tabItem { Label("Mercado", systemImage: "cart.fill") }

            ResidentsView()
                .tabItem { Label("Moradores", systemImage: "person.2.fill") }

            HouseholdSettingsView()
                .tabItem { Label("Casa", systemImage: "gearshape.fill") }
        }
        .tint(.purple)
    }
}

// MARK: - Household Settings Tab

struct HouseholdSettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var householdVM: HouseholdViewModel
    @State private var showCopied = false
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                // House info
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: "house.fill")
                                .font(.title3)
                                .foregroundStyle(.purple)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(householdVM.householdName ?? "Minha Casa")
                                .font(.headline)
                            Text("Casa ativa")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Invite code
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Código de convite")
                            .font(.subheadline.bold())
                        HStack {
                            Text(householdVM.inviteCode ?? "------")
                                .font(.system(.title2, design: .monospaced).bold())
                                .foregroundStyle(.purple)
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
                                .foregroundStyle(showCopied ? .green : .purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background((showCopied ? Color.green : Color.purple).opacity(0.12))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        Text("Compartilhe este código para que outros moradores entrem na sua casa.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Convite")
                }

                // Account
                Section("Conta") {
                    if let user = authVM.user {
                        LabeledContent("E-mail", value: user.email ?? "-")
                        LabeledContent("Nome", value: user.displayName ?? "-")
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sair da conta")
                        }
                    }
                }
            }
            .navigationTitle("Minha Casa")
            .confirmationDialog("Sair da conta?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Sair", role: .destructive) { authVM.signOut() }
            } message: {
                Text("Você precisará fazer login novamente.")
            }
        }
    }
}
