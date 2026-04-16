import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var householdVM: HouseholdViewModel
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        Group {
            if authVM.isCheckingAuth {
                SplashView()
            } else if authVM.user == nil {
                LoginView()
                    .transition(.opacity)
            } else if householdVM.isLoading {
                LoadingView(message: "Carregando sua casa...")
                    .transition(.opacity)
            } else if householdVM.householdId == nil {
                HouseholdSetupView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: authVM.user?.uid)
        .animation(.easeInOut(duration: 0.3), value: householdVM.householdId)
        .onChange(of: authVM.user?.uid) { _, newUid in
            if let uid = newUid {
                householdVM.startListening(userId: uid)
            } else {
                householdVM.stopListening()
                appVM.reset()
            }
        }
        .onChange(of: householdVM.householdId) { _, newId in
            if let id = newId {
                appVM.configure(householdId: id)
            } else {
                appVM.reset()
            }
        }
        .task {
            if let uid = authVM.user?.uid, householdVM.userListenerIsNil {
                householdVM.startListening(userId: uid)
            }
            if let id = householdVM.householdId, appVM.householdId.isEmpty {
                appVM.configure(householdId: id)
            }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(HubzorTheme.accentGradientDiag)
                .scaleEffect(pulsing ? 1.06 : 1.0)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulsing)
                .onAppear { pulsing = true }

            Text("Hubzor")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HubzorTheme.background.ignoresSafeArea())
    }
}

// MARK: - Loading

struct LoadingView: View {
    var message: String = "Carregando..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(HubzorTheme.neonPurple)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(HubzorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HubzorTheme.background.ignoresSafeArea())
    }
}
