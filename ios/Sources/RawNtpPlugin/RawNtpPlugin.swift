import Foundation
import Capacitor
import Network

@objc(RawNtpPlugin)
public class RawNtpPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "RawNtpPlugin"
    public let jsName = "RawNtp"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "request", returnType: CAPPluginReturnPromise)
    ]

    private let queue = DispatchQueue(label: "rawntp.udp")

    @objc func request(_ call: CAPPluginCall) {
        let host = call.getString("host") ?? "pool.ntp.org"
        let port = call.getInt("port") ?? 123
        let timeoutMs = call.getInt("timeout") ?? 5000

        var payload: Data
        if let custom = call.getString("requestPacket") {
            guard let decoded = Data(base64Encoded: custom) else {
                call.reject("requestPacket is not valid base64", "BAD_INPUT")
                return
            }
            payload = decoded
        } else {
            payload = Data(count: 48)
            payload[0] = 0x1B // LI=0, VN=3, Mode=3 (client)
        }

        guard (1...65535).contains(port), let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            call.reject("Invalid port", "BAD_INPUT")
            return
        }

        let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .udp)
        let once = OnceFlag()

        // Everything below runs on `queue`, so OnceFlag needs no lock.
        let finish: (() -> Void) -> Void = { action in
            guard once.claim() else { return }
            connection.stateUpdateHandler = nil
            connection.cancel()
            action()
        }

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let t1Mono = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
                let t1 = Date().timeIntervalSince1970 * 1000
                connection.send(content: payload, completion: .contentProcessed { sendError in
                    if let sendError = sendError {
                        finish { call.reject("Send failed: \(sendError)", "IO") }
                        return
                    }
                    connection.receiveMessage { data, _, _, recvError in
                        let t4Mono = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
                        let t4 = Date().timeIntervalSince1970 * 1000
                        if let recvError = recvError {
                            finish { call.reject("Receive failed: \(recvError)", "IO") }
                            return
                        }
                        guard let data = data, !data.isEmpty else {
                            finish { call.reject("Empty response", "IO") }
                            return
                        }
                        var address = host
                        if let endpoint = connection.currentPath?.remoteEndpoint,
                           case let .hostPort(remoteHost, _) = endpoint {
                            address = "\(remoteHost)"
                        }
                        finish {
                            call.resolve([
                                "packet": data.base64EncodedString(),
                                "address": address,
                                "t1": t1,
                                "t4": t4,
                                "t1Mono": Int(t1Mono),
                                "t4Mono": Int(t4Mono)
                            ])
                        }
                    }
                })
            case .waiting(let error):
                finish { call.reject("Network unavailable or DNS failed: \(error)", "IO") }
            case .failed(let error):
                finish { call.reject("Connection failed: \(error)", "IO") }
            default:
                break
            }
        }

        connection.start(queue: queue)

        queue.asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
            finish { call.reject("Timed out waiting for NTP response", "TIMEOUT") }
        }
    }
}

private final class OnceFlag {
    private var done = false
    func claim() -> Bool {
        if done { return false }
        done = true
        return true
    }
}
