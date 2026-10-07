import Foundation

struct Message: Identifiable, Equatable {
    let id: UUID
    let packetId: UInt16?
    let timestamp: Date
    let topic: String
    let qos: Int
    let payload: Data
    let retain: Bool
    let duplicate: Bool

    init(
        id: UUID = UUID(),
        packetId: UInt16? = nil,
        timestamp: Date = Date(),
        topic: String,
        qos: Int = 0,
        payload: Data,
        retain: Bool = false,
        duplicate: Bool = false
    ) {
        self.id = id
        self.packetId = packetId
        self.timestamp = timestamp
        self.topic = topic
        self.qos = qos
        self.payload = payload
        self.retain = retain
        self.duplicate = duplicate
    }

    var utf8Payload: String? {
        String(data: payload, encoding: .utf8)
    }

    var displayPayload: String {
        if let text = utf8Payload {
            if let object = try? JSONSerialization.jsonObject(with: payload),
               JSONSerialization.isValidJSONObject(object),
               let pretty = try? JSONSerialization.data(
                    withJSONObject: object,
                    options: [.prettyPrinted, .sortedKeys]
               ),
               let formatted = String(data: pretty, encoding: .utf8) {
                return formatted
            }
            return text
        }

        let preview = payload.prefix(256)
        let hex = preview.map { String(format: "%02x", $0) }.joined(separator: " ")
        return payload.count > preview.count ? "\(hex) …" : hex
    }

    var payloadSizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(payload.count), countStyle: .file)
    }
}

struct PublishDraft: Equatable {
    var topic: String = ""
    var qos: Int = 0
    var payload: String = ""
    var retain: Bool = false

    var isValid: Bool {
        TopicFilter.isValidTopicName(topic) && (0...2).contains(qos)
    }

    static var empty: PublishDraft {
        PublishDraft()
    }
}
