import AppKit

@MainActor
enum AppMenuBuilder {
    static func install(target: AnyObject, showMainAction: Selector, settingsAction: Selector) {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        mainMenu.addItem(appMenuItem)
        appMenuItem.submenu = appMenu
        addItem("Show GlissPad", "", showMainAction, target, to: appMenu)
        addItem("Settings...", ",", settingsAction, target, to: appMenu)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit GlissPad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }

    private static func addItem(
        _ title: String,
        _ keyEquivalent: String,
        _ action: Selector,
        _ target: AnyObject,
        to menu: NSMenu
    ) {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
    }
}
