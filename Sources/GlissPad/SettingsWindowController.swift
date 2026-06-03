import AppKit
import GlissPadCore

@MainActor
final class SettingsWindowController: NSWindowController {
    private let preferencesStore: UserDefaultsAppPreferencesStore
    private let statusItemController: StatusItemController
    private let loginItemController: LoginItemController
    private let showStatusItemButton = NSButton(checkboxWithTitle: "Show menu bar icon", target: nil, action: nil)
    private let launchAtLoginButton = NSButton(checkboxWithTitle: "Open at login", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "")

    init(
        preferencesStore: UserDefaultsAppPreferencesStore,
        statusItemController: StatusItemController,
        loginItemController: LoginItemController
    ) {
        self.preferencesStore = preferencesStore
        self.statusItemController = statusItemController
        self.loginItemController = loginItemController
        super.init(window: SettingsWindowController.makeWindow())
        window?.contentView = makeContentView()
        reloadControls()
    }

    required init?(coder: NSCoder) {
        nil
    }

    @objc private func showStatusItemChanged() {
        let showsStatusItem = showStatusItemButton.state == .on
        preferencesStore.preferences = AppPreferences(showsStatusItem: showsStatusItem)
        statusItemController.applyVisibility(showsStatusItem)
        statusLabel.stringValue = "Settings saved."
    }

    @objc private func launchAtLoginChanged() {
        let isEnabled = launchAtLoginButton.state == .on
        do {
            try loginItemController.setEnabled(isEnabled)
            statusLabel.stringValue = "Settings saved."
        } catch {
            launchAtLoginButton.state = loginItemController.isEnabled ? .on : .off
            statusLabel.stringValue = "Login item update failed: \(error)"
        }
    }

    private func reloadControls() {
        showStatusItemButton.state = preferencesStore.preferences.showsStatusItem ? .on : .off
        launchAtLoginButton.state = loginItemController.isEnabled ? .on : .off
    }

    private static func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "GlissPad Settings"
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = false
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.center()
        return window
    }

    private func makeContentView() -> NSView {
        let root = SettingsWindowController.rootView()
        let stack = NSStackView(views: [
            SettingsWindowController.titleLabel(),
            showStatusItemButton,
            launchAtLoginButton,
            statusLabel
        ])
        showStatusItemButton.target = self
        showStatusItemButton.action = #selector(showStatusItemChanged)
        launchAtLoginButton.target = self
        launchAtLoginButton.action = #selector(launchAtLoginChanged)
        LiquidGlassStyle.configureStatus(statusLabel)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 32)
        ])
        return root
    }

    private static func rootView() -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .windowBackground
        view.blendingMode = .withinWindow
        view.state = .active
        return view
    }

    private static func titleLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "Settings")
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        return label
    }
}
