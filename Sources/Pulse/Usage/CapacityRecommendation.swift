import Foundation

/// Cross-provider recommendation for this fork's two visible providers.
/// It compares quota state only, not model quality.
enum CapacityRecommendation {
    enum Choice: Equatable, Sendable {
        case codex
        case claude
        case either

        var message: String {
            switch self {
            case .codex: .localized("Prefer Codex right now.")
            case .claude: .localized("Prefer Claude right now.")
            case .either: .localized("Either provider is fine right now.")
            }
        }
    }

    struct Reading: Equatable, Sendable {
        let choice: Choice
    }
    /// Compare primary accounts only. Extra accounts do not silently change
    /// the app-wide recommendation.
    static func reading(codex: ProviderUsage, claude: ProviderUsage, now: Date = Date()) -> Reading? {
        guard let codexGuidance = UsageGuidance.reading(for: codex, now: now),
              let claudeGuidance = UsageGuidance.reading(for: claude, now: now)
        else { return nil }

        let codexPriority = priority(codexGuidance.status)
        let claudePriority = priority(claudeGuidance.status)
        if codexPriority > claudePriority { return Reading(choice: .codex) }
        if claudePriority > codexPriority { return Reading(choice: .claude) }
        return Reading(choice: .either)
    }

    private static func priority(_ status: UsageGuidance.Status) -> Int {
        switch status {
        case .useNow: 2
        case .normal: 1
        case .preserve: 0
        }
    }
}
