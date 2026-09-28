import Foundation
import Combine

/// Shared across displays so returning from a HUD doesn't clear or refetch the quota.
@MainActor
final class CodexQuotaActivityModel: ObservableObject {
    static let shared = CodexQuotaActivityModel()

    @Published private(set) var sessionLimit: UsageLimit?
    @Published private(set) var weekLimit: UsageLimit?
    @Published private(set) var hasRefreshed = false

    private let client: CodexQuotaClient
    private var lastRefresh: Date = .distantPast
    private var isRefreshing = false

    init(client: CodexQuotaClient = CodexQuotaClient()) {
        self.client = client
    }

    func refreshIfNeeded(now: Date = Date()) {
        guard !isRefreshing, now.timeIntervalSince(lastRefresh) >= 60 else { return }
        lastRefresh = now
        isRefreshing = true
        // Finish an in-flight request even if another activity temporarily replaces the view.
        Task {
            let limits = await client.fetchLimits()
            sessionLimit = limits.session
            weekLimit = limits.week
            hasRefreshed = true
            isRefreshing = false
        }
    }
}
