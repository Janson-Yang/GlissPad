import Foundation

struct ForcePressProgress: Equatable {
    private(set) var startedAt: TimeInterval?

    mutating func update(
        timestamp: TimeInterval,
        pressure: Double,
        activationThreshold: Double,
        sustainingThreshold: Double,
        clickSatisfied: Bool
    ) {
        if startedAt != nil {
            if pressure < sustainingThreshold {
                startedAt = nil
            }
            return
        }
        guard clickSatisfied, pressure >= activationThreshold else { return }
        startedAt = timestamp
    }

    func isSatisfied(at timestamp: TimeInterval, minimumMilliseconds: Int) -> Bool {
        guard let startedAt else { return false }
        return timestamp - startedAt >= TimeInterval(minimumMilliseconds) / 1000
    }
}
