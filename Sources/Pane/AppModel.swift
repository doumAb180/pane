import AppKit
import Combine
import SwiftUI
import PaneCore

final class AppModel: ObservableObject {
    @Published private var selectedTargetName: String?
    var targetName: String { selectedTargetName ?? text("Select a window") }
    @Published var targetIcon: NSImage?
    @Published var trusted = false
    @Published private var messageText: LocalizedText = .key("Select a window to arrange, then open Pane")
    var message: String { messageText.rendered(in: language) }
    @Published var isError = false
    @Published private var shortcutFailureTexts: [LocalizedText] = []
    var shortcutFailures: [String] { shortcutFailureTexts.map { $0.rendered(in: language) } }
    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: "appLanguage.v1")
            onLanguageChange?()
        }
    }
    var onLanguageChange: (() -> Void)?

    func text(_ key: String, _ arguments: String...) -> String {
        LocalizedText.key(key, arguments.map { .verbatim($0) }).rendered(in: language)
    }
    @Published var gap: Int {
        didSet { defaults.set(gap, forKey: "gap") }
    }
    @Published var shortcutsEnabled: Bool {
        didSet { defaults.set(shortcutsEnabled, forKey: "shortcutsEnabled"); configureShortcuts() }
    }
    @Published private(set) var bindings: ShortcutBindings
    @Published private(set) var recordingAction: Action?
    @Published private var recordingText: LocalizedText = .verbatim("")
    var recordingMessage: String { recordingText.rendered(in: language) }
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
        language = AppLanguage(rawValue: defaults.string(forKey: "appLanguage.v1") ?? "system") ?? .system
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
        bindings[action.shortcutID]?.label ?? text("Not set")
    }

    func startRecording(_ action: Action) {
        cancelRecording()
        recordingAction = action
        recordingText = .key("Press a new combination · Esc to cancel")
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
                    recordingText = .key("{0} · {1} saved", [action.titleText, .verbatim(shortcut.label)])
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
            recordingText = .key("{0} · Release the key to save", [.verbatim(shortcut.label)])
        } catch { showRecordingError(error) }
        return nil
    }

    private func showRecordingError(_ error: Error) {
        pendingShortcut = nil
        recordingError = true
        if case ShortcutBindingError.conflict(let id) = error,
           let other = Action.allCases.first(where: { $0.shortcutID == id }) {
            recordingText = .key("Already used by “{0}”. Try another combination.", [other.titleText])
        } else {
            recordingText = .key("Include Control, Option, or Command with another key.")
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
        recordingText = .verbatim("")
        recordingError = false
        if wasRecording { configureShortcuts() }
    }

    func resetShortcuts() {
        cancelRecording()
        bindings.reset()
        saveBindings()
        configureShortcuts()
        recordingText = .key("All shortcuts restored to defaults")
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
        selectedTargetName = targetApplication?.localizedName
        targetIcon = targetApplication?.icon
        target = try? manager.target(for: targetApplication)
        messageText = trusted ? .key("Choose a layout") : .key("Accessibility permission is needed to get started")
        isError = false
    }

    func refreshPermission() {
        let value = manager.isTrusted
        if trusted != value {
            trusted = value
            if value {
                target = try? manager.target(for: targetApplication)
                messageText = .key("Ready. Select a window and reopen Pane")
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
            messageText = try manager.perform(action, target: selected, gap: CGFloat(gap))
            isError = false
        } catch {
            messageText = (error as? WindowFailure)?.text ?? .verbatim(error.localizedDescription)
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
        shortcutFailureTexts = hotKeys?.failures ?? []
    }

    deinit {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
    }
}
