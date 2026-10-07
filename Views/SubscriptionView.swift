import SwiftUI

struct SubscriptionView: View {
    let subscription: Subscription

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .fontDesign(.monospaced)

                Text("QoS \(subscription.qos)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if subscription.name.contains("+") || subscription.name.contains("#") {
                Image(systemName: "asterisk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}
