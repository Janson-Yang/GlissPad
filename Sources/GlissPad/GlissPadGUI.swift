import AppKit
import GlissPadCore

@main
@MainActor
enum GlissPadGUI {
    static func main() {
        do {
            let options = try CommandLineOptions.parse(arguments: CommandLine.arguments)
            if options.showHelp {
                throw AppError.helpRequested(CommandLineOptions.helpText)
            }

            switch options.mode {
            case .gui:
                run(options: options)
            case .agent:
                let application = try Application.bootstrap(arguments: CommandLine.arguments)
                application.run()
            }
        } catch AppError.helpRequested(let helpText) {
            FileHandle.standardOutput.write(Data("\(helpText)\n".utf8))
            exit(EXIT_SUCCESS)
        } catch {
            FileHandle.standardError.write(Data("glisspad: \(error)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    static func run(options: CommandLineOptions) {
        let app = NSApplication.shared
        let delegate = GlissPadAppDelegate(options: options)
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.activate(ignoringOtherApps: true)
        app.run()
    }
}

@MainActor
final class GlissPadAppDelegate: NSObject, NSApplicationDelegate {
    private let options: CommandLineOptions
    private let preferencesStore = UserDefaultsAppPreferencesStore()
    private let loginItemController = LoginItemController()
    private var windowController: GestureEditorWindowController?
    private var statusItemController: StatusItemController?
    private var settingsWindowController: SettingsWindowController?
    private var permissionTimer: Timer?
    private var wasAccessibilityTrusted = false

    init(options: CommandLineOptions) {
        self.options = options
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = ConfigurationStore(configurationURL: configurationURL)
        let logger = Logger(debugEnabled: options.debug, logFileURL: logFileURL)
        AppMenuBuilder.install(
            target: self,
            showMainAction: #selector(showMainWindow(_:)),
            settingsAction: #selector(showSettings(_:))
        )
        AccessibilityPermission.requestIfNeeded(prompt: options.promptForPermissions, logger: logger)
        openAccessibilitySettingsIfNeeded()
        wasAccessibilityTrusted = AccessibilityPermission.isTrusted
        let controller = GestureEditorWindowController(store: store, logger: logger)
        windowController = controller
        let statusController = StatusItemController { [weak self] in
            self?.showMainWindow(nil)
        }
        statusItemController = statusController
        statusController.applyVisibility(preferencesStore.preferences.showsStatusItem)
        showMainWindow(nil)
        DispatchQueue.main.async {
            controller.startListener()
        }
        permissionTimer = Timer.scheduledTimer(
            timeInterval: 2,
            target: self,
            selector: #selector(checkAccessibilityPermission),
            userInfo: nil,
            repeats: true
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow(nil)
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        windowController?.prepareForTermination()
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
    }

    @objc func showMainWindow(_ sender: Any?) {
        windowController?.showWindow(sender)
        windowController?.window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showSettings(_ sender: Any?) {
        guard let statusItemController else { return }
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                preferencesStore: preferencesStore,
                statusItemController: statusItemController,
                loginItemController: loginItemController
            )
        }
        settingsWindowController?.showWindow(sender)
        settingsWindowController?.window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var configurationURL: URL {
        if let path = options.configPath {
            return URL(fileURLWithPath: path)
        }
        return ConfigurationStore.defaultConfigurationURL()
    }

    private var logFileURL: URL {
        configurationURL
            .deletingLastPathComponent()
            .appendingPathComponent("glisspad.log")
    }

    private func openAccessibilitySettingsIfNeeded() {
        guard !AccessibilityPermission.isTrusted,
              let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func checkAccessibilityPermission() {
        let isTrusted = AccessibilityPermission.isTrusted
        defer { wasAccessibilityTrusted = isTrusted }
        guard isTrusted, !wasAccessibilityTrusted else { return }
        windowController?.restartListener()
    }
}
