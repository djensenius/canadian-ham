public let rngAlgorithm = "fnv1a64-pcg32-xsh-rr"

public let RNG_ALGORITHM = rngAlgorithm

private let pcg32Multiplier: UInt64 = 0x5851_f42d_4c95_7f2d
private let defaultInitSeq: UInt64 = 0x1405_7b7e_f767_814f
private let fnv1a64Offset: UInt64 = 0xcbf2_9ce4_8422_2325
private let fnv1a64Prime: UInt64 = 0x0000_0100_0000_01b3
private let two32: UInt64 = 0x1_0000_0000

public struct RngVector: Codable, Equatable, Sendable {
    public let seed: String
    public let first8Uint32: [UInt32]

    public init(seed: String, first8Uint32: [UInt32]) {
        self.seed = seed
        self.first8Uint32 = first8Uint32
    }
}

public func fnv1a64Utf8(_ seed: String) -> UInt64 {
    var hash = fnv1a64Offset
    for byte in seed.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* fnv1a64Prime
    }
    return hash
}

public struct Pcg32: Sendable {
    private var state: UInt64 = 0
    private var inc: UInt64 = 0

    public init(initstate: UInt64) {
        self.init(initstate: initstate, initseq: defaultInitSeq)
    }

    public init(initstate: UInt64, initseq: UInt64) {
        srandom(initstate: initstate, initseq: initseq)
    }

    public init(seed: String) {
        self.init(initstate: fnv1a64Utf8(seed), initseq: defaultInitSeq)
    }

    public mutating func srandom(initstate: UInt64, initseq: UInt64) {
        state = 0
        inc = (initseq << 1) | 1
        _ = nextUint32()
        state = state &+ initstate
        _ = nextUint32()
    }

    public mutating func nextUint32() -> UInt32 {
        let oldstate = state
        state = oldstate &* pcg32Multiplier &+ inc
        let xorshifted = UInt32(truncatingIfNeeded: (((oldstate >> 18) ^ oldstate) >> 27))
        let rot = UInt32(oldstate >> 59) & 31
        return (xorshifted >> rot) | (xorshifted << ((0 &- rot) & 31))
    }

    public mutating func bounded(_ n: Int) throws -> Int {
        guard n >= 1 else {
            throw EngineError("bounded(n) requires an integer where 1 <= n <= 2^32; received \(n)")
        }
        let divisor = UInt64(n)
        guard divisor <= two32 else {
            throw EngineError("bounded(n) requires an integer where 1 <= n <= 2^32; received \(n)")
        }
        let threshold = (two32 &- divisor) % divisor
        while true {
            let r = UInt64(nextUint32())
            if r >= threshold {
                return Int(r % divisor)
            }
        }
    }
}

public func firstUint32Values(seed: String, count: Int) throws -> [UInt32] {
    guard count >= 0 else {
        throw EngineError("count must be a non-negative integer; received \(count)")
    }
    var rng = Pcg32(seed: seed)
    return (0..<count).map { _ in rng.nextUint32() }
}

public func pcg32DemoValues() -> [UInt32] {
    var rng = Pcg32(initstate: 42, initseq: 54)
    return (0..<6).map { _ in rng.nextUint32() }
}

public func shuffled<T: Sendable>(_ values: [T], rng: inout Pcg32) throws -> [T] {
    var output = values
    guard output.count > 1 else { return output }
    var index = output.count - 1
    while index >= 1 {
        let selected = try rng.bounded(index + 1)
        output.swapAt(index, selected)
        index -= 1
    }
    return output
}
