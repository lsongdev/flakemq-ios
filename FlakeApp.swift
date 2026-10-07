import SwiftUI

@main
struct FlakeApp: App {
    @StateObject private var appManager = FlakeAppManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainView()
            }
            .environmentObject(appManager)
        }
    }
}
