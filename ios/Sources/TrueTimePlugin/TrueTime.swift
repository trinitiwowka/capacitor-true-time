import Foundation
import Network

enum TrueTimeIdentity {
    static let implementation = "@trinitiwowka/capacitor-true-time"
    static let version = "1.0.0"
    static let signature = "capacitor-true-time-native-sntp-v1"
    static let protocolName = "SNTPv4"

    static let dictionary: [String: Any] = [
        "implementation": implementation,
        "implementationVersion": version,
        "signature": signature,
        "protocol": protocolName
    ]
}

struct TrueTimeSample {
    let t0: Double
    let t1: Double
    let t2: Double
    let t3: Double
    let delay: Double
    let offset: Double
    let stratum: UInt8
    let leap: UInt8

    func dictionary(host: String) -> [String: Any] {
        var result = TrueTimeIdentity.dictionary
        result.merge([
            "callback": t3 + offset,
            "t0": t0,
            "t1": t1,
            "t2": t2,
            "t3": t3,
            "delay": delay,
            "offset": offset,
            "host": host,
            "stratum": Int(stratum),
            "leap": Int(leap)
        ]) { _, new in new }
        return result
    }
}

enum SNTPError: LocalizedError {
    case connection(String)
    case timeout
    case malformed(String)

    var errorDescription: String? {
        switch self {
        case .connection(let message):
            return "NTP connection failed: \(message)"
        case .timeout:
            return "NTP request timed out"
        case .malformed(let message):
            return "Invalid NTP response: \(message)"
        }
    }
}

final class SNTPClient {
    static let ntpEpochOffset = 2_208_988_800.0
    static let fractionScale = 4_294_967_296.0

    private let queue = DispatchQueue(label: "io.github.trinitiwowka.capacitortruetime.sntp")
    private let connection: NWConnection
    private let timeout: TimeInterval
    private var completion: ((Result<TrueTimeSample, Error>) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?
    private var hasSent = false
    private var hasFinished = false

    init(host: String, timeout: TimeInterval, completion: @escaping (Result<TrueTimeSample, Error>) -> Void) {
        self.timeout = timeout
        self.completion = completion
        self.connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: 123,
            using: .udp
        )
    }

    func start() {
        let timeoutWorkItem = DispatchWorkItem { [self] in
            finish(.failure(SNTPError.timeout))
        }
        self.timeoutWorkItem = timeoutWorkItem
        queue.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        connection.stateUpdateHandler = { [self] state in
            switch state {
            case .ready:
                sendRequest()
            case .failed(let error):
                finish(.failure(SNTPError.connection(error.localizedDescription)))
            case .cancelled:
                break
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func sendRequest() {
        guard !hasSent else { return }
        hasSent = true

        let requestUptime = ProcessInfo.processInfo.systemUptime
        let request = Self.makeRequest(date: Date())
        let t0 = Self.readTimestamp(request, offset: 40)

        connection.receiveMessage { [self] data, _, _, error in
            if let error {
                finish(.failure(SNTPError.connection(error.localizedDescription)))
                return
            }
            guard let data else {
                finish(.failure(SNTPError.malformed("empty packet")))
                return
            }

            let elapsedMs = (ProcessInfo.processInfo.systemUptime - requestUptime) * 1_000
            let t3 = t0 + elapsedMs
            do {
                let sample = try Self.parseResponse(request: request, response: data, t0: t0, t3: t3)
                finish(.success(sample))
            } catch {
                finish(.failure(error))
            }
        }

        connection.send(content: request, completion: .contentProcessed { [self] error in
            if let error {
                finish(.failure(SNTPError.connection(error.localizedDescription)))
            }
        })
    }

    private func finish(_ result: Result<TrueTimeSample, Error>) {
        guard !hasFinished else { return }
        hasFinished = true
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        connection.stateUpdateHandler = nil
        connection.cancel()
        let callback = completion
        completion = nil
        callback?(result)
    }

    static func makeRequest(date: Date) -> Data {
        var bytes = [UInt8](repeating: 0, count: 48)
        bytes[0] = 0x23 // leap 0, SNTP version 4, client mode 3
        writeTimestamp(date.timeIntervalSince1970 * 1_000, into: &bytes, offset: 40)
        return Data(bytes)
    }

    static func parseResponse(request: Data, response: Data, t0: Double, t3: Double) throws -> TrueTimeSample {
        guard response.count >= 48 else {
            throw SNTPError.malformed("packet is shorter than 48 bytes")
        }

        let bytes = [UInt8](response)
        let leap = bytes[0] >> 6
        let version = (bytes[0] >> 3) & 0x07
        let mode = bytes[0] & 0x07
        let stratum = bytes[1]

        guard leap != 3 else {
            throw SNTPError.malformed("server clock is unsynchronized")
        }
        guard version >= 3 && version <= 4 else {
            throw SNTPError.malformed("unsupported protocol version")
        }
        guard mode == 4 else {
            throw SNTPError.malformed("response is not in server mode")
        }
        guard stratum >= 1 && stratum <= 15 else {
            throw SNTPError.malformed("invalid stratum")
        }

        let requestBytes = [UInt8](request)
        guard Array(bytes[24..<32]) == Array(requestBytes[40..<48]) else {
            throw SNTPError.malformed("origin timestamp does not match the request")
        }

        let t1 = readTimestamp(response, offset: 32)
        let t2 = readTimestamp(response, offset: 40)
        guard t1 > 0 && t2 > 0 else {
            throw SNTPError.malformed("server timestamps are missing")
        }

        let rawDelay = (t3 - t0) - (t2 - t1)
        guard rawDelay >= -1_000 && rawDelay <= 10_000 else {
            throw SNTPError.malformed("round-trip delay is outside the accepted range")
        }
        let delay = max(0, rawDelay)
        let offset = ((t1 - t0) + (t2 - t3)) / 2

        return TrueTimeSample(
            t0: t0,
            t1: t1,
            t2: t2,
            t3: t3,
            delay: delay,
            offset: offset,
            stratum: stratum,
            leap: leap
        )
    }

    static func writeTimestamp(_ unixMs: Double, into bytes: inout [UInt8], offset: Int) {
        let ntpSeconds = unixMs / 1_000 + ntpEpochOffset
        let seconds = UInt32(ntpSeconds.rounded(.down))
        let fraction = UInt32((ntpSeconds - ntpSeconds.rounded(.down)) * fractionScale)
        writeUInt32(seconds, into: &bytes, offset: offset)
        writeUInt32(fraction, into: &bytes, offset: offset + 4)
    }

    static func readTimestamp(_ data: Data, offset: Int) -> Double {
        let bytes = [UInt8](data)
        let seconds = readUInt32(bytes, offset: offset)
        let fraction = readUInt32(bytes, offset: offset + 4)
        return (Double(seconds) - ntpEpochOffset + Double(fraction) / fractionScale) * 1_000
    }

    private static func writeUInt32(_ value: UInt32, into bytes: inout [UInt8], offset: Int) {
        bytes[offset] = UInt8((value >> 24) & 0xff)
        bytes[offset + 1] = UInt8((value >> 16) & 0xff)
        bytes[offset + 2] = UInt8((value >> 8) & 0xff)
        bytes[offset + 3] = UInt8(value & 0xff)
    }

    private static func readUInt32(_ bytes: [UInt8], offset: Int) -> UInt32 {
        (UInt32(bytes[offset]) << 24)
            | (UInt32(bytes[offset + 1]) << 16)
            | (UInt32(bytes[offset + 2]) << 8)
            | UInt32(bytes[offset + 3])
    }
}
