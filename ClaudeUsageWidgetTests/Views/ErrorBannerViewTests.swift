import Testing
import Foundation
@testable import ClaudeUsageWidget

@Suite("ErrorBannerView")
struct ErrorBannerViewTests {

    // MARK: - AppError.errorDescription (via LocalizedError)

    @Test("tokenMissing description contains 'Install Claude Code'")
    func tokenMissingDescription() {
        #expect(AppError.tokenMissing.errorDescription?.contains("Install Claude Code") == true)
    }

    @Test("tokenExpired description contains 'expired'")
    func tokenExpiredDescription() {
        #expect(AppError.tokenExpired.errorDescription?.contains("expired") == true)
    }

    @Test("apiUnreachable(nil) description contains 'Will retry'")
    func apiUnreachableNilDescription() {
        #expect(AppError.apiUnreachable(lastSuccess: nil).errorDescription?.contains("Will retry") == true)
    }

    @Test("apiUnreachable(Date()) description contains 'minutes ago'")
    func apiUnreachableDateDescription() {
        let recentDate = Date(timeIntervalSinceNow: -1800) // 30 min ago
        #expect(AppError.apiUnreachable(lastSuccess: recentDate).errorDescription?.contains("minutes ago") == true)
    }

    @Test("apiError(503) description contains '503'")
    func apiErrorDescription() {
        #expect(AppError.apiError(statusCode: 503).errorDescription?.contains("503") == true)
    }

    // MARK: - ErrorBannerView.lastUpdatedText

    @Test("nil date returns empty string")
    func lastUpdatedTextNil() {
        #expect(ErrorBannerView.lastUpdatedText(from: nil) == "")
    }

    @Test("30 minutes ago returns text containing '30 minutes ago'")
    func lastUpdatedText30MinAgo() {
        let now = Date.now
        let thirtyMinAgo = now.addingTimeInterval(-30 * 60)
        let text = ErrorBannerView.lastUpdatedText(from: thirtyMinAgo, relativeTo: now)
        #expect(text.contains("30 minutes ago"))
    }

    @Test("1 minute ago uses singular 'minute'")
    func lastUpdatedText1MinAgo() {
        let now = Date.now
        let oneMinAgo = now.addingTimeInterval(-60)
        let text = ErrorBannerView.lastUpdatedText(from: oneMinAgo, relativeTo: now)
        #expect(text.contains("1 minute ago"))
        #expect(!text.contains("1 minutes ago"))
    }

    @Test("0 minutes ago (truncated) uses plural form correctly")
    func lastUpdatedText0MinAgo() {
        let now = Date.now
        let thirtySecondsAgo = now.addingTimeInterval(-30)
        let text = ErrorBannerView.lastUpdatedText(from: thirtySecondsAgo, relativeTo: now)
        #expect(text.contains("0 minutes ago"))
    }

    @Test("future date (clock skew) clamps to 0 minutes")
    func lastUpdatedTextFutureDate() {
        let now = Date.now
        let futureDate = now.addingTimeInterval(3600) // 1 hour in future
        let text = ErrorBannerView.lastUpdatedText(from: futureDate, relativeTo: now)
        #expect(text.contains("0 minutes ago"))
        #expect(!text.contains("-"))
    }
}
