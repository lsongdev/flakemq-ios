import CocoaMQTT

extension MQTTClient: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        guard isCurrent(mqtt) else { return }

        if ack == .accept {
            setConnectionState(.connected)
            restoreSubscriptions()
        } else {
            setConnectionState(.error("Connection rejected: \(ack)"))
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {}

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {}

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        guard isCurrent(mqtt) else { return }

        addMessage(
            packetId: id,
            topic: message.topic,
            payload: message.payload,
            qos: Int(message.qos.rawValue),
            retain: message.retained,
            duplicate: message.duplicated
        )
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        guard isCurrent(mqtt), !failed.isEmpty else { return }
        setConnectionState(.error("Subscription failed: \(failed.joined(separator: ", "))"))
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {}

    func mqttDidPing(_ mqtt: CocoaMQTT) {}

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError error: Error?) {
        guard isCurrent(mqtt), !isInErrorState else { return }
        setConnectionState(.reconnecting(attempt: 0, delay: 0))
    }

    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        guard isCurrent(mqtt), !isInErrorState else { return }

        switch state {
        case .connecting:
            setConnectionState(.connecting)
        case .connected:
            setConnectionState(.connected)
        case .disconnected:
            setConnectionState(.reconnecting(attempt: 0, delay: 0))
        }
    }

    func mqtt(
        _ mqtt: CocoaMQTT,
        didScheduleReconnect attemptCount: UInt,
        after interval: UInt16
    ) {
        guard isCurrent(mqtt), !isInErrorState else { return }
        setConnectionState(.reconnecting(attempt: attemptCount, delay: interval))
    }
}
