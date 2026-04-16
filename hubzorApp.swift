import SwiftUI
import FirebaseCore

@main
struct HubzorApp: App {
    @StateObject private var authVM      = AuthViewModel()
    @StateObject private var householdVM = HouseholdViewModel()
    @StateObject private var appVM       = AppViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(householdVM)
                .environmentObject(appVM)
        }
    }
}
