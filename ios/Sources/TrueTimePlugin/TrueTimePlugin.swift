import Capacitor
import Foundation
#if SWIFT_PACKAGE
import TrueTime
#endif

@objc(TrueTimePlugin)
public class TrueTimePlugin: CAPPlugin, CAPBridgedPlugin {
    private var isClientStarted = false
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

        let client = TrueTimeClient.sharedInstance
        if !isClientStarted {
            client.start(pool: [host])
            isClientStarted = true
        }

        let t0 = Date().timeIntervalSince1970 * 1_000
        client.fetchIfNeeded(completion: { result in
            switch result {
            case .success(let referenceTime):
                let serverTime = referenceTime.now().timeIntervalSince1970 * 1_000
                let t3 = Date().timeIntervalSince1970 * 1_000
                var response = TrueTimeIdentity.dictionary
                response.merge([
                    "callback": serverTime,
                    "t0": t0,
                    "t1": serverTime,
                    "t2": serverTime,
                    "t3": t3,
                    "delay": (t3 - t0) / 2,
                    "offset": serverTime - t3,
                    "host": host
                ]) { _, new in new }
                call.resolve(response)
            case .failure(let error):
                call.reject(error.localizedDescription)
            }
        })
    }

    @objc func getImplementationInfo(_ call: CAPPluginCall) {
        call.resolve(TrueTimeIdentity.dictionary)
    }
}
