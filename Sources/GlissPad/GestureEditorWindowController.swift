import AppKit
import GlissPadCore

@MainActor
final class GestureEditorWindowController: NSWindowController, NSWindowDelegate {
    let store: ConfigurationStore
    let logger: Logger
    var configuration: AppConfiguration
    var runtime: GestureRuntime?
    var selectedSlot = GestureSlot(index: 0)
    var selectedAction = ActionSlot(index: 0)
    var inspectorMode: InspectorMode = .trigger
    var actionExecutionStates: [ActionTestKey: ActionExecutionState] = [:]
    var actionTestSessionID = UUID()
    var listenerRefreshRequestID: UUID?
    var isLoadingSelection = false
    var actionPickerPopover: NSPopover?
    var triggerPickerPopover: NSPopover?
    var scriptModeHelpPopover: NSPopover?
    var triggerButtons: [GestureSlot: NSButton] = [:]
    var triggerStatusLights: [GestureSlot: TriggerStatusLightView] = [:]
    var actionButtons: [ActionSlot: NSButton] = [:]
    var actionStatusBadges: [ActionSlot: ActionStatusBadgeView] = [:]
    var didSetInitialSplitPositions = false
    var triggerReorderState: ListReorderState?
    var actionReorderState: ListReorderState?
    var triggerScrollView: StackScrollView?
    var actionScrollView: StackScrollView?
    var allowsWindowCloseForTermination = false

    let splitView = NSSplitView()
    let splitColumnDelegate = SplitColumnDelegate()
    let titleLabel = NSTextField(labelWithString: "")
    let enabledSwitch = NSSwitch()
    let statusLabel = NSTextField(labelWithString: "")
    let activeTriggerLabel = NSTextField(labelWithString: "")
    let actionTypeLabel = NSTextField(labelWithString: "")
    let actionListTitleLabel = NSTextField(labelWithString: "")
    let triggerNameField = FormFactory.textField(width: 180)
    let actionNameField = FormFactory.textField(width: 220)
    let latencySecondsField = FormFactory.textField(width: 90)
    let latencyMillisecondsField = FormFactory.textField(width: 90)
    let testHUDTitleField = FormFactory.textField(width: 220)
    let testHUDDetailField = FormFactory.textField(width: 220)
    let triggerListStack = NSStackView()
    let actionListStack = NSStackView()
    let inspectorStack = NSStackView()
    let requiresClickButton = NSButton(checkboxWithTitle: "Require real click", target: nil, action: nil)
    let pressureField = FormFactory.textField()
    let sustainPressureField = FormFactory.textField()
    let forceMsField = FormFactory.textField()
    let cooldownField = FormFactory.textField()
    let swipeTravelField = FormFactory.textField()
    let swipeEdgeWidthField = FormFactory.textField()
    let holdDurationField = FormFactory.textField()
    let holdMovementField = FormFactory.textField()
    let holdPressKindPopup = NSPopUpButton()
    let holdTriggerTimingPopup = NSPopUpButton()
    let releaseToleranceField = FormFactory.textField()
    let releaseFingerCountPopup = NSPopUpButton()
    let circleDirectionPopup = NSPopUpButton()
    let cornerPresetPopup = NSPopUpButton()
    let cornerClickKindPopup = NSPopUpButton()
    let cornerMovementField = FormFactory.textField()
    let tapDurationField = FormFactory.textField()
    let tapIntervalField = FormFactory.textField()
    let tapMovementField = FormFactory.textField()
    let tipTapStationaryMovementField = FormFactory.textField()
    let transformScaleField = FormFactory.textField()
    let transformRotationField = FormFactory.textField()
    let multiFingerSwipePresetPopup = NSPopUpButton()
    let oneFingerPressKindPopup = NSPopUpButton()
    let oneFingerPressMovementField = FormFactory.textField()
    let pathToleranceField = FormFactory.textField()
    let pathPointListStack = NSStackView()
    let pathEditorView = PathEditorView()
    let drawnPathEditorView = DrawnPathEditorView()
    var pathPointFields: [(x: NSTextField, y: NSTextField)] = []
    let regionFields = (
        minX: FormFactory.textField(width: 48),
        maxX: FormFactory.textField(width: 48),
        minY: FormFactory.textField(width: 48),
        maxY: FormFactory.textField(width: 48)
    )
    let regionSelectionView = RegionSelectionView()
    let swipeStartRegionFields = (
        minX: FormFactory.textField(width: 48),
        maxX: FormFactory.textField(width: 48),
        minY: FormFactory.textField(width: 48),
        maxY: FormFactory.textField(width: 48)
    )
    let swipeEndRegionFields = (
        minX: FormFactory.textField(width: 48),
        maxX: FormFactory.textField(width: 48),
        minY: FormFactory.textField(width: 48),
        maxY: FormFactory.textField(width: 48)
    )
    let swipeStartRegionView = RegionSelectionView()
    let swipeEndRegionView = RegionSelectionView()
    let languagePopup = NSPopUpButton()
    let scriptModeHelpButton = HelpIconButton(symbolName: "exclamationmark.circle")
    let keyboardModePopup = NSPopUpButton()
    let primaryKeyField = KeyCaptureField()
    let secondaryKeyField = KeyCaptureField()
    let keyboardHoldMillisecondsField = FormFactory.textField(width: 90)
    let keyboardPostReleaseDelayField = FormFactory.textField(width: 90)
    let scriptTextView = NSTextView()

