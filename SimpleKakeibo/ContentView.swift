import SwiftUI
import os

private let log = Logger(subsystem: "com.igals.SimpleKakeibo", category: "ContentView")

struct ContentView: View {
    @State private var network = NetworkMonitor()
    @State private var cookiesRestored = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if cookiesRestored {
                WebView(url: URL(string: "https://app.ymym.io/"))
                    .ignoresSafeArea(edges: .bottom)
            }

            if !network.isConnected {
                OfflineView {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: network.isConnected)
        .task {
            log.info("🟢 ContentView .task: starting cookie restore")
            await CookiePersistence.shared.restore()
            cookiesRestored = true
            log.info("🟢 ContentView .task: cookies restored, showing WebView")
        }
    }
}

#Preview {
    ContentView()
}
