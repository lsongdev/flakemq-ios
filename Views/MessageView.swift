import SwiftUI
import UIKit

struct MessageView: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(message.timestamp, style: .time)
                    .foregroundStyle(.secondary)

                Spacer()

                badge("QoS \(message.qos)")
                if message.retain {
                    badge("Retain")
                }
                if message.duplicate {
                    badge("Dup")
                }
                Text(message.payloadSizeText)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            Text(message.topic)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Text(message.displayPayload)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.displayPayload
            } label: {
                Label("Copy Payload", systemImage: "doc.on.doc")
            }

            Button {
                UIPasteboard.general.string = message.topic
            } label: {
                Label("Copy Topic", systemImage: "number")
            }
        }
        .padding(.vertical, 4)
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.quaternary, in: Capsule())
    }
}
