import SwiftUI

struct StatusView: View {
    let connectionState: MQTTClient.ConnectionState

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(statusColor)
        }
    }

    private var statusText: String {
        switch connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting…"
        case .reconnecting(let attempt, let delay):
            if attempt == 0 || delay == 0 {
                return "Reconnecting…"
            }
            return "Reconnecting in \(delay)s (attempt \(attempt))"
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return message
        }
    }

    private var statusColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .secondary
        case .error:
            return .red
        }
    }
}
