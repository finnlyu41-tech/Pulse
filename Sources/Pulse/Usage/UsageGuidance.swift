import Foundation

/// Conservative, actionable guidance derived only from provider-reported limits.
/// Strong advice is reserved for cases where the evidence is unambiguous.
enum UsageGuidance {
    enum Status: Equatable, Sendable {
        case useNow
        case normal
        case preserve

        var title: String {
            switch self {
            case .useNow: .localized("Use now")
            case .normal: .localized("Normal")
            case .preserve: .localized("Preserve")
            }
        }
    }

    struct Reading: Equatable, Sendable {
        let status: Status
        let message: String
    }

    static func reading(for usage: ProviderUsage, now: Date = Date()) -> Reading? {
        guard case .live = usage.state, !usage.windows.isEmpty else { return nil }

        if usage.windows.contains(where: { shouldPreserve($0, now: now) }) {
            return Reading(
                status: .preserve,
                message: .localized("Keep this capacity for work that needs it most.")
            )
        }

        if usage.windows.contains(where: { shouldUseNow($0, now: now) }) {
            return Reading(
                status: .useNow,
                message: .localized("Use this capacity before the current window resets.")
            )
        }

        return Reading(
            status: .normal,
            message: .localized("No quota action is needed right now.")
        )
    }

    private static func shouldPreserve(_ window: UsageWindow, now: Date) -> Bool {
        if let burn = BurnRate.reading(for: window, now: now), burn.exhaustsBeforeReset {
            return true
        }
        guard !window.isExhausted else { return true }
        return window.remainingFraction <= 0.20
    }

    private static func shouldUseNow(_ window: UsageWindow, now: Date) -> Bool {
        guard !window.isExhausted,
              window.remainingFraction >= 0.40,
              let reset = window.resetsAt
        else { return false }

        let untilReset = reset.timeIntervalSince(now)
        return untilReset > 0 && untilReset <= 2 * 3600
    }
}
