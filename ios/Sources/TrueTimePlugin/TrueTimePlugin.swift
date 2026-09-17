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

        SNTPClient(host: host, timeout: Double(timeoutMs) / 1_000) { result in
            switch result {
            case .success(let sample):
                call.resolve(sample.dictionary(host: host))
            case .failure(let error):
                call.reject(error.localizedDescription)
            }
        }.start()
    }

    @objc func getImplementationInfo(_ call: CAPPluginCall) {
        call.resolve(TrueTimeIdentity.dictionary)
    }
}
