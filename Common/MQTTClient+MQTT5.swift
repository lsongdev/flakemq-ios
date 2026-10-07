import CocoaMQTT
import Foundation

extension MQTTClient: CocoaMQTT5Delegate {
    func mqtt5(
        _ mqtt5: CocoaMQTT5,
        didConnectAck ack: CocoaMQTTCONNACKReasonCode,
        connAckData: MqttDecodeConnAck?
    ) {
        guard isCurrent(mqtt5) else { return }

        if ack == .success {
            setConnectionState(.connected)
            restoreSubscriptions()
        } else {
            setConnectionState(.error("Connection rejected: \(ack)"))
        }
    }

    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {}

    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {}

    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {}

    func mqtt5(
        _ mqtt5: CocoaMQTT5,
        didReceiveMessage message: CocoaMQTT5Message,
        id: UInt16,
        publishData: MqttDecodePublish?
    ) {
        guard isCurrent(mqtt5) else { return }

        addMessage(
            packetId: id,
            topic: message.topic,
            payload: message.payload,
            qos: Int(message.qos.rawValue),
            retain: message.retained,
            duplicate: message.duplicated
        )
    }

    func mqtt5(
        _ mqtt5: CocoaMQTT5,
        didSubscribeTopics success: NSDictionary,
        failed: [String],
        subAckData: MqttDecodeSubAck?
    ) {
        guard isCurrent(mqtt5), !failed.isEmpty else { return }
        setConnectionState(.error("Subscription failed: \(failed.joined(separator: ", "))"))
    }

    func mqtt5(
        _ mqtt5: CocoaMQTT5,
        didUnsubscribeTopics topics: [String],
        unsubAckData: MqttDecodeUnsubAck?
    ) {}

    func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {}

    func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {}

    func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError error: Error?) {
        guard isCurrent(mqtt5), !isInErrorState else { return }
        setConnectionState(.reconnecting(attempt: 0, delay: 0))
    }

    func mqtt5(_ mqtt5: CocoaMQTT5, didStateChangeTo state: CocoaMQTTConnState) {
        guard isCurrent(mqtt5), !isInErrorState else { return }

        switch state {
        case .connecting:
            setConnectionState(.connecting)
        case .connected:
            setConnectionState(.connected)
        case .disconnected:
            setConnectionState(.reconnecting(attempt: 0, delay: 0))
        }
    }

    func mqtt5(
        _ mqtt5: CocoaMQTT5,
        didScheduleReconnect attemptCount: UInt,
        after interval: UInt16
    ) {
        guard isCurrent(mqtt5), !isInErrorState else { return }
        setConnectionState(.reconnecting(attempt: attemptCount, delay: interval))
    }

    func mqtt5(
        _ mqtt5: CocoaMQTT5,
        didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode
    ) {
        guard isCurrent(mqtt5), reasonCode != .normalDisconnection else { return }
        setConnectionState(.error("Disconnected: \(reasonCode)"))
    }

    func mqtt5(
        _ mqtt5: CocoaMQTT5,
        didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode
    ) {}
}
