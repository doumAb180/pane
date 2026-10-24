import AppKit
import Combine
import SwiftUI

final class AppModel: ObservableObject {
    @Published var targetName = "창을 선택해 주세요"
    @Published var targetIcon: NSImage?
    @Published var trusted = false
    @Published var message = "배치할 창을 선택하고 Pane을 열어 주세요"
    @Published var isError = false
    @Published var shortcutFailures: [String] = []
    @Published var gap: Int {
        didSet { UserDefaults.standard.set(gap, forKey: "gap") }
    }
    @Published var shortcutsEnabled: Bool {
        didSet { UserDefaults.standard.set(shortcutsEnabled, forKey: "shortcutsEnabled"); configureShortcuts() }
    }
    @Published var extraCommand: Bool {
        didSet { UserDefaults.standard.set(extraCommand, forKey: "extraCommand"); configureShortcuts() }
    }
    private let manager = WindowManager()
    private var target: WindowTarget?
    private var targetApplication: NSRunningApplication?
    private var hotKeys: HotKeys?
    var onHotKeyResult: ((String, Bool) -> Void)?

    var modifierLabel: String { extraCommand ? "⌃⌥⌘" : "⌃⌥" }

    init() {
        UserDefaults.standard.register(defaults: ["gap": 8, "shortcutsEnabled": true, "extraCommand": false])
        gap = UserDefaults.standard.integer(forKey: "gap")
        shortcutsEnabled = UserDefaults.standard.bool(forKey: "shortcutsEnabled")
        extraCommand = UserDefaults.standard.bool(forKey: "extraCommand")
        trusted = manager.isTrusted
        hotKeys = HotKeys { [weak self] action in
            DispatchQueue.main.async { self?.performFromKeyboard(action) }
        }
        configureShortcuts()
    }

    func captureTarget() {
        trusted = manager.isTrusted
        let app = NSWorkspace.shared.frontmostApplication
        if app?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            targetApplication = app
        }
        targetName = targetApplication?.localizedName ?? "창을 선택해 주세요"
        targetIcon = targetApplication?.icon
        target = try? manager.target(for: targetApplication)
        message = trusted ? "원하는 배치를 골라 주세요" : "처음 한 번, 접근성 권한이 필요해요"
        isError = false
    }

    func refreshPermission() {
        let value = manager.isTrusted
        if trusted != value {
            trusted = value
            if value {
                target = try? manager.target(for: targetApplication)
                message = "준비됐어요. 배치할 창에서 Pane을 다시 열어 주세요"
                isError = false
            }
        }
    }

    func requestPermission() { manager.requestPermission() }

    func perform(_ action: Action) {
        do {
            // Preserve the exact window selected before opening the popover.
            let selected: WindowTarget
            if let target { selected = target }
            else { selected = try manager.target(for: targetApplication); target = selected }
            message = try manager.perform(action, target: selected, gap: CGFloat(gap))
            isError = false
        } catch {
            message = error.localizedDescription
            isError = true
        }
        trusted = manager.isTrusted
    }

    private func performFromKeyboard(_ action: Action) {
        let front = NSWorkspace.shared.frontmostApplication
        if front?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            targetApplication = front
            target = nil
        }
        perform(action)
        onHotKeyResult?(message, isError)
    }

    private func configureShortcuts() {
        hotKeys?.register(enabled: shortcutsEnabled, extraCommand: extraCommand)
        shortcutFailures = hotKeys?.failures ?? []
    }
}
