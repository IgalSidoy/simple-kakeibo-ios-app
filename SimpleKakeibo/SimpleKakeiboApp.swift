import SwiftUI
import os

private let log = Logger(subsystem: "com.igals.SimpleKakeibo", category: "AppLifecycle")

@main
struct SimpleKakeiboApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, phase in
            log.info("📱 scenePhase changed to: \(String(describing: phase))")
            switch phase {
            case .inactive, .background:
                log.info("📱 triggering cookie save for phase: \(String(describing: phase))")
                Task { await CookiePersistence.shared.save() }
            default:
                break
            }
        }
    }
}
