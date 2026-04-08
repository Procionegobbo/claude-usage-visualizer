import Testing
import Foundation
@testable import ClaudeUsageWidget

// Story 1.3: JSON decoding unit tests for UsageDataService.
// Full mock URLSession tests (HTTP error mapping, network failures) added in Story 3.4.

@Suite("UsageDataService")
struct UsageDataServiceTests {

    // MARK: - Happy path

    @Test("decode valid full response produces correct UsageData")
    func decodeValidFullResponse() throws {
        let json = """
        {
          "five_hour": {
            "utilization": 23.5,
            "resets_at": "2025-11-04T04:59:59.943648+00:00"
          },
          "seven_day": {
            "utilization": 67.0,
            "resets_at": "2025-11-06T03:59:59.943679+00:00"
          },
          "seven_day_oauth_apps": null,
          "seven_day_opus": { "utilization": 0.0, "resets_at": null },
          "iguana_necktie": null
        }
        """.data(using: .utf8)!

        let result = try UsageDataService.decode(json)

        #expect(result.fiveHour.utilization == 23.5)
        #expect(result.sevenDay.utilization == 67.0)
        #expect(result.fiveHour.resetsAt != nil)
        #expect(result.sevenDay.resetsAt != nil)
    }

    @Test("decode response with null resets_at produces nil resetsAt")
    func decodeNullResetsAt() throws {
        let json = """
        {
          "five_hour": { "utilization": 0.0, "resets_at": null },
          "seven_day": { "utilization": 100.0, "resets_at": null }
        }
        """.data(using: .utf8)!

        let result = try UsageDataService.decode(json)

        #expect(result.fiveHour.resetsAt == nil)
        #expect(result.sevenDay.resetsAt == nil)
        #expect(result.fiveHour.utilization == 0.0)
        #expect(result.sevenDay.utilization == 100.0)
    }

    @Test("decode resets_at with fractional seconds parses correctly")
    func decodeFractionalSecondsDate() throws {
        let json = """
        {
          "five_hour": {
            "utilization": 6.0,
            "resets_at": "2025-11-04T04:59:59.943648+00:00"
          },
          "seven_day": {
            "utilization": 35.0,
            "resets_at": "2025-11-06T03:59:59.943679+00:00"
          }
        }
        """.data(using: .utf8)!

        let result = try UsageDataService.decode(json)

        let fiveHourReset = try #require(result.fiveHour.resetsAt)
        // The parsed date should be 2025-11-04T04:59:59 UTC
        let calendar = Calendar(identifier: .gregorian)
        let utcComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: fiveHourReset)
        #expect(utcComponents.year == 2025)
        #expect(utcComponents.month == 11)
        #expect(utcComponents.day == 4)
        #expect(utcComponents.hour == 4)
        #expect(utcComponents.minute == 59)
        #expect(utcComponents.second == 59)
    }

    @Test("decode malformed JSON throws error")
    func decodeMalformedJson() {
        let json = Data("not valid json".utf8)
        #expect(throws: (any Error).self) {
            _ = try UsageDataService.decode(json)
        }
    }

    @Test("decode missing required field throws error")
    func decodeMissingField() {
        // Missing "seven_day"
        let json = """
        {
          "five_hour": { "utilization": 10.0, "resets_at": null }
        }
        """.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            _ = try UsageDataService.decode(json)
        }
    }
}

// MARK: - HTTP error mapping (mock URLSession)

@Suite("UsageDataService — HTTP error mapping")
struct UsageDataServiceHTTPTests {

    @Test("malformed JSON returns apiError(statusCode: 200)")
    func malformedJsonMapsToApiError() async throws {
        let service = UsageDataService(urlSession: MockURLProtocol.makeSession(statusCode: 200, data: Data("not json".utf8)))
        await #expect(throws: AppError.apiError(statusCode: 200)) {
            _ = try await service.fetchUsage(token: "sk-ant-test")
        }
    }

    @Test("HTTP 401 throws tokenExpired")
    func http401ThrowsTokenExpired() async throws {
        let service = UsageDataService(urlSession: MockURLProtocol.makeSession(statusCode: 401, data: Data()))
        await #expect(throws: AppError.tokenExpired) {
            _ = try await service.fetchUsage(token: "sk-ant-test")
        }
    }

    @Test("HTTP 403 throws tokenExpired")
    func http403ThrowsTokenExpired() async throws {
        let service = UsageDataService(urlSession: MockURLProtocol.makeSession(statusCode: 403, data: Data()))
        await #expect(throws: AppError.tokenExpired) {
            _ = try await service.fetchUsage(token: "sk-ant-test")
        }
    }

    @Test("HTTP 503 throws apiError(statusCode: 503)")
    func http503ThrowsApiError() async throws {
        let service = UsageDataService(urlSession: MockURLProtocol.makeSession(statusCode: 503, data: Data()))
        await #expect(throws: AppError.apiError(statusCode: 503)) {
            _ = try await service.fetchUsage(token: "sk-ant-test")
        }
    }

    @Test("network timeout throws non-AppError (caught upstream as apiUnreachable)")
    func networkTimeoutThrowsURLError() async throws {
        let service = UsageDataService(urlSession: MockURLProtocol.makeSession(error: URLError(.timedOut)))
        await #expect(throws: URLError.self) {
            _ = try await service.fetchUsage(token: "sk-ant-test")
        }
    }
}
