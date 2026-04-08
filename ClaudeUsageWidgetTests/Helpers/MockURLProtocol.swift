import Foundation

/// Intercepts URLSession requests and returns configured mock responses.
///
/// Each `makeSession(...)` call creates an isolated session whose handler is keyed by a UUID
/// stored in a request header. This prevents cross-test contamination when tests run in parallel.
///
/// Usage:
///   let session = MockURLProtocol.makeSession(statusCode: 200, data: someData)
///   let service = UsageDataService(urlSession: session)
final class MockURLProtocol: URLProtocol {
    // Session-keyed providers — safe for parallel test execution.
    private static let lock = NSLock()
    private nonisolated(unsafe) static var providers: [String: (URLRequest) throws -> (Data, HTTPURLResponse)] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: "X-Mock-Key") != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let key = request.value(forHTTPHeaderField: "X-Mock-Key") else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let provider = Self.lock.withLock { Self.providers[key] }
        guard let provider else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (data, response) = try provider(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    // MARK: - Factory methods

    /// Creates a URLSession that returns a fixed HTTP response.
    static func makeSession(
        statusCode: Int,
        data: Data,
        url: URL = URL(string: "https://api.anthropic.com/api/oauth/usage") ?? URL(fileURLWithPath: "/")
    ) -> URLSession {
        let key = UUID().uuidString
        lock.withLock {
            providers[key] = { _ in
                guard let response = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                ) else {
                    throw URLError(.badServerResponse)
                }
                return (data, response)
            }
        }
        return makeSession(key: key)
    }

    /// Creates a URLSession that throws a URLError.
    static func makeSession(error: URLError) -> URLSession {
        let key = UUID().uuidString
        lock.withLock {
            providers[key] = { _ in throw error }
        }
        return makeSession(key: key)
    }

    /// Clears all registered mock providers. Call at the end of tests to prevent unbounded memory growth.
    static func clearAllProviders() {
        lock.withLock {
            providers.removeAll()
        }
    }

    // MARK: - Private

    private static func makeSession(key: String) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.httpAdditionalHeaders = ["X-Mock-Key": key]
        return URLSession(configuration: config)
    }
}
