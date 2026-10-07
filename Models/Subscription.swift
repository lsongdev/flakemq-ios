import Foundation

struct Subscription: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    var qos: Int

    init(id: UUID = UUID(), name: String, qos: Int = 0) {
        self.id = id
        self.name = name
        self.qos = qos
    }
}

enum TopicFilter {
    static func isValid(_ filter: String) -> Bool {
        guard !filter.isEmpty,
              !filter.contains("\0"),
              filter.utf8.count <= 65_535 else {
            return false
        }

        let levels = split(filter)
        for (index, level) in levels.enumerated() {
            if level.contains("#") && (level != "#" || index != levels.count - 1) {
                return false
            }
            if level.contains("+") && level != "+" {
                return false
            }
        }
        return true
    }

    static func isValidTopicName(_ topic: String) -> Bool {
        !topic.isEmpty &&
        !topic.contains("\0") &&
        !topic.contains("#") &&
        !topic.contains("+") &&
        topic.utf8.count <= 65_535
    }

    static func matches(_ filter: String, topic: String) -> Bool {
        guard isValid(filter), isValidTopicName(topic) else {
            return false
        }

        let filterLevels = split(filter)
        let topicLevels = split(topic)

        if topic.hasPrefix("$"),
           let first = filterLevels.first,
           first == "#" || first == "+" {
            return false
        }

        var filterIndex = 0
        var topicIndex = 0

        while filterIndex < filterLevels.count {
            let filterLevel = filterLevels[filterIndex]

            if filterLevel == "#" {
                return true
            }

            guard topicIndex < topicLevels.count else {
                return false
            }

            if filterLevel != "+" && filterLevel != topicLevels[topicIndex] {
                return false
            }

            filterIndex += 1
            topicIndex += 1
        }

        return topicIndex == topicLevels.count
    }

    private static func split(_ value: String) -> [Substring] {
        value.split(separator: "/", omittingEmptySubsequences: false)
    }
}
