import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(TopicFilter.isValid("sensors/+/temperature"), "single-level wildcard should be valid")
expect(TopicFilter.isValid("devices/#"), "multi-level wildcard should be valid")
expect(!TopicFilter.isValid("devices/#/state"), "# must be the final level")
expect(!TopicFilter.isValid("devices/temp+"), "+ must occupy a complete level")

expect(
    TopicFilter.matches("sensors/+/temperature", topic: "sensors/kitchen/temperature"),
    "+ should match one level"
)
expect(
    !TopicFilter.matches("sensors/+/temperature", topic: "sensors/kitchen/upstairs/temperature"),
    "+ should not match multiple levels"
)
expect(TopicFilter.matches("devices/#", topic: "devices"), "# should match zero remaining levels")
expect(TopicFilter.matches("devices/#", topic: "devices/a/b"), "# should match remaining levels")
expect(!TopicFilter.matches("#", topic: "$SYS/broker"), "leading wildcard must not match system topics")

var buffer = CircularBuffer<Int>(maxSize: 3)
buffer.append(1)
buffer.append(2)
buffer.append(3)
buffer.append(4)
expect(Array(buffer) == [2, 3, 4], "buffer should evict the oldest value in O(1) ring order")
buffer.removeAll { $0.isMultiple(of: 2) == false }
expect(Array(buffer) == [2, 4], "buffer filtering should preserve order")

let server = ServerDescription(
    host: "broker.example.com",
    password: "secret"
)
let encoded = try JSONEncoder().encode(server)
let json = String(decoding: encoded, as: UTF8.self)
expect(!json.contains("secret"), "encoded broker configuration must not contain the password")

let legacy = """
{
  "id": "\(server.id.uuidString)",
  "host": "broker.example.com",
  "password": "legacy-secret"
}
""".data(using: .utf8)!
let decoded = try JSONDecoder().decode(ServerDescription.self, from: legacy)
expect(decoded.password == "legacy-secret", "legacy password must remain readable for Keychain migration")

print("Core tests passed")
