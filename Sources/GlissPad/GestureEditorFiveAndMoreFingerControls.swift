import AppKit
import GlissPadCore

@MainActor
final class FiveAndMoreFingerGestureControls {
    let touchEventPopup = NSPopUpButton()
    let palmDetectionModePopup = NSPopUpButton()

    let touchStableField = FormFactory.textField()
    let wholeHandNominalCountField = FormFactory.textField()
    let wholeHandMinimumCountField = FormFactory.textField()
    let wholeHandMaximumCountField = FormFactory.textField()
    let wholeHandTotalAreaField = FormFactory.textField()
    let wholeHandAverageAreaField = FormFactory.textField()
    let wholeHandMinimumTapField = FormFactory.textField()
    let wholeHandMaximumTapField = FormFactory.textField()
    let wholeHandMovementField = FormFactory.textField()

    let requireLargeAreaButton = NSButton(checkboxWithTitle: "Require large contact area", target: nil, action: nil)
    let requirePalmLikeButton = NSButton(checkboxWithTitle: "Require palm-like contact", target: nil, action: nil)
}

@MainActor
extension GestureEditorWindowController {
    func configureFiveAndMoreFingerControls() {
        configure(fiveAndMoreFingerControls.touchEventPopup, values: FiveFingerTouchEvent.allCases)
        configure(fiveAndMoreFingerControls.palmDetectionModePopup, values: WholeHandPalmDetectionMode.allCases)
        configureFiveAndMoreFingerCheckBoxes()
    }

    private func configureFiveAndMoreFingerCheckBoxes() {
        [
            fiveAndMoreFingerControls.requireLargeAreaButton,
            fiveAndMoreFingerControls.requirePalmLikeButton
        ].forEach {
            $0.controlSize = .large
            $0.target = self
            $0.action = #selector(configurationControlChanged(_:))
        }
    }
}

extension FiveFingerTouchEvent: DisplayNamed {}
extension WholeHandPalmDetectionMode: DisplayNamed {}
