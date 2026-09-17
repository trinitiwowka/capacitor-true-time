import XCTest
@testable import TrueTimePlugin

final class TrueTimeTests: XCTestCase {
    func testParsesFourTimestampSample() throws {
        let t0 = 1_700_000_000_000.0
        let t1 = t0 + 12
        let t2 = t0 + 14
        let t3 = t0 + 26
        let request = request(at: t0)
        let response = validResponse(for: request, t1: t1, t2: t2)

        let sample = try SNTPClient.parseResponse(request: request, response: response, t0: t0, t3: t3)

        XCTAssertEqual(sample.delay, 24, accuracy: 0.01)
        XCTAssertEqual(sample.offset, 0, accuracy: 0.01)
        XCTAssertEqual(sample.stratum, 2)
        XCTAssertEqual(sample.t3 + sample.offset, t3, accuracy: 0.01)
    }

    func testRejectsResponseForAnotherRequest() {
        let t0 = 1_700_000_000_000.0
        let request = request(at: t0)
        let otherRequest = self.request(at: t0 + 1_000)
        let response = validResponse(for: otherRequest, t1: t0 + 12, t2: t0 + 14)

        XCTAssertThrowsError(
            try SNTPClient.parseResponse(request: request, response: response, t0: t0, t3: t0 + 26)
        )
    }

    func testRejectsUnsynchronizedServer() {
        let t0 = 1_700_000_000_000.0
        let request = request(at: t0)
        var response = validResponse(for: request, t1: t0 + 12, t2: t0 + 14)
        response[0] = 0xe4

        XCTAssertThrowsError(
            try SNTPClient.parseResponse(request: request, response: response, t0: t0, t3: t0 + 26)
        )
    }

    private func request(at unixMs: Double) -> Data {
        SNTPClient.makeRequest(date: Date(timeIntervalSince1970: unixMs / 1_000))
    }

    private func validResponse(for request: Data, t1: Double, t2: Double) -> Data {
        var bytes = [UInt8](repeating: 0, count: 48)
        bytes[0] = 0x24 // leap 0, version 4, server mode 4
        bytes[1] = 2
        let requestBytes = [UInt8](request)
        bytes.replaceSubrange(24..<32, with: requestBytes[40..<48])
        SNTPClient.writeTimestamp(t1, into: &bytes, offset: 32)
        SNTPClient.writeTimestamp(t2, into: &bytes, offset: 40)
        return Data(bytes)
    }
}
