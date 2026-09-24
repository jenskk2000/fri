import Foundation

/// Where the current streak sits on the path the app is built around: the critical first
/// 14 days, then consolidation (1 and 3 months), then maintenance (6 months, then yearly).
struct QuitPhase: Equatable {
    enum Stage: Equatable { case critical, consolidation, maintenance }

    static let targets = [14, 30, 90, 180, 365]
    private static let day: TimeInterval = 86400

    let elapsed: TimeInterval
    let previousTargetDays: Int
    let targetDays: Int

    init(elapsed: TimeInterval) {
        let elapsed = max(0, elapsed)
        let days = elapsed / Self.day
        var previous = 0
        var target = Self.targets.first { Double($0) > days }
        if let found = target {
            previous = Self.targets.last { $0 < found } ?? 0
        } else {
            let years = Int(days / 365) + 1
            target = years * 365
            previous = (years - 1) * 365
        }
        self.elapsed = elapsed
        self.previousTargetDays = previous
        self.targetDays = target!
    }

    var stage: Stage {
        switch targetDays {
        case 14: .critical
        case 30, 90: .consolidation
        default: .maintenance
        }
    }

    /// Progress from the previous target to the next one, 0...1.
    var fraction: Double {
        let span = Double(targetDays - previousTargetDays) * Self.day
        return min(1, max(0, (elapsed - Double(previousTargetDays) * Self.day) / span))
    }

    var daysLeft: Int { Int(ceil((Double(targetDays) * Self.day - elapsed) / Self.day)) }
}

extension Journey {
    /// Nil while the stop date is still ahead.
    func phase(at now: Date) -> QuitPhase? {
        guard quitDate <= now else { return nil }
        return QuitPhase(elapsed: now.timeIntervalSince(streakStart(at: now)))
    }
}
