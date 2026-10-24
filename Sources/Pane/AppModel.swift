import AppKit
import Combine
import SwiftUI
import PaneCore

final class AppModel: ObservableObject {
    @Published var targetName = "창을 선택해 주세요"
    @Published var targetIcon: NSImage?
    @Published var trusted = false
    @Published var message = "배치할 창을 선택하고 Pane을 열어 주세요"
    @Published var isError = false
    @Published var shortcutFailures: [String] = []
    @Published var gap: Int {
        didSet { defaults.set(gap, forKey: "gap") }
    }
    @Published var shortcutsEnabled: Bool {
        didSet { defaults.set(shortcutsEnabled, forKey: "shortcutsEnabled"); configureShortcuts() }
    }
    @Published private(set) var bindings: ShortcutBindings
    @Published private(set) var recordingAction: Action?
    @Published private(set) var recordingMessage = ""
    @Published private(set) var recordingError = false
    private let defaults: UserDefaults
    private var eventMonitor: Any?
    private var resignObserver: NSObjectProtocol?
    private var pendingShortcut: Shortcut?
    private let manager = WindowManager()
    private var target: WindowTarget?
    private var targetApplication: NSRunningApplication?
    private var hotKeys: HotKeys?
    var onHotKeyResult: ((String, Bool) -> Void)?
    var onBeginRecording: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["gap": 8, "shortcutsEnabled": true, "extraCommand": false])
        gap = defaults.integer(forKey: "gap")
        shortcutsEnabled = defaults.bool(forKey: "shortcutsEnabled")
        var saved = defaults.data(forKey: "shortcutBindings.v1")
        if saved == nil, defaults.bool(forKey: "extraCommand") {
            saved = try? JSONEncoder().encode(Action.defaultShortcuts(extraCommand: true))
        }
        bindings = ShortcutBindings(defaults: Action.defaultShortcuts(extraCommand: false), savedData: saved)
        // Persist migration once; resetting later must not restore the legacy toggle.
        defaults.set(try? bindings.encoded(), forKey: "shortcutBindings.v1")
        trusted = manager.isTrusted
        hotKeys = HotKeys { [weak self] action in
            DispatchQueue.main.async { self?.performFromKeyboard(action) }
        }
        configureShortcuts()
    }

    func shortcutLabel(for action: Action) -> String {
        bindings[action.shortcutID]?.label ?? "미설정"
    }

    func startRecording(_ action: Action) {
        cancelRecording()
        recordingAction = action
        recordingMessage = "새 조합을 눌러 주세요 · Esc로 취소"
        recordingError = false
        configureShortcuts()
        onBeginRecording?()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self, self.recordingAction != nil else { return event }
            return self.handleRecordingEvent(event)
        }
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.cancelRecording() }
    }

    // Commit on key-up so the key used to record cannot immediately move a window.
    func handleRecordingEvent(_ event: NSEvent) -> NSEvent? {
        guard let action = recordingAction else { return event }
        if event.type == .keyUp {
            if let shortcut = pendingShortcut, shortcut.keyCode == UInt32(event.keyCode) {
                do {
                    try bindings.assign(shortcut, to: action.shortcutID)
                    saveBindings()
                    cancelRecording()
                    recordingMessage = "\(action.title) · \(shortcut.label) 저장됨"
                } catch { showRecordingError(error) }
            }
            return nil
        }
        guard event.type == .keyDown else { return event }
        guard !event.isARepeat else { return nil }
        let shortcut = Shortcut(event: event)
        if event.keyCode == 53, shortcut.modifiers.isEmpty {
            cancelRecording()
            return nil
        }
        pendingShortcut = nil
        do {
            try bindings.validate(shortcut, for: action.shortcutID)
            pendingShortcut = shortcut
            recordingError = false
            recordingMessage = "\(shortcut.label) · 키를 놓으면 저장됩니다"
        } catch { showRecordingError(error) }
        return nil
    }

    private func showRecordingError(_ error: Error) {
        pendingShortcut = nil
        recordingError = true
        if case ShortcutBindingError.conflict(let id) = error,
           let other = Action.allCases.first(where: { $0.shortcutID == id }) {
            recordingMessage = "‘\(other.title)’에서 사용 중이에요. 다른 조합을 눌러 주세요."
        } else {
            recordingMessage = "Control, Option, Command 중 하나 이상과 다른 키를 함께 눌러 주세요."
        }
    }

    func cancelRecording() {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        resignObserver = nil
        pendingShortcut = nil
        let wasRecording = recordingAction != nil
        recordingAction = nil
        recordingMessage = ""
        recordingError = false
        if wasRecording { configureShortcuts() }
    }

    func resetShortcuts() {
        cancelRecording()
        bindings.reset()
        saveBindings()
        configureShortcuts()
        recordingMessage = "모든 단축키를 기본값으로 복원했습니다"
    }

    private func saveBindings() {
        defaults.set(try? bindings.encoded(), forKey: "shortcutBindings.v1")
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
        guard recordingAction == nil else { return }
        let front = NSWorkspace.shared.frontmostApplication
        if front?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            targetApplication = front
            target = nil
        }
        perform(action)
        onHotKeyResult?(message, isError)
    }

    private func configureShortcuts() {
        hotKeys?.register(enabled: shortcutsEnabled && recordingAction == nil, bindings: bindings)
        shortcutFailures = hotKeys?.failures ?? []
    }

    deinit {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
    }
}
