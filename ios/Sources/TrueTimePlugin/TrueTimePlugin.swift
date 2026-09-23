import Capacitor
import Foundation

@objc(TrueTimePlugin)
public class TrueTimePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "TrueTimePlugin"
    public let jsName = "TrueTime"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getTime", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getImplementationInfo", returnType: CAPPluginReturnPromise)
    ]

    @objc func getTime(_ call: CAPPluginCall) {
        guard let rawHost = call.getString("host") else {
            call.reject("An NTP host is required")
            return
        }

        let host = rawHost.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else {
            call.reject("An NTP host is required")
            return
        }

        let requestedTimeout = call.getInt("timeoutMs") ?? 3_000
        let timeoutMs = min(max(requestedTimeout, 500), 10_000)

        let group = DispatchGroup()
        let lock = NSLock()
        var best: TrueTimeSample?
        var lastError: Error?

        // TrueTime.swift queried each address four times and kept its fastest sample.
        for _ in 0..<4 {
            group.enter()
            SNTPClient(host: host, timeout: Double(timeoutMs) / 1_000) { result in
                lock.lock()
                switch result {
                case .success(let sample):
                    if sample.delay < (best?.delay ?? .infinity) {
                        best = sample
                    }
                case .failure(let error):
                    lastError = error
                }
                lock.unlock()
                group.leave()
            }.start()
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            if let best {
                call.resolve(best.dictionary(host: host))
            } else {
                call.reject(lastError?.localizedDescription ?? "No valid NTP response")
            }
        }
    }

    @objc func getImplementationInfo(_ call: CAPPluginCall) {
        call.resolve(TrueTimeIdentity.dictionary)
    }
}
