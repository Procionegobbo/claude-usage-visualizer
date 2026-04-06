import Foundation

actor UsageDataService {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    func fetchUsage(token: String) async throws -> UsageData {
        var request = URLRequest(url: Self.endpoint)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await URLSession.shared.data(for: request)
        // URLSession always returns HTTPURLResponse for HTTP/HTTPS requests
        let http = response as! HTTPURLResponse

        switch http.statusCode {
        case 200:
            return try Self.decode(data)
        case 401, 403:
            throw AppError.tokenExpired
        default:
            throw AppError.apiError(statusCode: http.statusCode)
        }
    }

    // Internal — accessible via @testable import for unit testing the parse logic.
    static func decode(_ data: Data) throws -> UsageData {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = ISO8601DateFormatter.anthropicApiDate.date(from: string) {
                return date
            }
            if let date = ISO8601DateFormatter.anthropicApiFallback.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(string)"
            )
        }
        let response = try decoder.decode(UsageResponse.self, from: data)
        return UsageData(
            fiveHour: UsageWindow(
                utilization: response.fiveHour.utilization,
                resetsAt: response.fiveHour.resetsAt
            ),
            sevenDay: UsageWindow(
                utilization: response.sevenDay.utilization,
                resetsAt: response.sevenDay.resetsAt
            ),
            fetchedAt: Date()
        )
    }
}

// MARK: - Private response schema

private struct UsageResponse: Decodable {
    let fiveHour: Window
    let sevenDay: Window

    struct Window: Decodable {
        let utilization: Double
        let resetsAt: Date?
    }
}
