import Foundation

actor UsageDataService {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func fetchUsage(token: String) async throws -> UsageData {
        var request = URLRequest(url: Self.endpoint)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.apiUnreachable(lastSuccess: nil)
        }

        switch http.statusCode {
        case 200:
            do {
                return try Self.decode(data)
            } catch {
                throw AppError.apiError(statusCode: 200)  // 200 OK but response was malformed
            }
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
