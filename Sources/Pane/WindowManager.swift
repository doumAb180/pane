import AppKit
import ApplicationServices
import PaneCore

struct WindowTarget {
    let window: AXUIElement
    let name: String
    let pid: pid_t
}

enum WindowFailure: Error {
    case message(String)
    var text: LocalizedText {
        switch self { case .message(let key): return .key(key) }
    }
}

final class WindowManager {
    private struct SavedFrame {
        let window: AXUIElement
        let pid: pid_t
        var frame: CGRect
    }
    private var history: [SavedFrame] = []

    var isTrusted: Bool { AXIsProcessTrusted() }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func target(for app: NSRunningApplication?) throws -> WindowTarget {
        guard isTrusted else { throw WindowFailure.message("Enable accessibility permission to arrange windows.") }
        guard let app, app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              !app.isTerminated else { throw WindowFailure.message("Select an app window first.") }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.8)
        guard let value = attribute(application, kAXFocusedWindowAttribute),
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            throw WindowFailure.message("The selected app has no window to arrange.")
        }
        let window = unsafeBitCast(value, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(window, 0.8)
        return WindowTarget(window: window, name: app.localizedName ?? "", pid: app.processIdentifier)
    }

    func perform(_ action: Action, target: WindowTarget, gap: CGFloat) throws -> LocalizedText {
        guard isTrusted else { throw WindowFailure.message("Check accessibility permission.") }
        if (attribute(target.window, "AXFullScreen") as? Bool) == true {
            throw WindowFailure.message("Exit full-screen mode and try again.")
        }
        let current = try frame(of: target.window)
        let screens = NSScreen.screens
        guard let primary = screens.first else { throw WindowFailure.message("No display found.") }
        let visible = screens.map {
            ScreenGeometry.accessibilityFrame(fromAppKit: $0.visibleFrame, primaryTop: primary.frame.maxY)
        }
        let full = screens.map {
            ScreenGeometry.accessibilityFrame(fromAppKit: $0.frame, primaryTop: primary.frame.maxY)
        }
        guard let index = ScreenGeometry.bestScreen(for: current, screens: full) else {
            throw WindowFailure.message("No display found.")
        }
        let destination: CGRect
        if let layout = action.layout {
            destination = layout.nextFrame(in: visible[index], current: current, gap: gap)
        } else if action == .restore {
            guard let saved = history.last(where: { $0.pid == target.pid && CFEqual($0.window, target.window) }) else {
                throw WindowFailure.message("No previous layout to restore for this window.")
            }
            // A disconnected display must not strand the restored window off-screen.
            let screen = ScreenGeometry.bestScreen(for: saved.frame, screens: visible) ?? index
            destination = fitted(saved.frame, inside: visible[screen])
        } else {
            guard screens.count > 1 else { throw WindowFailure.message("Only one display is connected.") }
            let next = (index + (action == .nextScreen ? 1 : screens.count - 1)) % screens.count
            destination = ScreenGeometry.move(current, from: visible[index], to: visible[next])
        }
        if approximatelyEqual(current, destination) { return .key("Already in the selected position") }
        // Store before writes so even a partial AX failure can be undone.
        let previous = history.firstIndex { $0.pid == target.pid && CFEqual($0.window, target.window) }
        if let previous { history.remove(at: previous) }
        history.append(SavedFrame(window: target.window, pid: target.pid, frame: current))
        if history.count > 80 { history.removeFirst(history.count - 80) }
        try setFrame(destination, on: target.window)
        let actual = try frame(of: target.window)
        if !approximatelyEqual(actual, destination) {
            return .key("Arranged · This app limits its window size")
        }
        if let layout = action.layout, [.left, .right, .top, .bottom].contains(action) {
            let half = layout.frame(in: visible[index], current: current, gap: gap)
            let fraction = approximatelyEqual(destination, half) ? "½" : "¼"
            return .key("{0} {1} applied", [action.shortTitleText, .verbatim(fraction)])
        }
        return .key("{0} complete", [action.titleText])
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func frame(of window: AXUIElement) throws -> CGRect {
        guard let p = attribute(window, kAXPositionAttribute), let s = attribute(window, kAXSizeAttribute),
              CFGetTypeID(p) == AXValueGetTypeID(), CFGetTypeID(s) == AXValueGetTypeID() else {
            throw WindowFailure.message("Could not read window information. Select the window again.")
        }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(unsafeBitCast(p, to: AXValue.self), .cgPoint, &point),
              AXValueGetValue(unsafeBitCast(s, to: AXValue.self), .cgSize, &size) else {
            throw WindowFailure.message("Could not read the window position.")
        }
        return CGRect(origin: point, size: size)
    }

    private func setFrame(_ frame: CGRect, on window: AXUIElement) throws {
        var position = frame.origin
        var size = frame.size
        guard let p = AXValueCreate(.cgPoint, &position), let s = AXValueCreate(.cgSize, &size) else { return }
        // Resize before moving, then again on the destination display. Some apps clamp
        // sizes to their current screen, so a second pass is required across displays.
        _ = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, s)
        let move = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, p)
        let resize = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, s)
        _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, p)
        guard move == .success, resize == .success else {
            throw WindowFailure.message("This window does not support moving or resizing.")
        }
    }

    private func fitted(_ frame: CGRect, inside bounds: CGRect) -> CGRect {
        let size = CGSize(width: min(frame.width, bounds.width), height: min(frame.height, bounds.height))
        return CGRect(x: max(bounds.minX, min(frame.minX, bounds.maxX - size.width)),
                      y: max(bounds.minY, min(frame.minY, bounds.maxY - size.height)),
                      width: size.width, height: size.height)
    }

    private func approximatelyEqual(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 3 && abs(a.minY - b.minY) < 3 &&
        abs(a.width - b.width) < 3 && abs(a.height - b.height) < 3
    }
}
