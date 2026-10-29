import AppKit
import Carbon.HIToolbox

/// Tests the production panel and local key monitor against disposable data.
/// Clipboard polling, the app delegate, global hotkeys and paste stay inactive.
@main
@MainActor
struct PanelBehaviorProbe {
    private static var failures = 0
    private static var panel: NSWindow?
    private static var field: NSTextField?
    private static var editor: NSTextView?
    private static let query = "fixture text"

    private static func check(_ condition: Bool, _ description: String) {
        if !condition { failures += 1 }
        print("\(condition ? "PASS" : "FAIL") \(description)")
        fflush(stdout)
    }

    private static func descendants(_ view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap(descendants)
    }

    private static func arrow(_ code: Int, modifiers: NSEvent.ModifierFlags) {
        guard let panel else { return }
        let character = code == kVK_LeftArrow ? "\u{f702}" : "\u{f703}"
        let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
                                    timestamp: ProcessInfo.processInfo.systemUptime,
                                    windowNumber: panel.windowNumber, context: nil,
                                    characters: character, charactersIgnoringModifiers: character,
                                    isARepeat: false, keyCode: UInt16(code))!
        NSApp.postEvent(event, atStart: false)
    }

    private static func clickSecondCard() {
        guard let panel else { return }
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = NSEvent.mouseEvent(with: type, location: NSPoint(x: 400, y: 150),
                                          modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                          windowNumber: panel.windowNumber, context: nil,
                                          eventNumber: 1, clickCount: 1,
                                          pressure: type == .leftMouseDown ? 1 : 0)!
            NSApp.postEvent(event, atStart: false)
        }
    }

    static func main() {
        guard let home = ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"],
              URL(fileURLWithPath: NSHomeDirectory()).resolvingSymlinksInPath()
                == URL(fileURLWithPath: home).resolvingSymlinksInPath(),
              ClipboardStore.localBase.resolvingSymlinksInPath().path.hasPrefix(
                URL(fileURLWithPath: home).resolvingSymlinksInPath().path + "/"),
              FileManager.default.fileExists(atPath: home + "/.pesty-fixture") else {
            fputs("Refusing to run without an isolated home directory.\n", stderr)
            exit(1)
        }
        UserDefaults.standard.setVolatileDomain([
            "iCloudSync": false, "cloudKitSync": false,
            "historyLimit": 100, "showBarResizeHandle": false,
            "hideOnClickOutside": true
        ], forName: UserDefaults.argumentDomain)
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let store = ClipboardStore.shared
        let older = ClipItem(type: .text, text: query + " older")
        store.addCaptured(older)
        store.addCaptured(ClipItem(type: .text, text: query + " newer"))
        let board = store.addPinboard(name: "Fixture board")
        let controller = AppController.shared
        let originalFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            controller.showBar()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            panel = app.windows.first(where: { $0 is BarPanel })
            check(panel?.isVisible == true, "panel remains visible after the show animation")
            check(panel?.isKeyWindow == true, "panel takes keyboard focus")
            // NSApp.isActive is not a reliable proxy for the frontmost process
            // in this unbundled fixture. Check the WindowServer-facing app
            // identity instead, including that it was known before showing.
            check(originalFrontmost != nil && originalFrontmost != ProcessInfo.processInfo.processIdentifier,
                  "another application was frontmost before presentation")
            check(originalFrontmost != nil
                    && NSWorkspace.shared.frontmostApplication?.processIdentifier == originalFrontmost,
                  "showing the panel preserves the frontmost application")
            controller.updateBarSearchText(query)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if let content = panel?.contentView {
                field = descendants(content).compactMap { $0 as? NSTextField }
                    .first(where: \.isEditable)
            }
            let focused = field.map { panel?.makeFirstResponder($0) == true } ?? false
            editor = field?.currentEditor() as? NSTextView
            check(focused && editor != nil, "production search field owns first responder")
            editor?.setSelectedRange(NSRange(location: query.utf16.count, length: 0))
            arrow(kVK_RightArrow, modifiers: .command)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            check(store.source == .pinboard(board.id), "Command-Right switches section with search focused")
            check(store.searchText == query, "section switching preserves the search query")
            arrow(kVK_LeftArrow, modifiers: .command)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            check(store.source == .history, "Command-Left returns to history with search focused")
            editor?.setSelectedRange(NSRange(location: query.utf16.count, length: 0))
            arrow(kVK_LeftArrow, modifiers: [.command, .shift])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            check(store.source == .history, "Command-Shift-Left does not switch sections")
            check(editor?.selectedRange() == NSRange(location: 0, length: query.utf16.count),
                  "Command-Shift-Left selects query text")
            editor?.setSelectedRange(NSRange(location: 5, length: 0))
            arrow(kVK_LeftArrow, modifiers: [])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            check(editor?.selectedRange() == NSRange(location: 4, length: 0),
                  "ordinary Left still moves the query caret")
            check(store.source == .history, "ordinary Left leaves the section unchanged")
            clickSecondCard()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            check(store.selectedID == older.id, "card clicks select correctly in the nonactivating panel")
            check(store.selectionIsPointerDriven, "card clicks retain the immediate-selection scroll policy")
            controller.hideBar()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.1) {
            check(panel?.isVisible == false, "panel hides cleanly after search interaction")
            print("Failures: \(failures)")
            exit(failures == 0 ? 0 : 1)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 12) {
            fputs("Panel probe timed out.\n", stderr)
            exit(1)
        }
        app.run()
    }
}
