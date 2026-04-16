import SwiftUI

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
        .animation(.easeInOut(duration: 0.3), value: authVM.user?.uid)
        .animation(.easeInOut(duration: 0.3), value: householdVM.householdId)
        // Sync auth → household
        .onChange(of: authVM.user?.uid) { _, newUid in
            if let uid = newUid {
                householdVM.startListening(userId: uid)
            } else {
                householdVM.stopListening()
                appVM.reset()
            }
        }
        // Sync household → app data
        .onChange(of: householdVM.householdId) { _, newId in
            if let id = newId {
                appVM.configure(householdId: id)
            } else {
                appVM.reset()
            }
        }
    }
}

// MARK: - Splash / Loading

struct SplashView: View {
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(.purple)
                .scaleEffect(pulsing ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulsing)
                .onAppear { pulsing = true }

            Text("Hubzor")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct LoadingView: View {
    var message: String = "Carregando..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.purple)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
