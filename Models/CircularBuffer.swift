struct CircularBuffer<Element>: RandomAccessCollection {
    typealias Index = Int

    private var storage: [Element?]
    private var head = 0
    private(set) var count = 0
    let capacity: Int

    init(maxSize: Int = 1000) {
        precondition(maxSize > 0)
        capacity = maxSize
        storage = Array(repeating: nil, count: maxSize)
    }

    var startIndex: Int { 0 }
    var endIndex: Int { count }

    subscript(position: Int) -> Element {
        precondition(position >= 0 && position < count)
        return storage[(head + position) % capacity]!
    }

    func index(after i: Int) -> Int { i + 1 }
    func index(before i: Int) -> Int { i - 1 }

    mutating func append(_ element: Element) {
        if count < capacity {
            storage[(head + count) % capacity] = element
            count += 1
        } else {
            storage[head] = element
            head = (head + 1) % capacity
        }
    }

    mutating func removeFirst() {
        guard count > 0 else { return }
        storage[head] = nil
        head = (head + 1) % capacity
        count -= 1
        if count == 0 {
            head = 0
        }
    }

    mutating func removeAll(where shouldRemove: (Element) -> Bool) {
        let kept = filter { !shouldRemove($0) }
        clear()
        for element in kept {
            append(element)
        }
    }

    mutating func clear() {
        storage = Array(repeating: nil, count: capacity)
        head = 0
        count = 0
    }

    var last: Element? {
        guard count > 0 else { return nil }
        return self[count - 1]
    }
}

extension CircularBuffer: Equatable where Element: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        Array(lhs) == Array(rhs)
    }
}
