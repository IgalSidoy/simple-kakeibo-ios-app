import SwiftUI

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
            await CookiePersistence.shared.restore()
            cookiesRestored = true
        }
    }
}

#Preview {
    ContentView()
}
