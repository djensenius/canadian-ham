public enum OrdinalSort {
    public static func compare(_ lhs: String, _ rhs: String) -> Int {
        var left = lhs.utf8.makeIterator()
        var right = rhs.utf8.makeIterator()
        while true {
            let a = left.next()
            let b = right.next()
            switch (a, b) {
            case let (x?, y?):
                if x < y { return -1 }
                if x > y { return 1 }
            case (nil, nil):
                return 0
            case (nil, _?):
                return -1
            case (_?, nil):
                return 1
            }
        }
    }

    public static func ascending(_ lhs: String, _ rhs: String) -> Bool {
        compare(lhs, rhs) < 0
    }
}

extension Array where Element == String {
    package func sortedOrdinal() -> [String] {
        sorted(by: OrdinalSort.ascending)
    }
}
