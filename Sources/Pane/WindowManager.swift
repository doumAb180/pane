import AppKit
import ApplicationServices
import PaneCore

struct WindowTarget {
    let window: AXUIElement
    let name: String
    let pid: pid_t
}

enum WindowFailure: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let text): return text }
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
        guard isTrusted else { throw WindowFailure.message("접근성 권한을 켜면 창을 배치할 수 있어요.") }
        guard let app, app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              !app.isTerminated else { throw WindowFailure.message("배치할 앱의 창을 먼저 선택해 주세요.") }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.8)
        guard let value = attribute(application, kAXFocusedWindowAttribute),
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            throw WindowFailure.message("선택한 앱에 배치할 수 있는 창이 없어요.")
        }
        let window = unsafeBitCast(value, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(window, 0.8)
        return WindowTarget(window: window, name: app.localizedName ?? "앱", pid: app.processIdentifier)
    }

    func perform(_ action: Action, target: WindowTarget, gap: CGFloat) throws -> String {
        guard isTrusted else { throw WindowFailure.message("접근성 권한을 확인해 주세요.") }
        if (attribute(target.window, "AXFullScreen") as? Bool) == true {
            throw WindowFailure.message("전체 화면 모드를 해제한 뒤 다시 시도해 주세요.")
        }
        let current = try frame(of: target.window)
        let screens = NSScreen.screens
        guard let primary = screens.first else { throw WindowFailure.message("화면을 찾을 수 없어요.") }
        let visible = screens.map {
            ScreenGeometry.accessibilityFrame(fromAppKit: $0.visibleFrame, primaryTop: primary.frame.maxY)
        }
        let full = screens.map {
            ScreenGeometry.accessibilityFrame(fromAppKit: $0.frame, primaryTop: primary.frame.maxY)
        }
        guard let index = ScreenGeometry.bestScreen(for: current, screens: full) else {
            throw WindowFailure.message("화면을 찾을 수 없어요.")
        }
        let destination: CGRect
        if let layout = action.layout {
            destination = layout.nextFrame(in: visible[index], current: current, gap: gap)
        } else if action == .restore {
            guard let saved = history.last(where: { $0.pid == target.pid && CFEqual($0.window, target.window) }) else {
                throw WindowFailure.message("이 창에는 복원할 배치가 아직 없어요.")
            }
            // A disconnected display must not strand the restored window off-screen.
            let screen = ScreenGeometry.bestScreen(for: saved.frame, screens: visible) ?? index
            destination = fitted(saved.frame, inside: visible[screen])
        } else {
            guard screens.count > 1 else { throw WindowFailure.message("연결된 모니터가 하나뿐이에요.") }
            let next = (index + (action == .nextScreen ? 1 : screens.count - 1)) % screens.count
            destination = ScreenGeometry.move(current, from: visible[index], to: visible[next])
        }
        if approximatelyEqual(current, destination) { return "이미 선택한 위치에 있어요" }
        // Store before writes so even a partial AX failure can be undone.
        let previous = history.firstIndex { $0.pid == target.pid && CFEqual($0.window, target.window) }
        if let previous { history.remove(at: previous) }
        history.append(SavedFrame(window: target.window, pid: target.pid, frame: current))
        if history.count > 80 { history.removeFirst(history.count - 80) }
        try setFrame(destination, on: target.window)
        let actual = try frame(of: target.window)
        if !approximatelyEqual(actual, destination) {
            return "배치했어요 · 앱의 창 크기 제한이 적용됐어요"
        }
        return "\(action.title) 완료"
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func frame(of window: AXUIElement) throws -> CGRect {
        guard let p = attribute(window, kAXPositionAttribute), let s = attribute(window, kAXSizeAttribute),
              CFGetTypeID(p) == AXValueGetTypeID(), CFGetTypeID(s) == AXValueGetTypeID() else {
            throw WindowFailure.message("창 정보를 읽지 못했어요. 창을 다시 선택해 주세요.")
        }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(unsafeBitCast(p, to: AXValue.self), .cgPoint, &point),
              AXValueGetValue(unsafeBitCast(s, to: AXValue.self), .cgSize, &size) else {
            throw WindowFailure.message("창 위치를 읽을 수 없어요.")
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
            throw WindowFailure.message("이 창은 이동 또는 크기 변경을 지원하지 않아요.")
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
