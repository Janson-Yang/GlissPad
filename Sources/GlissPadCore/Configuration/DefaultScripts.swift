import Foundation

enum DefaultScripts {
    static let placeholderAppleScript = "return true"

    static let toggleKeyboardViewer = """
    on clickKeyboardViewerMenuItem(menuBarNumber)
        tell application "System Events"
            tell process "TextInputMenuAgent"
                tell menu bar item 1 of menu bar menuBarNumber
                    click
                    delay 0.15
                    tell menu 1
                        set itemTitles to {"Show Keyboard Viewer", "Hide Keyboard Viewer", "显示键盘检视器", "隐藏键盘检视器", "显示键盘查看器", "隐藏键盘查看器", "显示键盘显示程序", "隐藏键盘显示程序"}
                        repeat with itemTitle in itemTitles
                            if exists menu item (itemTitle as text) then
                                click menu item (itemTitle as text)
                                return true
                            end if
                        end repeat
                    end tell
                end tell
            end tell
        end tell
        return false
    end clickKeyboardViewerMenuItem

    set didToggle to false

    repeat with menuBarNumber from 1 to 6
        try
            set didToggle to my clickKeyboardViewerMenuItem(menuBarNumber)
            if didToggle is true then exit repeat
        end try
    end repeat

    if didToggle is false then error "Keyboard Viewer menu item was not found."
    """
}
