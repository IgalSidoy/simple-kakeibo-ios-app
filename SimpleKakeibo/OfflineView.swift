import SwiftUI

struct OfflineView: View {
    var onRetry: () -> Void

    @State private var wiggle = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(wiggle ? -5 : 5))
                .animation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: wiggle
                )
                .onAppear { wiggle = true }

            Text("No Connection")
                .font(.title2.weight(.semibold))

            Text("Check your internet and try again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding(40)
    }
}
