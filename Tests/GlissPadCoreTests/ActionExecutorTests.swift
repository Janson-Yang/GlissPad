@testable import GlissPadCore
import Foundation
import XCTest

final class ActionExecutorTests: XCTestCase {
    func testRunsActionsInConfiguredOrder() {
        let runner = RecordingScriptRunner(expectedCount: 2)
        let executor = ActionExecutor(scriptRunner: runner, logger: Logger(debugEnabled: false))
        let actions = [
            GestureAction.script(ScriptAction(language: .shell, script: "first")),
            GestureAction.script(ScriptAction(language: .shell, script: "second"))
        ]

        executor.run(actions)

        wait(for: [runner.expectation], timeout: 1)
        XCTAssertEqual(runner.recordedScripts, ["first", "second"])
    }

    func testRunsKeyboardShortcutActionsInOrder() {
        let scriptRunner = RecordingScriptRunner(expectedCount: 1)
        let keyboardRunner = RecordingKeyboardShortcutRunner(expectedCount: 1)
        let executor = ActionExecutor(
            scriptRunner: scriptRunner,
            keyboardShortcutRunner: keyboardRunner,
            logger: Logger(debugEnabled: false)
        )
        let shortcut = KeyboardShortcutAction(mode: .keyCombination, primaryKey: .command, secondaryKey: .a)
        let actions = [
            GestureAction.script(ScriptAction(language: .shell, script: "first")),
            GestureAction.keyboardShortcut(shortcut)
        ]

        executor.run(actions)

        wait(for: [scriptRunner.expectation, keyboardRunner.expectation], timeout: 1)
        XCTAssertEqual(scriptRunner.recordedScripts, ["first"])
        XCTAssertEqual(keyboardRunner.recordedShortcuts, [shortcut])
    }

    func testRunsLatencyActionsBeforeLaterActions() {
        let eventRecorder = ActionEventRecorder()
        let scriptRunner = RecordingScriptRunner(expectedCount: 2, eventRecorder: eventRecorder)
        let latencyRunner = RecordingLatencyRunner(expectedCount: 1, eventRecorder: eventRecorder)
        let executor = ActionExecutor(
            scriptRunner: scriptRunner,
            latencyRunner: latencyRunner,
            logger: Logger(debugEnabled: false)
        )
        let latency = LatencyAction(durationMilliseconds: 250)
        let actions = [
            GestureAction.script(ScriptAction(language: .shell, script: "first")),
            GestureAction.latency(latency),
            GestureAction.script(ScriptAction(language: .shell, script: "second"))
        ]

        executor.run(actions)

        wait(for: [scriptRunner.expectation, latencyRunner.expectation], timeout: 1)
        XCTAssertEqual(scriptRunner.recordedScripts, ["first", "second"])
        XCTAssertEqual(latencyRunner.recordedDurations, [250])
        XCTAssertEqual(eventRecorder.recordedEvents, [.script("first"), .latency(250), .script("second")])
    }

    func testRunsTestHUDActionsInConfiguredOrder() {
        let hudRecorder = RecordingTestHUDHandler(expectedCount: 2)
        let executor = ActionExecutor(
            testHUDActionHandler: hudRecorder.handle,
            logger: Logger(debugEnabled: false)
        )
        let actions = [
            GestureAction.testHUD(TestHUDAction(title: "First", detail: "one")),
            GestureAction.testHUD(TestHUDAction(title: "Second", detail: "two"))
        ]

        executor.run(actions)

        wait(for: [hudRecorder.expectation], timeout: 1)
        XCTAssertEqual(hudRecorder.recordedTitles, ["First", "Second"])
    }
}

private enum RecordedActionEvent: Equatable {
    case script(String)
    case latency(Int)
}

private final class ActionEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [RecordedActionEvent] = []

    func append(_ event: RecordedActionEvent) {
        lock.withLock {
            events.append(event)
        }
    }

    var recordedEvents: [RecordedActionEvent] {
        lock.withLock { events }
    }
}

private final class RecordingScriptRunner: ScriptRunning, @unchecked Sendable {
    let expectation: XCTestExpectation
    private let eventRecorder: ActionEventRecorder?
    private let lock = NSLock()
    private var scripts: [String] = []

    init(expectedCount: Int, eventRecorder: ActionEventRecorder? = nil) {
        expectation = XCTestExpectation(description: "actions executed")
        expectation.expectedFulfillmentCount = expectedCount
        self.eventRecorder = eventRecorder
    }

    var recordedScripts: [String] {
        lock.withLock { scripts }
    }

    func run(_ action: ScriptAction) throws {
        lock.withLock {
            scripts.append(action.script)
        }
        eventRecorder?.append(.script(action.script))
        expectation.fulfill()
    }
}

private final class RecordingKeyboardShortcutRunner: KeyboardShortcutRunning, @unchecked Sendable {
    let expectation: XCTestExpectation
    private let lock = NSLock()
    private var shortcuts: [KeyboardShortcutAction] = []

    init(expectedCount: Int) {
        expectation = XCTestExpectation(description: "keyboard actions executed")
        expectation.expectedFulfillmentCount = expectedCount
    }

    var recordedShortcuts: [KeyboardShortcutAction] {
        lock.withLock { shortcuts }
    }

    func run(_ action: KeyboardShortcutAction) throws {
        lock.withLock {
            shortcuts.append(action)
        }
        expectation.fulfill()
    }
}

private final class RecordingLatencyRunner: LatencyRunning, @unchecked Sendable {
    let expectation: XCTestExpectation
    private let eventRecorder: ActionEventRecorder
    private let lock = NSLock()
    private var durations: [Int] = []

    init(expectedCount: Int, eventRecorder: ActionEventRecorder = ActionEventRecorder()) {
        expectation = XCTestExpectation(description: "latency actions executed")
        expectation.expectedFulfillmentCount = expectedCount
        self.eventRecorder = eventRecorder
    }

    var recordedDurations: [Int] {
        lock.withLock { durations }
    }

    func run(_ action: LatencyAction) throws {
        lock.withLock {
            durations.append(action.durationMilliseconds)
        }
        eventRecorder.append(.latency(action.durationMilliseconds))
        expectation.fulfill()
    }
}

private final class RecordingTestHUDHandler: @unchecked Sendable {
    let expectation: XCTestExpectation
    private let lock = NSLock()
    private var titles: [String] = []

    init(expectedCount: Int) {
        expectation = XCTestExpectation(description: "HUD actions executed")
        expectation.expectedFulfillmentCount = expectedCount
    }

    var recordedTitles: [String] {
        lock.withLock { titles }
    }

    func handle(_ action: TestHUDAction) {
        lock.withLock {
            titles.append(action.title)
        }
        expectation.fulfill()
    }
}
