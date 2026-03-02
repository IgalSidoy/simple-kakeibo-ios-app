import SwiftUI

@main
struct SimpleKakeiboApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .inactive, .background:
                Task { await CookiePersistence.shared.save() }
            default:
                break
            }
        }
    }
}
