import GlissPadCore

struct TipSwipeFixedFingerCountOption: Equatable {
    let value: Int

    static let one = TipSwipeFixedFingerCountOption(value: 1)
    static let two = TipSwipeFixedFingerCountOption(value: 2)
    static let allCases = [one, two]

    var displayName: String {
        value == 1 ? "1 Finger" : "2 Fingers"
    }

    static func option(for value: Int) -> TipSwipeFixedFingerCountOption {
        allCases.first { $0.value == value } ?? .two
    }
}

extension TipSwipeFixedFingerCountOption: DisplayNamed {}
