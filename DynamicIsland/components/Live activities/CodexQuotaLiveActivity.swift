import SwiftUI
import AppKit

struct CodexQuotaLiveActivity: View {
    @ObservedObject var model = CodexQuotaActivityModel.shared
    let closedNotchWidth: CGFloat
    let height: CGFloat
    let availableWidth: CGFloat

    private var wingWidth: CGFloat {
        min(116, max(0, (availableWidth - closedNotchWidth) / 2))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            HStack(spacing: 0) {
                quota("Codex · 5h", limit: model.sessionLimit, now: context.date)
                Color.clear.frame(width: closedNotchWidth)
                quota("Week", limit: model.weekLimit, now: context.date)
            }
            .frame(height: height)
        }
        .accessibilityIdentifier("CodexQuotaLiveActivity")
        .task {
            while !Task.isCancelled {
                model.refreshIfNeeded()
                do { try await Task.sleep(for: .seconds(60)) }
                catch { return }
            }
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
            model.refreshIfNeeded()
        }
    }

    private func quota(_ title: String, limit: UsageLimit?, now: Date) -> some View {
        VStack(spacing: 1) {
            HStack(spacing: 4) {
                Text(wingWidth < 105 && title == "Codex · 5h" ? "5h" : title)
                    .foregroundStyle(.secondary)
                if let limit {
                    Text("\(Int(min(100, max(0, 100 - limit.used)).rounded()))% left")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .font(.system(size: 11))
            Text(resetText(limit, now: now))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .frame(width: wingWidth)
        .help("\(title) — remaining Codex quota; ↻ reset time")
    }

    private func resetText(_ limit: UsageLimit?, now: Date) -> String {
        guard let limit else { return model.hasRefreshed ? "Unavailable" : "Loading…" }
        guard let reset = limit.resetsAt else { return "Reset unavailable" }
        guard reset > now else { return "Reset pending…" }
        return "↻ " + reset.formatted(.dateTime.month(.twoDigits).day(.twoDigits).hour().minute())
    }
}
