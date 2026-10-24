import AppKit
import Carbon
import XCTest
import PaneCore
@testable import Pane

final class ShortcutRecordingTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        suite = "PaneTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        // Tests never register global hotkeys or change the user's preferences.
        defaults.set(false, forKey: "shortcutsEnabled")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    private func event(_ type: NSEvent.EventType, code: UInt16,
                       flags: NSEvent.ModifierFlags = [], repeatKey: Bool = false) -> NSEvent {
        NSEvent.keyEvent(with: type, location: .zero, modifierFlags: flags, timestamp: 0,
                        windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "",
                        isARepeat: repeatKey, keyCode: code)!
    }

    func testRecorderCommitsOnKeyUpAndPersistsAfterRestart() {
        let model = AppModel(defaults: defaults)
        let original = model.bindings["left"]
        model.startRecording(.left)
        XCTAssertNil(model.handleRecordingEvent(event(.keyDown, code: 0, flags: [.command, .shift])))
        XCTAssertEqual(model.bindings["left"], original)
        _ = model.handleRecordingEvent(event(.keyDown, code: 0, flags: [.command, .shift], repeatKey: true))
        XCTAssertEqual(model.bindings["left"], original)
        _ = model.handleRecordingEvent(event(.keyUp, code: 0))
        XCTAssertNil(model.recordingAction)
        XCTAssertEqual(model.shortcutLabel(for: .left), "⇧⌘A")
        let reloaded = AppModel(defaults: defaults)
        XCTAssertEqual(reloaded.bindings["left"], model.bindings["left"])
        XCTAssertFalse(reloaded.shortcutsEnabled)
    }

    func testRecorderRejectsDuplicateAndCanRetryWithoutOverwritingOtherAction() {
        let model = AppModel(defaults: defaults)
        let original = model.bindings["left"]
        model.startRecording(.left)
        _ = model.handleRecordingEvent(event(.keyDown, code: 124, flags: [.control, .option]))
        _ = model.handleRecordingEvent(event(.keyUp, code: 124))
        XCTAssertEqual(model.recordingAction, .left)
        XCTAssertTrue(model.recordingError)
        XCTAssertTrue(model.recordingMessage.contains(Action.right.title))
        XCTAssertEqual(model.bindings["left"], original)
        _ = model.handleRecordingEvent(event(.keyDown, code: 123, flags: [.control, .option]))
        _ = model.handleRecordingEvent(event(.keyUp, code: 123))
        XCTAssertNil(model.recordingAction)
        XCTAssertFalse(model.recordingError)
        XCTAssertEqual(model.bindings["left"], original)
    }

    func testEscapeAndFocusLossCancelPendingEdits() {
        let model = AppModel(defaults: defaults)
        let original = model.bindings["left"]
        model.startRecording(.left)
        _ = model.handleRecordingEvent(event(.keyDown, code: 0, flags: [.command]))
        _ = model.handleRecordingEvent(event(.keyDown, code: 53))
        XCTAssertNil(model.recordingAction)
        XCTAssertEqual(model.bindings["left"], original)
        model.startRecording(.left)
        _ = model.handleRecordingEvent(event(.keyDown, code: 0, flags: [.command]))
        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)
        XCTAssertNil(model.recordingAction)
        XCTAssertEqual(model.bindings["left"], original)
        model.startRecording(.left)
        model.startRecording(.right)
        _ = model.handleRecordingEvent(event(.keyUp, code: 0))
        XCTAssertEqual(model.recordingAction, .right)
        XCTAssertEqual(model.bindings["left"], original)
        model.cancelRecording()
    }

    func testLegacyCommandSettingMigratesOnceAndResetUsesStandardDefaults() {
        defaults.set(true, forKey: "extraCommand")
        let model = AppModel(defaults: defaults)
        XCTAssertEqual(model.shortcutLabel(for: .left), "⌃⌥⌘←")
        model.resetShortcuts()
        let reloaded = AppModel(defaults: defaults)
        XCTAssertEqual(reloaded.shortcutLabel(for: .left), "⌃⌥←")
    }

    func testCapsLockAndFunctionFlagsDoNotChangeShortcutIdentity() {
        let shortcut = Shortcut(event: event(.keyDown, code: 123,
                                            flags: [.control, .option, .capsLock, .function, .numericPad]))
        XCTAssertEqual(shortcut.modifiers, [.control, .option])
        XCTAssertEqual(shortcut.carbonModifiers, UInt32(controlKey | optionKey))
        XCTAssertEqual(shortcut.label, "⌃⌥←")
    }
}