    init(store: ConfigurationStore, logger: Logger) {
        self.store = store
        self.logger = logger
        configuration = (try? store.loadOrCreate()) ?? .default
        let metrics = ScreenLayoutMetrics.current(for: nil)
        let window = NSWindow(
            contentRect: metrics.initialWindowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "GlissPad"
        window.delegate = self
        window.minSize = metrics.minimumWindowSize
        LiquidGlassStyle.configure(window)
        window.contentView = makeContentView()
        loadSelectedRule()
        DispatchQueue.main.async { [weak self] in
            self?.setInitialSplitPositionsIfNeeded()
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

}

@MainActor
extension GestureEditorWindowController {
    func refreshSelectionVisuals() {
        titleLabel.stringValue = selectedSlot.trigger(in: configuration) == nil
            ? "No Trigger Selected"
            : selectedSlot.displayName(in: configuration)
        triggerButtons.forEach { slot, button in
            LiquidGlassStyle.configureListButton(button, selected: slot == selectedSlot)
            triggerStatusLights[slot]?.isTriggerEnabled = slot.isEnabled(in: configuration)
            if let button = button as? GlassListItemButton {
                button.itemTitle = slot.displayName(in: configuration)
                button.itemSubtitle = slot.title(in: configuration)
            }
        }
        actionButtons.forEach { action, button in
            LiquidGlassStyle.configureActionButton(button, selected: action == selectedAction && inspectorMode == .action)
            actionStatusBadges[action]?.state = actionExecutionState(for: action)
        }
        updateTriggerEnabledSwitch()
        updateActionListCopy()
    }

    func actionExecutionState(for action: ActionSlot) -> ActionExecutionState {
        guard let key = selectedSlot.actionTestKey(forActionIndex: action.index, in: configuration) else {
            return .idle
        }
        return actionExecutionStates[key] ?? .idle
    }

    func updateActionListCopy() {
        let actions = selectedSlot.actions(in: configuration)
        guard !actions.isEmpty else {
            selectedAction.index = 0
            actionListTitleLabel.stringValue = "No Action Selected"
            return
        }
        selectedAction.index = min(selectedAction.index, actions.count - 1)
        let selected = actions[selectedAction.index]
        actionListTitleLabel.stringValue = selectedAction.title(for: selected)
        for (slot, button) in actionButtons {
            guard actions.indices.contains(slot.index) else { continue }
            button.title = slot.title(for: actions[slot.index])
            if let button = button as? GlassListItemButton {
                button.itemTitle = slot.title(for: actions[slot.index])
                button.itemSubtitle = slot.subtitle(for: actions[slot.index])
            }
        }
    }
}
